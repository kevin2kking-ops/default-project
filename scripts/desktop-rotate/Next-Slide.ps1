$ErrorActionPreference = "Stop"
$anime = "C:\Users\KEVIN\OneDrive\Pictures\AnimeDesktop"
$indexPath = Join-Path $PSScriptRoot "slide-index.txt"
$walls = @(Get-ChildItem -LiteralPath $anime -File | Where-Object {
    $_.Extension -match '^\.(jpg|jpeg|png)$' -and $_.Name -ne "_live_temp.jpg"
} | Sort-Object Name)
if ($walls.Count -eq 0) { throw "no anime images" }
$i = 0
if (Test-Path -LiteralPath $indexPath) { $i = [int](Get-Content -LiteralPath $indexPath -Raw) }
$i = ($i + 1) % $walls.Count
$pic = $walls[$i].FullName
if (-not ("DeskWall2" -as [type])) {
    Add-Type -TypeDefinition @"
using System.Runtime.InteropServices;
public class DeskWall2 {
  [DllImport("user32.dll", CharSet = CharSet.Auto)]
  public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@
}
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value "10"
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0"
[DeskWall2]::SystemParametersInfo(20, 0, $pic, 3) | Out-Null
Set-Content -LiteralPath $indexPath -Value "$i"
Write-Output $pic
