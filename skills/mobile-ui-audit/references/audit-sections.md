# Mobile UI Audit — Section-by-Section Rubric

A forensic, evidence-grounded harness for auditing the **mobile** experience of any
web frontend (content sites, marketplaces, SaaS, docs, apps with media playback). It
is **broader than a per-component checklist**: it scores each surface against the
"shrunken desktop vs. mobile-designed" question and ends in an owner-actionable plan.

**This file is the generic spine. It is NOT the source of truth for project
specifics.** The project's own design docs (discovered per SKILL.md) own the *what* —
the design system, tokens, breakpoint posture, which behaviors are intentional. This
file owns the *how* — the method, the evidence bar, the section coverage. When a
project design doc and this file disagree on a project specific, the project doc wins;
when they disagree on audit method or evidence rigor, this file wins.

SKILL.md maps each `/mobile-ui-audit <target>` to a section here. For a single
target, read and run only that section (plus the shared Stance). For `full`, run every
applicable section and assemble the deliverable.

## Stance and rules (every section inherits these)

The full stance lives in SKILL.md and governs every run: **read-only on the source**
(findings only; you may write your own report), **evidence or it didn't happen**
(`file:line` *and* a screenshot or a measured value — computed px, font size,
Lighthouse number; a claim from "best practice" with no project evidence is a labeled
recommendation, not a finding), **drive the device — never audit from code alone**,
**separate confirmed issues from recommendations from "needs a real device"**,
**currency over memory** (refresh official guidance for currency-sensitive areas), and
**respect intentional-by-design behavior**. Don't restate them — apply them. The rules
specific to running the sections here:

- **Respect server ownership.** If a project doc names an owner of a persistent local
  server (e.g. a human owns an even port), you may inspect it if up but must not
  start/stop/restart it. If you need your own server, use the agent port (if the
  project defines one) or a temporary free port, and stop it when done.
- **Test at four viewports minimum:** 390×844 (primary), 360×800 (small Android),
  430×932 (Pro Max), 844×390 (landscape). Computed values, not assumptions —
  `:active` state and zoom-on-focus only show on a real interaction.
- **Don't regress desktop.** No mobile fix may break the desktop layout or violate the
  design system. Reuse existing tokens/components; don't invent parallel ones.

## §0 — Surface taxonomy (derive the real list from the router first)

Map the project's actual mobile-critical surfaces and audit in priority order — the
ones a distracted thumb hits most, first. Typical surfaces:

1. **Media playback** *(if the app has it — often where "mobile-optimized" is won or
   lost)* — the persistent player and its launch points.
2. **Global nav & chrome** — header, drawer/menu, footer, any sticky banners, the
   tokens/heights in the global stylesheet.
3. **Reading / detail templates** — the article/product/item page, rich-text renderer,
   reading-progress cue, related-content rails, share control.
4. **Collection / index / list pages** — the listing layouts and their filters.
5. **Search** — the search entry, results, and any faceted browse.
6. **Forms** — contact, signup/newsletter, checkout/donate, auth.
7. **Home & high-traffic landing pages.**

Resolve each to real files before judging. Where many templates look copy-pasted,
assess them *as a set* — how much is shared shell vs. genuinely per-surface.

## §1 — Touch & reach

- Every tappable element **≥ 44×44px** (48 preferred) with **≥ 8px** spacing between
  targets. **Padding counts toward hit area** — measure the computed box, not the icon.
- Primary actions live in the **bottom thumb zone**, not pinned to the top.
- Immediate `:active` / pressed feedback (**< 100ms**) on every control.
- Nothing essential gated behind `:hover` (no hover = no access on touch).
- Common offenders: icon buttons sized to the glyph (`size-icon-sm`, 28px hamburgers),
  list/rail links with tiny padding (`p-1.5` → 6px), grid items at `min-h-10` (40px),
  scrubbers/sliders only a few px tall.

Cite: NN/g *Touch Targets*, Material 3 target sizing, WCAG 2.2 **2.5.8** (target size,
min) and **2.5.5** (target size, enhanced).

## §2 — Navigation & chrome

- Is mobile nav **restructured** (drawer / bottom-tab / progressive disclosure /
  search-first) or a desktop mega-menu crammed into 390px? The latter is the canonical
  shrunken-desktop tell.
- Is there a **thumb-zone primary action**, or is everything top-pinned?
- **Fixed-chrome budget:** add up header + banner + any media dock. Does fixed chrome
  leave a usable content well, or eat a third-plus of the viewport before any content?
  (e.g. 64px header + 144px dock spacer ≈ 208px ≈ 53% of a 390px viewport.) Consider
  hide-on-scroll-down / reveal-on-scroll-up.

Cite: Smashing *Sticky Menus UX*, *Golden Rules of Mobile Navigation*, *Thumb Zone*.

## §3 — Reading & typography

- Body **≥ 16px**, comfortable line-height, measure **~45–75 ch** (not a fluid-shrunk
  desktop column running the full width).
- Multi-column desktop grids reflow *sanely*. **Rails that vanish below a breakpoint
  need a mobile fallback** (footer carousel / inline section), not nothing — losing
  related-content / sibling rails kills cross-content discovery on phones.
- Responsive `srcset` / `sizes`; no oversized desktop images shipped to phones.
- Pull quotes / callouts stay **visually distinct** on mobile (don't lose their frame
  below a breakpoint and read as body text).
- Determinate reading-progress cue where the template has one.

Cite: Baymard *Line Length*, web.dev responsive images.

## §4 — Forms & input

- Inputs **≥ 16px** font so iOS doesn't zoom-on-focus — and **do not disable user
  scaling** to "fix" it (`maximum-scale=1` / `user-scalable=no` is an a11y violation).
- Correct **`type` / `inputmode` / `autocomplete` / `autocapitalize`** per field so the
  right keyboard and autofill fire (email → email keyboard, numeric → `inputmode`,
  one-time-code → `autocomplete="one-time-code"`, etc.).
- `type=submit` buttons (Enter submits; mobile keyboards show the right action key).
- Verify zoom-on-focus and keyboard type by **actually focusing the field** on device.

Cite: Baymard *Touch Keyboard Types*, WCAG 2.2 **1.4.10** (reflow), **1.4.4** (resize).

## §5 — Device fit

- `viewport-fit=cover` declared in the viewport meta.
- Every fixed/sticky **top and bottom bar** pads with `env(safe-area-inset-*)` so
  nothing sits under the notch / Dynamic Island / home indicator. A common foundational
  gap is **zero `env(safe-area-inset-*)` and no `viewport-fit=cover` anywhere** — that's
  a root cause, not a per-component bug.
- Test a notched device profile in **both orientations**; landscape exposes side insets.

Cite: web.dev / MDN safe-area-inset + `viewport-fit`.

## §6 — Gestures & motion

- Native momentum scroll (no scroll-jacking); `overscroll-behavior: contain` on
  modals / sheets / drawers so scrolling one doesn't scroll the page behind it.
- Custom swipes don't fight the edge-back gesture; pull-to-refresh on feeds doesn't
  double-fire the browser's own.
- **Sharing uses `navigator.share()`** (feature-detected, canonical URL) — not a row of
  network icons ported from desktop.
- **Bottom sheets** (drag handle + scrim, non-destructive backdrop) instead of
  center modals ported from desktop.
- `prefers-reduced-motion` honored on every transition/animation.

Cite: web.dev *Web Share API*, Smashing mobile-interaction patterns, WCAG **2.3.3**.

## §7 — Performance (mobile CWV)

- p75 budgets on **throttled mobile**: **LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1.**
- Flag render-blocking JS/CSS, unsized media (CLS), long main-thread tasks (INP),
  un-prioritized LCP image, and full desktop JS/ad payload shipped to phones.
- Run Lighthouse **mobile** on the heavy templates (home, a detail page, a list page,
  search). A Vercel/preview deploy gives a closer-to-field profile than localhost.

Cite: web.dev *Top CWV* (verify the current metric set — CWV is LCP, INP, CLS; INP
replaced FID — refresh if web access is available).

## §8 — Media playback *(only if the app plays audio/video)*

This is the deepest dive for any media product — where mobile-optimized is most often
lost. Skip the section entirely if there's no playback.

- **Persistence:** a single player mounted above the router so it survives navigation
  with no gap/restart.
- **Media Session API** — lock-screen / notification **metadata + ≥512px artwork +
  transport handlers** (`play`/`pause`/`seek*`/`next`/`prev`/`stop`), and
  **`setPositionState`** for a live lock-screen scrubber. *Verify on a real iPhone
  (Safari) and Android (Chrome) — desktop DevTools doesn't prove lock-screen behavior.*
- **Background playback survives screen-lock** — no self-inflicted `visibilitychange`
  pause; test in a Safari tab *and* installed-PWA mode if a manifest ships.
- **Bottom bar in the thumb zone**, `safe-area-inset`-padded, with content padded so the
  bar never occludes the last item. **Scrubber hit area ≥ 44px tall** (a `h-1`/4px slider
  is near-impossible to grab one-thumbed mid-playback).
- **Controls:** skip ±15/30s, playback speed (persisted), sleep timer, resume position
  per item, auto-advance / queue through a series, optional transcript-sync.
- Full a11y on the controls (roles, `aria-valuetext`, keyboard).

Cite: web.dev / MDN *Media Session API*, WCAG **1.4.2** (audio control).

## §9 — Native parity / PWA *(opt-in — only when native-app parity is a goal)*

Run this when the product has (or is considering retiring) native mobile apps, or
wants installable-PWA parity. The framing: *does this gap give a user a reason to keep
reaching for the native app instead of the web?* Score against what native gives today:

- **Home-screen presence & installability** — valid manifest, `display: standalone`,
  icons + splash, an app shell that paints to the edges (`viewport-fit=cover` +
  safe-area), no "it's just a browser tab" tell.
- **Offline** — previously-read content and last-played media available offline, with a
  real custom offline page (not the browser error).
- **Background / lock-screen audio** *(if a media product)* — usually the single biggest
  native advantage; everything in §8 must be airtight on real iOS *and* Android.
- **Push / re-engagement** — if native drives reminders/alerts, can web push (or an
  honest alternative) match it, and where does iOS limit it?
- **Native-feeling interaction** — gestures, transitions, bottom sheets, instant tap
  feedback, no scroll-jank: the "is this an app or a website?" feel test.

Deliverable add-on: a **native-parity scorecard** — capability × web status (Met /
Partial / Missing) × what it'd take to close — so the retire-vs-keep cost/benefit is
obvious to the owner. Call out explicitly any gap that is a **legitimate reason to keep
a native app alive** — those are the P0s that gate the retirement decision.

Cite: web.dev *PWA Checklist*, *Media Session API*, the platform push docs (note iOS
web-push limits — verify current state).

## The "shrunken desktop" tell-test (score each surface)

Run this quick scorecard per surface; a row of "no"s is the proof the site is reflowed,
not designed, for mobile:

- Primary actions **bottom-anchored** (thumb zone), not top-pinned?
- Targets **truly ≥ 44px** (measured, padding included)?
- Nav **restructured** for mobile, not a crammed desktop mega-menu?
- **Tap, not hover** — nothing essential behind `:hover`?
- Breakpoints **mobile-*first*** (base styles are the mobile design), not
  `lg:`-designed-first with a default fallback?
- Rails/asides that drop at a breakpoint have a **mobile fallback**?
- Inputs **mobile-tuned** (16px, right keyboard, autofill)?
- **Device-fit** handled (`viewport-fit=cover` + safe-area)?

## External sources to cite (refresh if web access is available)

Map a finding to the rubric it satisfies and cite it. Don't parrot from memory if you
can verify the current guidance.

- **Touch & targets** — NN/g *Touch Targets*; Material 3 target sizing; WCAG 2.2
  **2.5.8** (min) / **2.5.5** (enhanced).
- **Typography & input** — Baymard *Touch Keyboard Types*, *Line Length*.
- **Navigation** — Smashing *Thumb Zone*, *Sticky Menus UX*, *Golden Rules of Mobile
  Navigation*.
- **Performance** — web.dev *Top CWV* (LCP/INP/CLS; INP replaced FID).
- **PWA / sharing / media** — web.dev *PWA Checklist*, *Web Share API*, *Media Session
  API* (+ MDN).
- **Audio control / motion** — WCAG 2.2 **1.4.2** (audio control), **2.3.3** (animation
  from interactions).
- **Holistic framing** — Heurilens *Mobile UX Audit Checklist* (the one-thumb /
  slow-network / distracted litmus).
