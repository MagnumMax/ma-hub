#!/usr/bin/env bash
set -euo pipefail

# Compare local Cursor MA cache with ma-hub (source of truth).
# Exit 1 if drift detected — use before commit / after local-only edits.
# Portable: works on macOS Bash 3.2 (no associative arrays).

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

drift=0

echo "Hub (truth): ${HUB}"
echo

echo "== commands =="
shopt -s nullglob
hub_cmds=("${HUB}/commands"/MA-*.md)
local_cmds=("${HOME}/.cursor/commands"/MA-*.md)

for hub_f in "${hub_cmds[@]}"; do
  base="$(basename "$hub_f")"
  local_f="${HOME}/.cursor/commands/${base}"
  if [[ ! -f "$local_f" ]]; then
    echo "MISSING locally: ${base} (run ma-hub-install-commands)"
    drift=1
    continue
  fi
  if ! cmp -s "$hub_f" "$local_f"; then
    echo "DRIFT: ${base}"
    echo "  hub:   ${hub_f}"
    echo "  local: ${local_f}"
    if [[ "$local_f" -nt "$hub_f" ]]; then
      echo "  → local is NEWER — copy into hub, then commit (do NOT leave only in ~/.cursor)"
    else
      echo "  → hub is newer — run: ${HUB}/bootstrap/install-commands.sh"
    fi
    drift=1
  else
    echo "ok  ${base}"
  fi
done

for local_f in "${local_cmds[@]}"; do
  base="$(basename "$local_f")"
  hub_f="${HUB}/commands/${base}"
  if [[ ! -f "$hub_f" ]]; then
    echo "LOCAL-ONLY: ${base} — not in hub; move to ${HUB}/commands/ and commit"
    drift=1
  fi
done

echo
echo "== skills (MA-owned) =="
if [[ -d "${HUB}/skills" ]]; then
  skill_dirs=("${HUB}/skills"/*/)
  for dir in "${skill_dirs[@]}"; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    [[ -f "${dir}/SKILL.md" ]] || continue
    local_skill="${HOME}/.cursor/skills/${name}"
    if [[ ! -d "$local_skill" ]]; then
      echo "MISSING locally: skill ${name} (run ma-hub-install-skills)"
      drift=1
      continue
    fi
    if ! diff -rq "$dir" "$local_skill" >/dev/null 2>&1; then
      echo "DRIFT: skill ${name}"
      if [[ "${local_skill}/SKILL.md" -nt "${dir}/SKILL.md" ]]; then
        echo "  → local is NEWER — copy into ${HUB}/skills/${name}/ and commit"
      else
        echo "  → hub is newer — run: ${HUB}/bootstrap/install-skills.sh"
      fi
      drift=1
    else
      echo "ok  skill ${name}"
    fi
  done
else
  echo "(no skills/ in hub)"
fi

echo
if [[ "$drift" -ne 0 ]]; then
  echo "FAIL: local cache ≠ hub. Fix, then commit+push ma-hub if you changed truth."
  exit 1
fi

echo "OK: no drift between hub and local MA cache"
