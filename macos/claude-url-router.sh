#!/bin/sh
ROUTER="$HOME/Applications/Claude Link Router.app"
LOG="$HOME/Library/Logs/claude-url-router.log"

if [ "$1" = --install ]; then
  set -e
  rm -rf "$ROUTER"
  mkdir -p "$(dirname "$ROUTER")" "$HOME/Library/LaunchAgents"
  osacompile -o "$ROUTER" -e 'on open location u' \
    -e 'do shell script quoted form of (POSIX path of (path to home folder) & ".claude-instances/claude-url-router.sh") & " " & quoted form of u' \
    -e 'end open location'
  PL="$ROUTER/Contents/Info.plist"
  plutil -replace CFBundleIdentifier -string local.claude-link-router "$PL"
  plutil -replace LSUIElement -bool true "$PL"
  plutil -replace CFBundleURLTypes -json '[{"CFBundleURLName":"Claude","CFBundleURLSchemes":["claude"]}]' "$PL"
  codesign --force --sign - "$ROUTER"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$ROUTER"
  A="$HOME/Library/LaunchAgents/local.multiple-claude.claude-url-router.plist"
  launchctl bootout "gui/$(id -u)" "$A" 2>/dev/null || true
  cat >"$A" <<EOP
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>local.multiple-claude.claude-url-router</string>
	<key>ProcessType</key><string>Background</string>
	<key>ProgramArguments</key><array><string>$HOME/.claude-instances/claude-url-router.sh</string></array>
	<key>RunAtLoad</key><true/>
	<key>WatchPaths</key><array><string>$HOME/Library/Preferences/com.apple.LaunchServices/com.apple.launchservices.secure.plist</string></array>
	<key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOP
  launchctl bootstrap "gui/$(id -u)" "$A"
  echo "Xong: $ROUTER + $A"
  exit 0
fi

if [ -z "$1" ]; then
  cur=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("claude://x")).path.js' 2>/dev/null)
  [ "$cur" = "$ROUTER" ] && exit 0
  osascript -l JavaScript -e 'ObjC.import("CoreServices"); $.LSSetDefaultHandlerForURLScheme($("claude"), $("local.claude-link-router"))' >/dev/null
  echo "$(date '+%F %T') reclaimed claude:// from ${cur:-?}" >>"$LOG"
  exit 0
fi

target=com.anthropic.claudefordesktop
for asn in $(lsappinfo visibleProcessList | grep -oE 'ASN:0x[0-9a-f]+-0x[0-9a-f]+'); do
  id=$(lsappinfo info -only bundleid "$asn" | sed -nE 's/.*="(.*)"/\1/p')
  case "$id" in com.anthropic.claudefordesktop|local.claude-desktop-*) target=$id; break ;; esac
done
echo "$(date '+%F %T') ${1%%[?#]*} -> $target" >>"$LOG"
exec open -b "$target" "$1"
