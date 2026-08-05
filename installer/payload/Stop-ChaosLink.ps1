[CmdletBinding()]
param()

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $process = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"") `
        -Verb RunAs -WindowStyle Hidden -Wait -PassThru
    exit $process.ExitCode
}

$runtime = Join-Path $PSScriptRoot 'runtime'
foreach ($name in @('agent', 'tunnel', 'server')) {
    $pidFile = Join-Path $runtime "$name.pid"
    if (-not (Test-Path $pidFile)) { continue }
    $processId = [int](Get-Content $pidFile -Raw)
    Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}
Write-Host 'Chaos Link остановлен.'
