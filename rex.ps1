# =====================================================================
# Custom Windows 11 Debloat & Setup Script - V8 (Extended)
# =====================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Pause
    Exit
}

Write-Host "Starting Custom Windows 11 Setup..." -ForegroundColor Cyan

# 1. Install Essential Software
Write-Host "`n[1/6] Installing Firefox and 7-Zip..." -ForegroundColor Yellow
winget install --id Mozilla.Firefox -e --accept-package-agreements --accept-source-agreements
winget install --id 7zip.7zip -e --accept-package-agreements --accept-source-agreements

# 2. Run Win11Debloat
Write-Host "`n[2/6] Running Win11Debloat by Raphire..." -ForegroundColor Yellow
$Win11DebloatURL = "https://debloat.raphi.re/"
$DebloatScript = Invoke-RestMethod -Uri $Win11DebloatURL
& ([scriptblock]::Create($DebloatScript)) -RemoveApps -DisableTelemetry -Silent

# 3. Windows 11 to Windows 10 Appearance
Write-Host "`n[3/6] Applying Windows 10 Appearance Tweaks..." -ForegroundColor Yellow
$contextMenuPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
if (!(Test-Path $contextMenuPath)) { New-Item -Path $contextMenuPath -Force | Out-Null }
Set-ItemProperty -Path $contextMenuPath -Name "(Default)" -Value "" -Force | Out-Null

$taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
if (!(Test-Path $taskbarPath)) { New-Item -Path $taskbarPath -Force | Out-Null }
Set-ItemProperty -Path $taskbarPath -Name "TaskbarAl" -Value 0 -Force | Out-Null

$personalizePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
if (!(Test-Path $personalizePath)) { New-Item -Path $personalizePath -Force | Out-Null }
Set-ItemProperty -Path $personalizePath -Name "SystemUsesLightTheme" -Value 0 
Set-ItemProperty -Path $personalizePath -Name "AppsUseLightTheme" -Value 0 
Set-ItemProperty -Path $personalizePath -Name "EnableTransparency" -Value 1 
Set-ItemProperty -Path $personalizePath -Name "ColorPrevalence" -Value 1 

$dwmPath = "HKCU:\SOFTWARE\Microsoft\Windows\DWM"
if (!(Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force | Out-Null }
Set-ItemProperty -Path $dwmPath -Name "ColorPrevalence" -Value 1

# 4. Quality of Life Tweaks (Explorer, Taskbar, Silent Installs)
Write-Host "`n[4/6] Applying Quality of Life Tweaks..." -ForegroundColor Yellow
$contentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (!(Test-Path $contentDelivery)) { New-Item -Path $contentDelivery -Force | Out-Null }
Set-ItemProperty -Path $contentDelivery -Name "SilentInstalledAppsEnabled" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $contentDelivery -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force | Out-Null

$explorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerAdvanced -Name "LaunchTo" -Value 1 -Force | Out-Null
Set-ItemProperty -Path $explorerAdvanced -Name "TaskbarDa" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $explorerAdvanced -Name "Start_TrackDocs" -Value 0 -Force | Out-Null

$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (!(Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Value 0 -Force | Out-Null

$galleryPath = "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
if (!(Test-Path $galleryPath)) { New-Item -Path $galleryPath -Force | Out-Null }
Set-ItemProperty -Path $galleryPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force | Out-Null

# 5. Remove Microsoft OneDrive
Write-Host "`n[5/6] Removing Microsoft OneDrive..." -ForegroundColor Yellow
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
$oneDriveSetup = "$env:systemroot\SysWOW64\OneDriveSetup.exe"
if (!(Test-Path $oneDriveSetup)) { $oneDriveSetup = "$env:systemroot\System32\OneDriveSetup.exe" }
if (Test-Path $oneDriveSetup) {
    Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow
}
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue

# 6. Remove Microsoft Edge
Write-Host "`n[6/6] Removing Microsoft Edge..." -ForegroundColor Yellow
$forceRemove = $true
$edgeSetup = Get-ChildItem -Path "C:\Program Files (x86)\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1

if ($edgeSetup) {
    $process = Start-Process -FilePath $edgeSetup.FullName -ArgumentList "--uninstall --system-level --force-uninstall" -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -eq 0) {
        $forceRemove = $false
    }
}

if ($forceRemove) {
    Get-Process -Name "msedge" -ErrorAction SilentlyContinue | Stop-Process -Force
    
    $edgePaths = @(
        "C:\Program Files (x86)\Microsoft\Edge\Application",
        "C:\Program Files (x86)\Microsoft\EdgeCore"
    )
    
    foreach ($path in $edgePaths) {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    
    $regPath = "HKLM:\SOFTWARE\Microsoft\EdgeUpdate"
    if (!(Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }
    New-ItemProperty -Path $regPath -Name "DoNotUpdateToEdgeWithChromium" -Value 1 -PropertyType DWord -Force | Out-Null
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Setup Complete! Please restart your PC to apply all changes." -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
