# agent-config

My portable agent skills, version-controlled and **symlinked** into Claude Code +
Codex. The real files live in `skills/` here; the tools read them through symlinks,
so editing a file in this repo *is* editing the live skill — just `git commit`.
**No secrets ever live here.**

---

## Skills catalog

### Mine — in this repo (installed by `./install.sh`)

| Skill | What it does | Invoke |
| --- | --- | --- |
| `decide` | Decision brief from the owner's POV — Context · Issue · Options · one recommendation, in stakes not jargon | `/decide` |

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

That symlinks every skill in `skills/` into `~/.claude/skills` and `~/.codex/skills`.
Idempotent — safe to re-run. Add `--dry-run` to preview. **Restart your Claude/Codex
session** for newly linked skills to appear.

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

---

## Guardrails

- **No secrets**, ever (tokens / `auth.json` / `settings.json` stay local).
- **User-global skills only.** Project-specific skills live in that project's
  `.claude/`, not here.
- **One `SKILL.md` format** serves both Claude Code and Codex — never fork per tool.
