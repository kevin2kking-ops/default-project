# OpenCode one-click setup for Windows (AMD64)
# Run in PowerShell 5.1 from this folder:
#   Set-ExecutionPolicy -Scope Process Bypass -Force; .\setup-opencode.ps1
# This downloads everything needed for OpenCode and arranges config/plugins.

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$globalCfg = Join-Path $env:USERPROFILE '.config\opencode'
$downloads = Join-Path $env:USERPROFILE 'Downloads\opencode'
New-Item -ItemType Directory -Path $downloads -Force | Out-Null

Write-Host "=== 1) Prerequisites ===" -Foreground Cyan
Write-Host "Node: $(node --version)"
Write-Host "npm:  $(npm --version)"
Write-Host "git:  $(git --version)"

Write-Host "`n=== 2) Install OpenCode CLI via npm (official Windows method) ===" -Foreground Cyan
# Docs: https://opencode.ai/docs/ - npm package uses postinstall to select native binary.
# Windows package managers are not supported, so npm is the path.
npm install -g @opencode/cli

Write-Host "`n=== 3) Plugin deps (project + global) ===" -Foreground Cyan
Push-Location (Join-Path $projectRoot '.opencode')
npm install
Pop-Location
Push-Location $globalCfg
npm install
Pop-Location

Write-Host "`n=== 4) Set API key env (no secrets in config) ===" -Foreground Cyan
# Project canonical key lives at .opencode/opencode-key (gitignored).
# Set it as a persistent User env var so global config can find it.
$keyFile = Join-Path $projectRoot '.opencode\opencode-key'
if (Test-Path $keyFile) {
    $key = (Get-Content $keyFile -Raw).Trim()
    if ($key) {
        [Environment]::SetEnvironmentVariable('OPENCODE_API_KEY', $key, 'User')
        $env:OPENCODE_API_KEY = $key
        Write-Host "OPENCODE_API_KEY set from .opencode/opencode-key (User env var)" -Foreground Green
    } else {
        Write-Host "WARNING: $keyFile is empty. Paste your key there and re-run." -Foreground Yellow
    }
} else {
    Write-Host "No $keyFile found. Set OPENCODE_API_KEY manually: [Environment]::SetEnvironmentVariable('OPENCODE_API_KEY','YOUR_KEY','User')" -Foreground Yellow
}

Write-Host "`n=== 5) Download backup binaries (optional, for 'everything') ===" -Foreground Cyan
# Standalone CLI for AMD64 + Desktop installer - saved to Downloads\opencode
# Not auto-installed. Run them when you want.
function Download-File($url, $out) {
    if (Test-Path $out) { Write-Host "Skip (exists): $out"; return }
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
}
# Standalone CLI (matches &requests=AMD64)
Download-File "https://opencode.ai/update/api/latest/cli/opencode/opencode-windows-x64.zip" (Join-Path $downloads 'opencode-windows-x64.zip')
Download-File "https://opencode.ai/update/api/latest/desktop/opencode/opencode-desktop-win-x64.exe" (Join-Path $downloads 'opencode-desktop-win-x64.exe')
Write-Host "Backups saved to: $downloads" -Foreground Green

Write-Host "`n=== 6) Verify ===" -Foreground Cyan
# Refresh PATH for this session
$env:PATH = [System.Environment]::GetEnvironmentVariable('PATH','User') + ';' + [System.Environment]::GetEnvironmentVariable('PATH','Machine')
opencode --version
opencode service status

Write-Host "`nDone. Next: in TUI press Ctrl+P > Open settings, /connect to login, or /mcps to auth github." -Foreground Green
Write-Host "Global config: $globalCfg" 
Write-Host "Project config: $projectRoot\opencode.json"
