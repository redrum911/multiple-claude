#!/bin/bash
LOG="$HOME/.claude/sync-claude-apps.log"
if [ "$1" != --detached ]; then
  /usr/bin/python3 -I -c 'import os, sys
if os.fork(): sys.exit()
os.setsid(); os.execv(sys.argv[1], [sys.argv[1], "--detached"] + sys.argv[2:])' "$0" "$@" </dev/null >>"$LOG" 2>&1
  exit 0
fi
shift
DRY=; [ "$1" = --dry-run ] && DRY=1
log() { echo "$(date '+%F %T') $*"; }
notify() { osascript -e "display notification \"$1\" with title \"Sync Claude apps\"" >/dev/null 2>&1; }
run() { if [ -n "$DRY" ]; then log "dry-run: $*"; else "$@"; fi; }

LOCK="$HOME/.claude/.sync-claude-apps.lock.d"
if ! mkdir "$LOCK" 2>/dev/null; then
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +10 2>/dev/null)" ]; then rmdir "$LOCK"; mkdir "$LOCK"
  else log "another sync is running, skipping"; exit 0; fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT

bid() { /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$1/Contents/Info.plist" 2>/dev/null; }
pids() { pgrep -f "^$1/Contents/MacOS/Claude( |$)"; }

APPS=()
for a in /Applications/Claude.app /Applications/Claude\ *.app; do
  [ -d "$a" ] || continue
  case "$(bid "$a")" in com.anthropic.claudefordesktop|local.claude-desktop-*) ;; *) continue ;; esac
  [ -n "$(pids "$a")" ] && APPS+=("$a")
done
log "start${DRY:+ (dry-run)}: ${APPS[*]:-no app running}"

for a in "${APPS[@]}"; do
  if [ -n "$DRY" ]; then log "dry-run: quit $(bid "$a")"; continue; fi
  osascript -e "tell application id \"$(bid "$a")\" to quit" >/dev/null 2>&1 \
    || { log "osascript quit failed for $a, sending SIGTERM"; kill -TERM $(pids "$a") 2>/dev/null; }
done

STUCK=()
if [ -z "$DRY" ]; then
  for _ in $(seq 120); do
    STUCK=(); for a in "${APPS[@]}"; do [ -n "$(pids "$a")" ] && STUCK+=("$a"); done
    [ ${#STUCK[@]} -eq 0 ] && break
    sleep 1
  done
fi

run "$HOME/.claude/share-sessions.sh"
log "sessions merged"

for a in "${APPS[@]}"; do
  [[ " ${STUCK[*]} " == *" $a "* ]] && continue
  run open "$a"
  sleep 2
done

if [ ${#STUCK[@]} -gt 0 ]; then
  log "still running after 120 s: ${STUCK[*]}"
  notify "Could not quit $(basename "${STUCK[0]}" .app). It may be waiting for a quit confirmation."
else
  log "done"
  [ -z "$DRY" ] && notify "Sessions synced. Reopened ${#APPS[@]} app(s)."
fi
