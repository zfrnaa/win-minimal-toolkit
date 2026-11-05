# Windows Minimal & High-Performance Setup ⚡

A clean, declarative, reproducible PowerShell setup to transform a stock Windows 11 installation into a lean, minimal, low-latency environment with an idle baseline of **~130–140 processes** (down from 250–350+ out-of-the-box).

---

## 🚀 What This Does

### 1. Curated Advanced Power Plan Visibility (Exact 34 Settings)
Unhides specifically your 34 essential power settings in Windows Control Panel (`powercfg.cpl`), including:
* **Processor Power Management:** Boost mode, Core parking min/max, idle demote/promote thresholds, frequency states, and heterogeneous scheduling (P-core vs E-core).
* **PCI Express:** Link State Power Management.
* **Storage & Display:** Disk spin-down timeout, adaptive display dimming, brightness.
* **Sleep & Timers:** Sleep after, Hibernate after, Allow hybrid sleep, unattended sleep timeouts.
* **Activates High Performance Power Scheme.**

### 2. Gaming & System Responsiveness (MMCSS)
* `SystemResponsiveness = 0`: Allocates 100% CPU priority to foreground applications instead of reserving 20% for background OS tasks.
* `NetworkThrottlingIndex = 0xffffffff`: Disables network throttling during CPU-heavy operations and gaming.
* `GPU Priority = 8` & `Priority = 6` for the Multimedia Class Scheduler (`Games` task).
* Disables `GameDVR` background recording and screenshot capture hooks.
* **HAGS (Hardware-Accelerated GPU Scheduling) is left untouched / disabled** per system preference.

### 3. Network / TCP Stack Optimization
* Configures TCP congestion provider to `CUBIC`.
* Sets TCP autotuning level to `Normal`.
* Enables Receive Side Scaling (`RSS`) and Receive Segment Coalescing (`RSC`) for multi-core packet offloading.
* Disables ECN and TCP timestamps for reduced overhead.

### 4. Telemetry, Diagnostic & Promo Bloat Removal
* Disables telemetry data collection (`AllowTelemetry = 0`).
* Enforces dump and diagnostic log upload limits.
* Disables Windows 11 lock screen tips, Start suggestions, and Consumer Experience auto-installs.
* Disables Windows Widgets and News & Interests (`AllowNewsAndInterests = 0`).

### 5. Instant UI Responsiveness
* Sets `MenuShowDelay = 0` for instantaneous right-click and context menu rendering without artificial Windows delays.
* Speeds up application kill timeout on shutdown.

### 6. Pure Windows Internal Service Trimming (47 Exact Services)
* Contains **zero third-party software services** — only pure Windows internal services.
* Sets all 47 Windows daemons that cause process bloat to `Disabled` (e.g., `DiagTrack`, `SysMain`, `WSearch`, `WerSvc`, `PcaSvc`, `DPS`, `TrkWks`, `WalletService`, `CscService`, `TermService`).

---

## 🛠️ Usage

### Quick Run (Entire Optimization Suite)
1. Open **PowerShell** as **Administrator**.
2. Run:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Optimize-WindowsPostInstall.ps1
```
3. Restart your PC when prompted.

### Standalone Power Settings Unhider
If you only want to expose the 34 curated power settings in the Windows Power Options dialog:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Unhide-PowerSettings.ps1
```
