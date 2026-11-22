# Install-SmartStartup.ps1 - backup native autostart, disable managed ones, create delayed logon task
# SAFE: only touches apps in config.json managedApps. NEVER touches antivirus/security.
# Run as normal user (no admin needed for HKCU + user Startup folder).
param([switch]$WhatIf)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$config = Get-Content (Join-Path $here "config.json") -Raw | ConvertFrom-Json
$backupDir = Join-Path $here "backup-startup"
if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory $backupDir -Force | Out-Null }

# 1. Backup full list
Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location, User |
  Export-Csv (Join-Path $backupDir ("backup-" + (Get-Date -Format "yyyyMMdd-HHmm") + ".csv")) -NoTypeInformation
Write-Output "Backup saved to $backupDir"

$userStartup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
foreach ($app in $config.managedApps) {
  # Disable .lnk in user startup by renaming to .lnk.disabled
  if (Test-Path $userStartup) {
    Get-ChildItem $userStartup -Filter "*.lnk*" | Where-Object { $_.Name -like "*$($app.match)*" } | ForEach-Object {
      $dest = $_.FullName + ".disabled"
      Write-Output ("DISABLE lnk: " + $_.Name)
      if (-not $WhatIf) { Move-Item $_.FullName $dest -Force }
    }
  }
  # Disable HKCU Run value (backup first)
  $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
  if (Test-Path $runKey) {
    Get-ItemProperty $runKey -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty |
      Where-Object { $_.Name -like "*$($app.match)*" } | ForEach-Object {
        $n = $_.Name
        $v = (Get-ItemProperty $runKey -Name $n).$n
        $v | Out-File (Join-Path $backupDir ("HKCU-Run-" + $n + ".txt"))
        Write-Output ("DISABLE HKCU Run: " + $n)
        if (-not $WhatIf) { Remove-ItemProperty $runKey -Name $n -Force }
      }
  }
}

# 2. Create logon trigger (delay handled inside SmartStartup.ps1 stagger)
$taskName = "SmartStartup-Lazy"
$ps = "powershell.exe"
$args = '-ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $here "SmartStartup.ps1") + '"'
if ($WhatIf) {
  Write-Output "WHATIF: would create logon task '$taskName' -> $ps $args"
} else {
  try {
    $act = New-ScheduledTaskAction -Execute $ps -Argument $args
    $trig = New-ScheduledTaskTrigger -AtLogOn
    $set = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -TaskName $taskName -Action $act -Trigger $trig -Settings $set -Description "Lazy low-resource startup manager" -Force | Out-Null
    Write-Output "Scheduled task '$taskName' installed. Reboot to test."
  } catch {
    Write-Output ("Task install failed with: " + $_.Exception.Message)
    Write-Output "Fallback: creating Startup-folder shortcut (no admin needed)."
    try {
      $lnkPath = Join-Path $userStartup "SmartStartup-Lazy.lnk"
      $sh = New-Object -ComObject WScript.Shell
      $sc = $sh.CreateShortcut($lnkPath)
      $sc.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
      $sc.Arguments = $args
      $sc.WindowStyle = 7
      $sc.Save()
      Write-Output ("Fallback shortcut created: " + $lnkPath)
    } catch {
      Write-Output ("Fallback also failed: " + $_.Exception.Message)
    }
  }
}
Write-Output "To undo: run Restore-Startup.ps1"
