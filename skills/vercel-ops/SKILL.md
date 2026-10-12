---
name: vercel-ops
description: Load when deploying, debugging production, or changing config on Drew's Vercel-hosted projects (all Next.js, one shared Vercel team) — firewall/WAF rules and rate limits, Bot Protection, a 403/429/503 from production, "the site is down for me", sharp or other native modules failing in production, "invalid deployment package" errors, preview deployments that won't build or can't be reached, env vars (`vercel env`, `.env.local`, `.env.production.local`, `vercel env pull`), Vercel spend and budget, crawler-driven cost spikes, ISR/cache write costs, `unstable_cache`, Link prefetch cost, `?_rsc=` requests, robots.txt and which crawlers to allow or block. Drew's hard-won gotchas and standing rules from boulder.art, not a general Vercel guide.
version: 1.0.0
user-invocable: false
---

# Vercel ops: Drew's gotchas and standing rules

All of Drew's projects share one Vercel team. A mistake that takes one project down, or a team-level setting, can hit the others. Rules first, then why, then a check where one exists. Examples carry boulder.art numbers "for scale" only.

## Firewall & bots

- **Telling an edge block from an app error takes one curl.** Run `curl -sD - -o /dev/null
  <url>` and read `x-vercel-mitigated`. `deny` means the firewall refused it and the request
  never reached Next.js, so stop reading app code. `challenge` (usually with a 429) means
  Bot Protection refused a non-browser. A paused project is a 503, not a 403.
- **Never verify production with a curl loop.** Bot Protection on means plain `curl` gets
  `429` plus `x-vercel-mitigated: challenge`. That is the firewall, not an outage. A polling
  loop spends the IP's request budget and never matches. Use a real browser, or a
  same-origin `fetch` from the page's JS console to read markup without loading images.
- **A path-scoped rate limit issues a site-wide deny.** The rule counts one path, but the
  persistent action blocks that IP across the whole hostname for the full window (10 min),
  including favicon and `/_next/image`. One page's limit therefore looks like a total outage
  from the affected network while everyone else browses fine.
- **Prefer Challenge over Deny (403) for rate limits on public browse routes.** The deny is
  site-wide per IP; a challenge lets a real person through.
- **Turning a rule off does not clear a deny already issued.** It self-expires; the end time
  is on the action's detail panel.
- **Normal browsing tripping a limit is a product bug, not a security event.** The visitor
  does not email, they leave. Never answer "the site stayed up for everyone else."
- **Before blaming a scraper for flooding a route, check what links to it with default
  prefetch.** A footer index of `<Link>`s is always expanded on desktop, so scrolling to the
  bottom fires a document prefetch for every link, heaviest page included. Browse fast and
  you out-request your own rule. Check: the route's inbound links; the fix is
  `prefetch={false}` on links to heavy documents (see Caching).
- **Modifying the firewall is Drew's to do.** Name the exact rule and toggle, hand it to
  him, and do not flip it yourself. That includes `update_firewall_config` /
  `put_firewall_config` through the Vercel MCP.

## Cost & crawlers

- **Cost tracks cold origin renders, not readers.** Edge requests and data transfer were $0
  on the Pro allowance (about 7% and 5% used); every charged line was origin work: cache
  writes, renders, image optimization. Serving a cached page is free; a cold render for a
  crawler is not.
- **A long-tail URL space crawled by bots is the expensive shape.** About 8k pages were
  written once and expired before anything read them (0.1 reads per write on the worst
  route). For scale: roughly $190/month against 7.4k human pageviews, with bots at about 55%
  of traffic.
- **Fix the expensive shape with long TTLs, not just blocks.** On the long-tail page types,
  `revalidate = false` with tag/on-demand invalidation; for images, `images.minimumCacheTTL`
  of 31 days (Vercel serves 30d). Measure the writes/reads ratio per route in Observability
  before and after.
- **Crawler access rule: a crawler earns access by being able to send a reader or a
  citation.** Google, Bing, OpenAI (GPTBot, OAI-SearchBot), Claude, Perplexity and Meta's
  indexer stay welcome, because being the answer is the job. Extractors that cite, rank or
  refer nobody are refused: Amazonbot, PetalBot, Bytespider, and the SEO backlink crawlers
  (AhrefsBot, SemrushBot, DataForSeoBot, DotBot, MJ12bot, SEOkicks, serpstatbot).
- **Cost alone never justifies blocking a crawler that can send a reader.** Google is
  expensive too. The policy is about what the crawl can return; cost only raises the
  question.
- **robots.txt is voluntary, so enforce the refusal list twice.** Put it in `robots.txt` and
  deny the same names by user agent in a Vercel firewall rule (boulder.art calls it
  "Extractive crawlers").
- **Disallow `?_rsc=` in robots.txt.** Googlebot's renderer runs `<Link>` prefetches while
  rendering, which fetch RSC payloads. In one launch burst that was about 180K of 190K
  Googlebot requests in a day, crawl allowance spent on payloads instead of documents. Add
  `/*?_rsc=` and `/*&_rsc=` (two patterns, because `_rsc` is not always the first query
  parameter). Server-rendered HTML does not need the payloads; remove the rule only if URL
  Inspection's rendered view shows a page incomplete.
- **Sitemap shape decides where a new domain's small crawl allowance goes.** If most
  advertised URLs are the thinnest page type (boulder.art: 63% were untitled artwork pages),
  Google samples those and rates the site down. Submit the strongest pages first; keep thin
  pages live but out of the sitemap, or noindex them.
- **A budget is an alarm, not a brake.** Spend Management is set to a budget with
  notifications on and Pause Projects OFF. Pause is the only true hard cap, but it takes
  every project on the team offline, and for an SEO-first site a day of 503s costs more than
  the overage. A webhook on that panel is the middle path: fire at the cap and tighten the
  firewall instead of going dark.
- **Observability Plus stays off by default.** It bills per event (about $30/month at
  crawler volume) and does not backfill if re-enabled. The base ISR panel still shows reads,
  writes, unique paths and per-route breakdown. Turn it on for a day when a real
  investigation needs it, then off.

## Builds & native modules

- **sharp on pnpm needs `nodeLinker: hoisted` plus a tracing include, together.** sharp's
  addon dlopens libvips from a sibling package by rpath, so nothing `require`s it and file
  tracing leaves the binary behind; image routes 500 with `ERR_DLOPEN_FAILED:
  libvips-cpp.so.8.x.x`. Hoisting makes `node_modules/@img/sharp-libvips-*` a real
  directory, and `next.config` then traces `./node_modules/@img/sharp-libvips-*/lib/**/*`.
  Removing either half silently breaks every image route in production.
- **In pnpm 11 the linker setting lives in `pnpm-workspace.yaml`, not `.npmrc`.** An
  `.npmrc` line is read and does nothing. Changing linkers needs `rm -rf node_modules` first
  or the old layout survives.
- **Tracing globs into `node_modules/.pnpm/**` build clean locally and still fail the
  deploy.** Vercel rejects the function after a successful build ("invalid deployment
  package for a Serverless Function ... symlinked directories"), and then every later push
  fails too, including commits carrying unrelated work. pnpm's store is symlinks; `next
  build` never exercises packaging.
- **A green local build and a correct `.nft.json` are not deploy evidence.** The trace
  proves a file is listed, not that Vercel can copy it. Prove any change to
  `outputFileTracingIncludes`, `distDir`, `serverExternalPackages` or native-module
  packaging on a preview deployment before it reaches the production branch.
- **If a push breaks packaging, revert first and diagnose second.** An unshippable trunk is
  worse than the original bug.
- **Hoisting has a real cost:** an undeclared transitive import now resolves instead of
  failing loudly. Accepted deliberately for sharp; do not assume it elsewhere.

## Previews

- **A pushed branch may build nothing.** If the project's Git settings have branch previews
  off, deploy explicitly from the worktree: `vercel deploy --yes`. It needs a
  `.vercel/project.json` (org and project IDs live in `.vercel/repo.json`).
- **Production-only secrets fail preview builds** if the app asserts its env at build time.
  Pass a throwaway for the build only: `--build-env NAME=preview-placeholder`. Never a real
  secret. The real fix is a Preview-scoped (ideally restricted) key.
- **Previews are deployment-protected.** Use the Vercel MCP `get_access_to_vercel_url` tool,
  then curl the returned `_vercel_share` URL to set the cookie.
- **Never test on the production branch because previews are awkward.** A push to it is a
  production deploy. If preview-first looks impossible, use the recipe above.

## Env vars

- **Never `vercel env pull` to check a value.** It can write `.env.production.local` with
  every value an empty string. `loadEnvConfig(dir)` with no second argument resolves to
  production mode, loads that file first, and never overwrites a set key, so `.env.local`'s
  real values never land.
- **Symptoms of that shadowing:** `next build` ZodError on the server env schema, a
  deployment-env assertion saying vars are missing "in Vercel", scripts dying with
  "MONGODB_URI is required" or "Invalid scheme". It does not reproduce in a git worktree
  (only `.env.local` is copied there), so it looks intermittent. Fix: delete
  `.env.production.local`.
- **Local scripts call `loadEnvConfig(process.cwd(), true)` (dev mode).** That is correct
  for a local tool anyway and is immune to the shadowing.
- **`.env.local` is off-limits to the agent.** Bash refuses commands naming it and Read
  refuses the path. A local env change is always Drew's: say which line. Listing loaded var
  names (never values) via a node one-liner calling `loadEnvConfig` is fine.
- **`vercel env add ... --force --yes` writes the value, then never exits** (even with
  `--non-interactive`). It looks like a failure and is not: check `vercel env ls` before
  retrying or you double-write. It also splits a Production+Preview row into two rows.
- **Patch values through the REST API instead.** `PATCH
  /v9/projects/{projectId}/env/{envId}` to change, `POST /v10/projects/{projectId}/env` to
  add, authenticated with the CLI's token from `~/Library/Application
  Support/com.vercel.cli/auth.json`. Read the token in the shell and never print it.
- **Sensitive vars cannot be read back** (`decrypt=true` returns `""`), so a botched write
  is invisible. Get it right the first time; the only proof is a deployment that works and
  the feature exercised.

## Caching

- **`unstable_cache` keys on the callback's source text** (`cb.toString()` plus `keyParts`).
  Any edit to the body of a cached read, even a refactor or a moved helper call, mints new
  keys, and every entry is cold after deploy though `keyParts`, `tags` and `revalidate` are
  unchanged. On a large page set (boulder.art: about 11.5k artwork pages) that is a full
  round of cold renders.
- **When a change touches inside an `unstable_cache` callback, say so before it ships.**
  Land it with other changes to the same reads rather than as a standalone deploy.
- **Link prefetch is a cost and a rate-limit input.** Default prefetch on a link to an
  expensive document (the heaviest page was about 300 KB) fires for every visible link. Set
  `prefetch={false}` on doors and index lists that point at heavy or long-tail pages.
- **Cache hits are free, so the aim is fewer cold writes.** Judge a change by writes per
  route and reads-per-write in the ISR panel, not by page speed alone.

## Small gotchas

- **The Vercel dashboard's project icon is an uploaded avatar, not the live favicon.**
  Redeploying never refreshes it. Change it at project Settings, General, Avatar: upload a
  PNG/SVG/ICO and "Set Avatar". A transparent mark can vanish on Vercel's dark card
  background.
- **"You need additional permissions to manage this project's avatar" shows only while the
  settings page is still loading.** Wait.
