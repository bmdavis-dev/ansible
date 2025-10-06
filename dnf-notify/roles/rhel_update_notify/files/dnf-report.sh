#!/bin/bash
set -euo pipefail
LOG=/var/log/dnf-report.log
echo "=== $(/usr/bin/date -Is) start on $(/usr/bin/hostname) ===" >> "$LOG"

# === Config ===
WEBHOOK_URL="add webhook here" # Add webhook
RELEASEVER="9.6"   # keep pinned to 9.6

# === Data collection ===
HOST="$(/usr/bin/hostname)"

# TOTAL: dnf check-update returns 100 when updates exist — that's expected, so add '|| true'
TOTAL_UPDATES=$(
  /usr/bin/dnf -q check-update --releasever="$RELEASEVER" 2>/dev/null || true
)
# Count only non-empty lines that aren't the "Last metadata..." noise
TOTAL_UPDATES=$(printf '%s\n' "$TOTAL_UPDATES" | grep -v '^Last' | sed '/^\s*$/d' | wc -l)

# Breakdown counts (these usually return 0, but add '|| true' to be safe)
BUGFIX_COUNT=$(/usr/bin/dnf -q updateinfo list bugfix      --releasever="$RELEASEVER" 2>/dev/null | wc -l || true)
SECURITY_COUNT=$(/usr/bin/dnf -q updateinfo list security  --releasever="$RELEASEVER" 2>/dev/null | wc -l || true)
ENHANCEMENT_COUNT=$(/usr/bin/dnf -q updateinfo list enhancement --releasever="$RELEASEVER" 2>/dev/null | wc -l || true)

# If nothing pending, skip posting
if [ "${TOTAL_UPDATES:-0}" -eq 0 ]; then
  echo "$(/usr/bin/date -Is) - no updates; not posting" >> "$LOG"
  exit 0
fi

SUMMARY=$(cat <<EOF
Server: $HOST
OS: RHEL $RELEASEVER
Available Updates: $TOTAL_UPDATES
Bugfix Updates: $BUGFIX_COUNT
Security Updates: $SECURITY_COUNT
Enhancement Updates: $ENHANCEMENT_COUNT
EOF
)

# Escape newlines for JSON
SUMMARY_ESCAPED=${SUMMARY//$'\n'/\\n}
JSON=$(printf '{"text":"%s"}' "$SUMMARY_ESCAPED")

# === Post to Teams via Power Automate webhook ===
/usr/bin/curl -sS -H "Content-Type: application/json" \
     -X POST \
     -d "$JSON" \
     "$WEBHOOK_URL" -w ' HTTP:%{http_code}\n' -o /tmp/dnf-teams.out >> "$LOG" 2>&1

echo "$(/usr/bin/date -Is) - posted to Teams (script completed)" >> "$LOG"