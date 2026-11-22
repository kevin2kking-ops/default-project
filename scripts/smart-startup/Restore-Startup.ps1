# Restore-Startup.ps1 - undo Install-SmartStartup.ps1
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $here "backup-startup"
$userStartup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"

Get-ChildItem $userStartup -Filter "*.disabled" -ErrorAction SilentlyContinue | ForEach-Object {
  $orig = $_.FullName -replace "\.disabled$", ""
  Move-Item $_.FullName $orig -Force
  Write-Output ("RESTORED: " + (Split-Path $orig -Leaf))
}

$runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
Get-ChildItem $backupDir -Filter "HKCU-Run-*.txt" -ErrorAction SilentlyContinue | ForEach-Object {
  $n = $_.BaseName -replace "^HKCU-Run-", ""
  $v = Get-Content $_.FullName -Raw
  New-ItemProperty $runKey -Name $n -Value $v.Trim() -PropertyType String -Force | Out-Null
  Write-Output ("RESTORED HKCU Run: " + $n)
}

Unregister-ScheduledTask -TaskName "SmartStartup-Lazy" -Confirm:$false -ErrorAction SilentlyContinue
$fallback = Join-Path $userStartup "SmartStartup-Lazy.lnk"
if (Test-Path $fallback) { Remove-Item $fallback -Force; Write-Output "Removed fallback shortcut." }
Write-Output "SmartStartup task removed (if existed)."
