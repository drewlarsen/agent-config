---
name: slack-reports
description: Load when a job, cron, script or app event should report to Slack (run summaries, failures that need a human, sales, new leads, claims, contact messages, weekly analytics), or when touching Slack posting code (SLACK_OAUTH_TOKEN, chat.postMessage, Block Kit, mrkdwn, notify/notifyRun, channel lists, #bda-* or #sba-* channels). Defines the house message style and posting mechanics shared across Drew's Next.js/Vercel projects, so new reporters match without copying files around.
version: 1.0.0
user-invocable: false
---

# Slack reports

Slack is the ops feed, not the record. The database is the record; a message says something happened, and the free tier keeps only 90 days of history. Never let a Slack message be the only place a fact lives.

## Where the reference lives

- **Origin:** `~/Projects/bo-co-art/src/lib/slack.ts`. Its header comment is the style guide. Read it before writing a message.
- **Copy:** `~/Projects/shayna-art/apps/web/lib/slack.ts` (marked `adapted-from`). It has drifted, in both directions. For a new project, start from the bo-co-art file.

| | bo-co-art | shayna-art |
|---|---|---|
| `notify` returns | `{ channel, ts } \| null` (thread under it) | `boolean` |
| Threads, `fields` (label/value pairs) | yes (`threadTs`, `fields`) | no |
| Link URLs | site-relative paths resolved by `absoluteUrl()` | absolute only |
| Request timeout | none | `AbortSignal.timeout(10_000)` (worth adopting) |
| `RunGroup` | `count` (true total) and `max` overrides; `items` optional | `items` required; report has `summary` line instead |
| `RunReport` | `source` joins the title (`Title — source`), `maxItems` | no `source`; fixed `MAX_ITEMS = 20` |
| Channel const | `slackChannels` (`#bda-*`) | `SLACK_CHANNELS` (`#sba-*`) |

No other project posts to Slack today. lumetto-app and balero-board have no Slack code.

## The house style

A message is read twice: as a push on a lock screen, and as a row in the channel. Each gets its own text.

- **title** (channel row): a label, not a sentence. What happened, then a colon or "for", then the subject. Bold at the top. `Takedown honored: jane-doe`, `Sale: $48.00, 2 items`, `Week of Oct 3–9: 14 outbound clicks`. When the event is a number, the number leads. No brand name (the channel says which feed). Never "today" or "just now"; a row is read later.
- **notification** (push): one plain sentence ending in a full stop, naming the person or thing. `Jane Doe has claimed their profile.` It defaults to the title, which is the wrong register for a lock screen, so set it whenever a human might see it. For batch runs the push is the headline number (`3 new events via email.`), including `No new events via email.` when nothing happened.
- **body**: facts as one line of short fragments joined by ` · `. `Boulder · painter · starter page · 12 works`. A reason or a state, never a paragraph, never the title again. A quoted message goes in `> ` blockquote lines. Use `fields` for long or free-text values (a takedown reason).
- **machine values** (slugs, origins, tiers, error codes, env var names) go in `` `backticks` ``. Names and titles are bare.
- **link**: one, as a muted footer, labelled with an imperative that names the page: `Open the claims queue`, `Reconnect Etsy`, `Read the issue`. Omit it when the thing is gone (a takedown has no link).
- **No emoji.** The one decoration in real messages is data (review stars `★☆`). No exclamation marks, no "Heads up".
- **Numbers:** show deltas against the prior period in parentheses: `412 views (was 380)` or `$310.00 (+$40.00 on the week before)`. Use `Intl.NumberFormat` for thousands and singular/plural-correct units (`1 pin`, `2 pins`).
- **One message per run.** A batch job posts one `notifyRun`, grouped by outcome, every row a link to the page it produced. Never one message per row (noise, and Slack's rate limit). Per-row detail goes in a thread under the returned `ts`.
- **Print every count, including zero.** `Failed 0` is information. A group that speaks only when non-empty looks the same as a group whose query broke. For a noisy repeat group (skips re-judged every pass) print a bare count with no rows.
- **A failure that needs a person** names the job in the title, says in the push what happens next (`It tries again tomorrow.`), puts the error code and a truncated detail in the body (slice to about 300–500 chars), and carries an action link that fixes it (`Reconnect Pinterest`, with a signed URL). If the fix link cannot be built (missing env var), say which env var is unset in the body.
- **A daily run reports every run**, even an empty one. A day with no message must mean the job did not run.

### Examples

```
title:         Daily pins posted: 3
notification:  3 pins went up on Pinterest.
body:          *Posted 3*  • <pin url|Title> — _mockup_  …   *Refused by Pinterest 0*
link:          Open the Pinterest profile

title:         Claim needs review: `Jane Doe`
notification:  Jane Doe has claimed their profile — it needs a look.
link:          Open the claims queue   (/admin/claims)

title:         Reconnect needed: Etsy sign-in
notification:  Etsy needs reconnecting before sales can be recorded.
body:          `etsy_reconnect_needed` · <detail, sliced to 300 chars>
link:          Reconnect Etsy
```

## Mechanics

- **Env var:** `SLACK_OAUTH_TOKEN` (a bot token, `xoxb-…`). Set on Vercel, and as a GitHub Actions secret for workflows that report. Documented, empty, in `.env.example`. All projects share one Slack workspace.
- **Call:** `POST https://slack.com/api/chat.postMessage` with `Authorization: Bearer <token>` and `Content-Type: application/json; charset=utf-8`. Body: `channel`, `text` (the notification: what push and screen readers get), `blocks` (the channel layout), `unfurl_links: false`, `unfurl_media: false`, optional `thread_ts`.
- **Blocks:** a `section` with `*title*`; one `section` per body entry; `fields` sections of at most 10 each; a `context` block holding `<url|label>`. Split any section above 2800 characters (Slack rejects 3000); `notifyRun` does this.
- **Success check:** Slack answers HTTP 200 with `{ ok: false, error }` for most real failures. Check `body.ok`, not the status.
- **Best-effort, never fatal.** A missing token, Slack outage or revoked token must never fail the job it reports on. Both implementations warn to the console and return null/false. A missing token is the normal case (previews, fresh clones) and stays silent.
- **mrkdwn, not Markdown:** `*bold*`, `_italic_`, `` `code` ``, `<url|label>`, `> quote`. Escape `&`, `<`, `>` in user-supplied text (an artist's name or a message body can contain them), or it can break a link or mention. The reference files do not do this yet, so do it in the caller.
- **Runtime:** the module reads `process.env` directly and has no `server-only` import, so it works from serverless routes, `tsx` scripts and GitHub Actions alike. Do not import it from client components.
- **Sandbox/dev never posts to a prod channel.** shayna-art posts only for `environment === 'production'` (`isReportable()`) and records sandbox runs in the database instead. Elsewhere, a missing token on previews does the same job. Keep that property in any new reporter.
- **Exactly-once:** retries must not double-post. Two patterns exist: bo-co-art stamps `notifiedAt` on the record when the answer goes out and drains "terminal and not yet notified" (retries and overlapping runs converge); shayna-art's Etsy orders claim each message before posting and release the claim if the post fails, so the webhook and the daily job never both post it. A once-a-day cron with a single trigger needs neither.
- **Channels:** a typed map, so a typo is a type error rather than a message that lands nowhere. Names are prefixed per project so feeds stay legible in one workspace: `#bda-*` (boulder.art: artists, events, newsletter, inbox, referrals), `#sba-*` (shayna.art: pinterest, etsy, etsy-store). Split by audience and cadence: what happens (sales, claims) separate from how it's run (weekly and monthly reports).

## Adding a new reporter

1. Pick or add a channel key in the project's channel map (new project: new two-or-three-letter prefix, `#xxx-name`). Create the channel and invite the bot.
2. Copy the bo-co-art `slack.ts` for a new project; otherwise use the project's existing one. Do not write a second Slack client.
3. Write title, notification and body separately, per the rules above. Read them back as a lock-screen push and as a channel row.
4. Single event: `notify`. Batch job: `notifyRun` with outcome groups, counts printed even at zero, rows linked.
5. Add the failure path: a `notify` with the error code, truncated detail, a next-step sentence in the push, and an action link.
6. Make it idempotent if more than one trigger can reach it (stamp the record, or claim-then-release).
7. Await the call inside the job but ignore its result. Confirm a missing token returns silently, and that dev/sandbox runs do not post to the prod channel.
8. Add `SLACK_OAUTH_TOKEN` to the places the code runs (Vercel, GitHub Actions secrets) and document the channel in the project's docs.
