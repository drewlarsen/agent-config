# agent-config

Durable, cross-tool agent assets (Claude Code + Codex), version-controlled here and
**symlinked** into place. Editing a file under `skills/` *is* editing the live skill.

## Layout

```
skills/<name>/SKILL.md   # hand-authored skills (same format for Claude & Codex)
```

## Install (per machine)

Symlink a skill into the tools that should see it:

```bash
ln -sfn "$PWD/skills/decide" ~/.claude/skills/decide   # Claude Code
ln -sfn "$PWD/skills/decide" ~/.codex/skills/decide    # Codex (same SKILL.md format)
```

A proper idempotent `install.sh` comes once the mechanics are proven.

## Notes

- Secrets never live here (no `settings.json` / `auth.json` / tokens).
- Project-scoped skills stay in their project repos; only user-global skills live here.
