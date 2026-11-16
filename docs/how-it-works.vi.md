# Cách hoạt động

[English](how-it-works.md) · **Tiếng Việt** · [简体中文](how-it-works.zh-CN.md)

Claude Desktop là app Electron. Electron lưu toàn bộ trạng thái (đăng nhập, cài đặt, cache) trong một *thư mục
user data*, và flag `--user-data-dir` đổi thư mục đó sang chỗ khác. Mỗi bản clone đều là cùng app Claude, chỉ khác
thư mục dữ liệu. Phần còn lại giúp mỗi bản trông như một app riêng và giữ các tính năng dùng chung vẫn chạy.

## macOS

| Thành phần | Cơ chế | Cài vào |
|---|---|---|
| App | `macos/build-claude2.sh` tạo APFS clone của `/Applications/Claude.app` (không tốn thêm dung lượng), đặt bundle ID `local.claude-desktop-<N>`, tên và icon, thay executable bằng launcher, bỏ 3 entitlement chỉ dành cho Anthropic rồi ký lại (dùng chứng chỉ Apple Development nếu có, không thì ký ad hoc). | `/Applications/Claude <N>.app` |
| Launcher | Không cho mở hai lần trên cùng thư mục dữ liệu, dựng lại bản clone khi `Claude.app` đổi phiên bản, gộp session, bảo vệ manifest của Claude in Chrome, trả `claude://` về app gốc trong 60 giây đầu, rồi chạy Claude với `--user-data-dir` và `REACT_PROFILE=1`. | trong từng app |
| Chặn updater | File `~/Library/Caches/local.claude-desktop-<N>.ShipIt` chặn updater riêng của bản clone (bản tải về cũng không qua được kiểm tra chữ ký). Bản clone theo app gốc qua launcher. | `~/Library/Caches` |
| Gộp session | `macos/share-sessions.sh`, chạy từ launcher, hook `SessionStart` (sau 30 giây) và hook `Stop` (sau 5 giây). | `~/.claude/share-sessions.sh` |
| Mở lại app | `macos/sync-claude-apps.sh` thoát bình thường mọi app Claude đang chạy, chờ tối đa 120 giây, gộp session rồi mở lại. Mod `/sync-apps` gọi script này. | `~/.claude/sync-claude-apps.sh` |
| Theme | `theme/apply-theme.mjs` chép extension theme vào `<thư mục dữ liệu>/extensions/fmkadmapgofadopljbjfkapdkoienihi` và ghi `theme.json`. Extension đọc `theme.json` mỗi giây. `REACT_PROFILE=1`, chỉ launcher của bản clone đặt, làm Claude nạp extension. | `~/.claude-instances/theme`, `set-theme.sh` |
| Router link (tuỳ chọn) | Applet AppleScript giữ `claude://` và chuyển từng URL cho app Claude nằm trên cùng. Một LaunchAgent giành lại scheme mỗi khi một app Claude chiếm nó lúc khởi động. | `~/Applications/Claude Link Router.app` |

### Quy tắc gộp session

Claude Desktop lưu sidebar Code trong `<thư mục dữ liệu>/claude-code-sessions/<account>/<org>/` và chỉ đọc lúc khởi
động. `share-sessions.sh` gộp mọi thư mục như vậy của mọi app:

- Bản ghi có `lastActivityAt` mới nhất thắng, lấy nguyên bản ghi.
- Session chưa có `cliSessionId` (vừa tạo, chưa có title) ở yên trong app tạo ra nó cho tới khi có.
- `isArchived` giữ riêng từng app.
- File `deleted_<id>` mới hơn hoạt động cuối của session sẽ xoá session đó ở mọi nơi; bản ghi được chuyển vào
  `~/.claude/backups/deleted-sessions/<ngày>/`, không chép ngược lại.

Khi thoát bình thường, app ghi danh sách session trong bộ nhớ xuống đĩa và có thể đè lên bản đã gộp mới hơn. Vì vậy
`sync-claude-apps.sh` thoát app trước rồi mới gộp.

### Dựng lại icon

`assets/macos/claude<N>.car` được biên dịch từ tài liệu Icon Composer `claude<N>.icon` (bản sao `assets/spark.png`
trên nền gradient lấy từ `assets/palette.json`):

```bash
xcrun actool --compile out --platform macosx --minimum-deployment-target 11.0 --app-icon claude<N> \
  --output-partial-info-plist /dev/null assets/macos/claude<N>.icon
cp out/Assets.car assets/macos/claude<N>.car
```

`claude<N>.icns` là phương án dự phòng cho macOS cũ.

## Windows

| Thành phần | Cơ chế | Cài vào |
|---|---|---|
| App | `windows/build-instance.ps1` chép thư mục app Store (`WindowsApps\Claude_*\app`) và đổi icon trong `claude.exe` của bản chép (`set-exe-icon.ps1`). `.package-version` ghi phiên bản nguồn. | `%USERPROFILE%\.claude-instances\app-claude<N>` |
| Shortcut | `Claude <N>.lnk` trong Start Menu chạy bản chép với `--user-data-dir`. | Start Menu |
| Icon | `windows/make-icons.ps1` vẽ từng `.ico` từ `assets/palette.json` và `assets/spark.png`. | `%USERPROFILE%\.claude-instances\icons` |
| Cập nhật | Scheduled Task `claude-instances-refresh` (lúc đăng nhập và mỗi 30 phút) dựng lại các bản chép cũ hơn Claude đã cài, bỏ qua bản đang chạy. | Task Scheduler |
| Router link | `windows/claude-link-router.cs`, biên dịch lúc cài bằng `csc.exe` của .NET Framework. Nó tìm cửa sổ Claude trên cùng, đọc command line rồi mở đúng bản đó kèm URL. | `%USERPROFILE%\.claude-instances\claude-link-router.exe` |
| Đồng bộ session | `shared/restore-cc-sessions.py` chạy qua `pythonw`, Scheduled Task `claude-session-sync` mỗi phút. Script cũng thêm mục sidebar cho session chạy từ CLI trong terminal. | `%USERPROFILE%\.claude\bin` |

Package Store tự đăng ký `claude://` và được ưu tiên hơn `HKCU\Software\Classes\claude`, nên router đăng ký như một
app thường và bạn chọn nó trong **Default apps › Choose default apps by protocol**. Windows bảo vệ lựa chọn đó bằng
hash, script không đặt được.

## Xử lý sự cố

| Triệu chứng | Kiểm tra |
|---|---|
| Không thấy session từ app khác | Mở lại app hoặc chạy `/sync-apps`. Log macOS: `~/.claude/sync-claude-apps.log`. |
| Một bản vẫn ở phiên bản Claude cũ | macOS: mở nó một lần, nó tự dựng lại (log `~/.claude-instances/build-claude2.log`). Windows: thoát nó rồi chạy `install.cmd <N>`. |
| "Another Claude window is already using the data" | Một app dùng cùng thư mục dữ liệu vẫn đang chạy. Thoát nó. |
| Không thấy theme | Bản clone phải do bộ công cụ này dựng (launcher đặt `REACT_PROFILE=1`). Chạy `set-theme.sh <N> <theme>` rồi mở lại app một lần. |
| Đăng nhập hoặc callback MCP mở nhầm app | Cài router (`bash install.sh --router`), hoặc hoàn tất đăng nhập ngay trong app đã bắt đầu. |
