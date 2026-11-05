# Windows Minimal & High-Performance Setup ⚡

A clean, declarative, reproducible PowerShell setup to transform a stock Windows 11 installation into a lean, minimal, low-latency environment with an idle baseline of **~130–140 processes** (down from 250–350+ out-of-the-box).

---

## 🚀 What This Does

### 1. Advanced Power Plan Visibility (No More Hidden Settings!)
By default, Windows hides dozens of critical power settings (CPU core parking, processor performance boost mode, PCIe power states, AHCI link management). 
* Sets `Attributes = 2` on all entries under `Control\Power\PowerSettings`.
* Makes all settings immediately visible and editable in `powercfg.cpl`.
* Activates the **High Performance** power scheme.

### 2. Gaming & System Responsiveness (MMCSS)
* `SystemResponsiveness = 0`: Allocates 100% CPU priority to foreground applications instead of reserving 20% for background OS tasks.
* `NetworkThrottlingIndex = 0xffffffff`: Disables network throttling during CPU-heavy operations and gaming.
* `GPU Priority = 8` & `Priority = 6` for the Multimedia Class Scheduler (`Games` task).
* Disables `GameDVR` background recording and screenshot capture hooks.
* Enables Hardware-Accelerated GPU Scheduling (`HwSchMode = 2`).

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

### 6. Process & Service Trimming (~140 Process Baseline)
* Cleanly stops and sets unnecessary background services to `Disabled` (e.g. `DiagTrack`, `SysMain`, `WSearch`, `WerSvc`, `PcaSvc`, `DPS`, `TrkWks`, `WalletService`, `CscService`).
* Prevents Edge and Chrome from lingering in the background after closing.

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
If you only want to expose all hidden power settings in the Windows Power Options dialog:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Unhide-PowerSettings.ps1
```

---

## 📂 Repository Structure

* `Optimize-WindowsPostInstall.ps1`: Main post-install script.
* `Unhide-PowerSettings.ps1`: Dedicated standalone utility to unhide power options.
* `README.md`: Documentation and setting details.
