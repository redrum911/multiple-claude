param([switch]$Purge)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'windows\config.ps1')

function Test-UnderRoot([string]$s) { $s -and $s.IndexOf($Root, [StringComparison]::OrdinalIgnoreCase) -ge 0 }

$running = Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -and $_.ExecutablePath.StartsWith("$Root\", 'OrdinalIgnoreCase') }
if ($running) { throw 'A Claude N instance is running; quit it from its tray icon and run again.' }

foreach ($t in $SyncTask, $RefreshTask) { Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue }

$shell = New-Object -ComObject WScript.Shell
$pinned = Join-Path $env:APPDATA 'Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar'
Get-ChildItem $StartMenu, $pinned -Filter 'Claude *.lnk' -ErrorAction SilentlyContinue | Where-Object {
    $l = $shell.CreateShortcut($_.FullName)
    (Test-UnderRoot $l.TargetPath) -or (Test-UnderRoot $l.Arguments)
} | Remove-Item -Force

$routerWasDefault = (Get-ItemProperty $UserChoiceKey -ErrorAction SilentlyContinue).ProgId -eq $RouterProgId
Remove-Item "HKCU:\Software\Classes\$RouterProgId", $RouterCapKey -Recurse -Force -ErrorAction SilentlyContinue
Remove-ItemProperty 'HKCU:\Software\RegisteredApplications' -Name $RouterName -ErrorAction SilentlyContinue

$cmd = { param($k) (Get-ItemProperty $k -ErrorAction SilentlyContinue).'(default)' }
foreach ($k in 'claude', 'Directory\shell\ClaudeCode', 'Directory\Background\shell\ClaudeCode') {
    $b = "HKCU:\Software\Classes\$k"
    if ((Test-UnderRoot (& $cmd "$b\shell\open\command")) -or (Test-UnderRoot (& $cmd "$b\command"))) { Remove-Item $b -Recurse -Force }
}
Get-ChildItem 'HKCU:\Software\Classes\CLSID' -ErrorAction SilentlyContinue |
    Where-Object { Test-UnderRoot (& $cmd "$($_.PSPath)\LocalServer32") } | Remove-Item -Recurse -Force

if (Test-Path $Root) {
    Get-ChildItem $Root -Directory -Filter 'app-claude*' | Remove-Item -Recurse -Force
    Remove-Item $IconDir -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($f in $RuntimeScripts + 'refresh.log', 'claude-link-router.exe') { Remove-Item (Join-Path $Root $f) -Force -ErrorAction SilentlyContinue }
}
Remove-Item (Join-Path $Bin 'restore-cc-sessions.py'), "$env:USERPROFILE\.claude\restore-cc-sessions.log",
    "$env:USERPROFILE\.claude\.restore-cc-sessions.lock", "$env:LOCALAPPDATA\claude-link-router.log" -Force -ErrorAction SilentlyContinue

if ($Purge -and (Test-Path $Root)) {
    $ok = Read-Host "Delete ALL instance data and sign-ins in $Root? [y/N]"
    if ($ok -match '^[yY]$') { Remove-Item $Root -Recurse -Force; Write-Output "Removed $Root" }
}
Write-Output 'Done: Multiple-Claude removed. Open the original Claude once to restore its Explorer menu entry.'
if ($routerWasDefault) {
    Write-Warning "claude:// links do nothing until you choose Claude again: Settings > Default apps > Choose default apps by protocol > CLAUDE."
    Start-Process 'ms-settings:defaultapps'
}
