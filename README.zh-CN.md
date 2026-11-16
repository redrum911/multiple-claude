<div align="center">

# multiple-claude

**同时运行多个 Claude Desktop，每个登录各自的账号。**

[English](README.md) · [Tiếng Việt](README.vi.md) · **简体中文**

![macOS](https://img.shields.io/badge/macOS-Apple%20silicon-black?logo=apple)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

</div>

> [!NOTE]
> 非官方社区工具，与 Anthropic 无关，也未获其认可。本项目是
> [Multiple-Claude](https://github.com/dris1153/multiple-claude)（MIT）的分支，主题来自
> [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes)（MIT）。见[致谢](#致谢)。

## 功能

- **原版旁边再开 Claude 2、3 … 10。** 每个实例有独立的登录、设置和数据。
- **每个实例一种颜色**，在 Dock、Cmd+Tab、任务栏和开始菜单中都能区分。
- **每个实例一个主题**（macOS）：16 个配色主题和动态壁纸，一眼看出当前是哪个账号。
- **共享 Claude Code 会话。** 在一个应用中开始的 Code 会话会出现在其他应用中。
- **一条命令同步**（macOS）：`/sync-apps` 重启所有 Claude 应用，让会话列表立即一致。
- **跟随 Claude 更新。** Claude 更新后实例会自动重建。
- **`claude://` 链接回到正确的应用**（可选链接路由器）：MCP 登录和魔法链接会回到你最近使用的应用。

## 要求

|                  | macOS                                   | Windows                                        |
| ---------------- | --------------------------------------- | ---------------------------------------------- |
| 系统             | Apple 芯片 Mac                          | Windows 10 / 11，x64                           |
| Claude           | `/Applications` 中的 `Claude.app`       | Microsoft Store 版 Claude Desktop（MSIX）      |
| 主题（可选）     | Node.js（`brew install node`）          | 暂不支持                                       |
| 会话同步         | 内置（`/usr/bin/python3`）              | Python 3（`winget install Python.Python.3.12`）|
| 每个实例占用空间 | 几乎为零（APFS 克隆）                   | 约 730 MB（完整复制应用）                      |

## 快速开始

### macOS

```bash
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
bash install.sh                 # Claude 2 和 Claude 3
bash install.sh --theme 2 3     # 同上，并使用各自的默认主题
```

从 `/Applications` 或启动台打开 **Claude 2**，用另一个账号登录。

### Windows

```powershell
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
.\install.cmd             # 或双击 install.cmd；构建 Claude 2 和 Claude 3
.\install.cmd 4 5         # 更多实例
```

安装程序会打开一次 **设置 › 应用 › 默认应用**。在 **按协议指定默认应用** 中，把 **CLAUDE** 设为
**Claude Link Router**。这一步只能由你手动完成，脚本无法代劳。

## 使用

### 实例（macOS）

```bash
bash install.sh 4 5             # 添加 Claude 4 和 Claude 5
bash install.sh --router 2 3    # 同时安装 claude:// 链接路由器
bash install.sh --help
```

可以放心重复运行。正在运行的实例不会被重建：先退出它（Cmd+Q）再运行。

### 主题（macOS）

可以在安装时选择主题，也可以随时更换。新主题一秒内生效，无需重启。

```bash
bash install.sh --theme 3=sakura 3          # 构建使用 Sakura 主题的 Claude 3
~/.claude-instances/set-theme.sh 2 moonlit  # 把 Claude 2 换成 Moonlit
~/.claude-instances/set-theme.sh 2 none     # 恢复 Claude 原本的外观
```

| 实例 | 默认主题 | | 配色主题 | 动态壁纸 |
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
| | | | | `snow-cabin`、`star-voyage` |

这里的 `night-sea` 在原主题上加了一层闪烁的星星。

### 会话

Claude Desktop 只在启动时读取 Code 会话列表，所以在其他应用中创建的会话，要重新打开当前应用后才会出现。在 macOS 上：

- 一个钩子会在会话开始 30 秒后、每次回复结束 5 秒后合并会话列表。
- `~/.claude/sync-claude-apps.sh`（或下面 mod 提供的 `/sync-apps`）会正常退出所有正在运行的 Claude 应用，合并后再重新打开。

`/sync-apps` 命令是 [`mods/sync-apps`](mods/sync-apps) 中的一个 Claude Code mod：

```bash
claude plugin marketplace add ./mods/sync-apps
claude plugin install sync-apps@multiple-claude
```

不要在两个应用中同时打开同一个会话：每个应用各自保存一份，最后退出的会覆盖另一份。

### 文件位置

|              | macOS                                                     | Windows                                                  |
| ------------ | --------------------------------------------------------- | -------------------------------------------------------- |
| 实例应用     | `/Applications/Claude <N>.app`                            | `%USERPROFILE%\.claude-instances\app-claude<N>`          |
| 数据与登录   | `~/.claude-instances/claude<N>`                           | `%USERPROFILE%\.claude-instances\claude<N>`              |
| 脚本与主题   | `~/.claude-instances/`、`~/.claude/share-sessions.sh`     | `%USERPROFILE%\.claude-instances\`、`%USERPROFILE%\.claude\bin` |
| 日志         | `~/.claude-instances/build-claude2.log`、`~/.claude/sync-claude-apps.log` | `%USERPROFILE%\.claude-instances\refresh.log` |

## 卸载

除非使用 purge，否则登录信息和实例数据都会保留。原版 Claude 应用不会被改动。

```bash
bash uninstall.sh --dry-run     # macOS：查看将删除的内容
bash uninstall.sh               # 加 --purge 同时删除实例数据
```

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1      # Windows；加 -Purge 删除实例数据
```

## 工作原理

Claude Desktop 是 Electron 应用，所有状态都保存在一个用户数据文件夹中。用 `--user-data-dir` 指向别处启动同一个应用，
就得到一个独立的登录。其余部分让每个实例看起来、用起来都像独立的应用。详见
[docs/how-it-works.zh-CN.md](docs/how-it-works.zh-CN.md)。

## 项目结构

```
install.sh / uninstall.sh       macOS
install.cmd / install.ps1       Windows
uninstall.ps1
macos/      实例构建、会话合并、重启应用、链接路由器、主题切换
windows/    复制应用、图标工具、链接路由器（C#）、更新任务
shared/     restore-cc-sessions.py（Windows 上的会话同步）
theme/      扩展、主题数据、CSS、apply-theme.mjs
mods/       sync-apps：/sync-apps 命令
assets/     实例颜色和图标
docs/       工作原理（en、vi、zh-CN）
```

## 限制

- Claude 的任何一次更新都可能让它失效，因为它依赖 Claude Desktop 目前的构建方式。
- 主题目前只支持 macOS。
- 链接路由按窗口顺序猜测：最近使用的 Claude 窗口会收到链接。
- Windows 实例是 Store 应用的非打包副本；仅 Store 版才有的功能（例如 Cowork）未经测试。

## 致谢

- 实例构建、会话同步、链接路由器和 Windows 版：
  Multiple-Claude contributors 的 [Multiple-Claude](https://github.com/dris1153/multiple-claude)（MIT）。
- 主题引擎、配色主题和动态壁纸：
  0toshigami 的 [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes)（MIT）。
- 本分支新增：按实例设置主题、Night Sea 的星星图层、合并会话时处理已删除的会话、Stop 钩子、
  `sync-claude-apps.sh` 和 `/sync-apps` mod，以及 macOS 卸载程序。

"Claude" 和 Claude 标志是 Anthropic 的商标。spark 图案仅用于区分实例。本工具只在你自己的电脑上复制并重新签名
Claude 应用，从不重新分发它。

## 许可证

[MIT](LICENSE)。`theme/` 中的文件适用 [theme/LICENSE](theme/LICENSE)。
