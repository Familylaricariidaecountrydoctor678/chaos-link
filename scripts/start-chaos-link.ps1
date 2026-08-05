[CmdletBinding()]
param(
    [int]$Port = 5075,
    [string]$BindAddress = '0.0.0.0',
    [switch]$SkipAgent
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$deployRoot = Join-Path $projectRoot 'deploy'
$runtimeRoot = Join-Path $projectRoot '.runtime'
$serverDll = Join-Path $deployRoot 'server\ChaosLink.Server.dll'

if (-not (Test-Path -LiteralPath $serverDll)) {
    throw 'Deploy-сборка не найдена. Сначала запустите scripts\publish-chaos-link.ps1.'
}

New-Item -ItemType Directory -Force -Path $runtimeRoot | Out-Null

$portProbe = [Net.Sockets.TcpClient]::new()
try {
    $connectTask = $portProbe.ConnectAsync('127.0.0.1', $Port)
    if ($connectTask.Wait(300) -and $portProbe.Connected) {
        throw "Порт $Port уже занят. Остановите текущий процесс или выберите другой порт."
    }
} catch [AggregateException] {
    # Connection refused means the port is available.
} finally {
    $portProbe.Dispose()
}

$serverOut = Join-Path $runtimeRoot 'server.out.log'
$serverErr = Join-Path $runtimeRoot 'server.err.log'
$server = Start-Process -FilePath 'dotnet' `
    -ArgumentList "`"$serverDll`"", '--urls', "http://${BindAddress}:$Port" `
    -WorkingDirectory (Join-Path $deployRoot 'server') `
    -WindowStyle Hidden `
    -RedirectStandardOutput $serverOut `
    -RedirectStandardError $serverErr `
    -PassThru

Set-Content -LiteralPath (Join-Path $runtimeRoot 'server.pid') -Value $server.Id -Encoding ascii

Start-Sleep -Seconds 1
if ($server.HasExited) {
    $details = Get-Content -LiteralPath $serverErr -Raw -ErrorAction SilentlyContinue
    throw "Chaos Link server не запустился. $details"
}
$health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/health" -TimeoutSec 5

if (-not $SkipAgent) {
    & (Join-Path $PSScriptRoot 'start-agent-admin.ps1') -Port $Port
    $agentPid = [int](Get-Content -LiteralPath (Join-Path $runtimeRoot 'agent.pid') -Raw)
    $agent = Get-Process -Id $agentPid -ErrorAction SilentlyContinue
    if (-not $agent) {
        Stop-Process -Id $server.Id -ErrorAction SilentlyContinue
        $details = Get-Content -LiteralPath (Join-Path $runtimeRoot 'agent.err.log') -Raw -ErrorAction SilentlyContinue
        throw "Chaos Link Agent не запустился. $details"
    }
}

Write-Host "Chaos Link запущен: http://127.0.0.1:$Port"
Write-Host "Локальная сеть: http://<IP-этого-компьютера>:$Port"
Write-Host "Reverse proxy upstream: http://127.0.0.1:$Port"
Write-Host "Комната: $($health.room)"
