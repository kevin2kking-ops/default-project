@echo off
rem One-click admin repairs. Double-click, then click YES on the UAC prompt.
rem Runs: sfc /scannow, DISM RestoreHealth, chkdsk /scan, minidump settings, TDR GPU fix.
rem Results are written to admin-fix.log in this same folder.
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%~dp0Admin-Fix-2-3-4.ps1\"'"
echo.
echo An elevated window should open. Watch it until it says DONE.
pause
