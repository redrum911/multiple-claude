# How it works

**English** · [Tiếng Việt](how-it-works.vi.md) · [简体中文](how-it-works.zh-CN.md)

Claude Desktop is an Electron app. Electron keeps all state (sign-in, settings, cache) in one *user-data folder*,
and the `--user-data-dir` flag moves it somewhere else. Every instance is the same Claude app started with its own
data folder. Everything else makes each instance look like a separate app and keeps shared features working.

## macOS

| Part | How | Installed to |
|---|---|---|
| Instance app | `macos/build-claude2.sh` makes an APFS clone of `/Applications/Claude.app` (no extra disk space), sets the bundle ID `local.claude-desktop-<N>`, name and icon, swaps the executable for a launcher, drops the three Anthropic-only entitlements and re-signs (Apple Development certificate if you have one, ad hoc otherwise). | `/Applications/Claude <N>.app` |
| Launcher | Refuses to open twice on the same data folder, rebuilds the instance when `Claude.app` changed version, merges sessions, protects the Claude in Chrome manifest, hands `claude://` back to the original app for 60 s after launch, then runs Claude with `--user-data-dir` and `REACT_PROFILE=1`. | inside each instance |
| Updater block | A file at `~/Library/Caches/local.claude-desktop-<N>.ShipIt` stops the instance's own updater (its download would fail the signature check anyway). Instances follow the original app through the launcher. | `~/Library/Caches` |
| Session merge | `macos/share-sessions.sh`, run by each launcher, by the `SessionStart` hook (after 30 s) and the `Stop` hook (after 5 s). | `~/.claude/share-sessions.sh` |
| App restart | `macos/sync-claude-apps.sh` quits every running Claude app normally, waits up to 120 s, merges, and opens them again. The `/sync-apps` mod calls it. | `~/.claude/sync-claude-apps.sh` |
| Themes | `theme/apply-theme.mjs` copies the theme extension into `<data folder>/extensions/fmkadmapgofadopljbjfkapdkoienihi` and writes `theme.json`. The extension reads `theme.json` every second. `REACT_PROFILE=1`, set only by instance launchers, makes Claude load it. | `~/.claude-instances/theme`, `set-theme.sh` |
| Link router (optional) | An AppleScript applet owns `claude://` and passes each URL to the topmost Claude app. A LaunchAgent takes the scheme back whenever a Claude app grabs it at launch. | `~/Applications/Claude Link Router.app` |

### Session merge rules

Claude Desktop keeps the Code sidebar in `<data folder>/claude-code-sessions/<account>/<org>/` and reads it only at
startup. `share-sessions.sh` merges every such folder of every app:

- The record with the newest `lastActivityAt` wins, whole.
- Sessions without a `cliSessionId` yet (just created, no title) stay in their own app until they have one.
- `isArchived` stays per app.
- A `deleted_<id>` file newer than the session's last activity removes it everywhere; the records are moved to
  `~/.claude/backups/deleted-sessions/<date>/`, not copied back.

When an app quits normally it writes its in-memory session list to disk, which can overwrite a newer merged copy.
That is why `sync-claude-apps.sh` quits the apps first and merges after.

### Rebuilding icons

`assets/macos/claude<N>.car` is compiled from the Icon Composer document `claude<N>.icon` (a copy of
`assets/spark.png` on a gradient from `assets/palette.json`):

```bash
xcrun actool --compile out --platform macosx --minimum-deployment-target 11.0 --app-icon claude<N> \
  --output-partial-info-plist /dev/null assets/macos/claude<N>.icon
cp out/Assets.car assets/macos/claude<N>.car
```

`claude<N>.icns` is the fallback for older macOS.

## Windows

| Part | How | Installed to |
|---|---|---|
| Instance app | `windows/build-instance.ps1` copies the Store app folder (`WindowsApps\Claude_*\app`) and changes the icon resource in the copy's `claude.exe` (`set-exe-icon.ps1`). `.package-version` records the source version. | `%USERPROFILE%\.claude-instances\app-claude<N>` |
| Shortcut | `Claude <N>.lnk` in the Start Menu runs the copy with `--user-data-dir`. | Start Menu |
| Icons | `windows/make-icons.ps1` draws each `.ico` from `assets/palette.json` and `assets/spark.png`. | `%USERPROFILE%\.claude-instances\icons` |
| Updates | Scheduled Task `claude-instances-refresh` (at sign-in and every 30 minutes) rebuilds copies older than the installed Claude, skipping running ones. | Task Scheduler |
| Link router | `windows/claude-link-router.cs`, compiled at install time with the .NET Framework `csc.exe`. It finds the topmost Claude window, reads its command line and starts that instance with the URL. | `%USERPROFILE%\.claude-instances\claude-link-router.exe` |
| Session sync | `shared/restore-cc-sessions.py` through `pythonw`, Scheduled Task `claude-session-sync` every minute. It also adds sidebar entries for sessions started from the terminal CLI. | `%USERPROFILE%\.claude\bin` |

The Store package registers `claude://` itself and wins over `HKCU\Software\Classes\claude`, so the router registers
as a normal app and you pick it in **Default apps › Choose default apps by protocol**. Windows protects that choice
with a hash, so a script cannot set it.

## Troubleshooting

| Symptom | Check |
|---|---|
| Sessions from another app do not show | Reopen the app, or run `/sync-apps`. macOS log: `~/.claude/sync-claude-apps.log`. |
| An instance stays on an old Claude version | macOS: open it once, it rebuilds itself (log `~/.claude-instances/build-claude2.log`). Windows: quit it and run `install.cmd <N>`. |
| "Another Claude window is already using the data" | An app using the same data folder is still running. Quit it. |
| Theme does not show | The instance must have been built by this kit (its launcher sets `REACT_PROFILE=1`). Run `set-theme.sh <N> <theme>` and reopen the app once. |
| Sign-in or MCP callback opens the wrong app | Install the router (`bash install.sh --router`), or finish the sign-in in the app that started it. |
