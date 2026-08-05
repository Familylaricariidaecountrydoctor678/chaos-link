[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$webRoot = Join-Path $projectRoot 'apps\web'
$deployRoot = Join-Path $projectRoot 'deploy'
$runtimeRoot = Join-Path $projectRoot '.runtime'

Push-Location $webRoot
try {
    npm run build
} finally {
    Pop-Location
}

dotnet publish (Join-Path $projectRoot 'apps\server\ChaosLink.Server.csproj') -c Release -o (Join-Path $deployRoot 'server') --no-self-contained
dotnet publish (Join-Path $projectRoot 'apps\agent\ChaosLink.Agent.csproj') -c Release -o (Join-Path $deployRoot 'agent') --no-self-contained

New-Item -ItemType Directory -Force -Path (Join-Path $deployRoot 'ahk'), (Join-Path $deployRoot 'screamer\images'), (Join-Path $deployRoot 'screamer\sounds'), $runtimeRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'ahk\Effects.ahk') -Destination (Join-Path $deployRoot 'ahk\Effects.ahk') -Force

$controllerToken = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(18)).ToLowerInvariant()
$adminToken = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(18)).ToLowerInvariant()
$agentToken = [Convert]::ToHexString([Security.Cryptography.RandomNumberGenerator]::GetBytes(24)).ToLowerInvariant()

$serverConfig = @{
    ChaosLink = @{
        RoomCode = 'K7M2'
        ControllerToken = $controllerToken
        AdminToken = $adminToken
        AgentToken = $agentToken
        ExecutionLeadMs = 250
    }
} | ConvertTo-Json -Depth 4
Set-Content -LiteralPath (Join-Path $deployRoot 'server\appsettings.Production.json') -Value $serverConfig -Encoding utf8

$autoHotkeyPath = Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'
$agentConfig = @{
    ServerUrl = 'ws://127.0.0.1:5075/ws'
    RoomCode = 'K7M2'
    AgentName = 'Игровой ПК'
    AgentToken = $agentToken
    AutoHotkeyPath = $autoHotkeyPath
    EffectsScript = '..\ahk\Effects.ahk'
    ScreamerSoundsPath = '..\screamer\sounds'
    ScreamerImagesPath = '..\screamer\images'
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $deployRoot 'agent\appsettings.json') -Value $agentConfig -Encoding utf8

$accessInfo = @{
    RoomCode = 'K7M2'
    ControllerToken = $controllerToken
    AdminToken = $adminToken
    LocalUrl = 'http://127.0.0.1:5075'
    ReverseProxyUpstream = 'http://127.0.0.1:5075'
} | ConvertTo-Json
Set-Content -LiteralPath (Join-Path $runtimeRoot 'access.json') -Value $accessInfo -Encoding utf8

Write-Host 'Deploy-сборка готова.'
Write-Host "Код комнаты: K7M2"
Write-Host "Ключ друзей: $controllerToken"
Write-Host "Ключ администратора: $adminToken"
Write-Host "Настройки сохранены в .runtime\access.json"
