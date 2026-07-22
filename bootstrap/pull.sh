#!/usr/bin/env bash
set -euo pipefail

# Pull latest main (or current branch) and reinstall commands.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

cd "$HUB"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: ${HUB} is not a git repo"
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "Pulling ${BRANCH} in ${HUB}..."

git fetch origin
if git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  git pull --ff-only origin "$BRANCH" || git pull --ff-only
else
  echo "WARN: no origin/${BRANCH} yet — skip pull (local only)"
fi

# Optional: if project pins a tag, user sets MA_HUB_REF=v1.0.0
if [[ -n "${MA_HUB_REF:-}" ]]; then
  echo "Checking out pin MA_HUB_REF=${MA_HUB_REF}"
  git checkout "$MA_HUB_REF"
fi

"${HUB}/bootstrap/install-commands.sh"
"${HUB}/bootstrap/install-skills.sh"

echo "OK: hub updated · standards VERSION=$(cat "${HUB}/standards/VERSION" 2>/dev/null || echo '?')"
echo "Tip: ma-hub-check-drift — убедиться, что локальный кэш = хаб"
