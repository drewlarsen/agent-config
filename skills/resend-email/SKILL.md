---
name: resend-email
description: Load when sending transactional email (magic links, verification, inquiries, admin notices) or newsletters through Resend; setting up or debugging a sending domain (SPF, DKIM, DMARC, return-path MX, Cloudflare Email Routing conflicts); choosing API key scopes (send-only vs full-access); composing the From line and sender display name; building HTML email templates; health-checking the key and domain; handling a Resend 401 or 403 ("API key is invalid"); or managing contacts, segments (formerly audiences), broadcasts, unsubscribes and webhooks. Captures the lessons and the proven design from the working boulder.art implementation, plus how Drew's other apps diverge.
version: 1.0.0
user-invocable: false
---

# Resend email

Drew's Next.js apps on Vercel send mail through Resend over plain `fetch`. The most complete implementation is boulder.art; the rest are smaller variants of it.

Reference implementation (`/Users/drewlarsen/Projects/bo-co-art`):

- `src/lib/resend.ts` is the one place that talks to Resend: transactional send, health check, contacts, broadcasts.
- `src/lib/resend-health.ts` is the pure verdict half of the health check (no `server-only`, unit-tested in `resend-health.test.ts`).
- `src/lib/email-template.ts` is the branded shell and body blocks.
- `src/app/api/health/email/route.ts` exposes the health check behind a secret.
- `docs/boulder-dot-art/newsletter.md` and `docs/ops/domain-email-infrastructure.md` hold the full story.

## Invariants

1. **Two keys, two scopes.** A send-only key (`RESEND_API_KEY`) does all transactional mail and cannot touch contacts. A separate full-access key (`RESEND_CONTACTS_API_KEY`) is confined to contact writes, broadcasts and the one-time setup script. Consequence: a leaked or misused transactional key cannot read or change the subscriber list.
2. **Env carries the address; code composes the name.** `EMAIL_FROM` holds only an address (`hello@example.com`). A helper (`senderFrom()`) builds `Brand <address>` from the site config's brand constant and discards any display name found in the variable. Consequence: a brand name in an env var drifts per environment, which is how one project sent as "Boulder Dot Art" while every page said boulder.art.
3. **A 401 usually means the key is absent or blank in that environment, not rotated.** An unset variable passes an `.optional()` schema and reaches Resend as an empty bearer token, which answers 401 "API key is invalid". The message names the symptom and hides the cause. Check whether the variable exists in that Vercel environment, and when it was created versus when the 401s happened, before blaming rotation or another project.
4. **Every project holds its own key.** Several apps share one Resend account. Borrowing another project's key means that project's next rotation silently kills yours.
5. **The build gate proves presence, not function.** A revoked, typo'd or wrong-account key builds green and fails on the first real email. Add a health check that makes a real authenticated call, and put the keys in the deployment-required list so a missing one fails the build.
6. **A verified domain is a second way to die.** A valid key sending as an unverified or unlisted domain sends nothing. Cloudflare/Namecheap "email forwarding" modes that take over the whole MX table drop Resend's return-path MX and un-verify the domain. Never enable them on a domain that sends through Resend.
7. **Confirmed opt-in, with the confirmation as a button.** A signup mails a signed, expiring link; the link opens a page with a button; the button's POST writes the contact. Consequence of completing on GET: corporate mail scanners follow every link and would subscribe people who never asked. Consequence of skipping confirmation: bots and typo'd addresses poison the domain that also sends your magic links.
8. **Resend owns the list.** No local subscriber table. Unsubscribes happen on Resend's own page and no code of yours runs. A fresh confirmed signup clears the old unsubscribe flag (`unsubscribed: false`), because a confirmed opt-in is an opt-in.
9. **Contacts are account-wide; segments are not isolation.** Resend keys a contact by email across the whole account, and `unsubscribed` belongs to the contact. Someone who unsubscribes from one brand's list is unsubscribed from every brand's list on that account. Separate accounts are the only real isolation.
10. **Only one deliberate action can mail a list.** One function creates the broadcast, it takes a `scheduledAt` (never "send now"), it refuses HTML lacking `{{{RESEND_UNSUBSCRIBE_URL}}}`, and only a human-pressed Approve calls it. Crons assemble drafts and notify; they never touch Resend's broadcast endpoint. Consequence: a cron that can mail the list will, once. A scheduled send can be cancelled in the minutes before it goes; an immediate one cannot.
11. **Fail closed on configuration.** With no key, production returns an explicit error or 503. It never pretends the message was sent. In development, log the message to the console and report success so forms can be exercised without an account.

## The proven design

**Client.** No SDK required. One function posts to `https://api.resend.com/emails` with `Authorization: Bearer <key>` and `{from, to, subject, html, text, reply_to?}`, and throws with the response body on a non-2xx. Every sender routes through it so From, auth and failure shape cannot drift. Always send an `html` and a `text` part. Use `reply_to` when forwarding a visitor's message: send FROM the site (so it authenticates), reply to the human.

**Templates.** One shell (single column, tables, inline styles, system font stack, light-only, logo as an absolute-URL raster because clients block `data:` images and CSS masks). Body blocks (`emailParagraph`, `emailButton`, `emailRule`, `emailLink`) are the only way callers produce markup, so type sizes and colors cannot drift. An `escapeHtml` helper wraps anything a human typed. Separate shells for different registers (artist-facing vs admin notices) so each can be restyled in one edit. A plain-text twin of every shell. Declare `<meta charset>` in the document.

**Newsletter.** An issue is a stored record; one body renderer produces a self-contained HTML string and two shells wrap it (email card, web archive page). Picks are frozen into the record so an archived issue cannot change. Sent status comes from a Resend webhook (`email.sent` carries `broadcast_id`, verified by Svix signature under `RESEND_WEBHOOK_SECRET`, refuses everything when unset) with a daily sweep as backstop. Review/edit pages use a signed token; keep the review token alive past Approve, or the Cancel button has nothing to authenticate with.

**Health check.** `GET /domains` with the key, `cache: "no-store"`. Never sends mail, so it is safe on a daily cron and an uptime monitor. Verdict logic is pure and tested:

| Response | Verdict |
| --- | --- |
| 401 | `invalid_key` (missing or revoked) |
| 403 | ok (a restricted key authenticates but cannot list domains; domain half unproven) |
| 200, sender domain missing or not `verified` | `domain_unverified` |
| 200, unreadable body | ok (the key authenticated; Resend changed shape) |
| other status or network error | `unknown`, not a bad key |

The route is gated by the cron secret or an admin session (the body names the sending domain) and answers 503 when mail is broken.

**Safe defaults for anything that mails.** Scripts that touch the list are dry-run or report-only by default, with `--apply` to write, and are idempotent (the segment setup script matches on name). A script that sends does nothing by default; `--test <address>` mails one copy to yourself; Approve is a separate flag. Test a new template by sending one copy to yourself before anything else.

**Abuse controls on public signup forms.** Honeypot field, CAPTCHA (Turnstile) where configured, per-IP and per-address rate limits. The form mails a stranger on demand, so it must not be usable to mail one person repeatedly.

## New project setup checklist

1. **Add the domain in Resend** and choose the region. Prefer a sending subdomain (for example `send.example.com`) when the apex serves a website, so a deliverability problem cannot touch the site's domain reputation. Turn open and click tracking off unless the privacy policy accounts for them.
2. **Publish the DNS records Resend lists**, in the DNS host (Cloudflare), all DNS-only (not proxied): DKIM TXT at `resend._domainkey`, return-path MX to `feedback-smtp.<region>.amazonses.com` (priority 10), and SPF TXT `v=spf1 include:amazonses.com ~all` on the return-path name. Add `_dmarc` TXT `v=DMARC1; p=none;` (add `rua=` for reports) as a deliberate decision, since it is a domain-wide policy.
3. **Never create a second SPF TXT on the same name.** Only one is permitted and a duplicate silently breaks authentication for everything. Merge includes into the existing record.
4. **Verify the domain** in the Resend dashboard (it passes once DNS is live) and confirm with `dig` before sending. If inbound mail is also needed, use a mode that adds records rather than owning the whole MX table.
5. **Create keys in Resend.** Send-only (sending permission) for transactional. Full-access only if the app manages contacts or broadcasts. Never reuse another project's key. A key an MCP server or dashboard session used is not an app key: the running app needs its own.
6. **Env var names by role** (names only):
   - `RESEND_API_KEY`: send-only key.
   - `EMAIL_FROM`: address only, on the verified domain.
   - `RESEND_CONTACTS_API_KEY`: full-access key, only if there is a list.
   - `RESEND_NEWSLETTER_SEGMENT_ID`: the list's segment id, printed by the setup script.
   - `RESEND_WEBHOOK_SECRET`: Svix signing secret, only if a webhook exists.
   - Declare them in the Zod server env as optional, then list the required ones in a deployment gate.
7. **Set them in Vercel for every environment that sends** (Production and Preview as needed), then **redeploy**: env changes only take effect on a new deployment. Sensitive vars cannot be read back, so verify by deploying and calling the health route, not by pulling the value.
8. **Verify.** Hit the health route (expect 200 `ok`), then send one real message to yourself and check DKIM/SPF pass in "Show original". Do not test a forwarding alias by mailing the same Gmail mailbox it forwards to; Gmail dedupes on Message-ID and the copy never appears.

## Debugging

- **401 "API key is invalid":** run the health route. If `invalid_key`, check the variable exists in that Vercel environment (not just locally), is not blank, and that the deployment postdates it. Compare the variable's created time to the first 401 before assuming rotation.
- **403 on send:** a restricted key, or a sender on a domain the key's scope or the account does not allow. The shared Resend test sender only delivers to the account owner's own address.
- **Key works, mail does not arrive:** the health route reporting `domain_unverified` means DNS drifted. Re-check the return-path MX and that nothing has taken over the MX table.
- **Contact or broadcast call fails with a send-only key:** expected; those need the full-access key.
- **Newsletter marked approved but never "sent":** the webhook is unset or its signature check is failing; the daily sweep should settle it within a day.
- **Someone unsubscribed from one brand and vanished from another:** invariant 9, expected.

## Divergences in Drew's other apps

- `balero-board` (`lib/email.ts`) and `thief-movie-website` are single-purpose: `fetch` to `/emails`, dev logs instead of sending, production fails loudly with a fallback address shown to the visitor. `lumetto-app` uses the `resend` npm package for magic links and degrades to printing the link in the console when no key is set.
- `shayna-art` and `lumetto-marketing` still say `RESEND_AUDIENCE_ID` (Resend's older word for a segment), use one key for send and list, and keep per-instance in-memory rate limits only. `shayna-art`'s migration note says a sending-permission key is enough for the audience route; boulder.art found send-only keys cannot touch contacts. Treat that note as unverified and test it before relying on it.
- `shayna-art` sends from a `send.` subdomain with a custom return-path name (`bounce`) and tracking off. `lumetto-app`'s ops note says Resend's free plan verifies one domain per account, so sender and brand can mismatch there until a second domain is added.
