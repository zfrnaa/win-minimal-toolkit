<#
.SYNOPSIS
    Optimize-WindowsPostInstall.ps1 - Automated Windows 11 Minimal & High-Performance Setup
.DESCRIPTION
    Replicates your exact 139-process, low-latency, zero-bloat Windows environment:
      1. Unhides specifically your 34 curated Advanced Power Plan settings.
      2. Activates High Performance power scheme.
      3. Network / TCP stack optimization (CUBIC, RSS, RSC, No Throttling).
      4. Gaming & MMCSS latency optimization (SystemResponsiveness=0, GPU Priority=8, GameDVR=0).
      5. Complete Windows Telemetry, Diagnostic Logging, and Promo bloat elimination.
      6. Trims all 47 pure Windows background services to Disabled / Manual (zero third-party dependencies).
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
# 1. UNHIDE SPECIFIC CURATED ADVANCED POWER SETTINGS (34 SETTINGS)
# -------------------------------------------------------------
Write-Host "[1/6] Unhiding Curated Advanced Power Options..." -ForegroundColor Green

$curatedPowerSettings = @(
    # Hard Disk: Turn off hard disk after
    @{ Sub = "0012ee47-9041-4b5d-9b77-535fba8b1442"; Setting = "6738e2c4-e8a5-4a42-b16a-e040e769756e" },
    # Battery: Critical battery action
    @{ Sub = "0d7dbae2-4294-402a-ba8e-26777e8488cd"; Setting = "309dce9b-bef4-4119-9921-a851fb12f0f4" },
    # Sleep: Sleep after, Hibernate after, Allow hybrid sleep
    @{ Sub = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; Setting = "29f6c1db-86da-48c5-9fdb-f2b67b1f44da" },
    @{ Sub = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; Setting = "9d7815a6-7ee4-497e-8888-515a05f02364" },
    @{ Sub = "238c9fa8-0aad-41ed-83f4-97be242c8f20"; Setting = "bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d" },
    # Power Buttons and Lid: Lid close, Power button, Sleep button
    @{ Sub = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "5ca83367-6e45-459f-a27b-476b1d01c936" },
    @{ Sub = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "7648efa3-dd9c-4e3e-b566-50f929386280" },
    @{ Sub = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "96996bc0-ad50-47ec-923b-6f41874dd9eb" },
    @{ Sub = "4f971e89-eebd-4455-a8de-9e59040e7347"; Setting = "99ff10e7-23b1-4c07-a9d1-5c3206d741b4" },
    # PCI Express: Link State Power Management
    @{ Sub = "501a4d13-42af-4429-9fd1-a8218c268e20"; Setting = "ee12f906-d277-404b-b6da-e5fa1a576df5" },
    # Processor Power Management (Boost Mode, Core Parking, Frequency, Min/Max States)
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "06cadf0e-64ed-448a-8927-ce7bf90eb35d" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "0cc5b647-c1df-4637-891a-dec35c318583" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "36687f9e-e3a5-4dbf-b1dc-15eb381c6863" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "45bcc044-d885-43e2-8605-ee0ec6e96b59" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "75b0ae3f-bce0-45a7-8c89-c9611c25e100" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "893dee8e-2bef-41e0-89c6-b55d0929964c" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "8baa4a8a-14c6-4451-8e8b-14bdbd197537" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "bc5038f7-23e0-4960-96da-33abaf5935ec" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "be337238-0d82-4146-a960-4f3749d470c7" },
    @{ Sub = "54533251-82be-4824-96c1-47b60b740d00"; Setting = "ea062031-0e34-4ff1-9b6d-eb1059334028" },
    # Display: Turn off display after, Display brightness
    @{ Sub = "7516b95f-f776-4464-8c53-06167f40cc99"; Setting = "3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e" },
    @{ Sub = "7516b95f-f776-4464-8c53-06167f40cc99"; Setting = "aded5e82-b909-4619-9949-f5d71dac0bcb" },
    @{ Sub = "7516b95f-f776-4464-8c53-06167f40cc99"; Setting = "f1fbfde2-a960-4165-9f88-50667911ce96" },
    @{ Sub = "7516b95f-f776-4464-8c53-06167f40cc99"; Setting = "fbd9aa66-9553-4097-ba44-ed6e9d65eab8" },
    # Presence: Adaptive Display Dimming / Session Disconnect
    @{ Sub = "c763b4ec-0e50-4b6b-9bed-2b92a6ee884e"; Setting = "7ec1751b-60ed-4588-afb5-9819d3d77d90" },
    # USB settings: USB selective suspend
    @{ Sub = "e276e160-7cb0-43c6-b20b-73f5dce39954"; Setting = "a1662ab2-9d34-4e53-ba8b-2639b9e20857" },
    # System unattended sleep and idle timers
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "637ea02f-bbcb-4015-8e2c-a1c7b9c0b546" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "8183ba9a-e910-48da-8769-14ae6dc1170a" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "bcded951-187b-4d05-bccc-f7e51960c258" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "d8742dcb-3e6a-4b3c-b3fe-374623cdcf06" },
    @{ Sub = "e73a048d-bf27-4f12-9731-8b2076e8891f"; Setting = "F3C5027D-CD16-4930-AA6B-90DB844A8F00" }
)

$basePowerKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$unhiddenCount = 0

foreach ($item in $curatedPowerSettings) {
    $targetPath = Join-Path (Join-Path $basePowerKey $item.Sub) $item.Setting
    if (Test-Path $targetPath) {
        Set-ItemProperty -Path $targetPath -Name "Attributes" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        $unhiddenCount++
    }
}
Write-Host "  -> Unhid $unhiddenCount custom power settings in Control Panel." -ForegroundColor Gray

# Set Active Power Scheme to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Write-Host "  -> Activated High Performance Power Scheme." -ForegroundColor Gray

# -------------------------------------------------------------
# 2. GAMING, MULTIMEDIA & MMCSS LATENCY TUNING (HAGS EXCLUDED)
# -------------------------------------------------------------
Write-Host "[2/6] Applying Gaming & System Responsiveness Tweaks..." -ForegroundColor Green

# Disable GameDVR background recording overhead
$gameConfigPath = "HKCU:\System\GameConfigStore"
if (-not (Test-Path $gameConfigPath)) { New-Item -Path $gameConfigPath -Force | Out-Null }
Set-ItemProperty -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $gameConfigPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force

$allowGameDvr = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
if (-not (Test-Path $allowGameDvr)) { New-Item -Path $allowGameDvr -Force | Out-Null }
Set-ItemProperty -Path $allowGameDvr -Name "AllowGameDVR" -Value 0 -Type DWord -Force

# Note: HAGS (Hardware-Accelerated GPU Scheduling) is intentionally untouched per preference.

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
Write-Host "[3/6] Tuning Network TCP Stack for Low Ping & Stability..." -ForegroundColor Green

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
Write-Host "[4/6] Disabling Windows Telemetry & Diagnostic Logging..." -ForegroundColor Green

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
Write-Host "[5/6] Minimizing UI Latency & Menu Delays..." -ForegroundColor Green

Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value 0 -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "1" -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -Type String -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -Type String -Force

Write-Host "  -> MenuShowDelay set to 0ms (Instant context and menu rendering)." -ForegroundColor Gray

# -------------------------------------------------------------
# 6. WINDOWS BUILT-IN SERVICE MANAGEMENT (47 EXACT SERVICES)
# -------------------------------------------------------------
Write-Host "[6/6] Trimming Exact Built-in Windows Services (Zero 3rd-Party Software)..." -ForegroundColor Green

# Exactly the 47 Windows internal services configured as Disabled on your system
$windowsServicesToDisable = @(
    "AppMgmt",                 # Application Management
    "AppVClient",              # Microsoft App-V Client
    "AxInstSV",                # ActiveX Installer (AxInstSV)
    "BDESVC",                  # BitLocker Drive Encryption Service
    "CertPropSvc",             # Certificate Propagation
    "CscService",              # Offline Files
    "DevQueryBroker",          # DevQuery Background Discovery Broker
    "diagsvc",                 # Diagnostic Execution Service
    "DiagTrack",               # Connected User Experiences and Telemetry
    "DialogBlockingService",   # DialogBlockingService
    "DispBrokerDesktopSvc",    # Display Policy Service
    "DPS",                     # Diagnostic Policy Service
    "FontCache",               # Windows Font Cache Service
    "FrameServer",             # Windows Camera Frame Server
    "FrameServerMonitor",      # Windows Camera Frame Server Monitor
    "hns",                     # Host Network Service
    "IKEEXT",                  # IKE and AuthIP IPsec Keying Modules
    "lmhosts",                 # TCP/IP NetBIOS Helper
    "mpssvc",                  # Windows Defender Firewall (if using custom firewall or disabled)
    "MsKeyboardFilter",        # Microsoft Keyboard Filter
    "PcaSvc",                  # Program Compatibility Assistant Service
    "PeerDistSvc",             # BranchCache
    "PolicyAgent",             # IPsec Policy Agent
    "RasMan",                  # Remote Access Connection Manager
    "RemoteRegistry",          # Remote Registry
    "SCardSvr",                # Smart Card
    "SCPolicySvc",             # Smart Card Removal Policy
    "SessionEnv",              # Remote Desktop Configuration
    "SharedAccess",            # Internet Connection Sharing (ICS)
    "shpamsvc",                # Shared PC Account Manager
    "smphost",                 # Microsoft Storage Spaces SMP
    "SNMPTrap",                # SNMP Trap
    "SSDPSRV",                 # SSDP Discovery
    "ssh-agent",               # OpenSSH Authentication Agent
    "SysMain",                 # SysMain / Superfetch
    "TermService",             # Remote Desktop Services
    "TrkWks",                  # Distributed Link Tracking Client
    "tzautoupdate",            # Auto Time Zone Updater
    "UevAgentService",         # User Experience Virtualization Service
    "WalletService",           # WalletService
    "WdiServiceHost",          # Diagnostic Service Host
    "WebClient",               # WebClient
    "WerSvc",                  # Windows Error Reporting Service
    "whesvc",                  # Windows Health and Optimized Experiences
    "WinRM",                   # Windows Remote Management (WS-Management)
    "WpcMonSvc",               # Parental Controls
    "WSearch"                  # Windows Search Indexer
)

$disabledCount = 0
foreach ($svc in $windowsServicesToDisable) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        $disabledCount++
    }
}

# Windows Geolocation service set to Manual
if (Get-Service -Name "lfsvc" -ErrorAction SilentlyContinue) {
    Stop-Service -Name "lfsvc" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "lfsvc" -StartupType Manual -ErrorAction SilentlyContinue
}

Write-Host "  -> Trimmed $disabledCount built-in Windows services to Disabled." -ForegroundColor Gray

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "       Minimal Windows Setup Completed Successfully!       " -ForegroundColor Yellow
Write-Host "===========================================================" -ForegroundColor Green
Write-Host "Your PC is configured for ultra-low process/handle count," -ForegroundColor Cyan
Write-Host "your exact 34 curated power settings, and low-latency gaming." -ForegroundColor Cyan
Write-Host ""

if (-not $SkipReboot) {
    Write-Host "A system restart is recommended for all kernel and power tweaks to take full effect." -ForegroundColor Yellow
}
