#!/usr/bin/env bash
set -euo pipefail

# Install macOS launchd job: daily ma-hub ensure-latest (commands, skills, standards).
# Default: every day at 09:15 local time.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

LABEL="com.ma-hub.ensure-latest"
PLIST_SRC="${HUB}/bootstrap/launchd/${LABEL}.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG_DIR="${HOME}/Library/Logs/ma-hub"
HOUR="${MA_HUB_LAUNCHD_HOUR:-9}"
MINUTE="${MA_HUB_LAUNCHD_MINUTE:-15}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "SKIP: launchd is macOS-only (this is $(uname -s))"
  exit 0
fi

if [[ ! -f "$PLIST_SRC" ]]; then
  echo "ERROR: missing ${PLIST_SRC}"
  exit 1
fi

mkdir -p "${HOME}/Library/LaunchAgents" "$LOG_DIR"

sed \
  -e "s|@MA_HUB_ROOT@|${HUB}|g" \
  -e "s|@HOME@|${HOME}|g" \
  -e "s|@HOUR@|${HOUR}|g" \
  -e "s|@MINUTE@|${MINUTE}|g" \
  "$PLIST_SRC" >"$PLIST_DEST"

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/${LABEL}" 2>/dev/null || true

echo "OK: installed ${PLIST_DEST}"
echo "    schedule: daily ${HOUR}:$(printf '%02d' "$MINUTE")"
echo "    logs:     ${LOG_DIR}/ensure-latest.*.log"
echo "Manual run:   launchctl kickstart -k gui/$(id -u)/${LABEL}"
echo "Or:           ma-hub-ensure-latest"
