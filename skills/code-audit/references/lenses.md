# Code Audit — Lens Detail, Trace Method & Verification Recipe

This file is the audit's spine: the detailed smell catalog per lens, how to ground
findings in a real path, and how to refute a finding before it ships. SKILL.md owns
the dispatch and the deliverable; this owns the depth.

**Inherited stance (from SKILL.md — apply, don't restate):** functionality is sacred
(no finding/fix changes observable behavior); evidence or it didn't happen (`file:line`
+ a concrete target shape, never "clean this up"); decide a finding is real before
reporting it; defect vs. taste; the project's own doctrine wins on project specifics,
this file wins on method. Judge code against its **stated design intent** and flag
code↔doc drift both ways.

---

## Lens: `naming` — does the name tell the truth?

A name is a contract. The defect is a name that **misdescribes what the thing does or
returns**, forcing every reader to open the body to learn what the signature lied
about. Hunt for:

- **Verb ≠ effect.** `discover()` / `get…()` / `parse…()` that also *writes*,
  mutates, or performs I/O. A reader trusts a `get` not to have side effects.
- **Type ≠ shape.** A `…Stub` / `…Summary` / `…Ref` that's actually a full object; a
  `Candidate` that's really a finished placement; a `list` that's a `Set`/`Map`; an
  `id` that's an object.
- **Plural/singular & collection lies.** `items` that holds one thing; `count` that's
  a boolean; `isX` that returns the value, not a boolean.
- **Stale domain words.** A name carrying a concept the code abandoned (v1 term on a
  v2 path), or two names for one concept (drift waiting to happen → also a `dry` hit).
- **Comments that misdescribe.** A comment that says *what* the next line obviously
  does (noise) — or worse, describes behavior the code no longer has (a trap).

**Recommended shape:** rename to the true effect/shape, or — if the name is right and
the behavior is wrong — flag the behavior. Prefer renaming the *symbol* over adding a
comment that apologizes for it. In `fix` mode, a rename updates **every** reference in
the same edit.

## Lens: `dry` — one source of truth per fact (highest priority)

The expensive defect is the same shape or logic existing **twice where the copies can
silently diverge** — a change lands in one, not the other, and the bug surfaces months
later. Hunt for:

- **Cross-layer / cross-seam twins.** The same constant, schema, regex, mapping, or
  algorithm reimplemented across a language/runtime seam (e.g. a `.mjs` helper and its
  `.ts` re-implementation), across features, or between a virtual/getter and the
  aggregation mapper that bypasses it. These are the highest-divergence-risk of all.
- **Copy-paste families.** N near-identical files (per-source scripts, per-type
  handlers) where the variation is a few literals. Assess the *set*: what's the shared
  skeleton vs. the genuinely per-instance config?
- **Parallel validation.** The same boundary validated by hand in one place and by a
  schema in another, or two schemas for one shape.
- **Re-derived values.** The same computation inlined in several call sites.

**For each `dry` finding, name two things:** (1) the **single source of truth** it
should collapse to (which module owns it), and (2) the **concrete divergence risk** —
what breaks when one copy changes and the other doesn't. A duplication with no
divergence risk (two unrelated functions that happen to look alike) is *taste*, not a
defect — say so. Don't DRY things that merely rhyme; coincidental similarity that
changes for different reasons should stay separate.

## Lens: `simplicity` — the simplest correct structure

Clarity and simplicity, the values that make code understandable on first read. Hunt
for:

- **Functions doing five things.** One function that fetches, transforms, validates,
  renders, and logs. Split along the seams; name each part by what it does.
- **Needless indirection / over-abstraction.** A wrapper that only forwards; a factory
  with one product; a config object passed through four layers untouched; an
  abstraction with a single caller. Inline it.
- **Collapsible control flow.** Nested conditionals that flatten to a guard clause or
  early return; a boolean built across ten lines that's one expression; a `switch`
  that's a lookup table.
- **Dead / zombie code.** Unreachable branches, unused exports, code wired to a path
  that no longer runs (e.g. v1 left live after a v2 cutover), commented-out blocks.
  Confirm it's truly dead (grep the references) before flagging.
- **Comments that explain *what* not *why*.** Delete the noise; **propose the missing
  *why*** where a non-obvious decision (a WAF workaround, a heuristic threshold, a sync
  contract for a cache) is undocumented.

**Recommended shape:** the collapsed/extracted/deleted form, concretely. Simplicity is
*correct* simplicity — never collapse two cases that only look alike, and never delete
code you haven't proven dead.

## Lens: `structure` — logic at the right altitude

Architecture and boundaries: is each piece of logic where it belongs, and do modules
respect the seams the project depends on? Hunt for:

- **Wrong altitude.** Business logic in a route/controller that should be in a feature;
  a pure helper reaching for `server-only` state; request-runtime work in a build
  script (or vice versa); a "thin" layer that's actually fat.
- **Boundary straddles.** A module that mixes runtime concerns the project keeps apart
  (Node-only ORM imported into edge/client; secrets module without `server-only`); a
  helper that both computes and persists.
- **Coupling / cadence.** Cheap deterministic work fused to expensive work
  (LLM/render/network) so they can't change independently; two things that change at
  different rates bolted into one unit; a module that must be edited in lockstep with
  another.
- **Type-safety / validation gaps.** Untyped boundaries (`.mjs` / `any` / hand-casts)
  where a wrong shape passes the typechecker silently; missing validation at a trust
  boundary (external/AI/script output without a schema); provenance/operational fields
  that can leak past a view-model allowlist.

**Recommended shape:** name where the logic should live and the seam it should sit
behind. Respect the project's invariants — never recommend moving logic across a
boundary the doctrine forbids.

---

## Grounding: trace one real path end-to-end

Architecture claims float unless tied to a real path. Before writing the synthesis,
pick **one representative entity** (one request, one record, one job) and follow it
through the target end-to-end — entry → each transform → exit. This surfaces the
coupling, the wrong-altitude logic, and the dead branches that a file-by-file read
misses, and it gives the synthesis a concrete spine. For a large surface, trace two
paths that exercise different branches.

## Verification: refute every finding before it ships

A plausible-but-wrong finding wastes the maintainer's trust. Every candidate finding
faces a skeptic — a separate agent in a workflow, or a deliberate self-pass in one
context — prompted to **refute it**, defaulting to "not a real finding" when unsure:

- **`dry`:** are the copies *actually* the same, and do they change for the *same*
  reason? Or do they merely rhyme? Would collapsing them couple two things that should
  move independently?
- **`naming`:** does the proposed name fit *every* call site, or just the one I read?
  Is the current name a domain term of art I'm misreading?
- **`simplicity`:** would the collapse/deletion change behavior in any edge case —
  null/undefined/empty, NaN/±0, error type & message, ordering/stability, short-circuit
  vs. eager eval, locale/timezone/encoding? Is the "dead" code reached by reflection, a
  string key, a config path, a test, a **public/barrel export** (consumed out-of-repo),
  a dynamic/lazy import or plugin registry, codegen/macros, a CLI/bin entrypoint, a
  framework convention (file-routing, decorators, DI auto-wiring, lifecycle hooks), or a
  feature-flag/env-gated path? **Grep-clean ≠ dead** when any of these apply.
- **`structure`:** does the move respect the project's stated boundaries? Am I fighting
  an invariant the doctrine set on purpose?

Findings that survive refutation ship; the rest are dropped or downgraded to *taste*.
This is what separates a rigorous audit from a thorough-looking one.

## Orchestration shape (when spawning subagents)

A pipeline that verifies each finding as soon as its lens completes (no global barrier):

1. **Find** — one agent per lens (× file-group for large surfaces), each returning
   structured candidate findings with `file:line`.
2. **Verify** — for each candidate, an independent skeptic returns a keep/drop verdict
   with a one-line reason (the refutation prompts above).
3. **Synthesize** — dedupe survivors across lenses, rank by severity/impact, write the
   verdict + grouped findings + architecture synthesis. In `fix` mode, the synthesis
   feeds the edit plan; apply, then run the behavior-preservation gate from SKILL.md.

Scale the finder/verifier fan-out to the surface size. A single small module may not
need orchestration at all — the sequential self-refutation pass meets the same bar.
