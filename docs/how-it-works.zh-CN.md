# 工作原理

[English](how-it-works.md) · [Tiếng Việt](how-it-works.vi.md) · **简体中文**

Claude Desktop 是 Electron 应用。Electron 把所有状态（登录、设置、缓存）保存在一个*用户数据文件夹*中，
`--user-data-dir` 参数可以把它换到别处。每个实例都是同一个 Claude 应用，只是使用各自的数据文件夹启动。
其余部分让每个实例看起来像独立的应用，并让共享功能继续可用。

## macOS

| 组件 | 机制 | 安装位置 |
|---|---|---|
| 实例应用 | `macos/build-claude2.sh` 对 `/Applications/Claude.app` 做 APFS 克隆（几乎不占额外空间），设置 bundle ID `local.claude-desktop-<N>`、名称和图标，把可执行文件换成启动器，去掉三个仅限 Anthropic 的 entitlement 后重新签名（有 Apple Development 证书就用它，否则 ad hoc 签名）。 | `/Applications/Claude <N>.app` |
| 启动器 | 禁止在同一数据文件夹上打开两次；`Claude.app` 版本变化时重建实例；合并会话；保护 Claude in Chrome 的 manifest；启动后 60 秒内把 `claude://` 交还给原版应用；然后以 `--user-data-dir` 和 `REACT_PROFILE=1` 运行 Claude。 | 每个实例内部 |
| 阻止更新器 | `~/Library/Caches/local.claude-desktop-<N>.ShipIt` 文件阻止实例自带的更新器（下载的更新本来也通不过签名检查）。实例通过启动器跟随原版应用。 | `~/Library/Caches` |
| 会话合并 | `macos/share-sessions.sh`，由每个启动器、`SessionStart` 钩子（30 秒后）和 `Stop` 钩子（5 秒后）运行。 | `~/.claude/share-sessions.sh` |
| 重启应用 | `macos/sync-claude-apps.sh` 正常退出所有正在运行的 Claude 应用，最多等待 120 秒，合并后重新打开。`/sync-apps` mod 调用它。 | `~/.claude/sync-claude-apps.sh` |
| 主题 | `theme/apply-theme.mjs` 把主题扩展复制到 `<数据文件夹>/extensions/fmkadmapgofadopljbjfkapdkoienihi` 并写入 `theme.json`。扩展每秒读取一次 `theme.json`。只有实例启动器会设置 `REACT_PROFILE=1`，让 Claude 加载该扩展。 | `~/.claude-instances/theme`、`set-theme.sh` |
| 链接路由器（可选） | 一个 AppleScript 小程序接管 `claude://`，把每个 URL 交给最前面的 Claude 应用。一个 LaunchAgent 会在任何 Claude 应用启动时抢走协议后把它夺回。 | `~/Applications/Claude Link Router.app` |

### 会话合并规则

Claude Desktop 把 Code 侧边栏保存在 `<数据文件夹>/claude-code-sessions/<account>/<org>/`，并且只在启动时读取。
`share-sessions.sh` 合并所有应用中的这些文件夹：

- `lastActivityAt` 最新的记录整体胜出。
- 还没有 `cliSessionId` 的会话（刚创建、没有标题）在获得它之前只留在创建它的应用中。
- `isArchived` 按应用各自保留。
- 比会话最后活动时间更新的 `deleted_<id>` 文件会在所有地方删除该会话；记录被移到
  `~/.claude/backups/deleted-sessions/<日期>/`，不会被复制回来。

应用正常退出时会把内存中的会话列表写回磁盘，可能覆盖较新的合并结果。所以 `sync-claude-apps.sh` 先退出应用再合并。

### 重新生成图标

`assets/macos/claude<N>.car` 由 Icon Composer 文档 `claude<N>.icon` 编译而成（`assets/spark.png` 的副本，
背景渐变取自 `assets/palette.json`）：

```bash
xcrun actool --compile out --platform macosx --minimum-deployment-target 11.0 --app-icon claude<N> \
  --output-partial-info-plist /dev/null assets/macos/claude<N>.icon
cp out/Assets.car assets/macos/claude<N>.car
```

`claude<N>.icns` 是旧版 macOS 的后备图标。

## Windows

| 组件 | 机制 | 安装位置 |
|---|---|---|
| 实例应用 | `windows/build-instance.ps1` 复制 Store 应用文件夹（`WindowsApps\Claude_*\app`），并修改副本中 `claude.exe` 的图标资源（`set-exe-icon.ps1`）。`.package-version` 记录源版本。 | `%USERPROFILE%\.claude-instances\app-claude<N>` |
| 快捷方式 | 开始菜单中的 `Claude <N>.lnk` 以 `--user-data-dir` 运行副本。 | 开始菜单 |
| 图标 | `windows/make-icons.ps1` 根据 `assets/palette.json` 和 `assets/spark.png` 绘制每个 `.ico`。 | `%USERPROFILE%\.claude-instances\icons` |
| 更新 | 计划任务 `claude-instances-refresh`（登录时及每 30 分钟）重建比已安装 Claude 旧的副本，跳过正在运行的。 | 任务计划程序 |
| 链接路由器 | `windows/claude-link-router.cs`，安装时用 .NET Framework 的 `csc.exe` 编译。它找到最前面的 Claude 窗口，读取其命令行，并带着 URL 启动该实例。 | `%USERPROFILE%\.claude-instances\claude-link-router.exe` |
| 会话同步 | `shared/restore-cc-sessions.py` 通过 `pythonw` 运行，计划任务 `claude-session-sync` 每分钟一次。它还会为终端 CLI 中运行的会话添加侧边栏条目。 | `%USERPROFILE%\.claude\bin` |

Store 包会自行注册 `claude://`，并优先于 `HKCU\Software\Classes\claude`，所以路由器以普通应用身份注册，
由你在 **默认应用 › 按协议指定默认应用** 中选择它。Windows 用哈希保护这个选择，脚本无法设置。

## 故障排除

| 现象 | 检查 |
|---|---|
| 看不到其他应用的会话 | 重新打开应用，或运行 `/sync-apps`。macOS 日志：`~/.claude/sync-claude-apps.log`。 |
| 实例停留在旧版 Claude | macOS：打开一次即可自动重建（日志 `~/.claude-instances/build-claude2.log`）。Windows：退出它并运行 `install.cmd <N>`。 |
| "Another Claude window is already using the data" | 使用同一数据文件夹的应用仍在运行。退出它。 |
| 主题没有显示 | 实例必须由本工具构建（启动器会设置 `REACT_PROFILE=1`）。运行 `set-theme.sh <N> <theme>` 并重新打开应用一次。 |
| 登录或 MCP 回调打开了错误的应用 | 安装路由器（`bash install.sh --router`），或在发起登录的应用中完成登录。 |
