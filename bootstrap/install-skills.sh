#!/usr/bin/env bash
set -euo pipefail

# Install / refresh Monster Automation–owned skills from this hub.
# Does NOT install third-party skills (Aaron, Vercel, etc.) — those stay on weekly scripts.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

SKILLS_SRC="${HUB}/skills"
if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "OK: no skills/ in hub — skip"
  exit 0
fi

CURSOR_SKILLS="${HOME}/.cursor/skills"
AGENTS_SKILLS="${HOME}/.agents/skills"
CLAUDE_SKILLS="${HOME}/.claude/skills"
mkdir -p "$CURSOR_SKILLS" "$AGENTS_SKILLS" "$CLAUDE_SKILLS"

shopt -s nullglob
skill_dirs=("${SKILLS_SRC}"/*/)
if [[ ${#skill_dirs[@]} -eq 0 ]]; then
  echo "OK: skills/ is empty — skip"
  exit 0
fi

installed_names=()
for dir in "${skill_dirs[@]}"; do
  name="$(basename "$dir")"
  if [[ ! -f "${dir}/SKILL.md" ]]; then
    echo "WARN: skip ${name} (no SKILL.md)"
    continue
  fi

  dest="${CURSOR_SKILLS}/${name}"
  rm -rf "$dest"
  mkdir -p "$dest"
  # Copy tree (portable: no rsync required)
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${dir}/" "${dest}/"
  else
    cp -R "${dir}/." "${dest}/"
  fi

  ln -sfn "$dest" "${AGENTS_SKILLS}/${name}"
  ln -sfn "$dest" "${CLAUDE_SKILLS}/${name}"
  installed_names+=("$name")
  echo "installed skill ${name} → ${dest}"
done

# Remove known renamed/deleted MA orchestrators from local cache.
# Do NOT prune arbitrary ~/.cursor/skills entries — third-party packages (Aaron, etc.) live there too.
for obsolete in seo-audit; do
  found=0
  for name in "${installed_names[@]+"${installed_names[@]}"}"; do
    [[ "$name" == "$obsolete" ]] && found=1 && break
  done
  if [[ "$found" -eq 0 ]]; then
    if [[ -e "${CURSOR_SKILLS}/${obsolete}" || -L "${AGENTS_SKILLS}/${obsolete}" || -L "${CLAUDE_SKILLS}/${obsolete}" || -d "${AGENTS_SKILLS}/${obsolete}" || -d "${CLAUDE_SKILLS}/${obsolete}" ]]; then
      rm -rf "${CURSOR_SKILLS}/${obsolete}"
      rm -rf "${AGENTS_SKILLS}/${obsolete}"
      rm -rf "${CLAUDE_SKILLS}/${obsolete}"
      echo "removed obsolete skill ${obsolete}"
    fi
  fi
done

echo "OK: MA skills installed from ${SKILLS_SRC}"
