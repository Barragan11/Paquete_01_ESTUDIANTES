$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
Write-Host 'Abre http://localhost:7357 en tu Chrome habitual (sin modo incognito).'
Write-Host 'Para comprobar un reinicio, detén este servidor con Ctrl+C y vuelve a ejecutar este script.'
flutter run -d web-server --web-hostname localhost --web-port 7357
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
