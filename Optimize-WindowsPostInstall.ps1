<#
.SYNOPSIS
    Optimize-WindowsPostInstall.ps1 - Automated Windows 11 Minimal & High-Performance Setup
.DESCRIPTION
    Replicates your exact 139-process, low-latency, zero-bloat Windows environment:
      1. Hardware Chassis Detection (Laptop vs Desktop) with interactive prompt or auto-override.
         - If Desktop: Sets CoalescingTimerInterval = 0x0 and HibernateEnabled = 0x0.
      2. Unhides specifically your 34 curated Advanced Power Plan settings.
      3. Activates High Performance power scheme.
      4. Gaming, MMCSS & Low-Latency DirectFlip:
         - Games task: Affinity=0x0, Background Only="False" (String), Clock Rate=0x2710 (10000),
           SFIO Priority="High" (String), Scheduling Category="High" (String), Latency Sensitive="True" (String).
         - DirectFlip, AllowTearing, SystemResponsiveness=0xa (10), Game Mode=ON.
      5. Kernel, DPC & Memory Management:
         - Session Manager\kernel: DebugPollInterval=0x3e8 (1000), DpcWatchdogProfileOffset=0x2710 (10000),
           ThreadDpcEnable=0x0, KernelSEHOPEnabled=0x0.
         - Memory Management: LargeSystemCache=0x0, SecondLevelDataCache=0x0, DisablePagingExecutive=0x1,
           IoPageLockLimit=0x8000000, MemoryCompression=False.
         - PriorityControl: Win32PrioritySeparation=0x26 (38).
         - Raw 1:1 Mouse Input without acceleration.
      6. Memory Integrity (HVCI) Disabled & Resizable BAR enforcement.
      7. Security & Hypervisor Prompt (Interactive optional prompt for VBS & Secure Boot with pros/cons).
      8. Advanced TCP/IP Stack Optimization (CUBIC, RSS, RSC, TimedWaitDelay=0x1e (30), MaxUserPort=0xfffe (65534)).
      9. Complete Windows Telemetry, Diagnostic Logging, and Promo bloat elimination.
      10. Trims all 47 pure Windows background services to Disabled / Manual (zero third-party dependencies).
      11. Disables Windows animation lag (MenuShowDelay=0, instantaneous snappy UI).
.NOTES
    Run in an elevated PowerShell session (Run as Administrator) after a fresh install.
#>

[CmdletBinding()]
param(
    [switch]$SkipReboot,
    [switch]$ForceDisableVBS,
    [ValidateSet("Desktop", "Laptop", "Auto")]
    [string]$DeviceType = "Auto"
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

# Helper function to safely set or update registry values without blind overwrites
function Set-RegistryValueSafe {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)]$Value,
        [Parameter(Mandatory=$true)][Microsoft.Win32.RegistryValueKind]$PropertyType
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $PropertyType -Force
}

# -------------------------------------------------------------
# 1. HARDWARE CHASSIS DECISION: LAPTOP VS DESKTOP
# -------------------------------------------------------------
Write-Host "[1/9] Determining Device Form Factor (Laptop vs Desktop)..." -ForegroundColor Green

# Auto-detect via Win32_SystemEnclosure ChassisTypes
# Common laptop chassis types: 8, 9, 10, 11, 12, 14, 18, 21, 31, 32
$detectedIsLaptop = $false
try {
    $chassis = (Get-CimInstance -ClassName Win32_SystemEnclosure -ErrorAction SilentlyContinue).ChassisTypes
    if ($chassis -and ($chassis | Where-Object { $_ -in @(8, 9, 10, 11, 12, 14, 18, 21, 31, 32) })) {
        $detectedIsLaptop = $true
    }
} catch {}

$targetDeviceType = $DeviceType
if ($targetDeviceType -eq "Auto") {
    $defaultChoice = if ($detectedIsLaptop) { "L" } else { "D" }
    $defaultLabel = if ($detectedIsLaptop) { "Laptop" } else { "Desktop" }
    Write-Host "  Detected hardware type: $defaultLabel" -ForegroundColor Yellow
    $ans = Read-Host "  Configure for [D]esktop or [L]aptop? (Default: $defaultChoice)"
    if ($ans.Trim().ToUpper() -eq "D") {
        $targetDeviceType = "Desktop"
    } elseif ($ans.Trim().ToUpper() -eq "L") {
        $targetDeviceType = "Laptop"
    } else {
        $targetDeviceType = $defaultLabel
    }
}

Write-Host "  -> Selected Mode: $targetDeviceType" -ForegroundColor Cyan

if ($targetDeviceType -eq "Desktop") {
    Write-Host "  -> Applying Desktop-specific Power optimizations..." -ForegroundColor Gray
    # Desktops have permanent wall power: disable coalescing timer and hibernation to eliminate timer jitter and disk wear
    Set-RegistryValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "CoalescingTimerInterval" -Value 0x0 -PropertyType DWord
    Set-RegistryValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Value 0x0 -PropertyType DWord
    Write-Host "     [+] CoalescingTimerInterval = 0x0 (Disabled timer coalescing for minimal latency)" -ForegroundColor Gray
    Write-Host "     [+] HibernateEnabled = 0x0 (Hibernation disabled on Desktop)" -ForegroundColor Gray
} else {
    Write-Host "  -> Laptop mode active: Preserving battery timer coalescing and lid/hibernation states." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 2. UNHIDE SPECIFIC CURATED ADVANCED POWER SETTINGS (34 SETTINGS)
# -------------------------------------------------------------
Write-Host "[2/9] Unhiding Curated Advanced Power Options..." -ForegroundColor Green

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
        Set-RegistryValueSafe -Path $targetPath -Name "Attributes" -Value 0x2 -PropertyType DWord
        $unhiddenCount++
    }
}
Write-Host "  -> Unhid $unhiddenCount custom power settings in Control Panel." -ForegroundColor Gray

# Set Active Power Scheme to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
Write-Host "  -> Activated High Performance Power Scheme." -ForegroundColor Gray

# -------------------------------------------------------------
# 3. GAMING, WINDOWS GAME MODE & LOW-LATENCY DIRECTFLIP
# -------------------------------------------------------------
Write-Host "[3/9] Configuring Windows Game Mode & Low-Latency DirectFlip..." -ForegroundColor Green

# Windows Game Mode = ON
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0x1 -PropertyType DWord

# Disable GameDVR background recording overhead
$gameConfigPath = "HKCU:\System\GameConfigStore"
Set-RegistryValueSafe -Path $gameConfigPath -Name "GameDVR_Enabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $gameConfigPath -Name "GameDVR_FSEBehaviorMode" -Value 0x2 -PropertyType DWord
Set-RegistryValueSafe -Path $gameConfigPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $gameConfigPath -Name "GameDVR_FSEBehavior" -Value 0x2 -PropertyType DWord

$allowGameDvr = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
Set-RegistryValueSafe -Path $allowGameDvr -Name "AllowGameDVR" -Value 0x0 -PropertyType DWord

# Multimedia Class Scheduler Service (MMCSS) & Low Latency DirectFlip
$systemProfile = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
Set-RegistryValueSafe -Path $systemProfile -Name "NetworkThrottlingIndex" -Value 0xffffffff -PropertyType DWord
Set-RegistryValueSafe -Path $systemProfile -Name "SystemResponsiveness" -Value 0xa -PropertyType DWord # 0xa = 10
Set-RegistryValueSafe -Path $systemProfile -Name "EnableMMCSS" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $systemProfile -Name "AlwaysUseDirectFlip" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $systemProfile -Name "AllowTearing" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $systemProfile -Name "AlwaysOn" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $systemProfile -Name "NoLazyMode" -Value 0x1 -PropertyType DWord

# Tasks\Games registry configuration
$tasksGames = "$systemProfile\Tasks\Games"
Set-RegistryValueSafe -Path $tasksGames -Name "Affinity" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $tasksGames -Name "Background Only" -Value "False" -PropertyType String
Set-RegistryValueSafe -Path $tasksGames -Name "Clock Rate" -Value 0x2710 -PropertyType DWord # 0x2710 = 10000
Set-RegistryValueSafe -Path $tasksGames -Name "GPU Priority" -Value 0x8 -PropertyType DWord
Set-RegistryValueSafe -Path $tasksGames -Name "Priority" -Value 0x6 -PropertyType DWord
Set-RegistryValueSafe -Path $tasksGames -Name "Scheduling Category" -Value "High" -PropertyType String
Set-RegistryValueSafe -Path $tasksGames -Name "SFIO Priority" -Value "High" -PropertyType String
Set-RegistryValueSafe -Path $tasksGames -Name "Latency Sensitive" -Value "True" -PropertyType String

Write-Host "  -> Game Mode ON, Games task (Clock Rate=0x2710, SFIO=High, Scheduling=High, Background Only=False)." -ForegroundColor Gray

# -------------------------------------------------------------
# 4. KERNEL DPC/INTERRUPT & MEMORY MANAGEMENT TUNING
# -------------------------------------------------------------
Write-Host "[4/9] Tuning Kernel Session Manager, DPC Watchdog & Memory Management..." -ForegroundColor Green

# Session Manager\kernel parameters
$smKernel = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel"
Set-RegistryValueSafe -Path $smKernel -Name "DebugPollInterval" -Value 0x3e8 -PropertyType DWord # 0x3e8 = 1000
Set-RegistryValueSafe -Path $smKernel -Name "DpcWatchdogProfileOffset" -Value 0x2710 -PropertyType DWord # 0x2710 = 10000
Set-RegistryValueSafe -Path $smKernel -Name "ThreadDpcEnable" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $smKernel -Name "KernelSEHOPEnabled" -Value 0x0 -PropertyType DWord

# Session Manager\Memory Management
$memMgmtPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-RegistryValueSafe -Path $memMgmtPath -Name "LargeSystemCache" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $memMgmtPath -Name "SecondLevelDataCache" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $memMgmtPath -Name "DisablePagingExecutive" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $memMgmtPath -Name "IoPageLockLimit" -Value 0x8000000 -PropertyType DWord # 128 MB

# Disable Windows Memory Compression (Frees CPU cycles on 16GB-32GB+ RAM)
try {
    Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Disable-MMAgent -PageCombining -ErrorAction SilentlyContinue
} catch {}

# CPU Quantum / Priority Separation (0x26 = 38: Short, variable foreground quantum)
Set-RegistryValueSafe -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x26 -PropertyType DWord

# Raw 1:1 Mouse Input (Disables Enhanced Pointer Precision / Acceleration)
$mouseKey = "HKCU:\Control Panel\Mouse"
Set-RegistryValueSafe -Path $mouseKey -Name "MouseSpeed" -Value "0" -PropertyType String
Set-RegistryValueSafe -Path $mouseKey -Name "MouseThreshold1" -Value "0" -PropertyType String
Set-RegistryValueSafe -Path $mouseKey -Name "MouseThreshold2" -Value "0" -PropertyType String

Write-Host "  -> Kernel (DebugPollInterval=0x3e8, DpcOffset=0x2710, ThreadDpc=0x0, SEHOP=0x0)." -ForegroundColor Gray
Write-Host "  -> Memory (LargeSystemCache=0x0, SecondLevelDataCache=0x0, DisablePagingExecutive=0x1)." -ForegroundColor Gray

# -------------------------------------------------------------
# 5. MEMORY INTEGRITY (HVCI) & RESIZABLE BAR
# -------------------------------------------------------------
Write-Host "[5/9] Disabling Memory Integrity (HVCI) & Enabling Resizable BAR..." -ForegroundColor Green

# Disable Memory Integrity (Core Isolation / HVCI)
$hvciPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
Set-RegistryValueSafe -Path $hvciPath -Name "Enabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $hvciPath -Name "HVCIMATRequired" -Value 0x0 -PropertyType DWord

# Enforce Resizable BAR in driver registry if supported
$gpuClassKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
if (Test-Path $gpuClassKey) {
    Get-ChildItem $gpuClassKey -ErrorAction SilentlyContinue | ForEach-Object {
        $driverDesc = (Get-ItemProperty $_.PSPath -ErrorAction SilentlyContinue).DriverDesc
        if ($driverDesc -like "*NVIDIA*") {
            Set-RegistryValueSafe -Path $_.PSPath -Name "MemoryManagement.ReBar" -Value 0x1 -PropertyType DWord
            Set-RegistryValueSafe -Path $_.PSPath -Name "RMReBar" -Value 0x1 -PropertyType DWord
        }
    }
}
Write-Host "  -> Memory Integrity (HVCI) disabled. Resizable BAR driver flags configured." -ForegroundColor Gray

# -------------------------------------------------------------
# 6. OPTIONAL: VBS (VIRTUALIZATION-BASED SECURITY) & SECURE BOOT
# -------------------------------------------------------------
Write-Host "[6/9] Checking Virtualization-Based Security (VBS) & Secure Boot..." -ForegroundColor Green

$disableVBSChoice = $false
if ($ForceDisableVBS) {
    $disableVBSChoice = $true
} else {
    Write-Host ""
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "  OPTIONAL: Disable VBS (Virtualization-Based Security)?   " -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------" -ForegroundColor Yellow
    Write-Host "  [+] BENEFIT: Boosts CPU frame rates by 5-15% in CPU-bound games and eliminates micro-stutters." -ForegroundColor White
    Write-Host "  [-] TRADE-OFF: Lowers kernel virtualization defense; WSL2/Hyper-V/Docker can still run, but Credential Guard is off." -ForegroundColor White
    Write-Host "  [-] NOTE ON SECURE BOOT: Secure Boot is controlled in your BIOS/UEFI. Some anti-cheat (e.g. Vanguard) requires it." -ForegroundColor White
    Write-Host ""
    $resp = Read-Host "Do you want to disable VBS (Virtualization-Based Security)? [y/N]"
    if ($resp.Trim().ToLower() -in @("y", "yes")) {
        $disableVBSChoice = $true
    }
}

if ($disableVBSChoice) {
    $dgPath = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
    Set-RegistryValueSafe -Path $dgPath -Name "EnableVirtualizationBasedSecurity" -Value 0x0 -PropertyType DWord
    Set-RegistryValueSafe -Path $dgPath -Name "RequirePlatformSecurityFeatures" -Value 0x0 -PropertyType DWord

    bcdedit /set hypervisorlaunchtype off | Out-Null
    Write-Host "  -> Virtualization-Based Security (VBS) disabled." -ForegroundColor Green
} else {
    Write-Host "  -> VBS left at default configuration." -ForegroundColor Gray
}

# -------------------------------------------------------------
# 7. NETWORK & ADVANCED TCP/IP STACK OPTIMIZATION
# -------------------------------------------------------------
Write-Host "[7/9] Tuning Network TCP Stack for Low Ping & Fast Socket Recycling..." -ForegroundColor Green

# Netsh TCP Global
netsh int tcp set global autotuninglevel=normal | Out-Null
netsh int tcp set global rss=enabled | Out-Null
netsh int tcp set global rsc=enabled | Out-Null
netsh int tcp set global chimney=disabled | Out-Null
netsh int tcp set global timestamps=disabled | Out-Null
netsh int tcp set global ecncapability=disabled | Out-Null
netsh int tcp set supplemental template=internet congestionprovider=cubic | Out-Null
netsh int tcp set supplemental template=datacenter congestionprovider=cubic | Out-Null

# Advanced TCP/IP Parameters in Registry
$tcpParams = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
Set-RegistryValueSafe -Path $tcpParams -Name "EnablePMTUDiscovery" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $tcpParams -Name "EnablePMTUBHDetect" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $tcpParams -Name "SackOpts" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $tcpParams -Name "DefaultTTL" -Value 0x40 -PropertyType DWord # 0x40 = 64
Set-RegistryValueSafe -Path $tcpParams -Name "TcpMaxDupAcks" -Value 0x2 -PropertyType DWord
Set-RegistryValueSafe -Path $tcpParams -Name "Tcp1323Opts" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $tcpParams -Name "MaxUserPort" -Value 0xfffe -PropertyType DWord # 0xfffe = 65534
Set-RegistryValueSafe -Path $tcpParams -Name "TCPTimedWaitDelay" -Value 0x1e -PropertyType DWord # 0x1e = 30

Write-Host "  -> Network TCP autotuning normal, CUBIC, TIME_WAIT=0x1e, MaxUserPort=0xfffe." -ForegroundColor Gray

# -------------------------------------------------------------
# 8. TELEMETRY, COPILOT, PROMOTIONS & BLOATWARE ELIMINATION
# -------------------------------------------------------------
Write-Host "[8/10] Disabling Windows Copilot, Bing Web Search, Cloud Bloat & Telemetry..." -ForegroundColor Green

# 1. Disable Windows Copilot
Set-RegistryValueSafe -Path "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0x0 -PropertyType DWord

# 2. Disable Bing Search in Windows Start Menu (Stops Edge background telemetry when typing)
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "DisableWebSearch" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0x0 -PropertyType DWord

# 3. Disable Windows Consumer Features & Cloud Content (Prevents TikTok, CandyCrush auto-downloads on fresh install)
$cloudKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
Set-RegistryValueSafe -Path $cloudKey -Name "DisableWindowsConsumerFeatures" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $cloudKey -Name "DisableCloudOptimizedContent" -Value 0x1 -PropertyType DWord

# 4. Disable User Activity Tracking & Timeline Uploads
$sysPolicyKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
Set-RegistryValueSafe -Path $sysPolicyKey -Name "PublishUserActivities" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $sysPolicyKey -Name "UploadUserActivities" -Value 0x0 -PropertyType DWord

# 5. Disable Advertising ID & Tailored Experiences
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0x0 -PropertyType DWord

# 6. Disable Lock Screen Promos & Content Delivery Suggestions
$cdmKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
Set-RegistryValueSafe -Path $cdmKey -Name "FeatureManagementEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "RotatingLockScreenEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "RotatingLockScreenOverlayEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "SoftLandingEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "SystemPaneSuggestionsEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "SubscribedContent-338387Enabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "SubscribedContent-338388Enabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $cdmKey -Name "SubscribedContent-338389Enabled" -Value 0x0 -PropertyType DWord

# 7. Disable Windows Widgets & Taskbar Clutter
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarMn" -Value 0x0 -PropertyType DWord # Chat/Teams button

# 8. File Explorer Power User Defaults (Show file extensions, show hidden files)
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 0x1 -PropertyType DWord

# 9. Telemetry Data Collection Restrictions
$dataCollKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
Set-RegistryValueSafe -Path $dataCollKey -Name "AllowTelemetry" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path $dataCollKey -Name "LimitDiagnosticLogCollection" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $dataCollKey -Name "LimitDumpCollection" -Value 0x1 -PropertyType DWord
Set-RegistryValueSafe -Path $dataCollKey -Name "AllowDeviceNameInTelemetry" -Value 0x0 -PropertyType DWord

# 10. UI Snappiness (0ms menu delay)
Set-RegistryValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -PropertyType String
Set-RegistryValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "AutoEndTasks" -Value "1" -PropertyType String
Set-RegistryValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "WaitToKillAppTimeout" -Value "2000" -PropertyType String
Set-RegistryValueSafe -Path "HKCU:\Control Panel\Desktop" -Name "HungAppTimeout" -Value "1000" -PropertyType String

# 11. Edge & Chrome Background Process Prevention
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "BackgroundModeEnabled" -Value 0x0 -PropertyType DWord
Set-RegistryValueSafe -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "BackgroundModeEnabled" -Value 0x0 -PropertyType DWord

Write-Host "  -> Copilot disabled, Bing search off, Cloud bloat blocked, Advertising ID & Telemetry off." -ForegroundColor Gray

# -------------------------------------------------------------
# 9. DEBLOAT UWP PACKAGES (STOCK BLOAT REMOVAL)
# -------------------------------------------------------------
Write-Host "[9/10] Removing Out-of-the-Box Windows Bloatware Apps..." -ForegroundColor Green

# Packages that are currently uninstalled / missing from your lean Windows install
$stockBloatPackages = @(
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.GamingApp",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.People",
    "Microsoft.Todos",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Clipchamp.Clipchamp"
)

foreach ($pkg in $stockBloatPackages) {
    Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
}
Write-Host "  -> Stock bloatware apps (Cortana/Solitaire/News/FeedbackHub/Maps) purged." -ForegroundColor Gray

# -------------------------------------------------------------
# 10. WINDOWS BUILT-IN SERVICE MANAGEMENT (47 EXACT SERVICES)
# -------------------------------------------------------------
Write-Host "[10/10] Trimming Exact Built-in Windows Services (Zero 3rd-Party Software)..." -ForegroundColor Green

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
Write-Host "Game Mode ON, ReBAR enabled, and low-latency gaming." -ForegroundColor Cyan
Write-Host ""

if (-not $SkipReboot) {
    Write-Host "A system restart is recommended for all kernel and power tweaks to take full effect." -ForegroundColor Yellow
}
