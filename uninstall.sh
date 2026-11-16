#!/bin/bash
set -euo pipefail

PURGE=0 DRY=0
for a; do
  case "$a" in
    --purge) PURGE=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) echo "Usage: bash uninstall.sh [--purge] [--dry-run]"; echo "  --purge    also delete instance data and sign-ins (~/.claude-instances/claude<N>)"; exit 0 ;;
    *) echo "Unknown option: $a" >&2; exit 2 ;;
  esac
done

run() { if [ "$DRY" = 1 ]; then echo "would run: $*"; else "$@"; fi; }
H="$HOME/.claude-instances"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

for app in /Applications/Claude\ *.app; do
  [ -d "$app" ] || continue
  id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist" 2>/dev/null || true)"
  case "$id" in local.claude-desktop-*) ;; *) continue ;; esac
  if pgrep -f "$app/Contents/MacOS/Claude" >/dev/null; then
    echo "$(basename "$app") is running. Quit it and run again." >&2; exit 1
  fi
  run "$LSREG" -u "$app"
  run rm -rf "$app"
  run rm -f "$HOME/Library/Caches/$id.ShipIt"
  echo "removed $app"
done

A="$HOME/Library/LaunchAgents/local.multiple-claude.claude-url-router.plist"
if [ -f "$A" ]; then
  run launchctl bootout "gui/$(id -u)" "$A" 2>/dev/null || true
  run rm -f "$A"
fi
[ -d "$HOME/Applications/Claude Link Router.app" ] && run rm -rf "$HOME/Applications/Claude Link Router.app"

if [ -f "$HOME/.claude/settings.json" ]; then
  if [ "$DRY" = 1 ]; then echo "would remove share-sessions.sh hooks from ~/.claude/settings.json"; else
  /usr/bin/python3 -I - "$HOME/.claude/settings.json" <<'PY'
import json, sys
p = sys.argv[1]
s = json.load(open(p, encoding='utf-8'))
hooks = s.get('hooks', {})
for event in ('SessionStart', 'Stop'):
    groups = []
    for g in hooks.get(event, []):
        g['hooks'] = [h for h in g.get('hooks', []) if 'share-sessions.sh' not in h.get('command', '')]
        if g['hooks']: groups.append(g)
    if groups: hooks[event] = groups
    else: hooks.pop(event, None)
with open(p, 'w', encoding='utf-8') as f: json.dump(s, f, indent=2, ensure_ascii=False)
PY
  fi
fi
run rm -f "$HOME/.claude/share-sessions.sh" "$HOME/.claude/sync-claude-apps.sh"

if [ -d "$H" ]; then
  run rm -rf "$H/theme"
  run find "$H" -maxdepth 1 \( -name 'claude*.car' -o -name 'claude*.icns' -o -name 'claude*.icon' -o -name '*.sh' -o -name '*.log' \) -exec rm -rf {} +
  if [ "$PURGE" = 1 ]; then
    run rm -rf "$H"
    echo "deleted instance data in $H"
  else
    echo "kept instance data in $H (use --purge to delete it)"
  fi
fi
echo "done. The original /Applications/Claude.app was not touched."
