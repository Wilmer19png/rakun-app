# RAKÜN Gestor · preparar Windows para Flutter/Android (requiere ADMINISTRADOR)
# Activa:
#   1. Modo desarrollador (lo piden los plugins de Flutter para crear enlaces simbólicos).
#   2. Plataforma del hipervisor de Windows (WHPX), para que el emulador Android
#      use aceleración por hardware. Además hay que activar SVM Mode en la BIOS.
# Cómo correrlo: clic derecho en el menú Inicio → "Terminal (administrador)" y pegar:
#   powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\wburi\rakun-app\herramientas\preparar_windows.ps1
# Después: reiniciar el equipo (y en ese reinicio entrar a la BIOS a activar SVM).

$log = 'C:\Users\wburi\rakun-app\herramientas\preparar_windows.log'
Start-Transcript -Path $log -Force

reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' /t REG_DWORD /f /v AllowDevelopmentWithoutDevLicense /d 1

Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart |
  Select-Object Online, RestartNeeded

Get-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform |
  Select-Object FeatureName, State

Write-Host ''
Write-Host 'Listo. Ahora reinicia el equipo y entra a la BIOS para activar SVM Mode.' -ForegroundColor Green
Stop-Transcript
