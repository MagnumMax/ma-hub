#!/usr/bin/env bash
set -euo pipefail

# Install / refresh Cursor commands from this hub into ~/.cursor/commands/

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

DEST="${HOME}/.cursor/commands"
mkdir -p "$DEST"

shopt -s nullglob
files=("${HUB}/commands"/MA-*.md)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "ERROR: no MA-*.md commands in ${HUB}/commands"
  exit 1
fi

for f in "${files[@]}"; do
  base="$(basename "$f")"
  cp "$f" "${DEST}/${base}"
  echo "installed ${base}"
done

echo "OK: commands installed to ${DEST}"
