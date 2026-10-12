# SEO doctrine — shared layer for entity & content sites

> **SHARED DOC — manually synced, keep copies byte-identical.** Known copies:
>
> - `bo-co-art` → `docs/ops/seo-doctrine.md`
> - `open-the-bible-ai-web` → `docs/seo/seo-doctrine.md`
> - `agent-config` → `skills/seo-audit/references/seo-doctrine.md` (the
>   `seo-audit` skill reads it when a project has no doctrine of its own)
>
> To change doctrine: edit one copy, then copy the whole file verbatim to the
> siblings (and update this list if a repo joins). **Nothing project-specific
> goes in this file** — strategy, decisions, calibrations, and logs live in
> each repo's own playbook (`seo-playbook.md` next to this file), which is
> always that project's authority.

**Provenance.** Distilled from the
[claude-code-seo knowledge base](https://github.com/mxfschr/claude-code-seo)
(CC BY-NC-SA 4.0 — internal adaptation with attribution; never republish or
resell), practitioner operational rules (u/iamMXFSCHR), and our own field
adaptations. Every claim carries an epistemic tag — keep the discipline when
adding doctrine:

- **[documented]** — DOJ testimony, Google statements, or original papers.
- **[inferred]** — May-2024 leak interpretation or strong practitioner
  consensus; probably right, not provable.
- **[anecdote]** — single experiments, Reddit lore. Directionally useful.
- **[ours]** — our own field adaptation.

---

## 1. Core doctrine

1. **Authority gates indexing; relevance + quality set position.** "Crawled,
   not indexed" is an authority problem, not a content problem. [inferred]
   For large thin-page sets (entity pages, passage/topic pages), indexing IS
   the early battle. Levers: hub→leaf internal links, full rosters in
   server-rendered HTML, sitemaps matched to indexability policy, and a few
   real external links pointed at hubs.
2. **One keyword = one dedicated page.** Exact-match URL, title, H1. A
   query-param view doesn't exist as far as this strategy is concerned; a
   facet worth ranking for gets a real path. [inferred, strong consensus]
3. **Internal authority is finite — route it deliberately.** Link FROM pages
   with proven traffic TO pages stuck at positions 4–20; fewer deliberate
   links beat link-everything. Pre-data, broad discovery linking is the right
   default; deliberate authority shaping starts only when Search Console
   identifies donors and stuck pages. [inferred]
4. **Thin starter pages, expanded by proven demand.** Publish minimal pages,
   watch GSC impressions/position for 2–4 weeks, invest where demand shows.
   [anecdote→consensus]
5. **Titles are merchandising; CTR is (probably) an authority signal.**
   NavBoost exists [documented]; its weights don't. Write titles for the SERP
   click: entity/topic + qualifier up front, plain words, no cleverness.
6. **Backlink quality is page-level, not domain-level.** A link from a page
   that itself ranks and has traffic passes value; a zero-traffic page on a
   high-DA domain passes ~nothing. Qualify targets by "does the linking page
   rank for anything." [inferred] Look for product-mechanics link sources
   before outreach (people linking to pages that are _theirs_ — profiles,
   embeds, bylines).
7. **Branded search is compounding equity.** Off-site activity that makes
   people search the brand by name builds trust; track it in GSC from day
   one. [inferred]
8. **AI-search visibility follows classic rankings.** LLM answers are
   assembled via query fan-out from Google/Bing results; being the
   structured, crawlable, citable source of facts IS the "GEO" program — no
   separate one needed. [inferred]
9. **Refusals — do not adopt:** schema skepticism (wrong for entity/fact
   pages: keep entity schema, skip schema bloat); press-release LLM
   manipulation; stub-page farms at scale (site-reputation + brand risk); DA
   chasing; guest-post marketplaces; .edu link schemes.

## 2. Operational gates (post-launch, GSC-driven)

1. **28-day histogram gate.** No authority-shaping links FROM a page until it
   has 28 days of GSC history with real impressions/clicks.
2. **Click-gated donors, with a low-volume fallback.** Position 1–3 with
   clicks = donor. Position 1–3, zero clicks, decent impressions =
   _provisional_ donor — small/local/niche query volumes starve under pure
   click gates. [ours]
3. **Topical neighborhood.** Donors fund pages in their own topic cluster
   only.
4. **Cannibalization taxonomy before redirects.** SERP rotation (pages
   alternating) is normal — no action. True cannibalization is both pages
   suppressed by the diversity filter simultaneously. Classify first; URLs
   usually have product jobs beyond SEO.
5. **7-day cooldown on deliberate SEO edits** (titles, H1s, hub copy) so GSC
   measurement windows stay clean. Product changes and data refreshes are
   exempt — content freshness is a feature, not thrash.
6. **State tracking.** Once audits recur, keep a state file (last run, pages
   touched, links already recommended) so successive runs don't repeat or
   thrash work.
7. **SERP composition beats keyword-difficulty scores.** Per planned page,
   eyeball who actually holds the SERP: genuine topical authorities vs.
   forums, listicles, stale directories. Soft SERP → build; fortified →
   defer. Difficulty scores don't capture this.

## 3. Dev checklist — every public surface

The generic template; each project's playbook binds it to real helpers,
files, and policies by name.

1. Metadata is intentional, not derived: title/description written for the
   SERP click; canonicals from shared helpers, never hand-built.
2. Indexability is decided explicitly per route (index vs. noindex + robots
   policy). Silence is a bug.
3. A rankable facet gets a real path with exact-match URL/title/H1.
4. Facts live in server-rendered HTML; structured data supplements, never
   substitutes.
5. Entity schema from shared helpers only; no schema bloat on non-entity
   pages.
6. Internal links are real server-rendered anchors; no orphan pages — every
   page receives links (hub/shelf/index) and gives them (breadcrumbs up,
   related laterally).
7. Images carry meaningful alt text.
8. Public pages stay cacheable and fast; SEO surfaces never depend on
   session state.
9. URL changes follow the project's canonicalization policy (301s; retired
   slugs never reassigned).
10. A pre-launch indexing gate opens as a launch event, not a toggle;
    post-launch deliberate SEO edits follow the cooldown (§2.5) and get
    logged in the project playbook.

## 4. Adaptation notes by site shape

- **Entity directory** (e.g. a local artist/gallery guide): long tail =
  entity-name queries, where indexing is the whole battle; hubs = category ×
  locality; the strongest link flywheel is owners linking to their own
  claimed pages. Watch for entity page vs. hub cannibalization on
  `[name] + noun` queries.
- **Content/reference site** (e.g. a Bible teaching library): long tail =
  passage/topic/question queries ("what does X mean", "[passage] explained");
  hubs = books/topics/series; programmatic surface = passage or topic pages
  that each carry unique value (never template-only). Curated question pages
  (one question, exact-match title/slug/H1, concise answer) fit this shape
  well — but stay curated and demand-gated, never a stub farm. Link flywheel
  candidates: embeds/widgets, partner organizations, author bylines —
  identify the real one in the project playbook.

## 5. What a project playbook owes this doc

Each repo's `seo-playbook.md` should cover, minimally: how the project wins
search (query classes + its link flywheel); project deltas from this doctrine
(with reasons); the dev checklist bound to the project's actual helpers and
policies; gate calibrations for the project's query volumes; a phased plan;
open questions; and a dated accumulation log where every SEO decision lands —
**no SEO decision lives only in a chat transcript.**
