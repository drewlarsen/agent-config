# agent-config

My portable agent skills **and global instructions**, version-controlled and
**symlinked** into Claude Code + Codex. The real files live in `skills/` and
`instructions/` here; the tools read them through symlinks, so editing a file in
this repo *is* editing the live skill or instruction — just `git commit`.
**No secrets ever live here.**

---

## Global instructions

The always-on rules each tool loads at the start of every session — how to talk
to me, plus tool-specific standing rules.

| File | Linked to | Holds |
| --- | --- | --- |
| `instructions/claude-global.md` | `~/.claude/CLAUDE.md` | How to talk to me · subagent model economy · dev-server ports |
| `instructions/codex-global.md` | `~/.codex/AGENTS.md` | How to talk to me · Karpathy coding guidelines |

**"How to talk to me" is deliberately identical in both files.** It's the one
thing that must not differ per tool — edit it in one, paste it to the other, in
the same commit. Everything below that block is tool-specific and free to differ.

Changes take effect in the **next** session, not the running one.

---

## Skills catalog

### Mine — in this repo (installed by `./install.sh`)

| Skill | What it does | Invoke |
| --- | --- | --- |
| `code-audit` | Deep review of **finished code at rest** — judged for simplicity, DRYness, clarity, naming. `audit` (read-only findings) or `fix` (behavior-preserving edits); one lens (`naming`·`dry`·`simplicity`·`structure`) or all four. The whole-module complement to diff-based `/code-review` & `/simplify` | `/code-audit [fix] [lens] <target>` |
| `decide` | Decision brief from the owner's POV — Context · Issue · Options · one recommendation, in stakes not jargon | `/decide` |
| `mobile-ui-audit` | Evidence-grounded **mobile UX** audit — drives the site at real phone viewports to prove mobile-*designed* vs. shrunken-desktop. One focused check (`touch`·`nav`·`reading`·`forms`·`device-fit`·`gestures`·`perf`·`media`·`pwa`) or a full Red/Yellow/Green audit; every finding cites `file:line` + a screenshot/measured value | `/mobile-ui-audit [target]` |
| `relish-open-play` | Finds back-to-back 2-hour Open Play Advanced blocks at Relish (CourtReserve), fits them around my Google Calendar (reminders and Shayna's events don't count), recommends 2–3, then on request puts them in my cart (I pay with the punch pass myself) and adds a `drew @ relish yellow` Peacock event. Runs in Claude in Chrome | `/relish-open-play [week / level / block]` |
| `seo-audit` | Read-only SEO + AI-search audit. One focused check (`sitemap`, `og`, `schema`, `headers`, `hreflang`, `cwv`, …) or a full launch audit; defers to the project's own SEO docs, and carries the shared SEO doctrine (`references/seo-doctrine.md`) for projects without one | `/seo-audit [target]` |

### Mine — integration playbooks (load automatically by topic)

Lessons and proven designs from integrations that recur across my projects, so
the next project starts from what already works. Not code libraries: each points
at the working reference implementation. Shared *code* gets extracted into a
package only once a second project really uses it.

| Skill | Covers | Reference implementation |
| --- | --- | --- |
| `pinterest-integration` | API v5, token renewal (one refresher only), sandbox vs production boards, daily auto-pinning, catalogs, weekly analytics | shayna-art |
| `etsy-integration` | Open API v3, OAuth + PKCE, the shared-secret header, sale recording, webhooks, selling one-of-a-kind work across channels | shayna-art |
| `slack-reports` | The house message style and posting mechanics for job reports, failures, sales and weekly summaries | bo-co-art |
| `resend-email` | Key scopes, the From line, sending-domain DNS, confirmed opt-in, newsletters, debugging a 401 | bo-co-art |
| `vercel-ops` | Firewall and bot gotchas, crawler cost, sharp in production, previews, env vars, caching | bo-co-art |

### Drew's toolbox — external (each managed by its own installer, **not** vendored here)

| Skill(s) | Source | Install / update command |
| --- | --- | --- |
| `impeccable` | impeccable.style (npx) | `npx -y impeccable@latest install --scope=global --providers=claude,codex --yes --no-hooks` |
| `vercel-*`, `deploy-to-vercel`, `web-design-guidelines` | `vercel-labs/agent-skills` (via the `skills` CLI) | `npx skills add vercel-labs/agent-skills` |

> Future third-party skills go in this table with their install command — don't copy
> their files into this repo. They self-update; vendoring them just freezes a stale
> copy. (`npx skills list` shows what the `skills` CLI manages; `npx impeccable check`
> checks impeccable.)

---

## Install my skills (this repo)

```bash
git clone <your-repo-url> ~/Projects/agent-config
cd ~/Projects/agent-config
./install.sh
```

That symlinks every skill in `skills/` into `~/.claude/skills` and `~/.codex/skills`,
and links the two files in `instructions/` to `~/.claude/CLAUDE.md` and
`~/.codex/AGENTS.md`. Idempotent — safe to re-run. Add `--dry-run` to preview.
Anything real already sitting at one of those paths is moved to `<name>.bak.<timestamp>`
first, never overwritten. **Restart your Claude/Codex session** for the changes to
take effect.

---

## Add or edit a skill

- **Edit:** change the file in `skills/<name>/` (the symlink already points here) →
  `git commit && git push`. Restart your session to pick up the new wording.
- **Add:** `mkdir -p skills/<name>`, write `skills/<name>/SKILL.md` (frontmatter
  `name` + `description`, then the body), run `./install.sh`, then commit & push.

---

## Back up to GitHub (one time — this is your disaster recovery)

```bash
gh repo create agent-config --private --source=. --remote=origin --push
```

New laptop after that: `git clone` → `./install.sh`, then reinstall the toolbox
skills from the table above.

---

## Troubleshooting

- **`/decide` not showing** → you're in a session that started before the link.
  Start a new one (skills load at startup).
- **Broken symlink** → the repo moved; re-run `./install.sh` to repoint it.
- **Where does a link point?** → `readlink ~/.claude/skills/decide`.

## Uninstall

```bash
rm ~/.claude/skills/decide ~/.codex/skills/decide   # removes only the symlinks
```

Same for the instruction files — `rm ~/.claude/CLAUDE.md` removes the link, not
the content (which stays in `instructions/`). Copy the file back out of the repo
first if you want to keep using it unlinked.

---

## Guardrails

- **No secrets**, ever (tokens / `auth.json` / `settings.json` stay local).
- **User-global skills only.** Project-specific skills live in that project's
  `.claude/`, not here.
- **One `SKILL.md` format** serves both Claude Code and Codex — never fork per tool.
