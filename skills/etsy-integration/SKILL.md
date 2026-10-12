---
name: etsy-integration
description: Load when building or debugging an Etsy Open API v3 integration in a Next.js/Vercel app: OAuth with PKCE, access and refresh tokens and who may refresh them, the x-api-key header with the app's shared secret, shop, listing and review reads, receipts and orders, order webhooks, idempotent sale recording and profit estimates, Slack sale and weekly/monthly reports, Vercel cron jobs, and keeping one-of-a-kind inventory in step across Etsy and other sales channels (own-site Stripe checkout, product feeds such as a Pinterest catalog). Captures lessons from a working implementation (shayna-art), not API documentation.
version: 1.0.0
user-invocable: false
---

# Etsy integration (Open API v3)

## Summary

A working Etsy integration in a Next.js app on Vercel: connect the shop owner's account once through a guarded link, keep the token alive without a person, record every order from a webhook plus a daily catch-up, estimate profit at sale time, and report to Slack. The decisions below are what survived contact with Etsy.

**Reference implementation: `/Users/drewlarsen/Projects/shayna-art`.** Read its `docs/etsy.md` first (shop and app ids, channel names, the plan of record live there, not here).

| Concern | Path |
| --- | --- |
| API client, rate spacing, paging, field renaming | `packages/engine/src/etsy/api.ts` |
| Auth URL, code exchange, refresh | `packages/engine/src/etsy/oauth.ts` |
| The one place a token is refreshed | `packages/engine/src/etsy/session.ts` |
| PKCE helpers (shared with Pinterest) | `packages/engine/src/pkce.ts` |
| Error classes | `packages/engine/src/etsy/errors.ts` |
| Receipt parsing, money | `packages/engine/src/etsy/receipt.ts` |
| Order sync, pending-post rules | `packages/engine/src/etsy/sync-orders.ts` |
| Profit estimate | `packages/engine/src/etsy/order-cost.ts` |
| Daily job, weekly and monthly reports | `packages/engine/src/etsy/run-daily.ts`, `weekly-report.ts`, `monthly-report.ts` |
| Token storage, refresh lock, orders, stats, runs | `packages/db/src/oauth-grants.ts`, `packages/db/src/etsy.ts`, `packages/db/src/schemas/` |
| Routes | `apps/web/app/etsy/connect`, `apps/web/app/etsy/etsy-grant-oauth-access-callback`, `apps/web/app/api/webhooks/etsy`, `apps/web/app/api/cron/etsy`, `apps/web/app/api/cron/etsy-report`, `apps/web/app/api/etsy/monthly-report` |
| Site glue (env reads, Slack copy) | `apps/web/lib/etsy.ts` |

## Invariants

1. **Every request carries `x-api-key: {keystring}:{shared secret}`, the token exchange and refresh included.** Etsy refuses requests with the keystring alone (since 2026-02-09), so an app sending only the keystring fails every call. Shop-acting calls also send `Authorization: Bearer <access token>`.
2. **Access tokens last one hour; refresh tokens last 90 days, and every refresh returns a new pair.** Anything that touches Etsy at least every 90 days never needs a person; going quiet longer forces a reconnect.
3. **Exactly one function may refresh (`loadEtsySession`), under a lock, writing the new token before use.** A refresh spends the old refresh token, so two concurrent refreshers (webhook and cron) leave one holding a dead token and the chain ends. The lock is a field with an expiry on the token owner's document (30 s), so a crash cannot hold it; waiters re-read the token instead of refreshing. Refresh when the token is within 10 minutes of expiry so a long job is not handed a dying token. Keep the previous refresh token if a response omits one.
4. **Store the token response exactly as Etsy sent it, plus your own `written_at` timestamp.** Etsy gives `expires_in` but not an issue time, so expiry cannot be computed without your own stamp. Retry the post-refresh write (`writeWithRetry`): losing it ends the chain.
5. **PKCE is S256 with a stored verifier.** The verifier (32 random bytes, base64url) is written when the grant starts and read by the callback; the challenge is its SHA-256, base64url, no padding. The callback refuses to exchange when no verifier is pending. The shared-secret header applies here too.
6. **The callback URL is registered with Etsy and cannot change.** Pick it once (shayna-art: `/etsy/etsy-grant-oauth-access-callback`) and treat it as frozen.
7. **Error classification drives behavior.** 401 on a call, or 400/401 on refresh (`invalid_grant`), is `EtsyReconnectNeededError`: no retry helps, a person must reconnect, and the job alerts Slack. 429 and 5xx are `EtsyError`; network failures and the 30 s timeout are wrapped as `etsy_unreachable`. A job must be able to tell "Etsy said no" from "Etsy is down".
8. **Rate limit: 10 requests/second and 10,000/day per app.** The client spaces calls at least 125 ms apart per process. Separate serverless instances each keep their own spacing, so the margin stays wide and call counts per job stay small.
9. **Money is integer amount over a `divisor`.** Convert with `Math.round(amount * 100 / divisor)` to cents at the parse boundary; never use floats downstream.
10. **A webhook delivery carries only a link to the receipt.** Handle every event type the same way: fetch the receipt, save it, post what it still owes. Do not trust the payload for order data.
11. **Verify webhook signatures (Standard Webhooks style).** HMAC-SHA256 over `{webhook-id}.{webhook-timestamp}.{raw body}`, keyed with the base64 part of the `whsec_` secret, compared in constant time against each space-separated `v1,<base64>` entry, with a 5-minute timestamp tolerance. Verify against the raw body, before parsing. Answer 500 on failure so Etsy retries (about a day and a half); a signed but unparseable body gets 200 because a retry will not fix it.
12. **Recording and posting are idempotent.** Orders are upserted by receipt id: Etsy-sourced fields are overwritten on each sync, your own fields (estimate, actual, `*_posted_at`) are set only on insert and survive. A Slack message is sent only by the caller that wins an atomic claim (`updateOne({receipt_id, field: null}, {$set})` returns modified count 1); a failed post releases the claim so the next run retries. The webhook and the daily job both try, so without the claim every sale posts twice.
13. **Backfills and first runs must not announce history.** Loading old orders stamps them as already posted; the first review check records existing reviews silently. Otherwise years of old sales arrive in Slack as new.
14. **Etsy has no review id.** Key a review by `transaction-<id>` when present, else by creation time plus listing.
15. **Cron may fire twice.** Take a per-job per-day lock (insert with `_id: "job:YYYY-MM-DD"`, treat duplicate key as "already ran") and record every run (outcome, summary, error code) in a runs table.
16. **Store the least buyer data that serves the job.** Shayna's records keep only ship-to city, state, ZIP and country; the street address is used for a shipping quote and dropped.
17. **Variation values arrive HTML-escaped** (`8 x 10&quot;`). Decode before parsing size or frame; an empty SKU means none.

## The proven design

**Generic plumbing (candidates for a shared package):**
- PKCE and OAuth state helpers (`pkce.ts`; Pinterest shares them).
- Authorize URL builder, code exchange, refresh, with the api-key header on token calls.
- `fetchFromEtsy` (spacing, timeout, error wrapping), `callEtsyApi` (401/429 classification), `fetchAllPages` (offset paging, `limit` 100, stop when a short page or `count` reached).
- Zod schemas that rename Etsy's field names once, at the boundary (`Shop`, `ListingSummary`, `ShopReview`, `Receipt`).
- `loadEtsySession` with the expiring lock; token read/write/lock functions.
- Webhook signature check, constant-time secret compare, connect-link guard, claim/release post primitives, run lock and run log.

**Per-app policy (stays in each app):**
- Which scopes to request (shayna-art: `listings_r listings_w listings_d shops_r shops_w transactions_r`; request only what code uses).
- Which orders fields are kept, what counts as canceled (status matches `cancel|refund`), what Slack says and in which channel.
- Profit math: Etsy price (subtotal + shipping) minus print-on-demand cost minus Etsy fees. Fee model used: 6.5% of subtotal+shipping, 3% of grand total + 25 cents processing, 20 cents renewal per item. Check these against current Etsy fees before reusing.
- A failed or impossible estimate is stored on the order (`estimate.error`, `unpricedLines`, null profit) and retried on the next sync; it never blocks saving or announcing the sale.
- Reports: weekly (this week vs prior, from own records, `?dryRun=1` to preview), monthly P&L (actual profit where reconciled, else estimate).

**Flow:** webhook (`order.paid`, `order.shipped`, `order.canceled`, `order.delivered`) gives immediacy; the daily job (renew token, re-sync receipts modified in the last 3 days, snapshot each active listing's lifetime views and favorites, check reviews) gives correctness. Weekly views are the difference of two daily snapshots, so view stats need a week of history before they appear.

## Setup checklist

Human, on Etsy's developer site:
1. Create the app (a seller app approved instantly in this case) and note the keystring and shared secret.
2. Register the callback URL exactly as the code builds it.
3. In the app's Webhook portal, register the endpoint for the four `order.*` events and copy the `whsec_` signing secret.

Env var names by role (set in Vercel; mark secrets sensitive):
- App identity: `ETSY_KEYSTRING`, `ETSY_SHARED_SECRET`
- Connect guard: `ETSY_CONNECT_KEY` (long random string)
- Webhook: `ETSY_WEBHOOK_SECRET`
- Cron and report auth: `CRON_SECRET` (cron routes check `Authorization: Bearer`)
- Slack: `SLACK_OAUTH_TOKEN`
- Optional cost quotes: `LUMA_API_KEY`, `LUMA_API_SECRET` (print-on-demand price; omit and orders are still saved, just unestimated)

Connect flow: open `/etsy/connect?key=$ETSY_CONNECT_KEY`, press the button, sign in to Etsy as the shop owner, approve. The GET only renders a button; the POST writes the verifier and 303-redirects to Etsy. Link previewers open links before anyone clicks, so a GET that wrote a verifier could clobber a sign-in in progress. The callback exchanges the code, stores the token, then reads the shop and reports its active listing count to prove the token works. The route must be `nodejs` runtime, `force-dynamic`, `noindex`. Reconnect the same way whenever a job reports `etsy_reconnect_needed`.

Cron lives in `vercel.json` (daily job 14:00 UTC; weekly report Monday 15:45 UTC). Routes that talk to Etsy set a long `maxDuration` (60 s webhook, 300 s daily job).

## Multi-channel selling hazard

An original or any one-of-a-kind item must exist in exactly one place that can sell it at a time. A sale in any channel (Etsy listing, own-site Stripe checkout, a product feed that deep-links to purchase) must take the item off every other channel, or two buyers pay for one object and one of them gets a refund and an apology.

What the sources support:
- The shayna-art Etsy integration records and reports orders; it does not change listing availability on Etsy or elsewhere. Nothing in it prevents double-selling.
- The Pinterest product feed (`pinterest/catalog.tsv`) lists each available original at its own price and is built once per deploy; Pinterest fetches it every 24 hours. So a sold original stays advertised until the next deploy plus the next fetch.
- Etsy carries only some of the paintings; the site's own pages are where both originals and prints are bought.

So when adding own-site e-commerce: (1) decide which channel is the source of truth for availability of each original; (2) a sale event in any channel (Etsy `order.paid` webhook, Stripe payment event) must mark the item sold in that source of truth; (3) from there, deactivate or quantity-zero the Etsy listing (listing scopes `listings_w` exist for this), rebuild or revalidate the site pages, and drop it from feeds; (4) handle the window before feeds refresh, as a sold item still advertised must fail gracefully on the page; (5) a prints (editions) channel is different from an original: only originals need exclusivity.

## Checking on it

- Collections (shayna-art, Mongo): `etsy_orders` (one per receipt: facts, estimate, actual, posted stamps), `etsy_listing_stats` (one row per listing per day), `etsy_reviews`, `etsy_runs` (one per job per day), `etsy_run_locks`. The token and refresh lock live on the token owner's user document.
- Daily job result: the route's JSON summary and the latest `etsy_runs` row (`outcome`: `done`, `reconnect_needed`, `failed`, plus error code).
- Weekly report preview: `GET /api/cron/etsy-report?dryRun=1` with the cron bearer secret returns numbers without posting.
- Monthly P&L: `GET /api/etsy/monthly-report?month=YYYY-MM` with the cron secret.
- `pnpm etsy:backfill` loads every Etsy order (safe to rerun; marks all as posted, so nothing is announced).
- `pnpm etsy:reconcile <file>` attaches actual print-provider charges to orders from a JSON list of `{receiptId, lumaOrderNumber, chargeCents}`; several rows for one receipt add up. Print-provider charges for orders its own Etsy connection creates are not visible through its public API, so they are read from its dashboard monthly.
