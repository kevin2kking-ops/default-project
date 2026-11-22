param(
    [ValidateSet("ApplyWeek", "Next", "Rest")]
    [string]$Mode = "ApplyWeek"
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$statePath = Join-Path $here "state.txt"
$anime = "C:\Users\KEVIN\OneDrive\Pictures\AnimeDesktop"
$rainmeter = "C:\Program Files\Rainmeter\Rainmeter.exe"
$layouts = @(
    "illustro default",
    "Iron Man OS 1.3",
    "[HOLO] - J.A.R.V.I.S. + S.H.I.E.L.D. O.S",
    "[BIG] - J.A.R.V.I.S. + S.H.I.E.L.D. O.S",
    "[OLD] - J.A.R.V.I.S. + S.H.I.E.L.D. O.S"
)

function Set-AnimeSlideshow([string]$Folder, [uint32]$IntervalMs) {
    if (-not ("SlideSet" -as [type])) {
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class SlideSet {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left, Top, Right, Bottom; }
  [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  public interface IShellItem {
    void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
    void GetParent(out IShellItem ppsi);
    void GetDisplayName(uint sigdnName, out IntPtr ppszName);
    void GetAttributes(uint sfgaoMask, out uint psfgaoAttribs);
    void Compare(IShellItem psi, uint hint, out int piOrder);
  }
  [ComImport, Guid("B63EA76D-1F85-456F-A19C-48159EFA858B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  public interface IShellItemArray {
    void BindToHandler(IntPtr pbc, ref Guid bhid, ref Guid riid, out IntPtr ppv);
    void GetPropertyStore(int flags, ref Guid riid, out IntPtr ppv);
    void GetPropertyDescriptionList(ref Guid key, ref Guid riid, out IntPtr ppv);
    void GetAttributes(int attribFlags, uint mask, out uint attribs);
    void GetCount(out uint count);
    void GetItemAt(uint index, out IntPtr ppsi);
    void EnumItems(out IntPtr ppenum);
  }
  [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
  public interface IDesktopWallpaper {
    void SetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, [MarshalAs(UnmanagedType.LPWStr)] string wallpaper);
    void GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out IntPtr wallpaper);
    void GetMonitorDevicePathAt(uint monitorIndex, out IntPtr monitorID);
    void GetMonitorDevicePathCount(out uint count);
    void GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorID, out RECT displayRect);
    void SetBackgroundColor(uint color);
    void GetBackgroundColor(out uint color);
    void SetPosition(int position);
    void GetPosition(out int position);
    void SetSlideshow(IShellItemArray items);
    void GetSlideshow(out IntPtr items);
    void SetSlideshowOptions(uint options, uint slideshowTick);
    void GetSlideshowOptions(out uint options, out uint slideshowTick);
    void AdvanceSlideshow([MarshalAs(UnmanagedType.LPWStr)] string monitorID, int direction);
    void GetStatus(out uint state);
    void Enable([MarshalAs(UnmanagedType.Bool)] bool enable);
  }
  [ComImport, Guid("C2CF3110-460E-4fc1-B9D0-8A1C0C9CC4BD")]
  public class DesktopWallpaper {}
  [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
  static extern void SHCreateItemFromParsingName(string pszPath, IntPtr pbc, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out IShellItem ppv);
  [DllImport("shell32.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
  static extern void SHCreateShellItemArrayFromShellItem(IShellItem psi, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out IShellItemArray ppv);
  public static void Apply(string folder, uint intervalMs) {
    Guid itemId = new Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE");
    Guid arrayId = new Guid("B63EA76D-1F85-456F-A19C-48159EFA858B");
    IShellItem item;
    SHCreateItemFromParsingName(folder, IntPtr.Zero, ref itemId, out item);
    IShellItemArray array;
    SHCreateShellItemArrayFromShellItem(item, ref arrayId, out array);
    IDesktopWallpaper wp = (IDesktopWallpaper)new DesktopWallpaper();
    wp.SetSlideshow(array);
    wp.SetSlideshowOptions(1, intervalMs);
    wp.SetPosition(4);
    wp.Enable(true);
  }
}
"@
    }
    [SlideSet]::Apply($Folder, $IntervalMs)
    $reg = "HKCU:\Control Panel\Personalization\Desktop Slideshow"
    if (-not (Test-Path -LiteralPath $reg)) { New-Item -Path $reg -Force | Out-Null }
    Set-ItemProperty -Path $reg -Name Interval -Value $IntervalMs -Type DWord
    Set-ItemProperty -Path $reg -Name Shuffle -Value 1 -Type DWord
}

function Set-Layout([string]$Name) {
    if (-not (Test-Path -LiteralPath $rainmeter)) { throw "Rainmeter.exe not found" }
    if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath $rainmeter
        Start-Sleep -Seconds 2
    }
    Start-Process -FilePath $rainmeter -ArgumentList "!LoadLayout", "`"$Name`""
}

if ($Mode -eq "Rest") {
    if (Get-Process Rainmeter -ErrorAction SilentlyContinue) { Start-Process -FilePath $rainmeter -ArgumentList "!Quit" }
    Write-Output "rest: Rainmeter stopped"
    exit 0
}

$walls = @(Get-ChildItem -LiteralPath $anime -File | Where-Object {
    $_.Extension -match '^\.(jpg|jpeg|png)$' -and $_.Name -ne "_live_temp.jpg"
} | Sort-Object Name)
if ($walls.Count -eq 0) { throw "no anime wallpapers in $anime" }

$epoch = Get-Date "2026-01-05"
$week = [int][math]::Floor(((Get-Date) - $epoch).TotalDays / 7)
if ($week -lt 0) { $week = 0 }
if ($Mode -eq "Next") { $week = $week + 1 }

$show = Join-Path $anime "WeekSlideshow"
if (Test-Path -LiteralPath $show) { Remove-Item -LiteralPath $show -Recurse -Force }
New-Item -ItemType Directory -Path $show | Out-Null
foreach ($w in $walls) { Copy-Item -LiteralPath $w.FullName -Destination (Join-Path $show $w.Name) }
$layout = $layouts[$week % $layouts.Count]
Set-Layout $layout
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -like "*LiveWallpaper.ps1*" } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
& (Join-Path $here "Enable-Slideshow.ps1") | Out-Null
Set-Content -LiteralPath $statePath -Value ("week=" + $week + "`r`nmode=slideshow`r`nfolder=" + $show + "`r`nimages=" + $walls.Count + "`r`nintervalMs=60000`r`nlayout=" + $layout)
Write-Output ("slideshow images=" + $walls.Count + " every 60s layout=" + $layout)
