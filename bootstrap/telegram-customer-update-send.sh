#!/usr/bin/env bash
# Send a customer release update via Telegram (MA-deploy Phase 7.5).
# Usage:
#   telegram-customer-update-send.sh <<'EOF'
#   message body
#   EOF
#   telegram-customer-update-send.sh --file path.txt
# Env:
#   MA_TELEGRAM_BOT_TOKEN — shared; prefer ~/.config/ma-hub/telegram.env
#   COMPANY_TELEGRAM_CHAT_ID — per product (.env.local)
#   COMPANY_TELEGRAM_THREAD_ID_UPDATES — optional per-product forum topic
set -euo pipefail

load_env_files() {
  local f
  # Project first, then machine — shared MA bot token wins if set on the machine.
  for f in .env.local .env; do
    if [[ -f "$f" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$f"
      set +a
    fi
  done
  if [[ -f "${HOME}/.config/ma-hub/telegram.env" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "${HOME}/.config/ma-hub/telegram.env"
    set +a
  fi
}

load_env_files

# Do NOT fall back to product TELEGRAM_BOT_TOKEN (ops bot).
TOKEN="${MA_TELEGRAM_BOT_TOKEN:-${DEV_TELEGRAM_BOT_TOKEN:-}}"
CHAT_ID="${COMPANY_TELEGRAM_CHAT_ID:-}"
THREAD_ID="${COMPANY_TELEGRAM_THREAD_ID_UPDATES:-}"

MESSAGE=""
if [[ "${1:-}" == "--file" ]]; then
  MESSAGE="$(cat "${2:?missing path after --file}")"
elif [[ ! -t 0 ]]; then
  MESSAGE="$(cat)"
else
  echo "error: pass message on stdin or --file PATH" >&2
  exit 2
fi

MESSAGE="$(printf '%s' "$MESSAGE" | sed -e 's/[[:space:]]*$//' )"
if [[ -z "$MESSAGE" ]]; then
  echo "error: empty message" >&2
  exit 2
fi
if [[ -z "$TOKEN" ]]; then
  echo "error: MA_TELEGRAM_BOT_TOKEN is not set (put it in ~/.config/ma-hub/telegram.env)" >&2
  exit 2
fi
if [[ -z "$CHAT_ID" ]]; then
  echo "error: COMPANY_TELEGRAM_CHAT_ID is not set (product .env.local)" >&2
  exit 2
fi

API="https://api.telegram.org/bot${TOKEN}/sendMessage"

JSON_PAYLOAD="$(MESSAGE="$MESSAGE" CHAT_ID="$CHAT_ID" THREAD_ID="$THREAD_ID" python3 - <<'PY'
import json, os
payload = {
    "chat_id": os.environ["CHAT_ID"],
    "text": os.environ["MESSAGE"],
    "disable_web_page_preview": True,
}
thread = os.environ.get("THREAD_ID", "").strip()
if thread:
    payload["message_thread_id"] = int(thread)
print(json.dumps(payload, ensure_ascii=False))
PY
)"

# Never echo token. Response body may be shown.
HTTP_CODE="$(curl -sS -o /tmp/ma-telegram-send-response.json -w '%{http_code}' \
  -X POST "$API" \
  -H 'Content-Type: application/json' \
  -d "$JSON_PAYLOAD")"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "error: Telegram HTTP $HTTP_CODE" >&2
  python3 -c 'import json,sys; print(json.load(open("/tmp/ma-telegram-send-response.json")), file=sys.stderr)' 2>/dev/null || true
  exit 1
fi

OK="$(python3 -c 'import json; print(json.load(open("/tmp/ma-telegram-send-response.json")).get("ok"))')"
if [[ "$OK" != "True" ]]; then
  echo "error: Telegram API ok=false" >&2
  python3 -c 'import json,sys; print(json.load(open("/tmp/ma-telegram-send-response.json")), file=sys.stderr)' 2>/dev/null || true
  exit 1
fi

echo "ok: customer update sent to chat ${CHAT_ID}${THREAD_ID:+ thread $THREAD_ID}"
