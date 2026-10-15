$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
flutter create . --project-name nexasoft_incidencias --platforms android,web,windows
flutter pub get
Write-Host 'Preparación terminada. Ejecuta flutter devices y flutter run -d web-server --web-hostname localhost --web-port 7357; abre http://localhost:7357 en tu navegador habitual'
