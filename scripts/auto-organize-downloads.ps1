# Auto-Organize Downloads - Watches Downloads folder and moves files to rightful folders
# by OpenCode / Muse Spark - 2026-09-19
param(
  [string]$WatchFolder = "$env:USERPROFILE\Downloads",
  [switch]$RunOnce  # if set, only organizes existing files and exits (for testing)
)

# --- CONFIG: Map extensions to destinations ---
# Edit this hashtable to customize your organization
$MovieFolder   = Join-Path ([Environment]::GetFolderPath("Desktop")) "Movie"
$PicturesDest  = "C:\Users\KEVIN\OneDrive\Pictures\Downloads-Images"
$DocumentsDest = "C:\Users\KEVIN\OneDrive\Documents\Downloads-Documents"
$MusicDest     = "C:\Users\KEVIN\Music\Downloads-Music"
$InstallersDest= Join-Path $WatchFolder "Installers"
$ArchivesDest  = Join-Path $WatchFolder "Archives"
$SchoolNotesBase = "C:\Users\KEVIN\OneDrive\Documents\Default Project\BBIT_Y2S1_School_Notes"

# Discover WhatsApp transfers folders (dynamic session id)
$WhatsAppWatchFolders = @()
$waBase = "C:\Users\KEVIN\AppData\Local\Packages\5319275A.WhatsAppDesktop_cv1g1gvanyjgm\LocalState\sessions"
if (Test-Path $waBase) {
  $transfersRoots = Get-ChildItem -Path $waBase -Recurse -Directory -Filter "transfers" -ErrorAction SilentlyContinue
  foreach ($tr in $transfersRoots) {
    # watch each year folder inside transfers (2026-36, 2026-31 etc) recursively
    $WhatsAppWatchFolders += $tr.FullName
  }
}
# Phone Link inbox inside Downloads (files land here, e.g. 9/22 batch)
$MobileDevicesFolder = Join-Path $WatchFolder "Mobile Devices"
# All watch folders = Downloads + Mobile Devices + WhatsApp transfers
$AllWatchFolders = @($WatchFolder) + $WhatsAppWatchFolders
if (Test-Path -LiteralPath $MobileDevicesFolder) { $AllWatchFolders += $MobileDevicesFolder }

$ExtensionMap = @{
  # Videos -> Movie folder on Desktop (your request)
  '.mp4'  = $MovieFolder; '.mkv' = $MovieFolder; '.avi' = $MovieFolder; '.mov' = $MovieFolder
  '.ts'   = $MovieFolder; '.webm'= $MovieFolder; '.m4v'= $MovieFolder; '.wmv'= $MovieFolder
  '.flv'  = $MovieFolder; '.3gp' = $MovieFolder

  # Images -> Pictures
  '.jpg'  = $PicturesDest; '.jpeg'= $PicturesDest; '.png'= $PicturesDest; '.gif'= $PicturesDest
  '.bmp'  = $PicturesDest; '.svg'= $PicturesDest; '.webp'= $PicturesDest; '.heic'= $PicturesDest
  '.ico'  = $PicturesDest

  # Documents -> Documents
  '.pdf'  = $DocumentsDest; '.docx'= $DocumentsDest; '.doc'= $DocumentsDest; '.xlsx'= $DocumentsDest
  '.xls'  = $DocumentsDest; '.csv'= $DocumentsDest; '.pptx'= $DocumentsDest; '.ppt'= $DocumentsDest
  '.txt'  = $DocumentsDest; '.md' = $DocumentsDest; '.rtf'= $DocumentsDest

  # Music -> Music
  '.mp3'  = $MusicDest; '.wav'= $MusicDest; '.flac'= $MusicDest; '.aac'= $MusicDest
  '.ogg'  = $MusicDest; '.m4a'= $MusicDest; '.wma'= $MusicDest

  # Archives -> Downloads\Archives
  '.zip'  = $ArchivesDest; '.rar'= $ArchivesDest; '.7z'= $ArchivesDest; '.tar'= $ArchivesDest
  '.gz'   = $ArchivesDest; '.bz2'= $ArchivesDest

  # Installers -> Downloads\Installers
  '.exe'  = $InstallersDest; '.msi'= $InstallersDest; '.msix'= $InstallersDest
}

# Extensions to IGNORE (temporary download files)
$IgnoreExt = @('.crdownload','.part','.tmp','.downloading')
$IgnoreNames = @('desktop.ini','thumbs.db')

$LogFile = Join-Path $PSScriptRoot "auto-organize.log"
function Log($msg) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  $line = "[$ts] $msg"
  Write-Host $line
  try { Add-Content -LiteralPath $LogFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

function Ensure-Dir($path) {
  if (!(Test-Path -LiteralPath $path)) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Log "Created folder: $path"
  }
}

function Test-FileReady($path) {
  # Wait until file is not locked and size stable
  $stableCount = 0
  $lastSize = -1
  for ($i=0; $i -lt 30; $i++) { # max 30*500ms=15s wait
    try {
      $info = Get-Item -LiteralPath $path -ErrorAction Stop
      if ($info.PSIsContainer) { return $true }
      $size = $info.Length
      # try to open for read - if locked, will throw
      $stream = [System.IO.File]::Open($path, 'Open', 'Read', 'None')
      $stream.Close()
      if ($size -eq $lastSize -and $size -gt 0) { $stableCount++ } else { $stableCount=0 }
      $lastSize=$size
      if ($stableCount -ge 3) { return $true } # stable for 1.5s
    } catch {
      $stableCount=0
    }
    Start-Sleep -Milliseconds 500
  }
  return $false
}

function Get-SmartDocDestination($fileName) {
  $lower = $fileName.ToLower()
  # Course code routing to School Notes
  if ($lower -match "cit3206") { return Join-Path $SchoolNotesBase "04_CIT3206_Statistical_Programming - David_Kibaara" }
  if ($lower -match "cit3200") { return Join-Path $SchoolNotesBase "01_CIT3200_Operating_Systems - Stephen_Mageto" }
  if ($lower -match "ccs3200") { return Join-Path $SchoolNotesBase "02_CCS3200_Data_Structures_Algorithms - Patrick_Njuguna" }
  if ($lower -match "bfb3150") { return Join-Path $SchoolNotesBase "03_BFB3150_Insurance_Risk_Management - Dr_Virginia_Wachira" }
  if ($lower -match "ssa3120") { return Join-Path $SchoolNotesBase "05_SSA3120_Probability_Statistics - NICHOLAS_MUGAMBI" }
  if ($lower -match "bec3200") { return Join-Path $SchoolNotesBase "06_BEC3200_Principles_of_Macroeconomics - Titus_Kirimi" }
  if ($lower -match "bfc3226") { return Join-Path $SchoolNotesBase "07_BFC3226_Financial_Management - Samuel_Mbogori" }
  if ($lower -match "cit3202") { return Join-Path $SchoolNotesBase "08_CIT3202_Network_Design_Implementation - Eli_Kangaru" }
  if ($lower -match "operating system|os course|cpu scheduling|memory management|deadlock|interprocess|file management|process management|input.output|lesson\s*1|introduction edited") { return Join-Path $SchoolNotesBase "01_CIT3200_Operating_Systems - Stephen_Mageto" }
  if ($lower -match "week\s*(9|10|11|12|13)\b") { return Join-Path $SchoolNotesBase "01_CIT3200_Operating_Systems - Stephen_Mageto" }
  if ($lower -match "algorithm|growth rate|data-structures|ccs\s*3200") { return Join-Path $SchoolNotesBase "02_CCS3200_Data_Structures_Algorithms - Patrick_Njuguna" }
  if ($lower -match "bec\s*3150|macroeconomics|macro topic") { return Join-Path $SchoolNotesBase "06_BEC3200_Principles_of_Macroeconomics - Titus_Kirimi" }
  if ($lower -match "itn_module|network design|cit3202") { return Join-Path $SchoolNotesBase "08_CIT3202_Network_Design_Implementation - Eli_Kangaru" }
  if ($lower -match "week\s*[1-8]\.pdf|week\s*[1-8]\.docx") {
    # Week 1-8 from current WhatsApp batch - default to CIT3206 (where .docx already lives)
    # Check if source batch is 2026-36 which is CIT3206
    return Join-Path $SchoolNotesBase "04_CIT3206_Statistical_Programming - David_Kibaara"
  }
  if ($lower -match "supplementary|exams?\s*timetable") { return Join-Path $SchoolNotesBase "00_General" }
  return $null
}

function Get-Destination($filePath) {
  $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
  if ($IgnoreExt -contains $ext) { return $null }
  $name = [System.IO.Path]::GetFileName($filePath)
  $lower = $name.ToLower()
  if ($IgnoreNames -contains $lower) { return $null }
  # Smart routing for documents
  if ($ext -in @('.pdf','.docx','.doc','.xlsx','.xls','.csv','.pptx','.ppt','.txt','.md','.rtf')) {
    $smart = Get-SmartDocDestination $name
    if ($smart) { return $smart }
  }
  if ($ExtensionMap.ContainsKey($ext)) { return $ExtensionMap[$ext] }
  return $null # no mapping -> keep in place
}

function Move-ToRightfulFolder($fullPath) {
  # Skip directories that are already organizer folders or the Movie folder itself if we watch Desktop (not needed)
  if (!(Test-Path -LiteralPath $fullPath)) { return }
  $item = Get-Item -LiteralPath $fullPath -ErrorAction SilentlyContinue
  if (!$item) { return }
  if ($item.PSIsContainer) {
    # For folders: if folder contains a single video file inside, treat as movie folder
    $videos = Get-ChildItem -LiteralPath $fullPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $ExtensionMap.ContainsKey($_.Extension.ToLower()) -and $ExtensionMap[$_.Extension.ToLower()] -eq $MovieFolder }
    if ($videos -and $videos.Count -gt 0) {
      # Check if folder is a movie pack (e.g. "The Odyssey (2026) [720p]...")
      $dest = $MovieFolder
      Ensure-Dir $dest
      $destPath = Join-Path $dest $item.Name
      if ($fullPath -eq $destPath) { return }
      if (Test-Path -LiteralPath $destPath) {
        Log "SKIP folder already exists at dest: $destPath"
        return
      }
      if (!(Test-FileReady $fullPath)) { Log "Folder not ready: $fullPath"; return }
      try {
        Move-Item -LiteralPath $fullPath -Destination $destPath -Force -ErrorAction Stop
        Log "MOVED folder: $($item.Name) -> Movie\"
      } catch { Log "FAIL folder $($item.Name): $_" }
      return
    }
    return # ignore other folders
  }

  $destFolder = Get-Destination $fullPath
  if (!$destFolder) { return } # no rule, keep in place

  Ensure-Dir $destFolder
  $fileName = Split-Path $fullPath -Leaf
  $destPath = Join-Path $destFolder $fileName

  # Avoid moving if already in right place
  if ($fullPath -eq $destPath) { return }

  # Avoid overwrite - if dest exists, rename with (1)
  if (Test-Path -LiteralPath $destPath) {
    $base = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    $ext = [System.IO.Path]::GetExtension($fileName)
    $i=1
    do {
      $newName = "$base ($i)$ext"
      $destPath = Join-Path $destFolder $newName
      $i++
    } while (Test-Path -LiteralPath $destPath)
    Log "Destination exists, renaming to: $(Split-Path $destPath -Leaf)"
  }

  if (!(Test-FileReady $fullPath)) { Log "File not ready (still downloading): $fileName"; return }
  try {
    Move-Item -LiteralPath $fullPath -Destination $destPath -Force -ErrorAction Stop
    Log "MOVED: $fileName -> $(Split-Path $destFolder -Leaf)\"
  } catch { Log "FAIL $fileName : $_" }
}

function Organize-Existing {
  foreach ($wf in $AllWatchFolders) {
    if (!(Test-Path -LiteralPath $wf)) { continue }
    Log "Scanning existing files in: $wf"
    # For WhatsApp transfers, scan recursively (files are in subfolders 2026-36 etc)
    $isWhatsApp = $wf -like "*transfers*"
    if ($isWhatsApp) {
      $items = Get-ChildItem -LiteralPath $wf -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.DirectoryName -ne $wf } | Select-Object -First 100
      # Convert to FileInfo with FullName
      foreach ($it in $items) {
        # Skip already processed? just try move
        Move-ToRightfulFolder $it.FullName
      }
    } else {
      $items = Get-ChildItem -LiteralPath $wf -ErrorAction SilentlyContinue
      foreach ($it in $items) {
        if ($it.FullName -eq $MovieFolder -or $it.FullName -eq $PicturesDest -or $it.FullName -eq $DocumentsDest -or $it.FullName -eq $MusicDest) { continue }
        if ($it.Name -in @("Archives","Installers")) { continue }
        Move-ToRightfulFolder $it.FullName
      }
    }
  }
  Log "Initial scan complete."
}

# --- MAIN ---
Log "=== Auto-Organize started (Watch: $($AllWatchFolders -join ', ')) ==="
Ensure-Dir $MovieFolder
Ensure-Dir $PicturesDest
Ensure-Dir $DocumentsDest
Ensure-Dir $MusicDest
Ensure-Dir $InstallersDest
Ensure-Dir $ArchivesDest
Ensure-Dir $SchoolNotesBase

Organize-Existing

if ($RunOnce) {
  Log "RunOnce mode - exiting."
  exit 0
}

Log "Watching for new downloads (polling every 10s)..."
Log "Destinations: Movie=$MovieFolder | Pictures=$PicturesDest | Docs=$DocumentsDest | Music=$MusicDest | Installers=$InstallersDest | Archives=$ArchivesDest"
Log "SchoolNotes: $SchoolNotesBase | WhatsApp: $($WhatsAppWatchFolders -join ', ') | MobileDevices: $MobileDevicesFolder"
Log "Press Ctrl+C to stop. Or run via Startup shortcut for background."

# Polling loop - reliable, no FileSystemWatcher scoping issues
while ($true) {
  try {
    Organize-Existing
  } catch { Log "Poll error: $_" }
  Start-Sleep -Seconds 10
}
