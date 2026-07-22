#!/usr/bin/env bash
set -euo pipefail

# Install / refresh third-party skills from registry/external-skills.manifest.
# Does NOT vendor skill bodies into ma-hub — pulls fresh from upstream via skills CLI.
# MA-owned skills: use install-skills.sh instead.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

MANIFEST="${HUB}/registry/external-skills.manifest"
if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: missing manifest ${MANIFEST}"
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "ERROR: npx not found in PATH"
  exit 1
fi

echo "=== external skills from ${MANIFEST} ==="

# Optional global refresh of already-installed skills
if [[ "${MA_EXTERNAL_SKILLS_UPDATE:-1}" == "1" ]]; then
  echo "skills update -g ..."
  npx -y skills update -g -y || echo "WARN: skills update had issues"
fi

package=""
skills=()

flush_package() {
  if [[ -z "$package" ]]; then
    return 0
  fi
  if [[ ${#skills[@]} -eq 0 ]]; then
    echo "WARN: package ${package} has no SKILL lines — skip"
    package=""
    skills=()
    return 0
  fi

  args=(npx -y skills add "$package" -g -y)
  for s in "${skills[@]}"; do
    args+=(-s "$s")
  done

  echo "add ${package} → ${skills[*]}"
  # Upstream can fail intermittently; continue other packages
  if ! "${args[@]}" >/dev/null 2>&1; then
    echo "WARN: failed to add ${package} (partial install possible)"
  fi

  package=""
  skills=()
}

while IFS= read -r line || [[ -n "$line" ]]; do
  # trim
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" || "$line" == \#* ]] && continue

  key="${line%% *}"
  rest="${line#* }"
  case "$key" in
    PACKAGE)
      flush_package
      package="$rest"
      skills=()
      ;;
    SKILL)
      if [[ -z "$package" ]]; then
        echo "WARN: SKILL before PACKAGE — skip: $rest"
        continue
      fi
      skills+=("$rest")
      ;;
    *)
      echo "WARN: unknown line: $line"
      ;;
  esac
done <"$MANIFEST"

flush_package

echo "OK: external skills refreshed from manifest"
echo "Docs: ${HUB}/registry/external-skills.md"
