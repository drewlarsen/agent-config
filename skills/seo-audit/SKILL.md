---
name: seo-audit
description: Read-only, evidence-grounded SEO + AI-search audit for any web codebase. Run `/seo-audit <target>` for one focused check — sitemap, canonicals, headers, hreflang, meta, og, schema/ld+json, content, ai, links, cwv, a11y, local, privacy — or `/seo-audit full` (or no argument) for a comprehensive launch-readiness audit ending in a Red/Yellow/Green verdict. Auto-discovers and defers to the project's own SEO docs; falls back to a built-in checklist. Use when asked to audit SEO or to check any of indexing, crawlability, robots, sitemaps, canonicals, redirects, HTTP headers, hreflang/i18n, titles/descriptions, Open Graph / social cards, structured data / schema, Core Web Vitals (LCP/INP/CLS), AI Overviews readiness, internal linking, local SEO, or public-data leakage.
version: 3.0.0
user-invocable: true
argument-hint: "[full · sitemap · canonicals · headers · hreflang · meta · og · schema · content · ai · links · cwv · a11y · local · privacy]"
---

# SEO Audit

A read-only, evidence-grounded SEO / AI-search audit harness. Run **one focused
check** or the **full launch audit** — both share the same method, evidence bar,
and the project-doc deference described below. This skill owns the *how*; the
project's own SEO docs own the *what*.

## Dispatch

`/seo-audit <target>` runs ONE focused sub-audit. **No argument (or `full`)** runs
the comprehensive launch-readiness audit. Match the argument to a target (accept
the aliases); if it matches nothing, treat it as a free-form focus and pick the
closest section(s).

| Target | Aliases | Checks | Section |
| --- | --- | --- | --- |
| `full` | `launch`, _(blank)_ | every section + Red/Yellow/Green verdict | all |
| `sitemap` | `crawl`, `robots`, `indexing` | sitemap ↔ index parity, robots, crawl/index directives | §2 |
| `canonicals` | `urls`, `redirects` | canonical tags, redirects, faceted-URL policy | §3 |
| `headers` | `http`, `x-robots` | SEO-relevant HTTP response headers | §4 |
| `hreflang` | `i18n`, `locale`, `lang` | hreflang / internationalization | §5 |
| `meta` | `metadata`, `titles`, `serp` | titles, descriptions, SERP snippets | §6 |
| `og` | `social`, `opengraph`, `cards` | Open Graph / Twitter cards / previews | §7 |
| `schema` | `ld+json`, `jsonld`, `structured-data` | JSON-LD validity, content parity, no leak | §8 |
| `content` | `eeat`, `thin`, `quality` | content quality / E-E-A-T / originality | §9 |
| `ai` | `geo`, `aeo`, `llm` | AI-search / AI Overviews readiness | §10 |
| `links` | `ia`, `internal`, `orphans` | internal linking, orphans, crawl depth | §11 |
| `cwv` | `perf`, `vitals`, `speed` | Core Web Vitals risk (LCP/INP/CLS) | §12 |
| `a11y` | `mobile`, `page-experience` | mobile + accessibility + page experience | §13 |
| `local` | `localseo`, `nap`, `gbp` | local SEO | §14 |
| `search` | `facets`, `browse`, `algolia` | on-site search / faceted browse | §15 |
| `privacy` | `boundary`, `leak`, `security` | public/private data boundary | §16 |
| `measurement` | `monitoring`, `gsc`, `analytics` | measurement & launch monitoring | §17 |

## How to run

**Shared prep (always, but keep it proportional to the target):**

1. **Stay read-only.** Findings and recommendations only; no file edits. If the
   user converts the task to implementation, that's a new task.
2. **Discover and defer to the project's own SEO docs.** Read `AGENTS.md` /
   `CLAUDE.md` (note any server-ownership rule + project stage), then find the
   project's SEO docs — don't assume a path, search: `rg -li 'seo|canonical|
   sitemap|structured data' --glob '*.md' -g '!node_modules'`, `fd -e md seo`. A
   doctrine + playbook pair (e.g. `docs/ops/seo-doctrine.md` +
   `seo-playbook.md`, or `docs/seo/**`) is the source of truth: the playbook is
   the binding project authority. Audit the code *against* those docs and flag
   **code↔doc drift both ways**. If none exist, use the generic checklist and note
   "no documented SEO strategy" as a finding. (BAG/`boco.art` is one example of a
   project with such docs — nothing here is project-specific.)
3. **Refresh official guidance** for any currency-sensitive target (`cwv`, `ai`,
   `schema`, `sitemap`) if web access is available — see the source list + currency
   guardrails at the top of the reference. Don't assert SEO facts from memory.
4. **Scope to the project:** derive the real surface inventory, entity/schema map,
   query/intent classes, and public/private field boundary from the project's docs
   + router — never assume another site's routes.

**Single target:** read only that section in `references/audit-sections.md`, run
its checks against the project's real routes/templates, and report **just that
aspect** — a tight, evidence-backed finding list + a one-line mini-verdict
(**Pass / Issues / Blocker**). Do not run the full multi-section pass.

**Full:** run every section, then output the full report — **Launch verdict
(Red/Yellow/Green)** first, then **P0 blockers → P1 fixes → P2 opportunities →
already strong → needs production/Search Console data.**

## Output discipline (both modes)

- **Evidence or it didn't happen:** file path + line, route + HTTP status, rendered
  HTML, browser/DevTools observation, official-doc citation, or a documented
  project requirement. No evidence → it's a recommendation, labeled.
- Keep confirmed issues, recommendations, and unprovable-pre-launch items visually
  separated. Lead with the verdict; don't bury blockers under a checklist. Where a
  finding maps to a project SEO-doc policy, cite it.
- **Anti-hack guard:** never recommend GEO/AEO gimmicks (keyword-stuffed AI-answer
  blocks, fabricated FAQ/QA schema, `llms.txt` as a ranking lever, cloaked AI-only
  content). The win condition for AI search is the same as classic search:
  crawlable, factual, well-structured, genuinely useful content.

See `references/audit-sections.md` for all 18 sections, the official sources to
refresh, and the currency guardrails.
