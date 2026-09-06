# Global instructions

## How to talk to me
- Plain words. Write as if to a smart friend who doesn't work in this codebase.
  Code names, paths, and commands stay exact; the prose around them is everyday
  English. A technical term gets its meaning in the same sentence, or gets
  replaced. Call actions by their ordinary names — "commit and push", not a
  coined phrase. Plain is not elementary: keep the substance, drop the vocabulary.
- Answer first, then stop. A routine result is 2–5 lines, no headers, no bullet
  lists. Don't restate my ask, narrate steps, or list files touched. Longer only
  when I need more to act — and then always the exact command, path, or code,
  never a step dropped to look short.
- Say what you ran and what it showed. If you didn't run it, say that.
- If you spot a structural problem: one plain sentence and a recommendation,
  in-line. Never a section.
- Test: can I act from this alone, without decoding anything?

## Subagent model economy (all projects)
- Don't let subagents inherit the main-loop model by default — pick the cheapest tier that fits the subtask:
  - **haiku**: search/exploration fan-outs, file/log sifting, mechanical transforms, doc lookups.
  - **sonnet**: routine implementation, first-pass reviews, well-specified refactors.
  - **Main-loop tier (opus/fable)**: only when the subtask is genuinely design, architecture, or hard debugging — or when I explicitly ask.
- Same rule in Workflows: set `model` per `agent()` stage, and `effort: 'low'` for mechanical stages.
- If a cheap subagent's output is visibly weak, escalate that one call a tier and say so — don't silently run everything top-tier.

## Dev server ports (all projects)
- **Even ports = mine (human); odd ports = the agent's.** Never take my port or kill my server.
- Each project has a unique **even base** port spaced by 10: `3010`, `3020`, `3030`, … so I can run several projects at once. Human runs on `base`, agent on `base + 1`.
- The base is declared per-project in `package.json` `config.devPortBase`; `pnpm dev` (human) and `pnpm dev:agent` (agent) derive their ports from it. The agent server is free to run anytime — even while my server runs — because it uses a separate build dir. Full setup + rationale: each repo's `docs/dev-ports.md`.
- So: spin up your own `dev:agent` server (`base + 1`) whenever you need to see/screenshot something; don't fetch-only and don't wait for me to free a port.
