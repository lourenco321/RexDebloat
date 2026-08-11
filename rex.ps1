# =====================================================================
# Custom Windows 11 Debloat & Setup Script
# =====================================================================

# 1. Require Administrator Privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please restart PowerShell as Admin and try again."
    Pause
    Exit
}

Write-Host "Starting Custom Windows 11 Setup..." -ForegroundColor Cyan

# 2. Install Essential Software (Firefox & 7-Zip) via Winget
Write-Host "`n[1/4] Installing Firefox and 7-Zip..." -ForegroundColor Yellow
winget install --id Mozilla.Firefox -e --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip -e --accept-package-agreements --accept-source-agreements

# 3. Remove Microsoft Edge
Write-Host "`n[2/4] Removing Microsoft Edge..." -ForegroundColor Yellow
# Finds the hidden Edge setup.exe and forces an unattended system-level uninstall
$edgeSetup = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($edgeSetup) {
    Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --force-uninstall" -Wait -NoNewWindow
}

# 4. Windows 11 to Windows 10 Appearance (ExplorerPatcher)
Write-Host "`n[3/4] Installing ExplorerPatcher (Windows 10 Look)..." -ForegroundColor Yellow
$ep_url = "https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe"
$ep_path = "$env:TEMP\ep_setup.exe"
Write-Host "Downloading ExplorerPatcher..."
Invoke-WebRequest -Uri $ep_url -OutFile $ep_path
Write-Host "Installing silently..."
Start-Process -FilePath $ep_path -ArgumentList "/S" -Wait
Remove-Item -Path $ep_path -Force

# 5. Remove Major Bloat & Telemetry (Win11Debloat)
Write-Host "`n[4/4] Running Win11Debloat by Raphire..." -ForegroundColor Yellow
$Win11DebloatURL = "https://debloat.raphi.re/"
$DebloatScript = Invoke-RestMethod -Uri $Win11DebloatURL
& ([scriptblock]::Create($DebloatScript)) -RemoveApps -DisableTelemetry -Silent

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Setup Complete! A system reboot is highly recommended." -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
