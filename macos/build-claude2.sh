#!/bin/bash
set -euo pipefail

SRC=/Applications/Claude.app
DEST="${1:-/Applications/Claude 2.app}"
NAME="$(basename "$DEST" .app)"
N="${NAME##* }"
DATA="${2:-$HOME/.claude-instances/claude$N}"
ID=local.claude-desktop-$N
HERE="$HOME/.claude-instances"

if pgrep -f "$DEST/Contents/MacOS/Claude" >/dev/null; then
  echo "$NAME is running. Quit it and run this script again." >&2
  exit 1
fi

TMP="$(mktemp -d "$HERE/.build.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
APP="$TMP/$NAME.app"
cp -Rc "$SRC" "$APP"
rm -f "$APP/Contents/embedded.provisionprofile" "$APP/Contents/CodeResources"

PL="$APP/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string "$ID" "$PL"
plutil -replace CFBundleDisplayName -string "$NAME" "$PL"
plutil -replace CFBundleExecutable -string claude2-launcher "$PL"
if [ -f "$HERE/claude$N.car" ]; then
  cp "$HERE/claude$N.car" "$APP/Contents/Resources/Assets.car"
  plutil -replace CFBundleIconName -string "claude$N" "$PL"
else
  plutil -remove CFBundleIconName "$PL"
fi
[ -f "$HERE/claude$N.icns" ] && cp "$HERE/claude$N.icns" "$APP/Contents/Resources/electron.icns"

L="$APP/Contents/MacOS/claude2-launcher"
cat >"$L" <<'EOF'
#!/bin/sh
DATA="__DATA__"
APP="$(cd "$(dirname "$0")/../.." && pwd)"
if pgrep -f -- "--user-data-dir=$DATA" >/dev/null; then
  osascript -e 'display alert "__NAME__" message "Another Claude window is already using the data of __NAME__. Quit it (Cmd+Q) and open __NAME__ again."' >/dev/null 2>&1
  exit 1
fi
v() { /usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$1/Contents/Info.plist" 2>/dev/null; }
if [ -n "$(v /Applications/Claude.app)" ] && [ "$(v /Applications/Claude.app)" != "$(v "$APP")" ]; then
  "__HERE__/build-claude2.sh" "$APP" "$DATA" >>"__HERE__/build-claude2.log" 2>&1
fi
"$HOME/.claude/share-sessions.sh" >/dev/null 2>&1
M="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.anthropic.claude_browser_extension.json"
[ -f "$M" ] && { chmod -a "everyone deny delete" "$M" 2>/dev/null; chmod +a "everyone deny delete" "$M"; }
NOW_US=$(( ($(date +%s) + 11644473600) * 1000000 ))
if [ "$(sqlite3 "file:$DATA/Cookies?immutable=1" "select count(*) from cookies where host_key like '%claude.ai' and name='sessionKey' and expires_utc > $NOW_US" 2>/dev/null)" -gt 0 ] 2>/dev/null; then
  H='ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("claude://x")).path.js'
  ( (
    for _ in $(seq 60); do
      [ "$(osascript -l JavaScript -e "$H" 2>/dev/null)" = "$APP" ] &&
        osascript -l JavaScript -e 'ObjC.import("CoreServices"); $.LSSetDefaultHandlerForURLScheme($("claude"), $("com.anthropic.claudefordesktop"))' >/dev/null 2>&1
      sleep 1
    done
  ) & )
fi
export REACT_PROFILE=1
exec "$APP/Contents/MacOS/Claude" --user-data-dir="$DATA" "$@"
EOF
sed -i '' -e "s#__DATA__#$DATA#g" -e "s#__HERE__#$HERE#g" -e "s#__NAME__#$NAME#g" "$L"
chmod +x "$L"

xattr -cr "$APP"

SIGN="$(security find-identity -v -p codesigning | awk -F'"' '/Apple Development/ {print $2; exit}')"
SIGN="${SIGN:--}"
ENT="$TMP/entitlements.plist"
codesign -d --entitlements - --xml "$SRC" 2>/dev/null | plutil -convert xml1 -o "$ENT" -
for k in com.apple.application-identifier com.apple.developer.team-identifier keychain-access-groups; do
  /usr/libexec/PlistBuddy -c "Delete :$k" "$ENT" 2>/dev/null || true
done
for f in "$APP"/Contents/Frameworks/* "$APP"/Contents/Helpers/*; do
  codesign --force --deep --timestamp=none --sign "$SIGN" --preserve-metadata=entitlements "$f"
done
codesign --force --timestamp=none --sign "$SIGN" --identifier "$ID" --entitlements "$ENT" "$APP/Contents/MacOS/Claude"
codesign --force --timestamp=none --sign "$SIGN" --identifier "$ID" --entitlements "$ENT" "$APP"
codesign --verify --deep --strict "$APP"

B="$HOME/Library/Caches/$ID.ShipIt"
[ -d "$B" ] && rm -rf "$B"
touch "$B"

if [ -e "$DEST" ]; then
  if [ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist" 2>/dev/null)" = "$ID" ]; then
    rm -rf "$DEST"
  else
    mv "$DEST" "$HOME/.Trash/$NAME old-$(date +%Y%m%d-%H%M%S).app"
  fi
fi
mv "$APP" "$DEST"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
echo "Done: $DEST (data: $DATA)"
