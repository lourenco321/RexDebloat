# =====================================================================
# Custom Windows 11 Debloat & Setup Script - V18 (Finaly FREEEEEE!)
# =====================================================================

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges."
    Pause
    Exit
}

Write-Host "Starting Custom Windows 11 Setup..." -ForegroundColor Cyan

# 1. Install Essential Software & Apps
Write-Host "`n[1/9] Installing Essential Software..." -ForegroundColor Yellow
$machineApps = @(
    "Mozilla.Firefox",
    "7zip.7zip",
    "Discord.Discord",
    "Valve.Steam",
    "Microsoft.VCRedist.2015+.x64"
)
foreach ($app in $machineApps) {
    winget install --id $app -e --accept-package-agreements --accept-source-agreements
}


# 2. Run Win11Debloat
Write-Host "`n[2/9] Running Win11Debloat by Raphire..." -ForegroundColor Yellow
$Win11DebloatURL = "https://debloat.raphi.re/"
$DebloatScript = Invoke-RestMethod -Uri $Win11DebloatURL
& ([scriptblock]::Create($DebloatScript)) -RemoveApps -DisableTelemetry -Silent

# 3. Windows 11 to Windows 10 Appearance
Write-Host "`n[3/9] Applying Windows 10 Appearance Tweaks..." -ForegroundColor Yellow
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

# 4. Quality of Life Tweaks
Write-Host "`n[4/9] Applying Quality of Life Tweaks..." -ForegroundColor Yellow
$contentDelivery = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (!(Test-Path $contentDelivery)) { New-Item -Path $contentDelivery -Force | Out-Null }
Set-ItemProperty -Path $contentDelivery -Name "SilentInstalledAppsEnabled" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $contentDelivery -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force | Out-Null

$explorerAdvanced = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $explorerAdvanced -Name "LaunchTo" -Value 1 -Force | Out-Null
Set-ItemProperty -Path $explorerAdvanced -Name "Start_TrackDocs" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $explorerAdvanced -Name "HideFileExt" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $explorerAdvanced -Name "ShowTaskViewButton" -Value 0 -Force | Out-Null

$dshPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (!(Test-Path $dshPolicy)) { New-Item -Path $dshPolicy -Force | Out-Null }
Set-ItemProperty -Path $dshPolicy -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force | Out-Null

$searchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
if (!(Test-Path $searchPath)) { New-Item -Path $searchPath -Force | Out-Null }
Set-ItemProperty -Path $searchPath -Name "SearchboxTaskbarMode" -Value 0 -Force | Out-Null

$galleryPath = "HKCU:\Software\Classes\CLSID\{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
if (!(Test-Path $galleryPath)) { New-Item -Path $galleryPath -Force | Out-Null }
Set-ItemProperty -Path $galleryPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force | Out-Null

$mousePath = "HKCU:\Control Panel\Mouse"
Set-ItemProperty -Path $mousePath -Name "MouseSpeed" -Value "0" -Force | Out-Null
Set-ItemProperty -Path $mousePath -Name "MouseThreshold1" -Value "0" -Force | Out-Null
Set-ItemProperty -Path $mousePath -Name "MouseThreshold2" -Value "0" -Force | Out-Null

$taskbandPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
if (Test-Path $taskbandPath) { Remove-Item -Path $taskbandPath -Recurse -Force -ErrorAction SilentlyContinue }

$explorerMain = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer"
Set-ItemProperty -Path $explorerMain -Name "EnableAutoTray" -Value 0 -Force | Out-Null

$explorerPolicy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
if (!(Test-Path $explorerPolicy)) { New-Item -Path $explorerPolicy -Force | Out-Null }
Set-ItemProperty -Path $explorerPolicy -Name "HideSCANetwork" -Value 0 -Type DWord -Force | Out-Null
Set-ItemProperty -Path $explorerPolicy -Name "HideSCAVolume" -Value 0 -Type DWord -Force | Out-Null

# 5. System Time & Power Settings
Write-Host "`n[5/9] Configuring Automatic Time and High Performance Power Plan..." -ForegroundColor Yellow
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" -Name "Type" -Value "NTP" -Force
Set-Service -Name w32time -StartupType Automatic
Start-Service -Name w32time -ErrorAction SilentlyContinue
w32tm /resync /force | Out-Null

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" -Name "Start" -Value 3 -Force
Start-Service -Name tzautoupdate -ErrorAction SilentlyContinue

powercfg /setactive SCHEME_MIN
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

# 6. Remove Microsoft OneDrive
Write-Host "`n[6/9] Removing Microsoft OneDrive..." -ForegroundColor Yellow
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
$oneDriveSetup = "$env:systemroot\SysWOW64\OneDriveSetup.exe"
if (!(Test-Path $oneDriveSetup)) { $oneDriveSetup = "$env:systemroot\System32\OneDriveSetup.exe" }
if (Test-Path $oneDriveSetup) {
    Start-Process -FilePath $oneDriveSetup -ArgumentList "/uninstall" -Wait -NoNewWindow
}
Remove-Item -Path "$env:USERPROFILE\OneDrive" -Force -Recurse -ErrorAction SilentlyContinue

# 7. Remove Microsoft Edge
Write-Host "`n[7/9] Removing Microsoft Edge..." -ForegroundColor Yellow
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

# 8. Download BurntSushi to Startup
Write-Host "`n[8/9] Downloading BurntSushi to Startup Folder..." -ForegroundColor Yellow
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$burntSushiUrl = "https://github.com/OpenByteDev/burnt-sushi/releases/latest/download/BurntSushi.exe"
$burntSushiPath = Join-Path -Path $startupFolder -ChildPath "BurntSushi.exe"

try {
    Invoke-WebRequest -Uri $burntSushiUrl -OutFile $burntSushiPath -ErrorAction Stop
} catch {
    Write-Host "Failed to download BurntSushi. Please check the repository URL." -ForegroundColor Red
}

# 9. Set Desktop Background & Lock Screen
Write-Host "`n[9/9] Applying Custom Wallpaper and Lock Screen..." -ForegroundColor Yellow
$bgUrl = "https://raw.githubusercontent.com/lourenco321/RexDebloat/main/bg.png"
$bgPath = "$env:USERPROFILE\Pictures\RexBackground.png"

try {
    Invoke-WebRequest -Uri $bgUrl -OutFile $bgPath -ErrorAction Stop
    
    $personalizationPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization"
    if (!(Test-Path $personalizationPolicy)) { New-Item -Path $personalizationPolicy -Force | Out-Null }
    Set-ItemProperty -Path $personalizationPolicy -Name "LockScreenImage" -Value $bgPath -Type String -Force | Out-Null
    
    $cSharp = @"
    using System;
    using System.Runtime.InteropServices;
    public class Wallpaper {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void Set(string path) {
            SystemParametersInfo(20, 0, path, 3);
        }
    }
"@
    Add-Type -TypeDefinition $cSharp -ErrorAction SilentlyContinue
    [Wallpaper]::Set($bgPath)
    
} catch {
    Write-Host "Failed to download or set the wallpaper." -ForegroundColor Red
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Setup Complete! Forcing system restart in 5 seconds..." -ForegroundColor Red
Write-Host "=====================================================================" -ForegroundColor Cyan
Start-Sleep -Seconds 5
Restart-Computer -Force
