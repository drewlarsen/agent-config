---
name: code-audit
description: Deep, evidence-grounded review of completed code **at rest** — one module or a whole surface — judged for simplicity, DRYness, clarity, naming, and structure. Two modes — `audit` (read-only findings, each with file:line + severity + a recommended shape) and `fix` (apply the behavior-preserving edits, then verify nothing broke). Focused lenses — naming, dry, simplicity, structure — or a full sweep across all four. Distinct from `/code-review` and `/simplify`, which only see the current git diff; this re-reads a finished module as a whole, at any git state. Use when asked to audit or review a module/file/directory, assess duplication & drift, sanity-check naming, simplify or clean up a finished file, remove dead code or needless indirection, or judge the architecture/boundaries of existing code.
version: 1.0.0
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write, Task
argument-hint: "[fix] [naming · dry · simplicity · structure] <module / file / dir / glob> — bare <target> = full read-only audit"
---

# Code Audit

A deep, evidence-grounded review of **completed code at rest** — judged against the
values that keep a codebase livable: **simple, DRY, understandable, well-named.**
This skill owns the *how* (method, evidence bar, lenses, the behavior-preservation
gate); the project's own docs own the *what* (its invariants, its design intent).

**The line that defines this skill: functionality is sacred.** No finding and no fix
may change observable behavior. The whole point is to make finished code clearer and
less duplicated *without* touching what it does.

**Why it exists / how it differs.** `/code-review` and `/simplify` operate on the
current **git diff** — changed lines only. `/code-audit` re-reads a *finished* module
as a whole, regardless of git state, and judges its form. It's the at-rest,
whole-module complement, not a duplicate. It is about **form** (clarity / DRY /
naming / structure), not runtime bug-hunting — for diff-level bug hunting use
`/code-review`.

## Dispatch

Parse the argument left-to-right: an optional leading **`fix`** keyword (mode; absent
= `audit`), then an optional **lens** keyword (absent = all four), then the rest is
the **target** (a module name, file, directory, glob, or free description). Resolve
the target to real files *before* judging — never audit a path you haven't opened.

```
/code-audit <target>                  full read-only audit, all lenses
/code-audit <lens> <target>           read-only audit, one lens
/code-audit fix <target>              audit, then apply behavior-preserving edits (all lenses)
/code-audit fix <lens> <target>       same, scoped to one lens
```

**Resolving collisions.** Decide keyword-vs-target by **existence**: if a token
resolves to a real file or directory, it's the target, not a mode/lens. A bare `fix`
or a bare lens keyword with **no** following target is an error — ask for the target;
never default to an empty target, and never silently apply edits. To audit a path
literally named `fix` / `naming` / `dry` / `structure` / `simplicity` (or an alias),
make it path-shaped: `./fix`, `src/dry.ts`.

| Lens | Aliases | What it hunts |
| --- | --- | --- |
| `naming` | `names`, `semantics` | Names that **misdescribe** what a module/function/variable/type does or returns — a `discover()` that also writes, a `…Stub` that's a full object, a `candidate` that's really a placement; plus stale/misleading comments. Naming is a first-class defect here, not polish. |
| `dry` | `duplication`, `drift`, `dup` | The same shape or logic existing **twice where the copies can silently diverge** — across files, layers, or a language seam. For each: name the single source of truth it *should* have and the concrete divergence risk. **Highest priority.** |
| `simplicity` | `simple`, `clarity`, `clutter`, `dead` | Needless indirection, over-abstraction, functions doing five things, collapsible control flow, **dead/zombie code**, and comments that explain *what* instead of *why* (or omit a load-bearing *why*). Prefer the simplest correct structure. |
| `structure` | `architecture`, `boundaries`, `arch`, `types` | Logic at the wrong altitude (fat route / thin feature, pure helper vs. server-only, script vs. request-runtime), modules straddling a boundary, coupling things that change at different rates, and **type-safety / validation gaps** at trust boundaries. |

<!-- This table is the canonical lens list. Keep the frontmatter `description` +
`argument-hint` and `agents/openai.yaml` in sync when changing it. Cap: 4 lenses.
Aliases live ONLY in this table — the description / argument-hint / openai.yaml carry
the 4 canonical lens names only. -->

## How to run — always (both modes)

1. **Map the surface, read the doctrine, then judge against it.** Resolve the target
   to real files. Read the project's standards first — `AGENTS.md` / `CLAUDE.md`
   (note architecture invariants, runtime boundaries, project stage, any
   server-ownership rule), then any design doc near the target (search, don't assume
   a path: `rg -li` on likely terms, `fd -e md`). Judge the code *against its own
   stated design intent* and flag **code↔doc drift both ways**. If there's no
   doctrine, say so and fall back to the universal values above.
2. **Read before judging; assess families as a set.** Read the whole target, plus
   enough of its callers/callees to **trace one real path end-to-end**. Where many
   files look copy-pasted, assess them *as a set* — how much is boilerplate vs.
   genuinely source-specific — not one by one.
3. **Evidence or it didn't happen.** Every finding carries a `file:line` citation and
   a **concrete recommended target shape** (the structure to move to, not "clean this
   up"). Decide a finding is real *before* reporting it. Separate **defect from
   taste**, and **must-fix** (drift/naming/structure that will cause silent
   divergence or real confusion) from **should-fix** (clarity/structure) from
   **taste** (optional). "This is right, and here's why" is a valid finding — don't
   invent problems to look thorough.
4. **Functionality is sacred.** Audit and recommend only changes that preserve
   observable behavior. Respect project invariants (runtime boundaries, `server-only`,
   shared-helper contracts) — never recommend a fix that breaks one.

See `references/lenses.md` for each lens's detailed smell catalog, the end-to-end
trace method, and the adversarial-verification recipe.

## Depth — go deep by default

This skill is **thorough by default**, not a quick skim.

- **When you can spawn parallel subagents (in Claude Code, the Task tool):** drive a
  fan-out. (a) One **finder per lens** (split large surfaces into file-groups) reads
  in parallel and returns structured candidate findings. (b) **Adversarially verify
  every candidate** — an independent skeptic prompted to *refute* each one (is the
  duplication real and divergent? does the rename actually fit? would the
  simplification change behavior?); drop findings that don't survive. (c)
  **Synthesize** a deduped, severity-ranked review, and **trace at least one entity
  end-to-end** to ground the architecture claims. Scale finder/verifier count to the
  size of the surface.
- **When orchestration isn't available (e.g. Codex):** do the equivalent in one
  context — lens by lens, then a deliberate **self-refutation pass** that tries to
  kill each finding before it ships. Same bar, sequential.

## Audit mode (default) — the deliverable

A single structured review:

1. **Verdict + the 3–5 highest-leverage findings**, one line each, ranked by impact.
2. **Findings, grouped by lens.** Each: `file:line` · **severity** (must-fix /
   should-fix / taste) · what's wrong · *why it matters here* · the recommended
   target shape.
3. **Architecture synthesis** — the *disease* behind the symptoms (is the duplication
   a missing source of truth? is logic at the wrong altitude?), the single source of
   truth each fact should have, and a **prioritized, sequenced cleanup plan.**

Stay read-only: no edits in audit mode. If the user wants the fixes applied, that's
`fix` mode (or re-invoke with `fix`). Read-only here is enforced by **instruction, not
`allowed-tools`** (fix mode shares this skill's tool grant) — so self-police: don't
call Edit/Write or mutating Bash (`sed -i`, redirects) unless `fix` mode was
explicitly selected.

## Fix mode — apply, with a behavior-preservation gate

1. **Audit first** (the pass above) so you know each target shape before touching
   anything.
2. **Apply only behavior-preserving changes** — renames, de-duplication into a single
   source of truth, extracting/collapsing, deleting dead code, fixing misleading
   comments. **Never** alter logic, outputs, or any contract visible to a caller. A
   rename or a DRY consolidation must **update every reference in the same edit** — a
   half-applied rename is worse than none. Before a rename/consolidation, enumerate the
   **non-lexical** references grep misses — string-keyed access, reflection, serialized
   field names (JSON/DB/API), config keys, templates/JSX, DI tokens, and `.mjs`↔`.ts`
   language-seam twins. A **published/exported** symbol (package entrypoint, barrel
   re-export, documented API) is an external contract no in-repo gate can see —
   renaming it is *not* behavior-preserving, so leave it a recommendation (or add a
   deprecation alias). If references can't be found exhaustively, recommend the change
   — don't half-apply it.
3. **Sequence safely:** smallest independent edits, one concern at a time; **snapshot
   the files you're about to touch** so a failed gate has a defined restore point. Treat
   a DRY consolidation as one atomic multi-file unit — verify and revert it as a whole.
4. **Verify nothing broke — a hard gate.** First **record the baseline** — run the
   project's typecheck / build / tests (`package.json` scripts, `Makefile`, etc.)
   *before* editing and note each command's pass/fail, so a pre-existing failure isn't
   blamed on your edit (treat a flaky / timeout / skipped suite as *no coverage*, not a
   pass). Re-run the gate after each smallest edit; anything green at baseline must stay
   green — if an edit breaks it, **revert that edit** to its snapshot. State exactly
   what you ran and the before→after result. If there is **no** test/typecheck to lean
   on, say so plainly and restrict yourself to the **provably mechanical** (pure
   renames, dead-code deletion); downgrade riskier simplifications to recommendations
   rather than applying them blind.
5. **Report** what changed (`file:line`, before→after intent) and what you
   deliberately left as a recommendation (too risky to auto-apply without behavior
   coverage). Don't commit unless asked.

## Non-goals

- **Stay in the target's lane.** Note cross-cutting issues you pass through; don't
  expand scope into unrelated subsystems.
- **Not a bug hunter.** Runtime-correctness bugs are `/code-review`'s job; diff-level
  cleanups are `/simplify`'s. This is the at-rest, whole-module form audit.
