#!/usr/bin/env bash
#
# install.sh — symlink every skill in ./skills/ into Claude Code and Codex.
#
# Each skill is a directory (skills/<name>/SKILL.md). This script points
# ~/.claude/skills/<name> and ~/.codex/skills/<name> at the copy in THIS repo,
# so the repo is the single source of truth: edit a file here, the live skill
# changes; `git commit` captures it.
#
# Safe to run repeatedly (idempotent). If a real (non-symlink) skill dir is
# already in the way, it's moved aside to <name>.bak.<timestamp> before linking.
#
# Usage:
#   ./install.sh             install into whichever of Claude / Codex is present
#   ./install.sh --dry-run   print what WOULD happen; change nothing
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$REPO/skills"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

# Run a command, or just print it under --dry-run. Space-safe (no eval).
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'DRY-RUN:'; printf ' %q' "$@"; printf '\n'
  else
    "$@"
  fi
}

link_skill() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local cur; cur="$(readlink "$dest")"
    if [ "$cur" = "$src" ]; then
      echo "  ok (already linked): $dest"
    else
      echo "  relink (was -> $cur): $dest"
      run ln -sfn "$src" "$dest"
    fi
  elif [ -e "$dest" ]; then
    local bak="$dest.bak.$(date +%Y%m%d-%H%M%S)"
    echo "  backup real dir -> $bak, then link: $dest"
    run mv "$dest" "$bak"
    run ln -sfn "$src" "$dest"
  else
    echo "  link: $dest"
    run ln -sfn "$src" "$dest"
  fi
}

install_into() {
  local label="$1" base="$2" skills_dir="$3"
  if [ ! -d "$base" ]; then
    echo "$label: $base not found — skipping (install $label and run it once first)."
    return
  fi
  echo "$label -> $skills_dir"
  run mkdir -p "$skills_dir"
  local found=0
  for d in "$SKILLS_SRC"/*/; do
    [ -d "$d" ] || continue
    found=1
    link_skill "${d%/}" "$skills_dir/$(basename "$d")"
  done
  if [ "$found" -eq 0 ]; then
    echo "  (no skills found in $SKILLS_SRC)"
  fi
  return 0
}

echo "agent-config installer"
echo "repo: $REPO"
[ "$DRY_RUN" -eq 1 ] && echo "*** DRY RUN — no changes will be made ***"
echo

install_into "Claude Code" "$HOME/.claude" "$HOME/.claude/skills"
echo
install_into "Codex" "$HOME/.codex" "$HOME/.codex/skills"
echo
echo "Done. Start a NEW Claude/Codex session for newly linked skills to appear."
