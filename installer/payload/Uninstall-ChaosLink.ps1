[CmdletBinding()]
param()

$answer = Read-Host 'Удалить Chaos Link, настройки и скримеры? Введите DELETE'
if ($answer -ne 'DELETE') { Write-Host 'Отменено.'; exit }
if (-not (Test-Path (Join-Path $PSScriptRoot '.chaos-link-install'))) {
    throw 'Защитная метка установки отсутствует. Папка не будет удалена автоматически.'
}
& (Join-Path $PSScriptRoot 'Stop-ChaosLink.ps1')

$desktop = [Environment]::GetFolderPath('Desktop')
foreach ($name in @('Chaos Link - Запустить.lnk', 'Chaos Link - Остановить.lnk', 'Chaos Link - Удалить.lnk')) {
    Remove-Item (Join-Path $desktop $name) -Force -ErrorAction SilentlyContinue
}
$cleanupScript = Join-Path $env:TEMP ("ChaosLinkCleanup-" + [Guid]::NewGuid().ToString('N') + '.ps1')
$cleanup = @'
param([int]$ParentPid, [string]$InstallRoot, [string]$CleanupScript)
Wait-Process -Id $ParentPid -ErrorAction SilentlyContinue
if (Test-Path (Join-Path $InstallRoot '.chaos-link-install')) {
    Remove-Item -LiteralPath $InstallRoot -Recurse -Force
}
Remove-Item -LiteralPath $CleanupScript -Force -ErrorAction SilentlyContinue
'@
Set-Content $cleanupScript $cleanup -Encoding utf8
Start-Process powershell.exe -WindowStyle Hidden -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$cleanupScript`"",
    '-ParentPid', $PID, '-InstallRoot', "`"$PSScriptRoot`"", '-CleanupScript', "`"$cleanupScript`""
) | Out-Null
Write-Host 'Chaos Link остановлен. Папка установки и ярлыки будут удалены после закрытия окна.'
