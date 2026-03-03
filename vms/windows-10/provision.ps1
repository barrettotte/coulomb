# Windows 10 VM provisioning script
#
# Run as Administrator in PowerShell:
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\provision.ps1
#
# This script is meant to be run on a fresh Windows 10 VM.
# Try to maintain anything that's changed that's worth automating.

$ErrorActionPreference = "Stop"

Write-Host "=== Windows 10 VM Provisioning ===" -ForegroundColor Cyan

# ============================================
# Bootstrap WinGet
# ============================================

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "`n=== Installing WinGet ===" -ForegroundColor Cyan
    $ProgressPreference = 'SilentlyContinue'
    Install-PackageProvider -Name NuGet -Force | Out-Null
    Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
    Repair-WinGetPackageManager -Force -Latest
    Write-Host "WinGet installed. Refreshing PATH..."
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# ============================================
# Timezone / Clock
# ============================================

Write-Host "`n=== Setting timezone ===" -ForegroundColor Cyan
Set-TimeZone -Id "Eastern Standard Time"
w32tm /resync /force 2>&1 | Out-Null

# ============================================
# WinGet packages
# ============================================

Write-Host "`n=== Installing WinGet packages ===" -ForegroundColor Cyan

$packages = @(
    # browsers
    "Mozilla.Firefox"

    # development
    "Git.Git"
    "Microsoft.VisualStudioCode"
    "Microsoft.PowerShell"
    "Microsoft.WindowsTerminal"

    # debuggers / reverse engineering
    "x64dbg.x64dbg"
    "dnSpyEx.dnSpy"
    "Microsoft.WinDbg"

    # virtiofs dependency
    "WinFsp.WinFsp"

    # utilities
    "7zip.7zip"
    "Microsoft.Sysinternals.Suite"

    # languages
    "Python.Python.3.13"
    "GoLang.Go"
    "Microsoft.DotNet.SDK.8"
    "Microsoft.OpenJDK.21"

    # media
    "VideoLAN.VLC"
    "dotPDN.PaintDotNet"
)
foreach ($pkg in $packages) {
    $installed = winget list --id $pkg --accept-source-agreements 2>&1
    if ($installed -match $pkg) {
        Write-Host "Already installed: $pkg" -ForegroundColor DarkGray
    } else {
        Write-Host "Installing $pkg..." -ForegroundColor Yellow
        winget install --id $pkg --accept-source-agreements --accept-package-agreements --silent
    }
}

# Fusion 360 - download bootstrapper directly from Autodesk (winget hash is often stale)
if (-not (Test-Path "$env:LOCALAPPDATA\Autodesk\webdeploy\production\*\FusionLauncher.exe")) {
    Write-Host "Installing Fusion 360 (launches in background)..." -ForegroundColor Yellow
    $fusionInstaller = "$env:TEMP\Fusion360Installer.exe"
    Invoke-WebRequest -Uri "https://dl.appstreaming.autodesk.com/production/installers/Fusion%20Client%20Downloader.exe" -OutFile $fusionInstaller
    Start-Process -FilePath $fusionInstaller
} else {
    Write-Host "Already installed: Fusion 360" -ForegroundColor DarkGray
}

# ============================================
# Windows settings
# ============================================

Write-Host "`n=== Applying Windows settings ===" -ForegroundColor Cyan

# show file extensions
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0

# show hidden files
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1

# disable web search in start menu
$searchPath = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $searchPath)) {
    New-Item -Path $searchPath -Force | Out-Null
}
Set-ItemProperty -Path $searchPath -Name "DisableSearchBoxSuggestions" -Value 1

# set dark mode
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0

# ============================================
# Debloat
# ============================================

Write-Host "`n=== Removing bloatware ===" -ForegroundColor Cyan

$bloatApps = @(
    "Microsoft.3DViewer"
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MixedReality.Portal"
    "Microsoft.OneConnect"
    "Microsoft.People"
    "Microsoft.ScreenSketch"
    "Microsoft.SkypeApp"
    "Microsoft.Todos"
    "Microsoft.WindowsAlarms"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "SpotifyAB.SpotifyMusic"
    "Microsoft.Office.OneNote"
    "Microsoft.LinkedInForWindows"
    "Microsoft.Todos"
    "Microsoft.OneDriveSync"
    "Microsoft.WindowsCommunicationsApps"
    "Microsoft.Wallet"
    "Microsoft.Print3D"
    "Microsoft.MSPaint"
    "Microsoft.WindowsCamera"
    "Microsoft.GrooveMusic"
)
foreach ($app in $bloatApps) {
    $pkg = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    if ($pkg) {
        Write-Host "  Removing $app..." -ForegroundColor Yellow
        $pkg | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object DisplayName -eq $app |
            Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
    }
}

# disable Cortana
$cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $cortanaPath)) {
    New-Item -Path $cortanaPath -Force | Out-Null
}
Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0

# ============================================
# Privacy / Telemetry
# ============================================

Write-Host "`n=== Applying privacy settings ===" -ForegroundColor Cyan

# disable diagnostic data
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0

# disable activity history
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "PublishUserActivities" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "UploadUserActivities" -Value 0

# disable advertising ID
$advertisingPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
if (-not (Test-Path $advertisingPath)) {
    New-Item -Path $advertisingPath -Force | Out-Null
}
Set-ItemProperty -Path $advertisingPath -Name "Enabled" -Value 0

# disable suggested content in settings
$contentDeliveryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-338393Enabled" -Value 0
Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-353694Enabled" -Value 0
Set-ItemProperty -Path $contentDeliveryPath -Name "SubscribedContent-353696Enabled" -Value 0
Set-ItemProperty -Path $contentDeliveryPath -Name "SoftLandingEnabled" -Value 0

# ============================================
# Taskbar / UI
# ============================================

Write-Host "`n=== Configuring taskbar ===" -ForegroundColor Cyan

$taskbarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

# remove task view button
Set-ItemProperty -Path $taskbarPath -Name "ShowTaskViewButton" -Value 0

# hide Cortana button from taskbar
Set-ItemProperty -Path $taskbarPath -Name "ShowCortanaButton" -Value 0

# hide People button from taskbar
$peoplePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"
if (-not (Test-Path $peoplePath)) {
    New-Item -Path $peoplePath -Force | Out-Null
}
Set-ItemProperty -Path $peoplePath -Name "PeopleBand" -Value 0

# disable "show recently opened items" in start and taskbar
Set-ItemProperty -Path $taskbarPath -Name "Start_TrackDocs" -Value 0

# ============================================
# Performance
# ============================================

Write-Host "`n=== Applying performance settings ===" -ForegroundColor Cyan

# disable startup delay
$serializePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize"
if (-not (Test-Path $serializePath)) {
    New-Item -Path $serializePath -Force | Out-Null
}
Set-ItemProperty -Path $serializePath -Name "StartupDelayInMSec" -Value 0

# set power plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# ============================================
# Developer settings
# ============================================

Write-Host "`n=== Applying developer settings ===" -ForegroundColor Cyan

# enable long file paths
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1

# enable Developer Mode
$devModePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
if (-not (Test-Path $devModePath)) {
    New-Item -Path $devModePath -Force | Out-Null
}
Set-ItemProperty -Path $devModePath -Name "AllowDevelopmentWithoutDevLicense" -Value 1
Set-ItemProperty -Path $devModePath -Name "AllowAllTrustedApps" -Value 1

# ============================================
# Done
# ============================================

Write-Host "`n=== Provisioning complete ===" -ForegroundColor Green
Write-Host "Reboot for all settings to take effect."
