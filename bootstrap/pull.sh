#!/usr/bin/env bash
set -euo pipefail

# Always pull + reinstall (manual / weekly). For smart daily sync prefer ensure-latest.sh.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec "${ROOT}/bootstrap/ensure-latest.sh" --force "$@"
