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

### 2. Gaming, MMCSS & Low-Latency DirectFlip
* `SystemResponsiveness = 10`: Reserves 90% CPU priority for foreground games while retaining smooth background audio/voice comms.
* `NetworkThrottlingIndex = 0xffffffff`: Disables network throttling during CPU-heavy operations and gaming.
* `GPU Priority = 8` & `Priority = 6` for the Multimedia Class Scheduler (`Games` task).
* `Latency Sensitive = True`: Eliminates scheduler thread latency for gaming workloads.
* **DirectFlip & DXGI Low-Latency Swapchain:**
  * `EnableMMCSS = 1`
  * `AlwaysUseDirectFlip = 1` (Bypasses DWM compositor overhead for lower input latency in windowed/borderless games)
  * `AllowTearing = 1` (Allows uncapped tearing frames for minimal latency)
  * `AlwaysOn = 1` & `NoLazyMode = 1`
* Disables `GameDVR` background recording, FSE overlays, and screenshot capture hooks.
* **HAGS (Hardware-Accelerated GPU Scheduling) is left untouched / disabled** per system preference.

### 3. Kernel, Memory Management & 1:1 Mouse Input
* `Disable-MMAgent -MemoryCompression`: **Disables Windows Memory Compression** (`MemoryCompression = False`) and Page Combining. Since your PC has plenty of RAM (32 GB), turning this off eliminates the constant CPU overhead of compressing/decompressing memory pages in the background.
* `Win32PrioritySeparation = 38` (`0x26`): Short, variable high-priority quantum favoring foreground gaming loops.
* `DisablePagingExecutive = 1`: Keeps drivers and Windows kernel locked in physical RAM instead of paging to disk.
* `IoPageLockLimit = 134217728` (128 MB): Expands the I/O lock buffer for high disk/network transfer rates.
* **Raw 1:1 Mouse Input:** Disables Enhanced Pointer Precision (mouse acceleration) via `MouseSpeed = 0`, `MouseThreshold1 = 0`, `MouseThreshold2 = 0`.

### 4. Advanced Network & TCP/IP Stack
* Configures TCP congestion provider to `CUBIC`.
* Sets TCP autotuning level to `Normal`.
* Enables Receive Side Scaling (`RSS`) and Receive Segment Coalescing (`RSC`) for multi-core packet offloading.
* `TCPTimedWaitDelay = 30`: Accelerates socket reuse by lowering TIME_WAIT teardown from 120s down to 30s.
* `MaxUserPort = 65534`: Maximizes dynamic outbound port availability.
* `TcpMaxDupAcks = 2`: Speeds up fast retransmits on lost packets.
* `SackOpts = 1`, `EnablePMTUDiscovery = 1`.

### 5. Telemetry, Diagnostic & Promo Bloat Removal
* Disables telemetry data collection (`AllowTelemetry = 0`).
* Enforces dump and diagnostic log upload limits.
* Disables Windows 11 lock screen tips, Start suggestions, and Consumer Experience auto-installs.
* Disables Windows Widgets and News & Interests (`AllowNewsAndInterests = 0`).
* Sets `MenuShowDelay = 0` for instantaneous right-click and menu rendering.

### 6. Pure Windows Internal Service Trimming (47 Exact Services)
* Contains **zero third-party software services** — only pure Windows internal services.
* Sets all 47 Windows daemons that cause process bloat to `Disabled` (e.g., `DiagTrack`, `SysMain`, `WSearch`, `WerSvc`, `PcaSvc`, `DPS`, `TrkWks`, `WalletService`, `CscService`, `TermService`).
* Sets `lfsvc` (Geolocation) to `Manual`.

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
