$ErrorActionPreference = "Stop"
$folder = "C:\Users\KEVIN\OneDrive\Pictures\AnimeDesktop\WeekSlideshow"
if (-not (Test-Path -LiteralPath $folder)) { throw "missing $folder" }
$files = @(Get-ChildItem -LiteralPath $folder -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png)$' } | Select-Object -ExpandProperty FullName)
if ($files.Count -lt 2) { throw "need at least 2 images" }

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class SlideOn {
  [StructLayout(LayoutKind.Sequential)]
  public struct RECT { public int Left, Top, Right, Bottom; }
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
  [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
  public static extern IntPtr ILCreateFromPath(string pszPath);
  [DllImport("shell32.dll")]
  public static extern uint ILGetSize(IntPtr pidl);
  [DllImport("shell32.dll")]
  public static extern void ILFree(IntPtr pidl);
  [DllImport("shell32.dll", PreserveSig = false)]
  static extern void SHCreateShellItemArrayFromIDLists(uint cidl, IntPtr[] rgpidl, [MarshalAs(UnmanagedType.Interface)] out IShellItemArray ppsiItemArray);
  public static string Pidl(string path) {
    IntPtr pidl = ILCreateFromPath(path);
    if (pidl == IntPtr.Zero) throw new Exception("pidl failed");
    uint size = ILGetSize(pidl);
    byte[] bytes = new byte[size];
    Marshal.Copy(pidl, bytes, 0, (int)size);
    ILFree(pidl);
    return Convert.ToBase64String(bytes);
  }
  public static uint Apply(string[] files, uint intervalMs) {
    IntPtr[] pidls = new IntPtr[files.Length];
    for (int i = 0; i < files.Length; i++) pidls[i] = ILCreateFromPath(files[i]);
    IShellItemArray array;
    SHCreateShellItemArrayFromIDLists((uint)pidls.Length, pidls, out array);
    IDesktopWallpaper wp = (IDesktopWallpaper)new DesktopWallpaper();
    wp.SetSlideshow(array);
    wp.SetSlideshowOptions(1, intervalMs);
    wp.SetPosition(4);
    wp.Enable(true);
    wp.AdvanceSlideshow(null, 0);
    uint state;
    wp.GetStatus(out state);
    for (int i = 0; i < pidls.Length; i++) if (pidls[i] != IntPtr.Zero) ILFree(pidls[i]);
    return state;
  }
}
"@

$pidl = [SlideOn]::Pidl($folder)
$state = [SlideOn]::Apply($files, 60000)
$reg = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers"
Set-ItemProperty -Path $reg -Name BackgroundType -Value 2 -Type DWord
Set-ItemProperty -Path $reg -Name SlideshowSourceDirectoriesSet -Value 1 -Type DWord
Write-Output "pidl=$($pidl.Substring(0,12))"
$ss = "HKCU:\Control Panel\Personalization\Desktop Slideshow"
if (-not (Test-Path $ss)) { New-Item -Path $ss -Force | Out-Null }
Set-ItemProperty -Path $ss -Name Interval -Value 60000 -Type DWord
Set-ItemProperty -Path $ss -Name Shuffle -Value 1 -Type DWord
Start-Sleep -Seconds 1
$now = (Get-ItemProperty $reg).BackgroundType
Write-Output "status=$state BackgroundType=$now images=$($files.Count)"
