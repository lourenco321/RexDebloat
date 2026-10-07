# =====================================================================
# RexDebloat - Custom Windows 11 Debloat & Setup Script - V19
# https://github.com/lourenco321/RexDebloat
# =====================================================================

$RexUrl = "https://raw.githubusercontent.com/lourenco321/RexDebloat/main/rex.ps1"
$BgUrl  = "https://raw.githubusercontent.com/lourenco321/RexDebloat/main/bg.png"

# ---------------------------------------------------------------------
# 0. Requirements: Windows PowerShell 5.1 + Administrator
#    Win11Debloat refuses to run under PowerShell 7 (pwsh), so if we are
#    not in Windows PowerShell or not elevated, relaunch ourselves in an
#    elevated Windows PowerShell window and stop here.
# ---------------------------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if ($PSVersionTable.PSEdition -eq 'Core' -or -not $isAdmin) {
    if ($PSVersionTable.PSEdition -eq 'Core') { Write-Warning "RexDebloat needs Windows PowerShell 5.1 (Win11Debloat does not support PowerShell 7)." }
    if (-not $isAdmin) { Write-Warning "RexDebloat needs Administrator privileges." }
    Write-Host "Relaunching in an elevated Windows PowerShell window..." -ForegroundColor Cyan
    $command = if ($PSCommandPath) { "& '$PSCommandPath'" } else { "irm '$RexUrl' | iex" }
    try {
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"$command`"" -ErrorAction Stop
        Write-Host "Continue in the new window, you can close this one." -ForegroundColor Cyan
    } catch {
        Write-Host "Could not relaunch (UAC declined?). Open Windows PowerShell as Administrator and run the command again." -ForegroundColor Red
    }
    return
}

# Progress bars make Invoke-WebRequest painfully slow on Windows PowerShell 5.1
$ProgressPreference = 'SilentlyContinue'

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Set-LockScreenImage {
    # Sets the lock screen for the current user through the same Windows Runtime API the
    # Settings app uses, so it works on Home and Pro alike. Windows PowerShell 5.1 only.
    param([Parameter(Mandatory = $true)][string]$Path)
    [Windows.System.UserProfile.LockScreen,Windows.System.UserProfile,ContentType=WindowsRuntime] | Out-Null
    [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime] | Out-Null
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
    $asTaskOperation = $asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' } | Select-Object -First 1
    $asTaskAction    = $asTask | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' } | Select-Object -First 1

    $fileTask = $asTaskOperation.MakeGenericMethod([Windows.Storage.StorageFile]).Invoke($null, @([Windows.Storage.StorageFile]::GetFileFromPathAsync($Path)))
    $fileTask.Wait()
    $setTask = $asTaskAction.Invoke($null, @([Windows.System.UserProfile.LockScreen]::SetImageFileAsync($fileTask.Result)))
    $setTask.Wait()
}

Write-Host "Starting RexDebloat..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# 1. Install essential software
# ---------------------------------------------------------------------
Write-Host "`n[1/8] Installing Essential Software..." -ForegroundColor Yellow
$machineApps = @(
    "Mozilla.Firefox",
    "7zip.7zip",
    "Discord.Discord",
    "Valve.Steam",
    "Microsoft.VCRedist.2015+.x64"
)

$winget = Get-Command winget -ErrorAction SilentlyContinue
if (-not $winget) {
    # Fresh installs often ship App Installer without it being registered for this user yet
    Write-Host "winget not found, trying to register App Installer..." -ForegroundColor DarkYellow
    try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop } catch { }
    $wingetExe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
    if (Test-Path $wingetExe) { $winget = Get-Command $wingetExe -ErrorAction SilentlyContinue }
}

if ($winget) {
    foreach ($app in $machineApps) {
        & $winget.Source install --id $app -e --accept-package-agreements --accept-source-agreements
    }
} else {
    Write-Host "winget is not available. Update 'App Installer' from the Microsoft Store and re-run the script, or install the apps manually." -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 2. Win11Debloat by Raphire (https://github.com/Raphire/Win11Debloat)
#    Handles app removal, telemetry, Edge, the Windows 10 look and most
#    quality of life tweaks. Explorer is restarted by us in step 4.
# ---------------------------------------------------------------------
Write-Host "`n[2/8] Running Win11Debloat by Raphire..." -ForegroundColor Yellow
try {
    $DebloatScript = Invoke-RestMethod -Uri "https://debloat.raphi.re/" -UseBasicParsing -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($DebloatScript)) { throw "empty response from debloat.raphi.re" }
    & ([scriptblock]::Create($DebloatScript)) -Silent -CreateRestorePoint -SkipExplorerRestart `
        -RemoveApps -DisableTelemetry -ForceRemoveEdge `
        -DisableSuggestions -DisableBing -DisableCopilot -DisableRecall -DisableWidgets `
        -RevertContextMenu -EnableDarkMode -ExplorerToThisPC -ShowKnownFileExt -HideGallery `
        -TaskbarAlignLeft -HideSearchTb -HideTaskview -DisableMouseAcceleration
} catch {
    Write-Host "Win11Debloat could not be downloaded or run: $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 3. Remaining appearance & quality of life tweaks (not covered above)
# ---------------------------------------------------------------------
Write-Host "`n[3/8] Applying remaining appearance & quality of life tweaks..." -ForegroundColor Yellow
$personalize = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
Set-RegValue $personalize "EnableTransparency" 1
Set-RegValue $personalize "ColorPrevalence" 1                             # accent colour on Start and taskbar
Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\DWM" "ColorPrevalence" 1   # accent colour on title bars and borders

Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Start_TrackDocs" 0   # no recent items in Start / Jump Lists
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0                        # keep widgets off even if an update brings the app back

# Tray: never hide the network / volume icons, show all tray icons (the latter only works on Windows 10 style taskbars)
$explorerPolicy = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-RegValue $explorerPolicy "HideSCANetwork" 0
Set-RegValue $explorerPolicy "HideSCAVolume" 0
Set-RegValue "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "EnableAutoTray" 0

# ---------------------------------------------------------------------
# 4. Clear all pinned taskbar items and restart Explorer
#    Explorer writes its pins back to the registry when it exits, so write
#    the "nothing pinned" state first, then kill it (no graceful exit, no
#    write-back). This also applies everything Win11Debloat changed.
# ---------------------------------------------------------------------
Write-Host "`n[4/8] Clearing pinned taskbar items and restarting Explorer..." -ForegroundColor Yellow
$taskband = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
if (-not (Test-Path $taskband)) { New-Item -Path $taskband -Force | Out-Null }
Remove-ItemProperty -Path $taskband -Name "FavoritesResolve" -ErrorAction SilentlyContinue
Set-RegValue $taskband "Favorites" ([byte[]](0xFF)) 'Binary'
Remove-Item -Path "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk" -Force -ErrorAction SilentlyContinue

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
if (-not (Get-Process -Name explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }

# ---------------------------------------------------------------------
# 5. Automatic time & High Performance power plan
# ---------------------------------------------------------------------
Write-Host "`n[5/8] Configuring automatic time and High Performance power plan..." -ForegroundColor Yellow
Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" "Type" "NTP" 'String'
Set-Service -Name w32time -StartupType Automatic
Start-Service -Name w32time -ErrorAction SilentlyContinue
w32tm /resync /force | Out-Null

Set-RegValue "HKLM:\SYSTEM\CurrentControlSet\Services\tzautoupdate" "Start" 3
Start-Service -Name tzautoupdate -ErrorAction SilentlyContinue

# SCHEME_MIN = High performance. Hidden on Modern Standby laptops, so duplicate it if activating fails.
powercfg /setactive SCHEME_MIN | Out-Null
if ($LASTEXITCODE -ne 0) {
    $duplicated = powercfg /duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    if ("$duplicated" -match '([0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12})') {
        powercfg /setactive $Matches[1] | Out-Null
    } else {
        Write-Host "Could not activate the High Performance power plan on this device." -ForegroundColor DarkYellow
    }
}
powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0

# ---------------------------------------------------------------------
# 6. Remove Microsoft OneDrive (the app, never your files)
# ---------------------------------------------------------------------
Write-Host "`n[6/8] Removing Microsoft OneDrive..." -ForegroundColor Yellow
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force

# Prefer the uninstaller OneDrive registered itself (per-user under HKCU, per-machine under HKLM),
# fall back to the copy that ships with Windows.
$uninstallKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$oneDriveUninstallers = @(Get-ItemProperty -Path $uninstallKeys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "Microsoft OneDrive*" -and $_.UninstallString } |
    Select-Object -ExpandProperty UninstallString -Unique)
if ($oneDriveUninstallers.Count -eq 0) {
    $oneDriveUninstallers = @("$env:SystemRoot\SysWOW64\OneDriveSetup.exe", "$env:SystemRoot\System32\OneDriveSetup.exe" |
        Where-Object { Test-Path $_ } | Select-Object -First 1 | ForEach-Object { "`"$_`" /uninstall" })
}

if ($oneDriveUninstallers.Count -eq 0) {
    Write-Host "OneDrive does not appear to be installed."
}
foreach ($uninstallString in $oneDriveUninstallers) {
    if ($uninstallString -match '^\s*"?(?<exe>[^"]+?\.exe)"?\s*(?<args>.*)$') {
        $exe = $Matches['exe']
        $arguments = $Matches['args'].Trim()
        if ($arguments -notmatch '/uninstall') { $arguments = "/uninstall $arguments".Trim() }
        Write-Host "Running: `"$exe`" $arguments"
        try { Start-Process -FilePath $exe -ArgumentList $arguments -Wait -NoNewWindow -ErrorAction Stop }
        catch { Write-Host "OneDrive uninstaller failed: $($_.Exception.Message)" -ForegroundColor DarkYellow }
    }
}

# Only remove the OneDrive folder when it is empty. If "Back up folders" was ever on, Desktop,
# Documents and Pictures physically live in here and deleting it would wipe them.
$oneDriveFolder = "$env:USERPROFILE\OneDrive"
if (Test-Path $oneDriveFolder) {
    $hasFiles = Get-ChildItem -Path $oneDriveFolder -Force -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hasFiles) {
        Write-Host "Kept '$oneDriveFolder' because it still contains files. Move them out and delete it yourself if you want." -ForegroundColor DarkYellow
    } else {
        Remove-Item -Path $oneDriveFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------
# 7. BurntSushi (Spotify ad blocker) into the Startup folder
# ---------------------------------------------------------------------
Write-Host "`n[7/8] Downloading BurntSushi to Startup Folder..." -ForegroundColor Yellow
$startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$burntSushiUrl = "https://github.com/OpenByteDev/burnt-sushi/releases/latest/download/BurntSushi.exe"
$burntSushiPath = Join-Path -Path $startupFolder -ChildPath "BurntSushi.exe"

try {
    Invoke-WebRequest -Uri $burntSushiUrl -OutFile $burntSushiPath -UseBasicParsing -ErrorAction Stop
} catch {
    Write-Host "Failed to download BurntSushi: $($_.Exception.Message)" -ForegroundColor Red
}

# ---------------------------------------------------------------------
# 8. Desktop background & lock screen
# ---------------------------------------------------------------------
Write-Host "`n[8/8] Applying Custom Wallpaper and Lock Screen..." -ForegroundColor Yellow
$bgDir  = "$env:ProgramData\RexDebloat"   # stable, readable by every user and by the sign-in screen
$bgPath = Join-Path -Path $bgDir -ChildPath "bg.png"

try {
    New-Item -Path $bgDir -ItemType Directory -Force | Out-Null
    Invoke-WebRequest -Uri $BgUrl -OutFile $bgPath -UseBasicParsing -ErrorAction Stop
    $bgDownloaded = $true
} catch {
    $bgDownloaded = $false
    Write-Host "Failed to download the wallpaper: $($_.Exception.Message)" -ForegroundColor Red
}

if ($bgDownloaded) {
    # Desktop wallpaper, "Fill"
    try {
        Set-RegValue "HKCU:\Control Panel\Desktop" "WallpaperStyle" "10" 'String'
        Set-RegValue "HKCU:\Control Panel\Desktop" "TileWallpaper" "0" 'String'
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
        Write-Host "Failed to set the desktop wallpaper: $($_.Exception.Message)" -ForegroundColor Red
    }

    # Lock screen: the Settings app way first (works on every edition), policy only as a fallback
    try {
        Set-LockScreenImage -Path $bgPath
    } catch {
        $reason = $_.Exception.Message
        if ($_.Exception.InnerException) { $reason = $_.Exception.InnerException.Message }
        Write-Host "Could not set the lock screen through the Windows API ($reason), falling back to the lock screen policy." -ForegroundColor DarkYellow
        Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization" "LockScreenImage" $bgPath 'String'
    }
}

# ---------------------------------------------------------------------
# Done. Restart with a chance to cancel.
# ---------------------------------------------------------------------
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Setup Complete! Restarting in 15 seconds, press any key to cancel the restart." -ForegroundColor Red
Write-Host "=====================================================================" -ForegroundColor Cyan
$restart = $true
try {
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }   # drop keys pressed earlier
    $deadline = (Get-Date).AddSeconds(15)
    while ((Get-Date) -lt $deadline) {
        if ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null; $restart = $false; break }
        Start-Sleep -Milliseconds 250
    }
} catch {
    Start-Sleep -Seconds 15   # no interactive console, just wait
}

if ($restart) {
    Restart-Computer -Force
} else {
    Write-Host "Restart cancelled. Restart your PC yourself to finish applying everything." -ForegroundColor Yellow
}
