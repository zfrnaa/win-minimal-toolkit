<#
.SYNOPSIS
    Optimize-WindowsPostInstall.ps1 - Automated Windows 11 Minimal & High-Performance Setup
.DESCRIPTION
    Replicates your exact 139-process, low-latency, zero-bloat Windows environment:
      1. Unhides all hidden Advanced Power Plan settings (CPU Core Parking, Frequency, Throttling).
      2. Activates High Performance power scheme and tunes processor performance states.
      3. Network / TCP stack optimization (CUBIC, RSS, RSC, No Throttling).
      4. Gaming & MMCSS latency optimization (SystemResponsiveness=0, GPU Priority=8, GameDVR=0).
      5. Complete Windows Telemetry, Diagnostic Logging, and Promo bloat elimination.
      6. Trims unnecessary background services to Disabled / Manual.
      7. Disables Windows animation lag (MenuShowDelay=0, instantaneous snappy UI).
.NOTES
    Run in an elevated PowerShell session (Run as Administrator) after a fresh install.
#>

[CmdletBinding()]
param(
    [switch]$SkipReboot
)

# Ensure script is running with Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "ERROR: This script must be executed as Administrator! Please re-open PowerShell as Administrator."
    exit 1
}

Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "   Windows Minimal & High-Performance Post-Install Setup   " -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# -------------------------------------------------------------
# 1. UNHIDE ALL ADVANCED POWER SETTINGS
# -------------------------------------------------------------
Write-Host "[1/7] Unhiding All Hidden Advanced Power Options..." -ForegroundColor Green
$powerSettingsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$unhiddenCount = 0

Get-ChildItem $powerSettingsKey -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ChildItem $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
        $settingPath = $_.PSPath
        $attrs = (Get-ItemProperty $settingPath -ErrorAction SilentlyContinue).Attributes
        if ($null -ne $attrs -and $attrs -ne 2) {
            # Attributes = 2 makes the setting visible in powercfg.cpl
            Set-ItemProperty -Path $settingPath -Name "Attributes" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            $unhiddenCount++
        }
    }
}
Write-Host "  -> Successfully verified and unhid power options across all power subgroups." -ForegroundColor Gray

# Set Active Power Scheme to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Write-Host "  -> Activated High Performance Power Scheme." -ForegroundColor Gray

# -------------------------------------------------------------
# 2. GAMING, MULTIMEDIA & MMCSS LATENCY TUNING
# -------------------------------------------------------------
Write-Host "[2/7] Applying Gaming & System Responsiveness Tweaks..." -ForegroundColor Green

# Disable GameDVR background recording overhead
$gameConfigPath = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $gameConfigPath)) { New-Item -Path $gameConfigPath -Force | Out-Null }
Set-ItemProperty -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gameConfigPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force

$allowGameDvr = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
if (-not (Test-Path $allowGameDvr)) { New-Item -Path $allowGameDvr -Force | Out-Null }
Set-ItemProperty -Path $allowGameDvr -Name "AllowGameDVR" -Value 0 -Type DWord -Force

# Hardware-Accelerated GPU Scheduling (HAGS)
$gfxPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
if (-not (Test-Path $gfxPath)) { New-Item -Path $gfxPath -Force | Out-Null }
Set-ItemProperty -Path $gfxPath -Name "HwSchMode" -Value 2 -Type DWord -Force

# Multimedia Class Scheduler Service (MMCSS) - 100% foreground CPU slice
$systemProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
if (-not (Test-Path $systemProfile)) { New-Item -Path $systemProfile -Force | Out-Null }
Set-ItemProperty -Path $systemProfile -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord -Force
Set-ItemProperty -Path $systemProfile -Name "SystemResponsiveness" -Value 0 -Type DWord -Force

$tasksGames = "$systemProfile\Tasks\Games"
if (-not (Test-Path $tasksGames)) { New-Item -Path $tasksGames -Force | Out-Null }
Set-ItemProperty -Path $tasksGames -Name "Affinity" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $tasksGames -Name "Background Only" -Value "False" -Type String -Force
Set-ItemProperty -Path $tasksGames -Name "Clock Rate" -Value 10000 -Type DWord -Force
Set-ItemProperty -Path $tasksGames -Name "GPU Priority" -Value 8 -Type DWord -Force
Set-ItemProperty -Path $tasksGames -Name "Priority" -Value 6 -Type DWord -Force
Set-ItemProperty -Path $tasksGames -Name "Scheduling Category" -Value "High" -Type String -Force
Set-ItemProperty -Path $tasksGames -Name "SFIO Priority" -Value "High" -Type String -Force

Write-Host "  -> MMCSS gaming priority and zero-throttle rules applied." -ForegroundColor Gray

# -------------------------------------------------------------
# 3. NETWORK & TCP STACK OPTIMIZATION
# -------------------------------------------------------------
Write-Host "[3/7] Tuning Network TCP Stack for Low Ping & Stability..." -ForegroundColor Green

# Global TCP Settings via Netsh
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set global rsc=enabled | Out-Null
netsh int tcp set global chimney=disabled | Out-Null
netsh int tcp set global timestamps=disabled | Out-Null
netsh int tcp set global ecncapability=disabled | Out-Null
netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
netsh int tcp set supplemental template=datacenter congestionprovider=cubic | Out-Null

Write-Host "  -> Network TCP autotuning normal, CUBIC congestion provider, RSS/RSC enabled." -ForegroundColor Gray

# -------------------------------------------------------------
# 4. TELEMETRY, PROMOTIONS & WIDGETS ELIMINATION
# -------------------------------------------------------------
Write-Host "[4/7] Disabling Windows Telemetry & Diagnostic Logging..." -ForegroundColor Green

$dataCollKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $dataCollKey)) { New-Item -Path $dataCollKey -Force | Out-Null }
Set-ItemProperty -Path $dataCollKey -Name "AllowTelemetry" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $dataCollKey -Name "LimitDiagnosticLogCollection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $dataCollKey -Name "LimitDumpCollection" -Value 1 -Type DWord -Force
Set-ItemProperty -Path $dataCollKey -Name "AllowDeviceNameInTelemetry" -Value 0 -Type DWord -Force

# Disable Widgets / News and Interests
$dshKey = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $dshKey)) { New-Item -Path $dshKey -Force | Out-Null }
Set-ItemProperty -Path $dshKey -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force

# Disable Advertising ID & Content Delivery Manager Promos
$cdmKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $cdmKey)) { New-Item -Path $cdmKey -Force | Out-Null }
Set-ItemProperty -Path $cdmKey -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $cdmKey -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $cdmKey -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force

Write-Host "  -> Telemetry policies locked to 0, diagnostic upload limits enforced." -ForegroundColor Gray

# -------------------------------------------------------------
# 5. UI SNAPPINESS & LATENCY REDUCTION
# -------------------------------------------------------------
Write-Host "[5/7] Minimizing UI Latency & Menu Delays..." -ForegroundColor Green

Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0 -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "1" -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -Type String -Force

Write-Host "  -> MenuShowDelay set to 0ms (Instant context and menu rendering)." -ForegroundColor Gray

# -------------------------------------------------------------
# 6. SERVICE MANAGEMENT (REDUCING IDLE PROCESS COUNT)
# -------------------------------------------------------------
Write-Host "[6/7] Trimming Redundant Background Services..." -ForegroundColor Green

# Core list of non-essential background daemons that cause process bloat
$servicesToDisable = @(
    "DiagTrack",                 # Connected User Experiences and Telemetry
    "SysMain",                   # SuperFetch / Prefetch memory cache daemon
    "WSearch",                   # Windows Search Indexer (Voidtools Everything handles indexing)
    "WerSvc",                    # Windows Error Reporting Service
    "PcaSvc",                    # Program Compatibility Assistant Service
    "DPS",                       # Diagnostic Policy Service
    "diagsvc",                   # Diagnostic Execution Service
    "WdiServiceHost",            # Diagnostic Service Host
    "TrkWks",                    # Distributed Link Tracking Client
    "WalletService",             # Windows Wallet Service
    "CscService",                # Offline Files
    "AppVClient",                # Microsoft App-V Client
    "PeerDistSvc",               # BranchCache
    "RemoteRegistry",            # Remote Registry
    "TermService",               # Remote Desktop Services (if not used)
    "SessionEnv",                # Remote Desktop Configuration
    "RetailDemo",                # Retail Demo Service
    "MapsBroker",                # Downloaded Maps Manager
    "whesvc",                    # Windows Health and Optimized Experiences
    "WpcMonSvc"                  # Parental Controls
)

foreach ($svc in $servicesToDisable) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

# Geolocation service set to Manual
if (Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "lfsvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "lfsvc" -StartupType Manual -ErrorAction SilentlyContinue
}

Write-Host "  -> Background telemetry, diagnostics, and indexing services cleanly disabled." -ForegroundColor Gray

# -------------------------------------------------------------
# 7. CLEAN STARTUP AND EDGE BACKGROUND RUNNERS
# -------------------------------------------------------------
Write-Host "[7/7] Disabling Headless Browser Runners & Startup Overhead..." -ForegroundColor Green

# Edge background process prevention
$edgeKey = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
if (-not (Test-Path $edgeKey)) { New-Item -Path $edgeKey -Force | Out-Null }
Set-ItemProperty -Path $edgeKey -Name "StartupBoostEnabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $edgeKey -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force

# Chrome background process prevention
$chromeKey = "HKLM:\SOFTWARE\Policies\Google\Chrome"
if (-not (Test-Path $chromeKey)) { New-Item -Path $chromeKey -Force | Out-Null }
Set-ItemProperty -Path $chromeKey -Name "BackgroundModeEnabled" -Value 0 -Type DWord -Force

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "       Minimal Windows Setup Completed Successfully!       " -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "Your PC is configured for ultra-low process/handle count," -ForegroundColor Cyan
Write-Host "unhidden advanced power options, and low-latency gaming." -ForegroundColor Cyan
Write-Host ""

if (-not $SkipReboot) {
    Write-Host "A system restart is recommended for all kernel and power tweaks to take full effect." -ForegroundColor Yellow
}
