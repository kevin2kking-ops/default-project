# Removes AI Top Monitor from Windows Startup
$dst = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\AI_Top_Monitor.vbs"
if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Force; Write-Output "Removed: $dst" }
else { Write-Output "Not installed." }
