@echo off
REM Double-click this to install OpenCode (Windows AMD64)
REM Uses PowerShell 5.1 so you don't have to type commands.
Set-ExecutionPolicy -Scope Process Bypass -Force
powershell -ExecutionPolicy Bypass -File "%~dp0setup-opencode.ps1"
pause
