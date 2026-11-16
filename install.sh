#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
Usage: bash install.sh [options] [N ...]

  N                 instance numbers to build (default: 2 3). Claude 2 to 10 have their own icon colour.
  --theme           give every built instance its default theme (needs node)
  --theme N=ID      give instance N the theme ID (repeatable); ID "none" removes it
  --router          install Claude Link Router (claude:// links go to the app you used last)
  -h, --help        show this help

Examples:
  bash install.sh                      Claude 2 and Claude 3
  bash install.sh 4 5                  Claude 4 and Claude 5
  bash install.sh --theme 2 3          Claude 2 and 3 with their default themes
  bash install.sh --theme 3=sakura 3   Claude 3 with Sakura
EOF
}

declare -a NUMS=() PICKS=()
ROUTER=0 THEME_ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --router) ROUTER=1 ;;
    --theme)
      if [[ "${2:-}" =~ ^[0-9]+=[a-z-]+$ ]]; then PICKS+=("$2"); shift; else THEME_ALL=1; fi ;;
    --theme=*) PICKS+=("${1#--theme=}") ;;
    [0-9]*) NUMS+=("$1") ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done
[ ${#NUMS[@]} -gt 0 ] || NUMS=(2 3)

default_theme() {
  case "$1" in
    2) echo night-sea ;; 3) echo terminal ;; 4) echo jellyfish ;; 5) echo sunset-cloud ;; 6) echo honu-lagoon ;;
    7) echo sakura-dusk ;; 8) echo lantern-night ;; 9) echo moonlit ;; 10) echo star-voyage ;; *) echo night-sea ;;
  esac
}

[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = 1 ] || { echo "Apple silicon Macs only." >&2; exit 1; }
[ -d /Applications/Claude.app ] || { echo "/Applications/Claude.app not found. Install Claude first." >&2; exit 1; }
if [ "$THEME_ALL" = 1 ] || [ ${#PICKS[@]} -gt 0 ]; then
  command -v node >/dev/null || { echo "Themes need node (brew install node)." >&2; exit 1; }
fi

xattr -cr .
H="$HOME/.claude-instances"
mkdir -p "$H" "$HOME/.claude"
cp -R assets/macos/claude*.car assets/macos/claude*.icns assets/macos/claude*.icon "$H/"
install -m 755 macos/build-claude2.sh macos/rebuild-when-quit.sh macos/claude-url-router.sh macos/set-theme.sh "$H/"
install -m 755 macos/share-sessions.sh macos/sync-claude-apps.sh "$HOME/.claude/"
rm -rf "$H/theme" && cp -R theme "$H/theme"

/usr/bin/python3 -I - "$HOME/.claude/settings.json" "$HOME/.claude/share-sessions.sh" <<'PY'
import json, os, sys
p, script = sys.argv[1:]
s = json.load(open(p, encoding='utf-8')) if os.path.exists(p) else {}
for event, flag in (('SessionStart', '--later'), ('Stop', '--soon')):
    cmd = '"%s" %s' % (script, flag)
    groups = s.setdefault('hooks', {}).setdefault(event, [])
    mine = [h for g in groups for h in g.get('hooks', []) if 'share-sessions.sh' in h.get('command', '')]
    for h in mine: h['command'] = cmd
    if not mine: groups.append({'matcher': '', 'hooks': [{'type': 'command', 'command': cmd, 'timeout': 15}]})
with open(p, 'w', encoding='utf-8') as f: json.dump(s, f, indent=2, ensure_ascii=False)
PY

[ "$ROUTER" = 1 ] && "$H/claude-url-router.sh" --install

fail=0
for n in "${NUMS[@]}"; do "$H/build-claude2.sh" "/Applications/Claude $n.app" || fail=1; done

if [ "$THEME_ALL" = 1 ]; then
  for n in "${NUMS[@]}"; do "$H/set-theme.sh" "$n" "$(default_theme "$n")" || fail=1; done
fi
for p in "${PICKS[@]+"${PICKS[@]}"}"; do "$H/set-theme.sh" "${p%%=*}" "${p#*=}" || fail=1; done
exit $fail
