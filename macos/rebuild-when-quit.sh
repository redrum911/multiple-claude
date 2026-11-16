#!/bin/bash
APP="${1:-/Applications/Claude 2.app}"
H="$HOME/.claude-instances"
running() { pgrep -f "$APP/Contents/MacOS/Claude" >/dev/null; }
for _ in $(seq 1800); do running || break; sleep 1; done
running && { echo "$(date) timed out waiting for $APP to quit"; exit 1; }
sleep 2
echo "$(date) rebuilding $APP"
"$H/build-claude2.sh" "$APP" && open -a "$APP"
