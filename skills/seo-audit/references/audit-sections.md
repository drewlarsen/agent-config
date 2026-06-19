# SEO Audit — Section-by-Section Checklist

A forensic, read-only audit harness for any entity- or content-driven website
(directories, marketplaces, publishers, docs sites, local-business listings,
SaaS marketing sites). It is **broader than a per-surface dev checklist**: it adds
crawl/index forensics, launch readiness, and measurement on top of the per-page
checks a project's own SEO docs already define.

**This file is the generic fallback + the audit's spine. It is NOT the source of
truth for project specifics.** The project's own SEO docs (discovered per
SKILL.md) own the *what* — which routes exist, which schema types apply, which
query classes matter, what counts as a thin page, the canonicalization policy.
This file owns the *how* — the method, the evidence bar, the section coverage.
When a project SEO doc and this file disagree on a project specific, the project
doc wins; when they disagree on audit method or evidence rigor, this file wins.

SKILL.md maps each `/seo-audit <target>` to a section here. For a single target,
read and run only that section (plus the shared Stance below). For `full`, run
every section and assemble §18.

## Stance and rules (every section inherits these)

- **Read-only.** Do not edit files. Produce findings and recommendations only.
  If the user explicitly converts the task to implementation, that is a new task.
- **Evidence or it didn't happen.** Ground every finding in one of: file path +
  line, route + HTTP status, rendered HTML (view-source or fetched), browser/
  DevTools observation, official-doc citation, or a documented project
  requirement. "Best practice says…" with no project evidence is not a finding —
  it is at most a recommendation, labeled as such.
- **Separate confirmed issues from recommendations from "needs production data."**
  Never present a hypothesis as a confirmed defect.
- **Respect server ownership.** If the project doc names an owner of a persistent
  local server (e.g. a human owns `:3000`), you may inspect it if it is up but
  must not start/stop/restart it. If it is down, say so. If you need your own
  server, ask first and use a temporary port, then stop it when done.
- **Currency over memory.** Refresh official guidance (see below) before relying
  on any threshold, metric name, or eligibility rule. Search SEO moves; do not
  assert from training data.

## Refresh these official sources first (if web access is available)

Treat these as the baseline; everything else (agency blogs, this file's prose) is
secondary. Tag any claim you carry forward with where it came from.

- Google SEO fundamentals / Starter Guide —
  `https://developers.google.com/search/docs/fundamentals/seo-starter-guide`
- Google "AI features and your website" (AI Overviews / AI Mode eligibility) —
  `https://developers.google.com/search/docs/appearance/ai-features`
- Google crawling & indexing (incl. canonicalization, hreflang, robots) —
  `https://developers.google.com/search/docs/crawling-indexing`
- Google structured data (search gallery + general guidelines) —
  `https://developers.google.com/search/docs/appearance/structured-data`
- Google Core Web Vitals —
  `https://developers.google.com/search/docs/appearance/core-web-vitals`
- OpenAI crawlers (GPTBot / OAI-SearchBot / ChatGPT-User) —
  `https://developers.openai.com/api/docs/bots`
- For other AI crawlers, check the operator's own current docs (Anthropic
  `ClaudeBot`/`anthropic-ai`, Perplexity `PerplexityBot`, Common Crawl `CCBot`).
  Do not hardcode a token list from memory — verify current user-agent strings.

### Currency guardrails (known-stale traps — verify, do not parrot)

- **Core Web Vitals are LCP, INP, CLS.** INP (Interaction to Next Paint) fully
  **replaced FID in March 2024** — FID is retired. Current "good" p75 thresholds:
  **LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1.** If you cite a different LCP bar,
  cite the Google doc that says so — do not repeat blog claims of a "2.0 s"
  threshold unless Google's own doc confirms it at audit time.
- **AI search has no secret markup.** Google's own AI-features doc states there is
  *no special schema.org structured data, no AI text files, and no special
  optimization* required to appear in AI Overviews / AI Mode — eligibility is
  "indexed and eligible to be shown with a snippet," reached via ordinary SEO.
  This is the authoritative basis for the anti-hack guard below.
- **`llms.txt` is unproven.** As of audit time, Google does not use or endorse it,
  and major AI crawlers (OpenAI, Anthropic, Google) do not request it. Treat it as
  optional, low-cost, speculative — never as a substitute for crawlable HTML, and
  never as a finding-grade requirement. Re-verify status during the refresh step.
- **`rel=prev/next` is not used by Google for indexing.** Don't flag its absence
  as a defect; judge paginated/faceted crawl paths on link discoverability and
  canonical/`noindex` policy instead.
- **No GEO/AEO hacks.** Do not recommend keyword-stuffed "AI answer" blocks,
  fake Q&A schema, `llms.txt` as a ranking lever, or any "trick the AI" tactic.
  The win condition for AI search is the same as for classic search: crawlable,
  factual, well-structured, genuinely useful content with clear entities.

## How to scope the inspection to THIS project

Before running the sections, derive the project's specifics from its own docs and
code (SKILL.md describes discovery). Build these working lists:

- **Surface inventory** — the canonical public route families and a few real
  instances of each (one populated detail page per entity type), plus the
  should-be-private surfaces (auth, account, admin, internal tools) and the
  utility routes (`/sitemap.xml`, `/robots.txt`, any feeds). Pull these from the
  project's URL/route policy doc and the router/filesystem, not from this file.
- **Entity & schema map** — which schema.org types the project's content actually
  warrants (e.g. `Organization`/`LocalBusiness`/`Product`/`Article`/`Person`/
  `Event`/`BreadcrumbList`), from the project's data-model + structured-data docs.
- **Query/intent classes** — the searcher intents the project is trying to win
  (name/brand, category × locality, informational/discovery, commercial), from
  the project's SEO strategy doc. These set what "winning" means per surface.
- **Boundary rules** — which fields are public vs. provenance/operational/private,
  from the project's data-model / view-model docs. This drives Section 16.

If the project has **no SEO docs**, run the sections as written using the generic
defaults, and note in the Executive Summary that the project lacks a documented
SEO strategy/checklist (itself a finding worth raising).

---

## 1. Executive Summary

Lead with the verdict, then the leverage. Answer:

- Is the site launch-ready for SEO and AI-search visibility? One line.
- Top 3–5 blockers or highest-leverage fixes, each with a one-line evidence ref.
- What is already strong (so it isn't accidentally "fixed" away).
- What **cannot be proven pre-launch** — anything that needs production crawl
  data, Search Console / Bing Webmaster, field CWV, or real index coverage.
- **Launch verdict: Red / Yellow / Green.** Red = a P0 blocks indexing or leaks
  data. Yellow = indexable but with P1 gaps. Green = launch-ready, P2 polish only.

Capture: the project's stage (pre- vs. post-launch — it changes how you weigh
URL-stability/301 concerns), and whether a documented SEO strategy exists.

## 2. Crawlability & Indexability

Verify the site can be crawled and the right pages (only those) can be indexed.

- `robots.txt`: present, correct host/sitemap directive, not accidentally
  `Disallow: /`; any AI-crawler allow/deny rules are intentional (see §10).
- Global index switch: any environment flag, middleware header, or meta that sets
  `noindex` / `X-Robots-Tag` sitewide. Confirm staging/preview is `noindex` and
  production is **not** accidentally inheriting it. A single inverted flag here is
  the most common launch-killing P0 — verify the actual rendered header/meta on a
  production-like build, not just the source intent. (Header-level checks: §4.)
- Per-surface index intent: public pages indexable; private/auth/account/admin and
  thin utility pages `noindex`. Cross-check against the project's surface
  inventory.
- HTTP status hygiene: 200 for live pages, real 404 (not soft-200) for missing,
  3xx only where intended. Spot-check a deleted/unknown slug.
- Rendering: if content is client-rendered, confirm the indexable HTML actually
  contains the content/links a crawler needs (view-source or fetch without JS).
  SPA shells that render empty to a no-JS fetch are a crawl risk — capture it.
- Sitemap ↔ index intent parity: every URL in the sitemap is canonical,
  200, indexable, and self-canonical; no `noindex`/redirected/private URLs in it.

**Evidence to capture:** the rendered `robots.txt` and `/sitemap.xml`, the
`X-Robots-Tag`/meta-robots on 2–3 representative public + private routes, and the
HTTP status of one known-missing slug.

## 3. URL Architecture, Canonicals & Redirects

Verify one canonical URL per thing, stable identity, no index-bloat surface.

- Canonical route families match the project's URL policy; slugs are stable and,
  where the policy promises it, self-healing (old slug → 301 → canonical).
- `rel=canonical` on every indexable page points to the absolute canonical self
  (or the chosen canonical for duplicates); no cross-domain or stale canonicals.
- Faceted/parameterized URLs (filters, sort, pagination, tracking params) have a
  deliberate policy: canonicalized to the base, `noindex`, or robots-excluded —
  not silently spawning thousands of thin indexable permutations.
- Redirects: shortlinks/legacy paths use 301 (not 302 for permanent), no chains or
  loops; trailing-slash and case handled consistently; HTTP→HTTPS and
  apex/www→canonical-host resolve to one host. (Verify status codes at §4.)
- Pre-launch projects: optimize for the *right* URL model, not migration cost —
  do not let "don't break existing URLs" constrain a pre-traffic redesign.

**Evidence:** the `<link rel=canonical>` value on one detail page per entity type,
the redirect status of one legacy/shortlink path, and one faceted URL's index
treatment.

## 4. HTTP Headers

Verify the response *headers* — not just the HTML — say the right thing. Crawlers
act on headers, and a header silently overrides the page's stated intent.

- **`X-Robots-Tag`** (the response-header form of meta-robots): confirm it is not
  applying `noindex`/`nofollow`/`none` to pages you intend to rank (a classic
  CDN / middleware / leftover-staging footgun), and that it *is* applied where you
  want non-HTML assets (PDFs, JSON feeds) excluded.
- **`Link: rel="canonical"`**: canonicals can be set via header — the only way for
  non-HTML resources (PDFs). If used, it points to the correct absolute URL and
  does not conflict with an in-HTML `<link rel=canonical>` (a header+HTML mismatch
  is a real defect).
- **Status codes** are correct per intent and emitted at the header level:
  200 live, real 404/410 for gone, **301/308 for permanent** redirects (not
  302/307), HSTS on HTTPS, HTTP→HTTPS and host canonicalization done at the edge.
  (Ties to §2/§3.)
- **`Content-Type`** correct per resource (`text/html; charset=utf-8`,
  `application/xml` for sitemaps, `image/*` for OG images) — a wrong content-type
  can break rendering or indexing.
- **`Vary`** set appropriately if you serve different content by `User-Agent` /
  `Accept-Language` / cookie. Watch for **cloaking**: serving crawlers different
  content than users is a violation — verify parity, don't just trust `Vary`.
- **Caching** (`Cache-Control` / `ETag` / `Last-Modified`): present and sane so
  crawlers can revalidate; public indexable pages are not `no-store`.
- **Security headers, only where they affect SEO:** a `Content-Security-Policy`,
  `X-Frame-Options`, or COEP/CORP rule that blocks Googlebot from rendering needed
  JS/CSS/resources (rendering-blocking CSP is an under-diagnosed indexing bug).
- **`Link: rel="alternate" hreflang=…`** if i18n is delivered via headers — §5.

**Evidence:** full response headers (`curl -sI`) for one indexable page, one
redirect, and one non-HTML asset (sitemap / PDF / OG image); flag any
`X-Robots-Tag` or `Link` header that contradicts the page's in-HTML intent.

## 5. Hreflang & Internationalization

For multi-language or multi-region sites. **If the site is single-locale, say so
and skip the cluster checks — but confirm a single correct `<html lang>` is set
and there are no stray/partial hreflang tags.**

- **Annotation completeness:** every localized URL in a set declares
  `rel="alternate" hreflang="<lang>[-REGION]"` for *each* variant, including a
  self-reference, via one consistent method (HTML `<link>`, the sitemap, or the
  `Link` header — not a mix).
- **Reciprocity (return links):** if page A lists B as an alternate, B must list A.
  Non-reciprocal hreflang is ignored by Google — verify both directions.
- **`x-default`:** present, pointing at the language selector or default-fallback
  page.
- **Valid codes:** ISO 639-1 language, optional ISO 3166-1 alpha-2 region, correct
  form (`en`, `en-US`, `es-419`); no invented codes, no region-as-language mixups.
- **Canonical × hreflang:** each locale page is **self-canonical** — NOT
  canonicalized to another locale (a frequent bug that collapses the whole set);
  hreflang targets are canonical, indexable URLs.
- **Routing & localized content:** locale routing (path `/es/`, subdomain, or
  ccTLD) is consistent; localized pages have genuinely localized content (not the
  same language at a different URL — duplicate-content risk); `<html lang>` matches.
- **No locale trap:** IP/geo auto-redirects don't lock crawlers into one locale or
  block the others (Googlebot crawls predominantly from the US — it must reach
  every locale).

**Evidence:** the full hreflang cluster for one localized URL (all alternates +
`x-default` + the return links), and the `<link rel=canonical>` of two locale
variants (confirm each is self-canonical).

## 6. Metadata & SERP Snippets

Verify each indexable page earns an accurate, compelling, unique snippet.

- `<title>`: unique per page, front-loaded with the entity/topic + qualifier,
  within sane length; templated titles don't collide across entities.
- Meta description: present, unique, accurate, action-oriented (not boilerplate
  repeated sitewide); missing is acceptable (Google may synthesize) but
  duplicate-everywhere is a finding.
- Robots/snippet directives intended for the page (`index`, no accidental
  `noindex`/`nosnippet`/`max-snippet` that suppresses the listing).
- No title/description that overpromises vs. on-page content (snippet-content
  mismatch hurts trust and CTR).
- Open Graph / social cards are audited separately in §7.

**Evidence:** title + description for one page per entity type; flag any duplicate
title/description pair across distinct pages.

## 7. Open Graph & Social Previews

Verify link unfurls (social shares, chat embeds, some AI surfaces) render an
accurate, compelling card.

- Core tags: `og:title`, `og:description`, `og:url` (the canonical absolute URL),
  `og:type` (`website`/`article`/`profile`/`product` as apt), `og:site_name`.
- `og:image`: absolute URL that returns 200, correct dimensions (1200×630
  recommended; ≥600×315; under ~5 MB), plus `og:image:width`/`:height`/`:alt`.
  **Not** a generic sitewide logo on content pages — a representative image per
  entity.
- Twitter/X: `twitter:card` (`summary_large_image` for a rich card) and
  `twitter:title`/`description`/`image` set explicitly where they differ from OG
  (they fall back to OG otherwise).
- Per-entity uniqueness: detail pages get their own title/description/image, not a
  sitewide default.
- Dynamic/generated OG images: the route returns a valid image (200, correct
  `Content-Type`) and does **not** render private fields into the card (ties to §16).
- Parity: the card's claims match the page; no stale or placeholder cards.

**Evidence:** the OG + Twitter tags and the fetched `og:image` status/dimensions
for one page per entity type; a rendered unfurl preview if a tool is available.

## 8. Structured Data & Entity Graph

Verify machine-readable identity that mirrors visible content — for rich results
*and* entity clarity for AI/search. Use the schema types the project's content
actually warrants (from its docs), not a speculative pile.

- Site-level: `Organization`/`WebSite` (with `sameAs` to real profiles); site
  search `potentialAction` only if a real search endpoint backs it.
- `BreadcrumbList` matching the visible breadcrumb trail.
- Entity pages: the right type per content (e.g. `LocalBusiness`/`ArtGallery`,
  `Product`/`Offer`, `Article`/`NewsArticle`, `Person`, `Event`,
  `CreativeWork`/`VisualArtwork`), with required + recommended fields populated
  from real data (address/hours/geo, price/availability, author/date, etc.).
- JSON-LD ↔ visible-content parity: structured data must reflect what's on the
  page — no invented ratings, no fields the page doesn't show, no marked-up
  content hidden from users.
- Validity: parses as JSON-LD, passes Rich Results / schema validation, no
  required-field warnings on types that target rich results.
- **No private leakage:** structured data must not expose provenance/operational/
  internal fields (see §16).
- Remember Google's AI-features guidance: structured data helps *understanding and
  rich results*, but there is **no special schema required for AI features** —
  don't recommend schema as an "AI ranking hack."

**Evidence:** the JSON-LD block(s) from one page per entity type, plus a
validation result or an explicit list of missing required fields.

## 9. Content Quality, E-E-A-T & Originality

Verify pages are genuinely useful to a real visitor and demonstrate
first-hand, trustworthy, original value (Google's helpful-content lens).

- Each indexable template has substantive, unique content — not a near-empty
  shell or boilerplate cloned across thousands of entities (thin/doorway risk).
  Use the project's own definition of a "thin"/publishable page if it has one.
- Experience/Expertise/Authoritativeness/Trust signals appropriate to the genre:
  authorship/bylines where relevant, real addresses/contact for local entities,
  citations/sources, dates, and clear provenance of facts.
- Originality: flag scraped, AI-spun, or derived-without-value copy; unique local
  or first-party data is the moat — verify it's actually present and surfaced.
- Match to query intent (§ scoping): does the page answer the intent it targets
  (name lookup, category×place, how-to, commercial), or is it generic filler?
- Duplicate/near-duplicate bodies across entities (same description reused) —
  a quality and canonical risk.

**Evidence:** word/section count and a uniqueness read on 2–3 representative
detail pages; name any template that renders effectively empty for sparse data.

## 10. AI / Generative Search Readiness

Verify the site is well-positioned for AI Overviews, AI Mode, and AI assistants —
**by the same fundamentals as classic search**, plus an intentional crawler
posture. Per Google's own doc, there is no special markup, file, or trick.

- The content AI would cite is in **crawlable, server-rendered HTML** with clear
  entities, concise factual statements, and a clean DOM — not locked behind JS,
  interaction, or auth.
- Pages are snippet-eligible (indexable, not `nosnippet`/blocked) — that
  eligibility is the literal gate for appearing as an AI supporting link.
- Clear, self-contained factual summaries near the top of key pages (who/what/
  where) so a model can extract them without guessing.
- **AI-crawler posture is intentional and documented:** decide per crawler whether
  to allow training vs. search/answer crawlers (e.g. OpenAI `GPTBot` vs.
  `OAI-SearchBot`; Google `Google-Extended`; Anthropic `ClaudeBot`/`anthropic-ai`;
  Perplexity `PerplexityBot`; `CCBot`). Verify current tokens from operator docs —
  blocking the *search/answer* crawler silently removes you from that AI's
  citations, which is usually not what a discovery site wants. Flag any block that
  contradicts the project's distribution goals.
- `llms.txt`: at most an optional, low-cost experiment; **not** a requirement, a
  ranking lever, or a substitute for crawlable HTML. Don't flag its absence as a
  defect.
- **Anti-hack guard:** do not recommend GEO/AEO gimmicks (keyword-stuffed answer
  blocks, fabricated FAQ/QA schema, cloaked "AI-only" content). Recommend only
  crawlability, factual clarity, entity structure, and genuine usefulness.

**Evidence:** the no-JS rendered HTML of one key entity page (does the citable
fact survive?), and the AI-crawler rules actually present in `robots.txt`.

## 11. Internal Linking & Information Architecture

Verify crawlers (and users) can reach every important page through links, with
meaningful anchors and a shallow path.

- Primary nav, footer, and breadcrumbs expose the main hubs; no important hub is
  reachable only via search or JS interaction.
- Entity cross-links exist where the model implies them (parent↔child,
  related/"more like this", category↔member) and use descriptive anchor text
  (not "click here" / bare slugs).
- No orphan pages: every indexable URL is linked from somewhere crawlable;
  cross-check sitemap URLs against discoverable internal links.
- Crawl depth: key entity pages reachable within a few clicks of the homepage;
  flag deep burial behind paginated facets only.
- Hub/index pages actually link to their members (and paginate crawlably) rather
  than loading them via uncrawlable infinite scroll with no link fallback.

**Evidence:** the link path from homepage to one deep entity page; one example of
a related/cross-link module and its anchor text; any orphan found via the
sitemap-vs-links diff.

## 12. Performance & Core Web Vitals

Verify the indexable pages are fast and stable. Lab signals only pre-launch;
field data (CrUX/Search Console) is post-launch — say which you're judging on.

- **LCP** (load): the LCP element (usually the hero image) is prioritized — proper
  `next/image`-style optimization or sized/`fetchpriority=high` for above-the-fold,
  not lazy-loaded; explicit dimensions; no render-blocking hero. Target p75
  ≤ 2.5 s.
- **INP** (responsiveness): minimal main-thread blocking JS on indexable pages;
  heavy widgets (maps, search, carousels) are deferred/dynamically imported and
  don't gate first interaction. Target p75 ≤ 200 ms. (INP replaced FID — judge
  responsiveness across all interactions, not just the first.)
- **CLS** (stability): images/embeds/ads have reserved dimensions; fonts use
  `font-display: swap` with fallback metrics; no late-injected content shoving
  layout. Target p75 ≤ 0.1.
- Client JS footprint on indexable pages is justified; no shipping an SPA's worth
  of JS to render a mostly-static content page.
- No horizontal overflow / forced reflow on mobile (also a page-experience signal).

**Evidence:** the LCP element and its loading strategy on one heavy page; the
list of large/blocking client bundles on an indexable route. If a perf tool is
available, capture a lab score; otherwise reason from the code and label it lab/
inferred.

## 13. Mobile, Accessibility & Page Experience

Verify the mobile experience and baseline a11y — Google indexes mobile-first and
page-experience signals overlap with a11y.

- Renders correctly at ≤ 375 px: no horizontal scroll, no clipped content, tap
  targets adequately sized and spaced.
- Semantic structure: one logical `<h1>`, sensible heading order, landmarks
  (`main`/`nav`/`header`/`footer`), `lang` set.
- Images have meaningful `alt` (empty `alt` only for decorative); form controls
  have labels; interactive elements are real buttons/links (focusable, keyboard
  operable) with visible focus states.
- Color contrast meets WCAG AA on text and key UI.
- No intrusive interstitials covering content on mobile load; graceful degradation
  if JS fails (core content/links still present).

**Evidence:** mobile render observation at 375 px (browser or code reasoning),
heading outline of one key page, and any missing-`alt`/unlabeled-control instance.

## 14. Local SEO (if the project has a place/locality dimension)

For sites tied to physical places or service areas. Skip if not applicable, but
say so.

- Consistent NAP (name, address, phone) on entity pages, matching what would be on
  the business profile; real `LocalBusiness`/`ArtGallery`/etc. schema with
  `address`, `geo`, `openingHours`, `telephone`.
- Locality signals in content, titles, and headings for the target area — without
  doorway-page spam (no near-duplicate "[service] in [town]" pages with no unique
  value).
- Map/coordinate handling is accurate; embedded maps don't tank performance on the
  indexable page.
- Genuine local landing pages (real content per place), not programmatic doorways;
  use the project's locality policy to judge what's legitimately "local."
- Note Google Business Profile / map-pack implications as post-launch actions
  (can't be audited in-repo).

**Evidence:** NAP + `LocalBusiness` schema for one place entity; flag any
doorway-style locality page set.

## 15. Search, Facets & Browse Surfaces

Verify on-site search and faceted/category browse help users and crawlers without
spawning index bloat or leaking private data.

- The search results page itself: typically `noindex` (or carefully canonicalized)
  — don't let infinite query-string result pages into the index.
- Category/facet pages that *should* rank (curated, valuable category landings)
  are indexable and canonical; combinatorial filter URLs are not (see §3).
- If using a hosted search service (e.g. Algolia), verify: env split (public
  search key vs. admin key — admin key never client-exposed), the indexed records
  contain **only public view-model fields** (no provenance/private leakage), and
  the indexed records / settings haven't drifted from the app's documented schema.
- Browse facets expose crawlable links to canonical category pages so members are
  discoverable (ties to §11).

**Evidence:** index treatment of the search results route; the field set of one
indexed search record (confirm no private fields); confirmation that only a public
key reaches the client.

## 16. Security, Privacy & the Public-Data Boundary

Verify nothing operational, provenance-related, or private leaks into any
crawlable/public surface. Use the project's documented public-vs-private field
list as the allowlist.

- Public pages, metadata, JSON-LD, OG images, sitemap, feeds, and search records
  expose **only** the intended public fields — no source/provenance, internal
  scores, draft/unpublished flags, owner PII, or admin-only data.
- Protected surfaces (auth, account, claim/edit, admin, internal tools) are both
  **access-gated** and `noindex`, and never appear in the sitemap or internal
  links from public pages.
- Unpublished/draft entities are not reachable or indexable via guessable URLs,
  sitemap, or search records.
- API/JSON endpoints that back public pages don't return private fields in their
  payloads (rendered HTML can hide a field the JSON still ships).
- No secrets in client bundles or `NEXT_PUBLIC_*`-style public env (admin/API keys
  stay server-only).

**Evidence:** the field set of one public detail page's HTML + JSON-LD + (if
applicable) search record, checked against the allowlist; the index/gate status of
one admin/account route; one unpublished entity's reachability.

## 17. Measurement & Launch Monitoring

Verify the instrumentation to *know* SEO is working exists or is planned. Most of
this is post-launch, so frame as a readiness checklist, not a pass/fail.

- Search Console (Google) and Bing Webmaster Tools: property verification planned;
  sitemap submission planned.
- Analytics / traffic measurement wired (or a concrete plan), distinguishing
  organic + AI-referral traffic where possible.
- Field Core Web Vitals monitoring (CrUX / Search Console / RUM) planned.
- Post-launch index-coverage check planned (are the right pages getting indexed,
  the wrong ones excluded?), plus 404/500 and crawl-error monitoring.
- A cadence for reviewing queries/pages and acting on it.
- Note explicitly which findings in this audit are **unprovable until production
  data exists** and route them here.

**Evidence:** what measurement is already wired in-repo (analytics snippet, GSC
verification meta, sitemap submission), vs. what's only planned/absent.

## 18. Final Deliverable (full audit)

Assemble the report in this shape (concise, code-review style — do not bury
blockers under a checklist):

1. **Launch verdict** — Red / Yellow / Green, one-line rationale.
2. **P0 blockers** — would prevent correct indexing, or leak private data, at
   launch. Each: the defect, the evidence ref, the fix direction.
3. **P1 high-value fixes** — material organic/AI-visibility wins; same format.
4. **P2 opportunities** — polish and upside.
5. **Already strong** — what's working, so it's preserved.
6. **Needs production / Search Console data** — what can't be proven pre-launch.

Every item carries its evidence (file:line, route + status, rendered HTML, doc
citation). Confirmed issues, recommendations, and unprovable items stay visually
separated. This is a forensic audit and recommendation pass only — **no file
edits.**

(For a single `/seo-audit <target>` run, skip this assembly: report just that
section's findings with evidence and a one-line mini-verdict — **Pass / Issues /
Blocker**.)
