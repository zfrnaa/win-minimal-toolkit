<#
.SYNOPSIS
    Unhide-PowerSettings.ps1 - Unhide your exact curated Power Options in Control Panel
.DESCRIPTION
    Sets Attributes = 2 for specifically the 34 curated power settings currently enabled
    on your system (Processor Performance Boost Mode, Core Parking, Frequency, PCI Express Link State, etc.)
    and launches Control Panel Power Options.
#>

# Check Administrator privileges
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator!"
    exit 1
}

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
$count = 0

Write-Host "Unhiding your 34 curated Advanced Power Settings in Windows..." -ForegroundColor Cyan

foreach ($item in $curatedPowerSettings) {
    $targetPath = Join-Path (Join-Path $basePowerKey $item.Sub) $item.Setting
    if (Test-Path $targetPath) {
        Set-ItemProperty -Path $targetPath -Name "Attributes" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
        $count++
    }
}

Write-Host "Done! Successfully unhid $count curated power settings." -ForegroundColor Green
Write-Host "Opening Advanced Power Options dialog..." -ForegroundColor Yellow
Start-Process "control.exe" -ArgumentList "powercfg.cpl,,3"
