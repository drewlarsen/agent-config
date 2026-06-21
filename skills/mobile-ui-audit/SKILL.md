---
name: mobile-ui-audit
description: Evidence-grounded mobile UX audit for any web frontend — proves whether a site is genuinely **mobile-designed** or just a **shrunken desktop layout**, by driving it at real phone viewports (not reading code). Run `/mobile-ui-audit <target>` for one focused check — touch, nav, reading, forms, device-fit, gestures, perf, media, pwa — or `/mobile-ui-audit full` (or no argument) for a comprehensive audit ending in a Red/Yellow/Green verdict, a prioritized P0/P1/P2 findings table, and (if `/decide` is available) owner decision briefs. Every finding cites a `file:line` AND a screenshot or measured value. Use when asked to audit/review the mobile or responsive experience, check touch targets / thumb zone / tap feedback, mobile navigation, safe-area / notch / `viewport-fit`, mobile typography & line length, input ergonomics / keyboards / zoom-on-focus, bottom sheets / gestures / `navigator.share`, mobile Core Web Vitals, a media/audio/video player on mobile, or PWA install / offline / background-audio / native-parity readiness.
version: 1.0.0
user-invocable: true
argument-hint: "[full · touch · nav · reading · forms · device-fit · gestures · perf · media · pwa] — bare or `full` = comprehensive audit"
---

# Mobile UI Audit

A read-only, evidence-grounded audit of a web app's **mobile** experience. The bar
is **mobile-*optimized*, not "looks ok at 390px."** The litmus test for every screen
is task-based, not layout-based:

> *Can someone finish the task one-thumbed, on a slow network, while distracted —
> eyes half on the road, phone in one hand?*

The job is to prove or disprove that the site is mobile-*designed* vs. a **shrunken
desktop layout** — surface what's genuinely mobile-optimized vs. merely reflowed —
and hand back a **prioritized set of changes the owner can act on this week.** This
skill owns the *how* (method, evidence bar, rubric, the device-driving discipline);
the project's own design docs own the *what* (its design system, tokens, intent).

**The line that defines this skill: evidence or it didn't happen.** No finding is
inferred from code alone. Every claim cites a `file:line` *and* a screenshot or a
measured value (computed px, font size, Lighthouse number). If you only drove the
device, find the code; if you only read the code, drive the device.

## Dispatch

`/mobile-ui-audit <target>` runs ONE focused check. **No argument (or `full`)** runs
the comprehensive audit. Match the argument to a target (accept the aliases); if it
matches nothing, treat it as a free-form focus and pick the closest section(s).

| Target | Aliases | Checks | Section |
| --- | --- | --- | --- |
| `full` | `launch`, _(blank)_ | every applicable section + Red/Yellow/Green verdict | all |
| `touch` | `reach`, `targets`, `thumb`, `tap` | hit area ≥44px, spacing, thumb-zone placement, `:active` feedback, no hover-gated actions | §1 |
| `nav` | `navigation`, `chrome`, `header`, `menu` | nav *restructured* vs. desktop mega-menu crammed in; fixed-chrome budget; thumb-zone primary action | §2 |
| `reading` | `typography`, `type`, `content`, `text` | body ≥16px, line-height, measure ~45–75ch, sane reflow, rails have mobile fallbacks, responsive images | §3 |
| `forms` | `input`, `keyboard`, `fields` | inputs ≥16px (no iOS zoom), correct `type`/`inputmode`/`autocomplete`, `type=submit` | §4 |
| `device-fit` | `safe-area`, `notch`, `viewport`, `inset` | `viewport-fit=cover` + `env(safe-area-inset-*)` on every fixed bar; notch/Island/home-indicator; orientation | §5 |
| `gestures` | `motion`, `sheets`, `share`, `scroll` | momentum scroll, `overscroll-behavior: contain`, `navigator.share()`, bottom sheets, `prefers-reduced-motion` | §6 |
| `perf` | `cwv`, `vitals`, `speed`, `performance` | mobile Core Web Vitals (LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 on throttled mobile) | §7 |
| `media` | `audio`, `video`, `player`, `playback` | _(only if the app plays media)_ Media Session metadata/artwork/transport, background playback, scrubber hit area, queue/resume/speed/sleep-timer | §8 |
| `pwa` | `native`, `native-parity`, `install`, `offline`, `push` | _(opt-in)_ installable manifest, offline shell, background audio, push/re-engagement, native-feel — the retire-vs-keep-native-app lens | §9 |

<!-- This table is the canonical target list. Keep the frontmatter `description` and
`argument-hint`, plus `agents/openai.yaml`, in sync with it when adding/removing targets.
`media` runs only if the app has playback; `pwa` is opt-in (native-parity goal). -->

## How to run

**Shared prep (always, proportional to the target):**

1. **Read-only on the source; write only your own report.** Findings and
   recommendations only — no edits to the app's code. (Producing the audit markdown
   is fine.) If the user converts the task to implementation, that's a new task.
2. **Discover the stack and defer to the project's design docs.** Read `AGENTS.md` /
   `CLAUDE.md` (note server-ownership rules, project stage, design-system state),
   then find the project's design docs — don't assume a path, search: `rg -li
   'design system|tokens|mobile|responsive|breakpoint' --glob '*.md' -g
   '!node_modules'`, `fd -e md`. Detect the framework/CSS approach from
   `package.json` (Next/React/Vue/Svelte/Astro; Tailwind/CSS-modules/etc.) so your
   selectors, file globs, and fixes match reality. Audit the code *against* those
   docs and flag **code↔doc drift both ways**; reuse existing tokens/components,
   don't invent parallel ones. If a behavior is **intentional by design** (documented
   locale fallback, deliberate desktop-only feature), don't flag it as a mobile bug.
3. **Derive the real surface inventory from the router** — never assume another
   site's routes. Map the project's actual mobile-critical surfaces (see §0 in the
   reference): global nav & chrome, primary content/detail templates, collection/list
   pages, search, forms, media playback (if any), home & high-traffic landings, auth/
   account. Audit in priority order — the surfaces a distracted thumb hits most.
4. **If handed prior leads, treat them as leads, not conclusions** — confirm or kill
   each one with fresh evidence before it enters the report.

**Method & tools — in this order:**

1. **Run the agent dev server, never the human's.** If the project documents a
   server-ownership convention (e.g. human owns an even port / `base`, the agent owns
   `base+1` with a separate build dir), use the agent server and **never start, fetch,
   or kill the human's.** If there's no convention, start your own on a free port and
   stop it when done. **Drive it — don't fetch-only and don't audit from code alone.**
2. **Drive at real device viewports** with whatever browser-driving tooling the
   session has — a preview/automation MCP (e.g. Claude Preview, Claude-in-Chrome),
   Playwright via Bash, or a manual run-and-screenshot. Resize to **390×844** (iPhone
   14/15 class, primary), **360×800** (small Android), **430×932** (Pro Max), and
   **844×390** (landscape). Snapshot structure, **inspect computed CSS** (measure
   touch targets, font sizes, line length, fixed-bar heights), exercise nav / sheets /
   any media player / search / forms, watch the console + network for errors and
   payload weight, and screenshot as evidence.
3. **Design-quality critique (if the skills are installed):** invoke `/impeccable`
   for the visual-hierarchy / IA / cognitive-load / motion critique and live element
   iteration; use the `frontend-design` skill for any redesign sketch you propose.
4. **Compliance pass (if installed):** run `web-design-guidelines` (Web Interface
   Guidelines + a11y) against the mobile views.
5. **Performance lens:** apply `vercel-react-best-practices` / `vercel-optimize`
   thinking and a Lighthouse **mobile** run on the heavy templates (home, a detail
   page, a list page, search). Target p75 LCP ≤2.5s, INP ≤200ms, CLS ≤0.1 on
   throttled mobile. A preview deploy can give a closer-to-field profile.
6. **Cross-check against external mobile rubrics and cite them** where a finding
   maps to one (NN/g touch targets, Baymard keyboards/line-length, Material 3, WCAG
   2.2 §2.5.8 / §1.4.2 / §2.5.5, web.dev CWV/PWA/Media Session). Full source list in
   the reference. Don't assert mobile-UX facts from memory if web access is available.

**Single target:** read that section in `references/audit-sections.md` (plus the
short **Stance** preamble), run its checks against the project's real routes at the
viewports above, and report **just that aspect** — a tight, evidence-backed finding
list + a one-line mini-verdict (**Pass / Issues / Blocker**). Don't run the full pass.

**Full:** run every applicable section (skip `media` if there's no playback; run
`pwa` only when native-parity is a stated goal — note it as conditional), then output
the full deliverable below.

## Point of view (what makes this an *audit*, not a bug list)

- **Audit as the product owner.** If `/decide` is available, frame each prioritized
  cluster as a **decision brief**: Context → Issue → Options → one recommended path,
  in the stakes a product/tech/business leader weighs (time, cost, risk,
  reversibility, product impact, distribution/SEO, brand, maintenance, optionality).
  Owner language, full technical fidelity, no implementer jargon in the recommendation.
- **Act as a technical architect, not a bug-lister.** Separate **root causes**
  (desktop-first breakpoint posture; absence of a device-fit/safe-area foundation; a
  player built on a bare `<audio>`) from the **symptoms** they spawn. Recommend the
  structural fix first, then the local patches it makes cheap.
- **Where a fix needs a product call** (add a bottom tab bar; build a now-playing
  screen; invest in offline) present it as a decision-brief option — don't silently
  pick.

## Depth — go deep by default

Thorough by default, not a skim. **When you can spawn parallel subagents (e.g. the
Task tool):** one finder per surface or per rubric dimension reads + drives in
parallel and returns structured candidates; **adversarially verify** each (is the
target really sub-44px at this viewport? does the rail actually have no fallback?),
dropping any that don't survive; then synthesize a deduped, severity-ranked review.
**When orchestration isn't available:** do the equivalent sequentially — surface by
surface, then a deliberate self-refutation pass before anything ships.

## Deliverable

Write the report to the project's audit location if one exists (else report inline):

1. **Verdict** — Red / Yellow / Green on "mobile-optimized vs. shrunken desktop," a
   one-sentence answer to the litmus question, and a screenshot strip of the 3–4 worst
   offenders.
2. **Prioritized findings table** — **P0** (broken/blocking on a phone) · **P1**
   (clearly sub-optimal, real UX cost) · **P2** (polish), each with surface,
   `file:line`, evidence link (screenshot / measured value), and a one-line fix.
3. **Decision briefs** (via `/decide`, if available) for the top clusters — root-cause
   briefs first (device-fit foundation, breakpoint posture, media platform, PWA/offline
   shell) before the local ones.
4. **Sequenced roadmap** — quick wins (≤ a day each) → structural bets, with the 1–2
   root causes called out as the highest-leverage work and the symptom fixes they unlock.
5. **Evidence appendix** — screenshots at 360 / 390 / 430 / landscape for every major
   finding.
6. **(pwa target only) Native-parity scorecard** — native capability (install ·
   offline · background/lock-screen audio · push · native-feel gestures) × current web
   status (**Met / Partial / Missing**) × what it would take to close.

See `references/audit-sections.md` for every section's detailed checks, the
"shrunken-desktop tell-test," the surface taxonomy, and the external sources to cite.
