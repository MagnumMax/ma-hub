#!/usr/bin/env bash
set -euo pipefail

# Install a user-level Cursor sessionStart hook that soft-syncs ma-hub when stale.
# Does not block chat; only runs ensure-latest if stamp is older than 24h or missing.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=resolve-hub.sh
source "${ROOT}/bootstrap/resolve-hub.sh"

HUB="$(ma_hub_resolve || true)"
if [[ -z "${HUB:-}" ]]; then
  HUB="$ROOT"
fi

HOOKS_DIR="${HOME}/.cursor/hooks"
HOOK_SCRIPT="${HOOKS_DIR}/ma-hub-session-start.sh"
HOOKS_JSON="${HOME}/.cursor/hooks.json"

mkdir -p "$HOOKS_DIR"

cat >"$HOOK_SCRIPT" <<EOF
#!/usr/bin/env bash
set -euo pipefail
# Cursor sessionStart hook — soft-refresh ma-hub if stamp is stale (>24h) or missing.

HUB="${HUB}"
STATE="\${HOME}/.config/ma-hub/installed-state"
MAX_AGE_SECS=\${MA_HUB_SESSION_MAX_AGE_SECS:-86400}

additional=""
ran=0

should_sync() {
  if [[ ! -f "\$STATE" ]]; then
    return 0
  fi
  local mtime now age
  mtime=\$(stat -f %m "\$STATE" 2>/dev/null || stat -c %Y "\$STATE" 2>/dev/null || echo 0)
  now=\$(date +%s)
  age=\$((now - mtime))
  [[ "\$age" -ge "\$MAX_AGE_SECS" ]]
}

if [[ -x "\${HUB}/bootstrap/ensure-latest.sh" ]] && should_sync; then
  if "\${HUB}/bootstrap/ensure-latest.sh" --quiet >/tmp/ma-hub-session-ensure.log 2>&1; then
    ran=1
  else
    ran=0
  fi
fi

ver="?"
sha="?"
if [[ -f "\$STATE" ]]; then
  ver=\$(sed -n 's/^STANDARDS_VERSION=//p' "\$STATE" | head -n1)
  sha=\$(sed -n 's/^GIT_SHA=//p' "\$STATE" | head -n1 | cut -c1-12)
fi

if [[ "\$ran" -eq 1 ]]; then
  additional="ma-hub synced for this session (standards \${ver}, sha \${sha}). Source of truth: \${HUB}."
else
  additional="ma-hub cache: standards \${ver}, sha \${sha}. Auto-sync runs daily; run ma-hub-ensure-latest if you need latest now."
fi

additional=\${additional//\\\\/\\\\\\\\}
additional=\${additional//\"/\\\\\"}

printf '{"additional_context":"%s"}\\n' "\$additional"
EOF

chmod +x "$HOOK_SCRIPT"

if [[ -f "$HOOKS_JSON" ]] && command -v python3 >/dev/null 2>&1; then
  python3 - "$HOOKS_JSON" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
hooks = data.setdefault("hooks", {})
entries = hooks.setdefault("sessionStart", [])
cmd = "./hooks/ma-hub-session-start.sh"
entries = [e for e in entries if e.get("command") != cmd]
entries.append({"command": cmd})
hooks["sessionStart"] = entries
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print(f"OK: merged sessionStart hook into {path}")
PY
else
  cat >"$HOOKS_JSON" <<'EOF'
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/ma-hub-session-start.sh"
      }
    ]
  }
}
EOF
  echo "OK: wrote ${HOOKS_JSON}"
fi

echo "OK: session hook → ${HOOK_SCRIPT}"
echo "Note: user hooks run from ~/.cursor/ — path ./hooks/... is correct."
