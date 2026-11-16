<div align="center">

# multiple-claude

**Run several Claude Desktop apps side by side, each signed in to its own account.**

**English** · [Tiếng Việt](README.vi.md) · [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-Apple%20silicon-black?logo=apple)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

</div>

> [!NOTE]
> Unofficial community tool, not affiliated with or endorsed by Anthropic. This is a fork of
> [Multiple-Claude](https://github.com/dris1153/multiple-claude) (MIT), with themes from
> [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes) (MIT). See [Credits](#credits).

## Features

- **Claude 2, 3 … 10 next to the original app.** Each instance has its own sign-in, settings and data.
- **Own colour per instance** in the Dock, Cmd+Tab, the taskbar and the Start Menu.
- **A theme per instance** (macOS): 16 colour themes and live wallpapers, so you always know which account you are in.
- **Shared Claude Code sessions.** A Code session started in one app shows up in the others.
- **One-command sync** (macOS): `/sync-apps` restarts every Claude app so their session lists match right away.
- **Follows Claude updates.** Instances rebuild themselves when Claude updates.
- **`claude://` links go to the right app** (optional link router): MCP sign-ins and magic links return to the app you used last.

## Requirements

|                    | macOS                                     | Windows                                        |
| ------------------ | ----------------------------------------- | ---------------------------------------------- |
| System             | Apple silicon Mac                         | Windows 10 / 11, x64                           |
| Claude             | `Claude.app` in `/Applications`           | Claude Desktop from the Microsoft Store (MSIX) |
| Themes (optional)  | Node.js (`brew install node`)             | not supported yet                              |
| Session sync       | built in (`/usr/bin/python3`)             | Python 3 (`winget install Python.Python.3.12`) |
| Disk per instance  | almost none (APFS clone)                  | about 730 MB (full app copy)                   |

## Quick start

### macOS

```bash
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
bash install.sh                 # Claude 2 and Claude 3
bash install.sh --theme 2 3     # the same, each with its default theme
```

Open **Claude 2** from `/Applications` or Launchpad and sign in with another account.

### Windows

```powershell
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
.\install.cmd             # or double-click install.cmd; builds Claude 2 and Claude 3
.\install.cmd 4 5         # more instances
```

Once, the installer opens **Settings › Apps › Default apps**. Under **Choose default apps by protocol**, set
**CLAUDE** to **Claude Link Router**. Windows lets only you make that choice.

## Usage

### Instances (macOS)

```bash
bash install.sh 4 5             # add Claude 4 and Claude 5
bash install.sh --router 2 3    # also install the claude:// link router
bash install.sh --help
```

Re-running is safe. A running instance is not rebuilt: quit it (Cmd+Q) and run again.

### Themes (macOS)

Pick a theme at install time, or change it any time. The new theme shows within a second, no restart needed.

```bash
bash install.sh --theme 3=sakura 3          # build Claude 3 with Sakura
~/.claude-instances/set-theme.sh 2 moonlit  # change Claude 2 to Moonlit
~/.claude-instances/set-theme.sh 2 none     # back to Claude's own look
```

| Instance | Default theme | | Colour themes | Live wallpapers |
| :-: | --- | - | --- | --- |
| 2 | `night-sea` | | `night-sea` | `moonlit` |
| 3 | `terminal` | | `sakura` | `cloud-drift` |
| 4 | `jellyfish` | | `terminal` | `honu-lagoon` |
| 5 | `sunset-cloud` | | `sunset-cloud` | `koi-pond` |
| 6 | `honu-lagoon` | | `old-paper` | `jellyfish` |
| 7 | `sakura-dusk` | | | `lantern-night` |
| 8 | `lantern-night` | | | `fireflies` |
| 9 | `moonlit` | | | `neon-rain` |
| 10 | `star-voyage` | | | `sakura-dusk` |
| | | | | `snow-cabin`, `star-voyage` |

`night-sea` here adds a layer of twinkling stars to the original theme.

### Sessions

Claude Desktop reads its Code session list only when it starts, so a session made in another app appears after
you reopen the app you are looking at. On macOS:

- A hook merges the session lists 30 s after a session starts and 5 s after each reply.
- `~/.claude/sync-claude-apps.sh` (or `/sync-apps` with the mod below) quits every running Claude app normally,
  merges, and opens them again.

The `/sync-apps` command is a Claude Code mod in [`mods/sync-apps`](mods/sync-apps):

```bash
claude plugin marketplace add ./mods/sync-apps
claude plugin install sync-apps@multiple-claude
```

Avoid opening the same session in two apps at once: each keeps its own copy and the last one to quit wins.

### Where things live

|                 | macOS                                                     | Windows                                                  |
| --------------- | --------------------------------------------------------- | -------------------------------------------------------- |
| Instance apps   | `/Applications/Claude <N>.app`                            | `%USERPROFILE%\.claude-instances\app-claude<N>`          |
| Data, sign-in   | `~/.claude-instances/claude<N>`                           | `%USERPROFILE%\.claude-instances\claude<N>`              |
| Scripts, themes | `~/.claude-instances/`, `~/.claude/share-sessions.sh`     | `%USERPROFILE%\.claude-instances\`, `%USERPROFILE%\.claude\bin` |
| Logs            | `~/.claude-instances/build-claude2.log`, `~/.claude/sync-claude-apps.log` | `%USERPROFILE%\.claude-instances\refresh.log` |

## Uninstall

Sign-ins and instance data are kept unless you purge them. The original Claude app is never touched.

```bash
bash uninstall.sh --dry-run     # macOS: show what would be removed
bash uninstall.sh               # add --purge to also delete instance data
```

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1      # Windows; add -Purge to delete instance data
```

## How it works

Claude Desktop is an Electron app, and Electron keeps all its state in one user-data folder. Starting the same app
with `--user-data-dir` pointing elsewhere gives a separate sign-in. The rest of the kit makes each instance look and
behave like its own app. Details: [docs/how-it-works.md](docs/how-it-works.md).

## Project layout

```
install.sh / uninstall.sh       macOS
install.cmd / install.ps1       Windows
uninstall.ps1
macos/      instance builder, session sync, app restart, link router, theme switcher
windows/    app-copy builder, icon tools, link router (C#), refresh task
shared/     restore-cc-sessions.py (session sync on Windows)
theme/      extension, theme data, CSS, apply-theme.mjs
mods/       sync-apps: the /sync-apps command
assets/     instance colours and icons
docs/       how it works (en, vi, zh-CN)
```

## Limitations

- A Claude update can break this at any time; it relies on how Claude Desktop is built today.
- Themes are macOS only for now.
- Link routing guesses from window order: the Claude window you used last gets the link.
- Windows instances are unpackaged copies of the Store app; Store-only features (for example Cowork) are untested there.

## Credits

- Instance builder, session sync, link routers and the Windows port:
  [Multiple-Claude](https://github.com/dris1153/multiple-claude) by the Multiple-Claude contributors (MIT).
- Theme engine, colour themes and wallpapers:
  [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes) by 0toshigami (MIT).
- This fork adds per-instance themes, the star layer for Night Sea, deleted-session handling in the session merge,
  the Stop hook, `sync-claude-apps.sh` with the `/sync-apps` mod, and a macOS uninstaller.

"Claude" and the Claude logo are trademarks of Anthropic. The spark artwork is used only to tell instances apart.
The tool copies and re-signs the Claude app on your own machine and never redistributes it.

## License

[MIT](LICENSE). Files in `theme/` are under [theme/LICENSE](theme/LICENSE).
