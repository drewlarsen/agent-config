---
name: pinterest-integration
description: Lessons and a proven design for integrating Pinterest's API v5 into a Next.js/Vercel app. Load when building or debugging a Pinterest integration — OAuth and token refresh, auto-pinning artwork or products on a schedule, boards and board sections, sandbox vs production, the Pinterest tag, product catalogs / shoppable pins / TSV feeds, domain claiming, Pinterest analytics or weekly reports, Slack reporting of cron runs, or "why did Pinterest refuse this pin / board / refresh". Captures what a working implementation (shayna-art) learned the hard way, so the next project starts from what works instead of rediscovering it.
version: 1.0.0
user-invocable: false
---

# Pinterest integration (API v5)

A daily Vercel cron posts a few pins from a catalog of artwork, keeps its own sign-in alive, reports every run to Slack, and sends a weekly analytics summary. It has run unattended against a real account. This skill is the lessons and the design, not a code library: read the reference implementation and port the shape, not the paths.

**Reference implementation (shayna-art, `/Users/drewlarsen/Projects/shayna-art`):** runbook `docs/pinterest.md` (also holds that project's account, catalog and ad-account ids; this skill deliberately omits them). Logic in `packages/engine/src/pinterest/` (`api.ts`, `oauth.ts`, `errors.ts`, `boards.ts`, `pin-plan.ts`, `pin-content.ts`, `pinnables.ts`, `run-daily-pins.ts`, `weekly-report.ts`, `catalog.ts`). Routes under `apps/web/app/api/cron/pinterest/`, `.../pinterest-report/`, `apps/web/app/pinterest/` (connect, callback, `catalog.tsv`). Records in `packages/db/src/pinterest.ts`. Tag in `apps/web/components/pinterest-tag.tsx`. Schedules in `apps/web/vercel.json`.

## Invariants (break these and something fails)

- **Exactly one process refreshes the token.** Each refresh spends the refresh token and issues a new one; a second refresher uses up a token the first still holds and the chain dies. Everything else (weekly report, legacy admin) reads the stored token and never refreshes.
- **Tokens renew indefinitely, but only if refreshed.** A "continuous refresh" refresh token lasts 60 days and every refresh returns a new one. Ask for it with `continuous_refresh=true` in the code exchange. Refresh weekly (not daily): that leaves eight chances to recover before expiry, and daily only adds moments where a lost write breaks the chain.
- **Write the refreshed token back with retry, and keep the old refresh token if the response has none.** The refresh already happened at Pinterest; a lost write strands you. Read the stored token back after writing.
- **A 400 or 401 on refresh means reconnect needed** (expired or revoked token; 400 is how Pinterest says it). Sometimes a 400 is something else; reconnecting fixes it either way. This is the only failure that needs a human.
- **Sandbox and production are one Pinterest account but do not share boards.** A board made in sandbox shows up in production's board list, but production cannot pin to it ("Cannot add non-sandbox pins on sandbox boards"); sandbox cannot see production's boards at all. Use distinct board names per environment (e.g. "Sandbox ..." names) and never reuse a name sandbox has created. Unset environment means sandbox; going live is a deliberate switch.
- **Boards are matched by exact name.** Renaming a board on Pinterest makes the job create a new one. Board names must be under 50 characters.
- **Record each pin the moment Pinterest accepts it,** keyed by the image's asset key, with a retried write. A lost record means the image is posted again. Put a unique index on `(environment, image_key)`; in shayna-art it was created by hand and nothing in code creates it, so create it as part of setup.
- **Take a per-environment, per-day run lock before doing anything.** Vercel can deliver a cron event twice; two runs would post the same plan and refresh the token twice (the second refresh fails because the first used the token up). The lock is an insert with `_id = "{environment}:{day}"`; a duplicate-key error means "already ran". Dry runs skip the lock.
- **Classify errors by who is at fault.** A 4xx other than 429 is Pinterest refusing this request (bad image, refused board name): skip it, record it, try a spare. A 5xx, 429, or timeout is Pinterest as a whole: stop the run for the day. A 401 on any call is reconnect-needed. If every pin tried is refused, fail the run.
- **Plan spares beyond the daily count** (shayna-art plans 5 extra). A deterministic plan otherwise puts the same refused pin at the head of every day's plan forever. A refused board or section sets its whole collection aside for the day, instead of failing each of its candidates the same way.
- **Pause between writes** (3 s) and time out every request (30 s); a hung request otherwise runs the cron to its limit with no run record and no alert. Set `maxDuration` on the cron route (300 s there).
- **The OAuth redirect must match byte for byte** between authorize and token exchange, including any environment segment in the path. Token exchange uses HTTP Basic auth (client id : secret). Both environments authorize on `www.pinterest.com`; the token exchange goes to the per-environment API host (`api.pinterest.com/v5` vs `api-sandbox.pinterest.com/v5`). Pinterest's PKCE is vestigial here: the verifier is never sent, but a stored one is a useful proof that a grant is in progress.
- **Analytics lag a day or two and reach back 90 days.** End the reporting week two days ago.
- **Pinterest fetches the image itself** (`media_source: { source_type: "image_url", url }`), so images must be publicly reachable; no base64 upload needed. IDs come as JSON strings; never read them as numbers.
- **Pinterest's content limits:** pin title 100, description 800, alt text 500 characters (truncate with an ellipsis).

## The proven design

**Daily cron** (`0 15 * * *`).
- Route is `runtime = nodejs`, `dynamic = force-dynamic`, with `maxDuration` set.
- Auth: Vercel sends `Authorization: Bearer $CRON_SECRET`. Compare with a constant-time helper. 401 on mismatch, 503 if config is missing (a 503 writes no run record, so it shows only as a failed cron in Vercel).
- Flow: take the lock, load the token (refresh if more than 7 days old, never in dry run), load pinnables and recorded pins, plan, fetch boards, then per candidate ensure board and section, create the pin, record it, pause.
- Finish by writing one run record (`posted` / `reconnect_needed` / `failed`, pin ids, error) and reporting to Slack.
- On failure, read back the pins already recorded since the run started, so a partial run reports honestly.

**Plan / pick rule** (a pure function with no randomness, so it is predictable and testable):
1. Images never pinned come first, newest first, interleaved round-robin across collections so a small collection is not queued behind a big one.
2. When everything has a pin, post alternate images (mockups), preferring tall over wide (Pinterest shows wide ones small), starting with the item pinned longest ago. Never re-pin an item within 21 days.
3. Never pin the same image twice (the recorded `image_key` set). Pins made by an older system count as already pinned, in production only.
4. "Pinnable" means active and present in the deployed asset manifest: the same moment it appears on the site.

**Pin content:**
- Reuse the page's published SEO title, description and alt text.
- Link to your own page, not the shop, tagged `utm_source=pinterest&utm_medium=social&utm_campaign=<board slug>&utm_content=<painting|mockup>`.
- Pass `dominant_color` if known. Board sections can group a numbered series (25 per section in shayna-art).

**Reconnect flow.**
- A `reconnect_needed` run posts a Slack message with a link `/pinterest/connect/{environment}?key=$PINTEREST_CONNECT_KEY`. The key guards it; otherwise anyone could connect their own account and the job would post there. The message repeats daily until fixed.
- **GET only renders a button; POST starts the grant** (stores a fresh code verifier, 303s to Pinterest). Link previewers and mail scanners open links, and a GET that wrote state could clobber a sign-in in progress.
- The callback validates the environment segment (404 on anything else, never coerce to sandbox), exchanges the code with Basic auth and `continuous_refresh=true`, and stores the token blob plus a `writtenAt`.
- Scopes used: `pins:read pins:write boards:read boards:write user_accounts:read`.

**Slack reporting.**
- One message per run, every run (a silent day means the job did not run).
- Production runs post; sandbox runs are recorded in the run table but stay out of the channel.
- Reports and the run-record write must never throw out of the catch block or replace the original error. The run table is the history Slack will not keep.

**Weekly report** (Mondays, separate cron, read-only, never refreshes).
- Pulls `user_account/analytics` for the week and the week before (`IMPRESSION, PIN_CLICK, SAVE, OUTBOUND_CLICK`), plus `user_account/analytics/top_pins` sorted by `OUTBOUND_CLICK`.
- Fetches each clicked pin to show its title and link host. An outbound click goes wherever the pin links, which may not be your site.
- Supports `?dryRun=1` to return the numbers without posting.

**Generic plumbing (worth extracting into a shared package later):** OAuth authorize URL, code exchange, Basic auth, refresh; the API client (typed errors, timeout, bookmark pagination at `page_size=100`, Zod-parse every response); error classification; write-with-retry; run lock; run/pin record shapes; the reconnect page; Slack run reporting; the weekly analytics fetch. **Per-app policy:** what counts as pinnable, boards and sections and their names, pin copy, the plan's ordering and spacing, pins per day, schedule, report wording.

## Setup checklist (new project)

Human steps:
1. A Pinterest **business account** for the brand, and a Pinterest developer app. Likely an existing app with production access can be authorized by another account (verify before relying on it).
2. **Claim the domain** (DNS TXT record or meta tag) in the Pinterest account.
3. Register the redirect URI(s) on the app, one per environment, matching the callback route exactly.
4. Authorize: open the reconnect link, press the button, sign in as the account owner, approve. Do this in sandbox first.
5. Create the unique index on the pins table, then flip to production deliberately and watch the first live run (it will surface board-name and refusal problems sandbox cannot).

Env vars by role (names from the reference; no values here): `PINTEREST_SECRET_KEY` (app secret, used for Basic auth), `PINTEREST_ENVIRONMENT` (`production` to go live, anything else is sandbox), `PINTEREST_CONNECT_KEY` (guards the reconnect link), `CRON_SECRET` (Vercel cron bearer), `SLACK_OAUTH_TOKEN` (reports). The Pinterest client id is public (not a secret) and lives in code. Store the token (access, refresh, expiry, `writtenAt`) in the database, not env, since it changes.

## Catalogs and shoppable pins

**Apply when** you sell on your own domain at prices that match the landing page. **Skip when** the site is a directory that links out to other people's shops: there is no price you control and no checkout on your domain.

Mechanics (shayna-art): serve a TSV at a stable URL (`/pinterest/catalog.tsv`, force-static, built per deploy so price and availability match the pages). Columns follow Google's product data spec: `id, title, description, link, image_link, price, availability, condition, brand, google_product_category, product_type`; price like `30.00 USD`; strip tabs and newlines from values. One row per purchasable thing (original and print are separate rows with distinct ids). Create the catalog in Pinterest with that URL as a data source (fetched every 24 hours, no feed login). Requirements: claimed website, **the Pinterest tag installed on the site** (base code loaded lazily, `lazyOnload`; disclose it in the privacy policy), and visible contact, shipping and return policies. Image format caveat: `.webp` was accepted for regular pins; if catalog ingestion rejects webp, the feed needs a JPEG route.

## Checking on it

- Dry run: `curl -s -H "Authorization: Bearer $CRON_SECRET" "<site>/api/cron/pinterest?dryRun=1"` plans without posting, refreshing, locking or messaging Slack. The same `?dryRun=1` works on the report route.
- History: the run table (`pinterest_runs`: outcome, pin ids, error, when reported), the pin table (`pinterest_pins`), the cron's Vercel logs, and the Slack channel.
- To compare behaviour or copy a shape, read the reference files above; for account-specific ids and the setup log, read `docs/pinterest.md` in shayna-art.
