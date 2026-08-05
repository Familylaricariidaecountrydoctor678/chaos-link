[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'payload'
$zip = Join-Path $dist 'payload.zip'
$output = Join-Path $dist 'ChaosLink-Setup.ps1'

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'app\server'), (Join-Path $stage 'app\agent'), (Join-Path $stage 'ahk'), (Join-Path $stage 'screamer\images'), (Join-Path $stage 'screamer\sounds') | Out-Null

Push-Location (Join-Path $root 'apps\web')
try { npm run build } finally { Pop-Location }
dotnet publish (Join-Path $root 'apps\server\ChaosLink.Server.csproj') -c Release -o (Join-Path $stage 'app\server') --no-self-contained
dotnet publish (Join-Path $root 'apps\agent\ChaosLink.Agent.csproj') -c Release -o (Join-Path $stage 'app\agent') --no-self-contained

Copy-Item (Join-Path $root 'ahk\Effects.ahk') (Join-Path $stage 'ahk\Effects.ahk') -Force
Copy-Item (Join-Path $root 'installer\payload\*.ps1') $stage -Force
Copy-Item (Join-Path $root 'screamer\images\README.md') (Join-Path $stage 'screamer\images\README.md') -Force
Copy-Item (Join-Path $root 'screamer\sounds\README.md') (Join-Path $stage 'screamer\sounds\README.md') -Force

$utf8Bom = [Text.UTF8Encoding]::new($true)
Get-ChildItem $stage -Filter *.ps1 | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    [IO.File]::WriteAllText($_.FullName, $content, $utf8Bom)
}

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zip -CompressionLevel Optimal
$base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($zip))
$template = Get-Content (Join-Path $root 'installer\ChaosLink-Setup.template.ps1') -Raw
if (-not $template.Contains('__CHAOS_LINK_PAYLOAD__')) { throw 'Payload placeholder отсутствует.' }
[IO.File]::WriteAllText($output, $template.Replace('__CHAOS_LINK_PAYLOAD__', $base64), $utf8Bom)
Write-Host "Готовый установщик: $output"
