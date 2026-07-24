#!/usr/bin/env bash
# Stamp helpers: remember which hub git SHA / standards VERSION were last installed.
# shellcheck shell=bash

MA_HUB_STATE_DIR="${HOME}/.config/ma-hub"
MA_HUB_STATE_FILE="${MA_HUB_STATE_DIR}/installed-state"

ma_hub_standards_version() {
  local hub="${1:-}"
  if [[ -n "$hub" && -f "${hub}/standards/VERSION" ]]; then
    tr -d '[:space:]' <"${hub}/standards/VERSION"
  else
    echo "?"
  fi
}

ma_hub_read_stamp() {
  if [[ -f "$MA_HUB_STATE_FILE" ]]; then
    cat "$MA_HUB_STATE_FILE"
  fi
}

# Usage: ma_hub_stamp_get KEY [state_string]
ma_hub_stamp_get() {
  local key="$1"
  local state="${2-}"
  if [[ -z "$state" ]]; then
    state="$(ma_hub_read_stamp)"
  fi
  [[ -n "$state" ]] || return 0
  printf '%s\n' "$state" | sed -n "s/^${key}=//p" | head -n1
}

ma_hub_write_stamp() {
  local hub="$1"
  local sha version now
  sha="$(git -C "$hub" rev-parse HEAD)"
  version="$(ma_hub_standards_version "$hub")"
  now="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  mkdir -p "$MA_HUB_STATE_DIR"
  cat >"$MA_HUB_STATE_FILE" <<EOF
GIT_SHA=${sha}
STANDARDS_VERSION=${version}
UPDATED_AT=${now}
HUB_PATH=${hub}
BRANCH=$(git -C "$hub" rev-parse --abbrev-ref HEAD)
EOF
}
