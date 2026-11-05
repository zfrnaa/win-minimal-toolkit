<#
.SYNOPSIS
    Unhide-PowerSettings.ps1 - Unhide all hidden Power Options in Control Panel
.DESCRIPTION
    Iterates through all power subkeys under HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings
    and sets Attributes = 2 so they show up directly in Windows Advanced Power Settings.
    
    Includes:
      - Processor performance boost mode (Aggressive, Efficient, Disabled)
      - Processor idle demote/promote thresholds
      - Core parking minimum/maximum cores
      - Heterogeneous thread scheduling policy (P-cores vs E-cores)
      - PCIe Link State Power Management
      - AHCI Link Power Management (HIPM / DIPM)
      - USB selective suspend timeout
#>

# Check Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator!"
    exit 1
}

$powerSettingsKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings"
$count = 0

Write-Host "Unhiding all Advanced Power Settings in Windows..." -ForegroundColor Cyan

Get-ChildItem $powerSettingsKey -ErrorAction SilentlyContinue | ForEach-Object {
    Get-ChildItem $_.PSPath -ErrorAction SilentlyContinue | ForEach-Object {
        $settingPath = $_.PSPath
        $attrs = (Get-ItemProperty $settingPath -ErrorAction SilentlyContinue).Attributes
        if ($null -ne $attrs -and $attrs -ne 2) {
            Set-ItemProperty -Path $settingPath -Name "Attributes" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
            $count++
        }
    }
}

Write-Host "Done! Unhid / verified $count power settings." -ForegroundColor Green
Write-Host "Opening Advanced Power Options dialog..." -ForegroundColor Yellow
Start-Process "control.exe" -ArgumentList "powercfg.cpl,,3"
