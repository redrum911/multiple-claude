<div align="center">

# multiple-claude

**Chạy nhiều app Claude Desktop cùng lúc, mỗi app đăng nhập một tài khoản riêng.**

[English](README.md) · **Tiếng Việt** · [简体中文](README.zh-CN.md)

![macOS](https://img.shields.io/badge/macOS-Apple%20silicon-black?logo=apple)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![License: MIT](https://img.shields.io/badge/license-MIT-green)

</div>

> [!NOTE]
> Công cụ cộng đồng, không thuộc và không được Anthropic bảo trợ. Đây là bản fork của
> [Multiple-Claude](https://github.com/dris1153/multiple-claude) (MIT), dùng theme từ
> [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes) (MIT). Xem [Ghi công](#ghi-công).

## Tính năng

- **Claude 2, 3 … 10 chạy cạnh app gốc.** Mỗi bản có đăng nhập, cài đặt và dữ liệu riêng.
- **Mỗi bản một màu** trên Dock, Cmd+Tab, taskbar và Start Menu.
- **Mỗi bản một theme** (macOS): 16 theme màu và hình nền động, nhìn là biết đang ở tài khoản nào.
- **Dùng chung session Claude Code.** Session Code mở ở app này cũng hiện ở các app kia.
- **Đồng bộ bằng một lệnh** (macOS): `/sync-apps` mở lại mọi app Claude để danh sách session khớp ngay.
- **Tự theo bản cập nhật của Claude.** Các bản clone tự dựng lại khi Claude lên phiên bản mới.
- **Link `claude://` về đúng app** (router tuỳ chọn): đăng nhập MCP và magic link quay về app bạn vừa dùng.

## Yêu cầu

|                       | macOS                                  | Windows                                        |
| --------------------- | -------------------------------------- | ---------------------------------------------- |
| Hệ thống              | Mac chip Apple                         | Windows 10 / 11, x64                           |
| Claude                | `Claude.app` trong `/Applications`     | Claude Desktop từ Microsoft Store (MSIX)       |
| Theme (tuỳ chọn)      | Node.js (`brew install node`)          | chưa hỗ trợ                                    |
| Đồng bộ session       | có sẵn (`/usr/bin/python3`)            | Python 3 (`winget install Python.Python.3.12`) |
| Dung lượng mỗi bản    | gần như không tốn (APFS clone)         | khoảng 730 MB (chép cả app)                    |

## Bắt đầu nhanh

### macOS

```bash
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
bash install.sh                 # Claude 2 và Claude 3
bash install.sh --theme 2 3     # như trên, kèm theme mặc định của từng app
```

Mở **Claude 2** từ `/Applications` hoặc Launchpad rồi đăng nhập tài khoản khác.

### Windows

```powershell
git clone https://github.com/redrum911/multiple-claude.git
cd multiple-claude
.\install.cmd             # hoặc nhấp đúp install.cmd; dựng Claude 2 và Claude 3
.\install.cmd 4 5         # thêm bản
```

Một lần duy nhất, trình cài mở **Settings › Apps › Default apps**. Ở mục **Choose default apps by protocol**, chọn
**Claude Link Router** cho **CLAUDE**. Windows chỉ cho bạn tự chọn, script không làm thay được.

## Sử dụng

### Các bản Claude (macOS)

```bash
bash install.sh 4 5             # thêm Claude 4 và Claude 5
bash install.sh --router 2 3    # cài thêm router cho link claude://
bash install.sh --help
```

Chạy lại bao nhiêu lần cũng được. Bản đang mở thì không dựng lại được: thoát nó (Cmd+Q) rồi chạy lại.

### Theme (macOS)

Chọn theme lúc cài hoặc đổi bất cứ lúc nào. Theme mới hiện trong vòng một giây, không cần mở lại app.

```bash
bash install.sh --theme 3=sakura 3          # dựng Claude 3 với theme Sakura
~/.claude-instances/set-theme.sh 2 moonlit  # đổi Claude 2 sang Moonlit
~/.claude-instances/set-theme.sh 2 none     # về giao diện gốc của Claude
```

| Bản | Theme mặc định | | Theme màu | Hình nền động |
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

`night-sea` ở đây có thêm một lớp sao nhấp nháy so với theme gốc.

### Session

Claude Desktop chỉ đọc danh sách session Code lúc khởi động, nên session tạo ở app khác chỉ hiện sau khi mở lại app
đang xem. Trên macOS:

- Một hook gộp danh sách session 30 giây sau khi mở session và 5 giây sau mỗi lượt trả lời.
- `~/.claude/sync-claude-apps.sh` (hoặc `/sync-apps` qua mod bên dưới) thoát bình thường mọi app Claude đang chạy,
  gộp session rồi mở lại.

Lệnh `/sync-apps` là một mod Claude Code trong [`mods/sync-apps`](mods/sync-apps):

```bash
claude plugin marketplace add ./mods/sync-apps
claude plugin install sync-apps@multiple-claude
```

Đừng mở cùng một session ở hai app một lúc: mỗi app giữ một bản riêng và app thoát sau cùng sẽ ghi đè.

### Vị trí file

|                  | macOS                                                     | Windows                                                  |
| ---------------- | --------------------------------------------------------- | -------------------------------------------------------- |
| App              | `/Applications/Claude <N>.app`                            | `%USERPROFILE%\.claude-instances\app-claude<N>`          |
| Dữ liệu, đăng nhập | `~/.claude-instances/claude<N>`                         | `%USERPROFILE%\.claude-instances\claude<N>`              |
| Script, theme    | `~/.claude-instances/`, `~/.claude/share-sessions.sh`     | `%USERPROFILE%\.claude-instances\`, `%USERPROFILE%\.claude\bin` |
| Log              | `~/.claude-instances/build-claude2.log`, `~/.claude/sync-claude-apps.log` | `%USERPROFILE%\.claude-instances\refresh.log` |

## Gỡ cài đặt

Đăng nhập và dữ liệu của các bản được giữ lại nếu không purge. App Claude gốc không bị đụng tới.

```bash
bash uninstall.sh --dry-run     # macOS: xem sẽ xoá những gì
bash uninstall.sh               # thêm --purge để xoá cả dữ liệu các bản
```

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1      # Windows; thêm -Purge để xoá dữ liệu
```

## Cách hoạt động

Claude Desktop là app Electron, toàn bộ trạng thái nằm trong một thư mục user data. Mở cùng app đó với
`--user-data-dir` trỏ sang chỗ khác là có một phiên đăng nhập riêng. Phần còn lại của bộ công cụ giúp mỗi bản trông
và chạy như một app riêng. Chi tiết: [docs/how-it-works.vi.md](docs/how-it-works.vi.md).

## Cấu trúc

```
install.sh / uninstall.sh       macOS
install.cmd / install.ps1       Windows
uninstall.ps1
macos/      dựng bản clone, gộp session, mở lại app, router link, đổi theme
windows/    chép app, công cụ icon, router link (C#), task cập nhật
shared/     restore-cc-sessions.py (đồng bộ session trên Windows)
theme/      extension, dữ liệu theme, CSS, apply-theme.mjs
mods/       sync-apps: lệnh /sync-apps
assets/     màu và icon từng bản
docs/       cách hoạt động (en, vi, zh-CN)
```

## Giới hạn

- Một bản cập nhật của Claude có thể làm hỏng công cụ bất cứ lúc nào, vì nó dựa vào cách Claude Desktop được dựng hiện nay.
- Theme hiện chỉ có trên macOS.
- Router đoán app đích theo thứ tự cửa sổ: cửa sổ Claude dùng gần nhất nhận link.
- Bản trên Windows là bản chép không đóng gói của app Store; các tính năng chỉ có ở bản Store (ví dụ Cowork) chưa được thử.

## Ghi công

- Phần dựng bản clone, đồng bộ session, router link và bản Windows:
  [Multiple-Claude](https://github.com/dris1153/multiple-claude) của Multiple-Claude contributors (MIT).
- Engine theme, theme màu và hình nền động:
  [claude-desktop-themes](https://github.com/0toshigami/claude-desktop-themes) của 0toshigami (MIT).
- Bản fork này thêm theme cho từng bản, lớp sao cho Night Sea, xử lý session đã xoá khi gộp, hook Stop,
  `sync-claude-apps.sh` cùng mod `/sync-apps`, và trình gỡ cài đặt cho macOS.

"Claude" và logo Claude là thương hiệu của Anthropic. Hình spark chỉ dùng để phân biệt các bản. Công cụ chép và ký
lại app Claude ngay trên máy bạn, không phân phối lại app.

## Giấy phép

[MIT](LICENSE). Các file trong `theme/` theo [theme/LICENSE](theme/LICENSE).
