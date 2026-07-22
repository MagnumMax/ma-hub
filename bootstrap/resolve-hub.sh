#!/usr/bin/env bash
# Resolve MA_HUB_ROOT into the environment.
# Priority: MA_HUB_ROOT env → ~/.config/ma-hub/config → ~/ma-hub → repo relative to this script

ma_hub_resolve() {
  if [[ -n "${MA_HUB_ROOT:-}" && -d "${MA_HUB_ROOT}/standards" ]]; then
    printf '%s\n' "$MA_HUB_ROOT"
    return 0
  fi

  local config="${HOME}/.config/ma-hub/config"
  if [[ -f "$config" ]]; then
    # shellcheck disable=SC1090
    source "$config"
    if [[ -n "${MA_HUB_ROOT:-}" && -d "${MA_HUB_ROOT}/standards" ]]; then
      printf '%s\n' "$MA_HUB_ROOT"
      return 0
    fi
  fi

  if [[ -d "${HOME}/ma-hub/standards" ]]; then
    printf '%s\n' "${HOME}/ma-hub"
    return 0
  fi

  local here
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [[ -d "${here}/standards" ]]; then
    printf '%s\n' "$here"
    return 0
  fi

  return 1
}
