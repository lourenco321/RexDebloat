# =====================================================================
# Custom Windows 11 Debloat & Setup Script - DEBUG VERSION
# =====================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please restart PowerShell as Admin and try again."
    Pause
    Exit
}

Write-Host "Starting Custom Windows 11 Setup (Debug Mode)..." -ForegroundColor Cyan

# 2. Install Essential Software (Firefox & 7-Zip) via Winget
Write-Host "`n[1/4] Installing Firefox and 7-Zip..." -ForegroundColor Yellow
winget install --id Mozilla.Firefox -e --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip -e --accept-package-agreements --accept-source-agreements

# 3. Remove Microsoft Edge (Verbose)
Write-Host "`n[2/4] Removing Microsoft Edge..." -ForegroundColor Yellow
try {
    Write-Host "Searching for Edge setup.exe..." -ForegroundColor Cyan
    # Removed SilentlyContinue so errors show up
    $edgeSetup = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction Stop | Select-Object -First 1
    
    if ($edgeSetup) {
        Write-Host "Found Edge installer at: $($edgeSetup.FullName)" -ForegroundColor Green
        Write-Host "Attempting uninstall..." -ForegroundColor Cyan
        
        # Added -PassThru to capture the exit code, removed -NoNewWindow so you can see if it throws a popup
        $process = Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --force-uninstall" -Wait -PassThru
        
        Write-Host "Edge uninstaller exited with code: $($process.ExitCode)" -ForegroundColor Cyan
    } else {
        Write-Host "Could not find Edge installer on this system." -ForegroundColor Red
    }
} catch {
    Write-Host "ERROR during Edge removal: $_" -ForegroundColor Red
}

# 4. Windows 11 to Windows 10 Appearance (ExplorerPatcher)
Write-Host "`n[3/4] Installing ExplorerPatcher (Windows 10 Look)..." -ForegroundColor Yellow
$ep_url = "https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe"
$ep_path = "$env:TEMP\ep_setup.exe"
Invoke-WebRequest -Uri $ep_url -OutFile $ep_path
Start-Process -FilePath $ep_path -ArgumentList "/S" -Wait
Remove-Item -Path $ep_path -Force

# 5. Remove Major Bloat & Telemetry (Win11Debloat)
Write-Host "`n[4/4] Running Win11Debloat by Raphire..." -ForegroundColor Yellow
try {
    Write-Host "Downloading Win11Debloat..." -ForegroundColor Cyan
    $Win11DebloatURL = "https://debloat.raphi.re/"
    $DebloatScript = Invoke-RestMethod -Uri $Win11DebloatURL -ErrorAction Stop
    
    Write-Host "Executing Win11Debloat (Silent mode disabled to show errors)..." -ForegroundColor Cyan
    # Removed -Silent so you can see exactly where it gets stuck
    & ([scriptblock]::Create($DebloatScript)) -RemoveApps -DisableTelemetry
} catch {
    Write-Host "ERROR during Win11Debloat: $_" -ForegroundColor Red
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Debug Setup Complete! Please copy the output above." -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
