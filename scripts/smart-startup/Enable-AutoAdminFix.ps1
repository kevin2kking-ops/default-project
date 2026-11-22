# Enable-AutoAdminFix.ps1 - register one-shot admin repair task (runs once at next startup, elevated, no prompts)
# Requires: Run As Administrator (one time).
#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"
$taskName = "AdminFix-Auto"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$script = Join-Path $here "Admin-Fix-2-3-4.ps1"

$act = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ('-NoProfile -ExecutionPolicy Bypass -File "{0}" -Auto' -f $script)
$trig = New-ScheduledTaskTrigger -AtStartup
$set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 60)
Register-ScheduledTask -TaskName $taskName -Action $act -Trigger $trig -Settings $set -RunLevel Highest -Description "One-shot admin repairs: TDR/GPU fix, sfc, DISM, chkdsk, minidump" -Force | Out-Null
Write-Output "OK: task '$taskName' registered with highest privileges."
Write-Output "It will run ONCE at next startup and delete itself. No further action needed."
