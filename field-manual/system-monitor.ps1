# system-monitor.ps1 - feeds live system data to system-monitor.html
# The page polls system-monitor.json every 3s; this script keeps it fresh.
#
# Run:  .\system-monitor.ps1           -> live loop, Ctrl+C to stop
#       .\system-monitor.ps1 -Once     -> write one snapshot and exit (testing)
# Note: if the page shows OFFLINE, open system-monitor.html via a local server
#       (e.g. `npx serve .` or `python -m http.server`) - browsers block
#       fetch() on file:// pages.
param(
  [int]$IntervalSeconds = 3,
  [switch]$Once
)

$ErrorActionPreference = "SilentlyContinue"
$OutFile = Join-Path $PSScriptRoot "system-monitor.json"

function Get-Snapshot {
  # --- previous network + process CPU samples (module scope) ---
  if ($null -eq $script:NetPrev) { $script:NetPrev = $null }
  if ($null -eq $script:CpuPrev) { $script:CpuPrev = @{} }
  if ($null -eq $script:LastTs)  { $script:LastTs  = Get-Date }

  $now = Get-Date
  $elapsed = ($now - $script:LastTs).TotalSeconds
  if ($elapsed -lt 0.5) { $elapsed = [math]::Max($elapsed, 0.5) }
  $script:LastTs = $now

  $os = Get-CimInstance Win32_OperatingSystem
  $cpu = Get-CimInstance Win32_Processor

  # --- RAM (GB) ---
  $ramTotal = [math]::Round(($os.TotalVisibleMemorySize) / 1MB, 1)
  $ramUsed  = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)

  # --- Disk C: (GB) ---
  $d = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
  $diskTotal = [math]::Round($d.Size / 1GB, 1)
  $diskUsed  = [math]::Round(($d.Size - $d.FreeSpace) / 1GB, 1)

  # --- CPU % (average across cores) ---
  $cpuLoad = [math]::Round(($cpu | Measure-Object -Property LoadPercentage -Average).Average, 1)

  # --- Uptime (seconds) + process count ---
  $uptime   = [math]::Round(($now - $os.LastBootUpTime).TotalSeconds)
  $procList = Get-Process
  $procCount = $procList.Count

  # --- Network bytes/sec (delta across all up adapters) ---
  $netDown = 0; $netUp = 0
  # .NET API instead of Get-NetAdapterStatistics (CIM, ~8s per call)
  $rx = 0; $tx = 0
  foreach ($nic in [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
    if ($nic.OperationalStatus -ne [System.Net.NetworkInformation.OperationalStatus]::Up) { continue }
    if ($nic.NetworkInterfaceType -eq [System.Net.NetworkInformation.NetworkInterfaceType]::Loopback) { continue }
    $st = $nic.GetIPv4Statistics()
    $rx += $st.BytesReceived; $tx += $st.BytesSent
  }
  if ($null -ne $script:NetPrev) {
    $netDown = [math]::Round([math]::Max(0, $rx - $script:NetPrev.rx) / $elapsed)
    $netUp   = [math]::Round([math]::Max(0, $tx - $script:NetPrev.tx) / $elapsed)
  }
  $script:NetPrev = @{ rx = $rx; tx = $tx }

  # --- Top processes by CPU (delta of TotalProcessorTime / elapsed) ---
  $topProcs = @()
  $newPrev = @{}
  foreach ($p in $procList) {
    try {
      $pt = $p.TotalProcessorTime.TotalMilliseconds
      $newPrev[$p.Id] = $pt
      $prev = $script:CpuPrev[$p.Id]
      if ($null -ne $prev) {
        $pct = [math]::Round(($pt - $prev) / ($elapsed * 1000) * 100, 1)
        if ($pct -gt 0.5) {
          $topProcs += [pscustomobject]@{ name = $p.ProcessName; cpu = $pct }
        }
      }
    } catch { }
  }
  $script:CpuPrev = $newPrev
  $topProcs = $topProcs | Sort-Object cpu -Descending | Select-Object -First 5

  return [pscustomobject]@{
    cpu        = $cpuLoad
    ramUsed    = $ramUsed
    ramTotal   = $ramTotal
    diskUsed   = $diskUsed
    diskTotal  = $diskTotal
    uptime     = $uptime
    processes  = $procCount
    netDown    = $netDown
    netUp      = $netUp
    timestamp  = $now.ToString("yyyy-MM-dd HH:mm:ss")
    topProcs   = @($topProcs)
  }
}

function Write-Snapshot($snap) {
  $json = $snap | ConvertTo-Json -Compress -Depth 4
  $tmp = "$OutFile.tmp"
  try {
    Set-Content -LiteralPath $tmp -Value $json -Encoding utf8
    Move-Item -LiteralPath $tmp -Destination $OutFile -Force   # atomic swap - page never sees half-written JSON
  } catch { }
}

# Prime CPU-delta sampler so the first snapshot already has top processes
Get-Snapshot | Out-Null
Start-Sleep -Seconds 1

if ($Once) {
  $snap = Get-Snapshot
  Write-Snapshot $snap
  Write-Output "Wrote $OutFile @ $($snap.timestamp)"
  exit 0
}

Write-Output "system-monitor: writing $OutFile every ${IntervalSeconds}s - Ctrl+C to stop"
try {
  while ($true) {
    Write-Snapshot (Get-Snapshot)
    Start-Sleep -Seconds $IntervalSeconds
  }
} finally {
  Write-Output "system-monitor stopped."
}
