# agent-config

My portable, version-controlled agent assets — currently **skills** shared across
**Claude Code** and **Codex**. This repo is the single source of truth; the tools
read the skills through **symlinks** that point back here.

**Mental model:** the real files live in `skills/` in this repo. `install.sh`
creates symlinks at `~/.claude/skills/<name>` and `~/.codex/skills/<name>` that
point at them. So editing a file in this repo *is* editing the live skill — there
is no copy step, no "sync." To save changes you just `git commit && git push`.

**Secrets never live here.** No `settings.json`, no `auth.json`, no API tokens.
Only skills and (later) non-secret instruction files.

---

## What's in here

```
skills/
  decide/SKILL.md        # one folder per skill; SKILL.md is the skill
install.sh               # idempotent symlinker (Claude + Codex)
README.md                # this file
```

The `SKILL.md` format (YAML frontmatter `name` + `description`, then a markdown
body) is **identical for Claude Code and Codex**, so one folder serves both tools.

---

## First-time setup on a new laptop

Do these in order. Steps 1–2 are one-time prerequisites; 3–5 are the actual install.

### 1. Install the tools and run each once

The installer only links into a tool that already exists on disk, so the tools
must be installed and launched once (which creates `~/.claude` and `~/.codex`).

- **Claude Code** — install per Anthropic's docs, then run `claude` once.
- **Codex** — install per OpenAI's docs, then run `codex` once.

Confirm both config dirs exist:

```bash
ls -d ~/.claude ~/.codex
```

(If you only use one tool, that's fine — the installer just skips the missing one.)

### 2. Make sure `git` is available

```bash
git --version    # any recent version is fine
```

### 3. Clone this repo

The canonical location is `~/Projects/agent-config`, but the installer
self-locates, so any path works.

```bash
mkdir -p ~/Projects
git clone <your-repo-url> ~/Projects/agent-config
cd ~/Projects/agent-config
```

> Don't have the GitHub URL handy? See **Back up to GitHub** below — the repo may
> not be pushed yet on a brand-new setup.

### 4. Run the installer

```bash
./install.sh --dry-run    # optional: preview every action, changes nothing
./install.sh              # actually create the symlinks
```

Expected output is one line per skill per tool, e.g. `link: …/decide` or
`ok (already linked): …/decide`.

### 5. Verify

```bash
# The symlinks exist and point back into this repo:
ls -la ~/.claude/skills/decide ~/.codex/skills/decide

# The skill is readable through the link:
head -2 ~/.claude/skills/decide/SKILL.md   # -> "--- / name: decide"
```

Then **start a new Claude (or Codex) session** and confirm `/decide` is listed.
Skills are loaded at session start, so a session that was already open won't see
newly linked skills until you restart it.

---

## What `install.sh` does (so future-you can trust it)

For every folder in `skills/`, and for each of Claude / Codex that is installed:

1. If `~/.<tool>/skills/<name>` **doesn't exist** → create a symlink to this repo.
2. If it's **already the right symlink** → leave it (prints `ok`).
3. If it's a **different symlink** → repoint it here.
4. If it's a **real folder** (would be clobbered) → move it to
   `<name>.bak.<timestamp>` first, then symlink.

It never deletes a real directory and never touches secrets or settings. Re-running
it is always safe.

---

## Everyday use

### Edit an existing skill

Just edit the file in this repo (or via the symlink — same file), then:

```bash
cd ~/Projects/agent-config
git add -A && git commit -m "tweak decide skill" && git push
```

No re-install needed — the symlink already points here. Restart your session to
pick up the new wording.

### Add a new skill

```bash
cd ~/Projects/agent-config
mkdir -p skills/<name>
$EDITOR skills/<name>/SKILL.md      # frontmatter: name + description, then body
./install.sh                        # links the new skill into both tools
git add -A && git commit -m "add <name> skill" && git push
```

### Sync a second machine (or after pulling changes)

```bash
cd ~/Projects/agent-config
git pull
./install.sh        # links any newly added skills; existing ones already linked
```

---

## Back up to GitHub (one time)

This is your disaster recovery. With the GitHub CLI:

```bash
cd ~/Projects/agent-config
gh repo create agent-config --private --source=. --remote=origin --push
```

Or manually:

```bash
cd ~/Projects/agent-config
git remote add origin git@github.com:<you>/agent-config.git
git push -u origin main      # use 'master' if that's your default branch name
```

After that, the new-laptop story is just: install the tools → `git clone` →
`./install.sh`.

---

## Troubleshooting

- **`/decide` doesn't appear** → you're in a session that started before the link.
  Start a new session (skills load at startup).
- **Broken/red symlink** → the repo moved or isn't cloned where the link points.
  Re-run `./install.sh` from the repo's current location to repoint it.
- **Check where a link actually points** → `readlink ~/.claude/skills/decide`.
- **`base not found — skipping`** → that tool's `~/.claude` or `~/.codex` doesn't
  exist yet. Install/run the tool (step 1), then re-run `./install.sh`.
- **Accidentally backed up a real dir** → look for `*.bak.<timestamp>` next to the
  symlink; that's your previous content.

## Uninstall

```bash
rm ~/.claude/skills/decide ~/.codex/skills/decide   # removes only the symlinks
```

This deletes the links, not the source (which stays safe in this repo).

---

## Conventions / guardrails

- **No secrets, ever.** Tokens and `auth.json`/`settings.json` stay local and out
  of git.
- **User-global skills only.** Project-specific skills (e.g. a project's own
  `ship` / `verify-artist`) belong in that project's repo under `.claude/`, not
  here.
- **One format, two tools.** Don't fork a skill per tool — the same `SKILL.md`
  works for Claude Code and Codex.
