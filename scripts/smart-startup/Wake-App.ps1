# Wake-App.ps1 - give a managed app full resources when you need it
# Usage: .\Wake-App.ps1 -AppName Rainmeter
#        .\Wake-App.ps1 -List
param(
  [string]$AppName = "",
  [switch]$List
)

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$config = Get-Content (Join-Path $here "config.json") -Raw | ConvertFrom-Json

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinShow {
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@ -ErrorAction SilentlyContinue

if ($List) {
  Write-Output "Managed:"
  $config.managedApps | ForEach-Object { Write-Output (" - " + $_.match + " (t+" + $_.delaySec + "s)") }
  Write-Output "Running candidates:"
  Get-Process | Where-Object { $_.ProcessName -match "rainmeter|wallpaper|chrome|msedge|google" } |
    Select-Object ProcessName, Id, PriorityClass, @{N="MB";E={[math]::Round($_.WS/1MB,1)}} |
    Format-Table -AutoSize | Out-String | Write-Output
  exit 0
}

if (-not $AppName) { Write-Output "Usage: .\Wake-App.ps1 -AppName <match>  |  -List"; exit 1 }

$procs = Get-Process -ErrorAction SilentlyContinue | Where-Object {
  $_.ProcessName -like "*$AppName*" -or $_.MainWindowTitle -like "*$AppName*"
}
if (-not $procs) {
  Write-Output "Not running: $AppName. Starting it now via SmartStartup match..."
  $startup = Get-CimInstance Win32_StartupCommand | Where-Object { $_.Name -like "*$AppName*" } | Select-Object -First 1
  if ($startup) { Write-Output ("Found autostart: " + $startup.Command); Write-Output "Run it manually once, then it will be lazy-managed after reboot." }
  else { Write-Output "No autostart entry found for $AppName." }
  exit 1
}

foreach ($p in $procs) {
  try {
    $p.PriorityClass = "Normal"
    if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
      [WinShow]::ShowWindow($p.MainWindowHandle, 9) | Out-Null  # SW_RESTORE
    }
    Write-Output ("Woke $($p.ProcessName) pid=$($p.Id) -> Normal priority")
  } catch { Write-Output ("FAIL $($p.ProcessName): " + $_.Exception.Message) }
}
