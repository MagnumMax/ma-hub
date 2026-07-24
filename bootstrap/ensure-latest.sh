#!/usr/bin/env bash
set -euo pipefail

# Pull + reinstall MA cache only when remote hub moved (git SHA / standards VERSION).
# Safe to run daily (launchd), on session start, or manually: ma-hub-ensure-latest
#
# Flags:
#   --check     report only (exit 0 up-to-date, 1 update available, 2 error)
#   --force     always pull/reinstall even if stamp matches
#   --quiet     less chatter (still prints action summary)
#
# Env:
#   MA_HUB_REF          pin tag/branch (optional)
#   MA_HUB_FORCE=1      same as --force
#   MA_HUB_SKIP_FETCH=1 skip network fetch (compare local HEAD vs stamp only)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"
# shellcheck source=stamp.sh
source "${ROOT}/bootstrap/stamp.sh"

CHECK_ONLY=0
FORCE="${MA_HUB_FORCE:-0}"
QUIET=0

for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    --force) FORCE=1 ;;
    --quiet) QUIET=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
  esac
done

log() {
  if [[ "$QUIET" -eq 0 ]]; then
    echo "$@"
  fi
}

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  echo "ERROR: ma-hub not found. Clone and run bootstrap first."
  exit 2
fi

if ! git -C "$HUB" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: ${HUB} is not a git repo"
  exit 2
fi

cd "$HUB"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [[ -n "${MA_HUB_REF:-}" ]]; then
  DESIRED_REF="$MA_HUB_REF"
else
  DESIRED_REF="$BRANCH"
fi

if [[ "${MA_HUB_SKIP_FETCH:-0}" != "1" ]]; then
  log "Fetching origin…"
  if ! git fetch origin --quiet; then
    echo "WARN: git fetch failed (offline?). Using local state."
  fi
fi

REMOTE_SHA=""
if [[ -n "${MA_HUB_REF:-}" ]]; then
  if git rev-parse --verify --quiet "${MA_HUB_REF}^{commit}" >/dev/null; then
    REMOTE_SHA="$(git rev-parse "${MA_HUB_REF}^{commit}")"
  elif git rev-parse --verify --quiet "origin/${MA_HUB_REF}^{commit}" >/dev/null; then
    REMOTE_SHA="$(git rev-parse "origin/${MA_HUB_REF}^{commit}")"
  fi
elif git rev-parse --verify --quiet "origin/${BRANCH}^{commit}" >/dev/null; then
  REMOTE_SHA="$(git rev-parse "origin/${BRANCH}^{commit}")"
elif git rev-parse --verify --quiet "origin/main^{commit}" >/dev/null; then
  REMOTE_SHA="$(git rev-parse "origin/main^{commit}")"
  DESIRED_REF="main"
fi

LOCAL_SHA="$(git rev-parse HEAD)"
LOCAL_VERSION="$(ma_hub_standards_version "$HUB")"
STATE="$(ma_hub_read_stamp || true)"
INSTALLED_SHA="$(ma_hub_stamp_get GIT_SHA "$STATE" || true)"
INSTALLED_VERSION="$(ma_hub_stamp_get STANDARDS_VERSION "$STATE" || true)"

TARGET_SHA="${REMOTE_SHA:-$LOCAL_SHA}"

needs_git_update=0
needs_reinstall=0

if [[ "$FORCE" == "1" ]]; then
  needs_git_update=1
  needs_reinstall=1
else
  if [[ -n "$REMOTE_SHA" && "$LOCAL_SHA" != "$REMOTE_SHA" ]]; then
    needs_git_update=1
    needs_reinstall=1
  fi
  if [[ -z "${INSTALLED_SHA:-}" || "$INSTALLED_SHA" != "$TARGET_SHA" ]]; then
    needs_reinstall=1
  fi
  if [[ -z "${INSTALLED_VERSION:-}" || "$INSTALLED_VERSION" != "$LOCAL_VERSION" ]]; then
    needs_reinstall=1
  fi
fi

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  if [[ "$needs_git_update" -eq 1 || "$needs_reinstall" -eq 1 ]]; then
    echo "UPDATE available"
    echo "  hub:            ${HUB}"
    echo "  branch/ref:     ${DESIRED_REF}"
    echo "  local SHA:      ${LOCAL_SHA:0:12}"
    echo "  target SHA:     ${TARGET_SHA:0:12}"
    echo "  installed SHA:  ${INSTALLED_SHA:-'(none)'}"
    echo "  standards:      local=${LOCAL_VERSION} installed=${INSTALLED_VERSION:-'(none)'}"
    exit 1
  fi
  echo "OK: already latest (${LOCAL_SHA:0:12}, standards ${LOCAL_VERSION})"
  exit 0
fi

if [[ "$needs_git_update" -eq 0 && "$needs_reinstall" -eq 0 ]]; then
  log "OK: already latest (${LOCAL_SHA:0:12}, standards ${LOCAL_VERSION})"
  exit 0
fi

DIRTY="$(git status --porcelain)"
if [[ -n "$DIRTY" && "$needs_git_update" -eq 1 ]]; then
  echo "WARN: hub has local changes — skip git pull to avoid clobbering."
  echo "      Commit/stash (or discard) changes in ${HUB}, then re-run."
  echo "      Reinstalling cache from current HEAD only…"
  needs_git_update=0
fi

if [[ "$needs_git_update" -eq 1 ]]; then
  log "Updating hub → ${DESIRED_REF} (${TARGET_SHA:0:12})…"
  if [[ -n "${MA_HUB_REF:-}" ]]; then
    git checkout --quiet "$MA_HUB_REF"
  else
    git pull --ff-only origin "$BRANCH" 2>/dev/null || git pull --ff-only
  fi
  LOCAL_SHA="$(git rev-parse HEAD)"
  LOCAL_VERSION="$(ma_hub_standards_version "$HUB")"
fi

log "Installing commands + MA-skills…"
"${HUB}/bootstrap/install-commands.sh"
"${HUB}/bootstrap/install-skills.sh"

ma_hub_write_stamp "$HUB"
log "OK: hub synced · SHA=${LOCAL_SHA:0:12} · standards VERSION=${LOCAL_VERSION}"
log "Tip: ma-hub-check-drift"
