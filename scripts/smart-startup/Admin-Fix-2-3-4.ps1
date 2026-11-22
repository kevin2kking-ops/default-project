# Admin-Fix.ps1 - Fixes 2,3,4. MUST right-click > Run as Administrator.
#Requires -RunAsAdministrator
param([switch]$Auto)
$ErrorActionPreference = "Continue"

$logPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "admin-fix.log"
Start-Transcript -Path $logPath -Force | Out-Null

Write-Output "=== FIX 2: system repair ==="
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
chkdsk C: /scan
Write-Output "Intel GPU:"
Get-WmiObject Win32_VideoController | Select-Object Name, DriverVersion, DriverDate | Format-List | Out-String | Write-Output

Write-Output "=== FIX 3: crash logging + fast startup ==="
$cc = "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl"
Set-ItemProperty $cc -Name CrashDumpEnabled -Value 3 -Type DWord -Force
Set-ItemProperty $cc -Name MinidumpDir -Value "C:\Windows\Minidump" -Type ExpandString -Force
Set-ItemProperty $cc -Name Overwrite -Value 1 -Type DWord -Force
Set-ItemProperty $cc -Name AutoReboot -Value 1 -Type DWord -Force
Set-ItemProperty $cc -Name LogEvent -Value 1 -Type DWord -Force
if (-not (Test-Path "C:\Windows\Minidump")) { New-Item -ItemType Directory "C:\Windows\Minidump" -Force | Out-Null }
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name HiberbootEnabled -Value 0 -Type DWord -Force
Write-Output "Minidump=small(3), fast-startup disabled."

Write-Output "=== FIX 4: GPU TDR mitigation for Intel HD 520 ==="
$gd = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
# TdrDelay 2s default is too aggressive for old iGPU under RAM pressure -> 8s
New-ItemProperty $gd -Name TdrDelay -Value 8 -PropertyType DWord -Force | Out-Null
New-ItemProperty $gd -Name TdrDdiDelay -Value 10 -PropertyType DWord -Force | Out-Null
New-ItemProperty $gd -Name TdrLevel -Value 3 -PropertyType DWord -Force | Out-Null
Write-Output "TdrDelay=8, TdrDdiDelay=10, TdrLevel=3 set. REBOOT required."
Write-Output "Next: install HP EliteBook 840 G3 Intel HD 520 driver from HP.com (not Intel generic)."
Get-ItemProperty $gd | Select-Object TdrDelay, TdrDdiDelay, TdrLevel | Format-List | Out-String | Write-Output
Write-Output "DONE. Reboot, then run SmartStartup Install if you want lazy startup."
if ($Auto) {
  Unregister-ScheduledTask -TaskName "AdminFix-Auto" -Confirm:$false -ErrorAction SilentlyContinue
  Write-Output "Auto one-shot task 'AdminFix-Auto' removed."
}
Stop-Transcript | Out-Null
