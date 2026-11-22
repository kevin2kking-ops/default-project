@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Rotate-Desktop.ps1" -Mode ApplyWeek
