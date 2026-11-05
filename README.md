# Windows Minimal & High-Performance Setup ⚡

A clean, declarative, reproducible PowerShell setup to transform a stock Windows 11 installation into a lean, minimal, low-latency environment with an idle baseline of **~130–140 processes** (down from 250–350+ out-of-the-box).

---

## 🚀 What This Does

### 1. Form Factor Optimization: Desktop vs Laptop
* Prompts user or auto-detects hardware form factor (`Win32_SystemEnclosure ChassisTypes`).
* **If Normal Desktop:**
  * `CoalescingTimerInterval = 0x0` (DWORD Hex 0): Disables timer coalescing to eliminate CPU interrupt jitter on wall power.
  * `HibernateEnabled = 0x0` (DWORD Hex 0): Disables hibernation and removes the large `hiberfil.sys` file.
* **If Laptop:**
  * Preserves battery timer coalescing and lid/hibernation states.

### 2. Curated Advanced Power Plan Visibility (Exact 34 Settings)
Unhides specifically your 34 essential power settings in Windows Control Panel (`powercfg.cpl`), including:
* **Processor Power Management:** Boost mode, Core parking min/max, idle demote/promote thresholds, frequency states, and heterogeneous scheduling (P-core vs E-core).
* **PCI Express:** Link State Power Management.
* **Storage & Display:** Disk spin-down timeout, adaptive display dimming, brightness.
* **Sleep & Timers:** Sleep after, Hibernate after, Allow hybrid sleep, unattended sleep timeouts.
* **Activates High Performance Power Scheme.**

### 3. Gaming, Windows Game Mode & Low-Latency DirectFlip
* **Windows Game Mode = ON** (`AutoGameModeEnabled = 0x1`).
* **Multimedia Class Scheduler (`Tasks\Games`):**
  * `Affinity = 0x0` (DWORD Hex 0)
  * `Background Only = "False"` (String)
  * `Clock Rate = 0x2710` (DWORD Hex 2710 / Decimal 10000)
  * `SFIO Priority = "High"` (String)
  * `Scheduling Category = "High"` (String)
  * `GPU Priority = 0x8` & `Priority = 0x6`
  * `Latency Sensitive = "True"` (String)
* **DirectFlip & DXGI Low-Latency Swapchain:**
  * `EnableMMCSS = 0x1`, `SystemResponsiveness = 0xa` (Hex 0xa = Decimal 10)
  * `AlwaysUseDirectFlip = 0x1` (Bypasses DWM compositor overhead in windowed/borderless games)
  * `AllowTearing = 0x1` (Allows uncapped tearing frames for minimal latency)
  * `AlwaysOn = 0x1` & `NoLazyMode = 0x1`
* Disables `GameDVR` background recording, FSE overlays, and screenshot capture hooks.
* **HAGS (Hardware-Accelerated GPU Scheduling) is left untouched / disabled** per system preference.

### 4. Kernel DPC, Interrupts & Memory Management
* **`Session Manager\kernel`:**
  * `DebugPollInterval = 0x3e8` (DWORD Hex 3e8 = Decimal 1000)
  * `DpcWatchdogProfileOffset = 0x2710` (DWORD Hex 2710 = Decimal 10000)
  * `ThreadDpcEnable = 0x0` (DWORD Hex 0)
  * `KernelSEHOPEnabled = 0x0` (DWORD Hex 0)
* **`Session Manager\Memory Management`:**
  * `LargeSystemCache = 0x0` (DWORD Hex 0)
  * `SecondLevelDataCache = 0x0` (DWORD Hex 0)
  * `DisablePagingExecutive = 0x1` (DWORD Hex 1: Keeps drivers and Windows kernel locked in physical RAM)
  * `IoPageLockLimit = 0x8000000` (DWORD Hex 8000000 = 128 MB)
* `Disable-MMAgent -MemoryCompression`: **Disables Windows Memory Compression** (`MemoryCompression = False`) and Page Combining.
* `Win32PrioritySeparation = 0x26` (DWORD Hex 26 = Decimal 38): Short, variable high-priority quantum favoring foreground gaming loops.
* **Raw 1:1 Mouse Input:** Disables Enhanced Pointer Precision via `MouseSpeed = "0"`, `MouseThreshold1 = "0"`, `MouseThreshold2 = "0"` (String values).

### 5. Memory Integrity (HVCI) & Resizable BAR
* **Memory Integrity / Core Isolation (HVCI) Disabled:** Reduces hypervisor overhead and eliminates game micro-stutters.
* **Resizable BAR (ReBAR) Support:** Enables driver memory management flags (`MemoryManagement.ReBar = 0x1`, `RMReBar = 0x1`).

### 6. Interactive Security Prompt (VBS & Secure Boot)
* When run interactively, the script offers an **optional prompt to disable VBS (Virtualization-Based Security)**:
  * **Benefit:** 5–15% higher FPS in CPU-bound titles and consistent 1% low frame times.
  * **Trade-Off:** Lower virtualization defense (Credential Guard disabled).
  * **Secure Boot Note:** Clarifies that Secure Boot is handled in BIOS/UEFI and required by games with kernel anti-cheat (e.g. Riot Vanguard, Valorant).

### 7. Advanced Network & TCP/IP Stack
* Configures TCP congestion provider to `CUBIC`.
* Sets TCP autotuning level to `Normal`.
* Enables Receive Side Scaling (`RSS`) and Receive Segment Coalescing (`RSC`) for multi-core packet offloading.
* `TCPTimedWaitDelay = 0x1e` (DWORD Hex 1e = Decimal 30): Accelerates socket reuse.
* `MaxUserPort = 0xfffe` (DWORD Hex fffe = Decimal 65534): Maximizes dynamic outbound port availability.
* `DefaultTTL = 0x40` (DWORD Hex 40 = Decimal 64).
* `TcpMaxDupAcks = 0x2`, `SackOpts = 0x1`, `EnablePMTUDiscovery = 0x1`.

### 8. Telemetry, Copilot, Bing Search & Bloatware Elimination
* **Windows Copilot Disabled:** Sets `TurnOffWindowsCopilot = 0x1` and hides the Copilot taskbar button (`ShowCopilotButton = 0x0`).
* **Bing Web Search in Start Menu Disabled:** Sets `BingSearchEnabled = 0x0`, `DisableWebSearch = 0x1`, and `ConnectedSearchUseWeb = 0x0` to prevent Windows Start Menu from sending keystrokes and search queries to Bing.
* **Windows Consumer Cloud Content Blocked:** Sets `DisableWindowsConsumerFeatures = 0x1` (stops fresh installs from auto-downloading TikTok, Instagram, Disney, etc.).
* **User Activity Tracking / Timeline Uploads Disabled:** Sets `PublishUserActivities = 0x0` and `UploadUserActivities = 0x0`.
* **Advertising ID & Suggestions Disabled:** Sets `AdvertisingInfo\Enabled = 0x0`, `TailoredExperiences = 0x0`, and disables lock screen tips/promos.
* **Taskbar Clutter Cleaned:** Hides Task View button (`ShowTaskViewButton = 0x0`), Widgets (`AllowNewsAndInterests = 0x0`), and Chat/Teams (`TaskbarMn = 0x0`).
* **File Explorer Power User Defaults:** `HideFileExt = 0x0` (Always show file extensions), `Hidden = 0x1` (Show hidden files).
* Sets `MenuShowDelay = "0"` for instantaneous right-click and menu rendering.

### 9. Out-of-the-Box Bloatware App Removal (UWP)
* Removes unused stock packages that are stripped from your current lean install:
  * `BingNews`, `BingWeather`, `GamingApp`, `GetHelp`, `Getstarted`, `OfficeHub`, `SolitaireCollection`, `People`, `Todos`, `FeedbackHub`, `WindowsMaps`, `YourPhone`, `ZuneMusic`, `ZuneVideo`, `Clipchamp`.

### 10. Pure Windows Internal Service Trimming (47 Exact Services)
* Contains **zero third-party software services** — only pure Windows internal services.
* Sets all 47 Windows daemons that cause process bloat to `Disabled` (e.g., `DiagTrack`, `SysMain`, `WSearch`, `WerSvc`, `PcaSvc`, `DPS`, `TrkWks`, `WalletService`, `CscService`, `TermService`).
* Sets `lfsvc` (Geolocation) to `Manual`.

---

## 🛠️ Usage

### Quick Run (Interactive Prompt)
1. Open **PowerShell** as **Administrator**.
2. Run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Optimize-WindowsPostInstall.ps1
```

### Unattended Parameters
* Force Desktop configuration:
  ```powershell
  .\Optimize-WindowsPostInstall.ps1 -DeviceType Desktop
  ```
* Force Laptop configuration:
  ```powershell
  .\Optimize-WindowsPostInstall.ps1 -DeviceType Laptop
  ```
* Skip interactive VBS prompt:
  ```powershell
  .\Optimize-WindowsPostInstall.ps1 -ForceDisableVBS
  ```

### Standalone Power Settings Unhider
If you only want to expose the 34 curated power settings in the Windows Power Options dialog:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Unhide-PowerSettings.ps1
```
