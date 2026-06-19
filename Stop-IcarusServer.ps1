<#
.SYNOPSIS
  Stops any running Icarus dedicated server process.
.NOTES
  The server saves on a timer and on clean shutdown. Prefer using the in-game
  admin "save" before stopping if you want a guaranteed fresh save.
#>
[CmdletBinding()] param()
$ErrorActionPreference = 'SilentlyContinue'

$procs = Get-Process -Name 'IcarusServer' -ErrorAction SilentlyContinue
if (-not $procs) {
  Write-Host "No IcarusServer process running." -ForegroundColor DarkGray
  return
}
foreach ($p in $procs) {
  Write-Host "Stopping IcarusServer (PID $($p.Id))..." -ForegroundColor Yellow
  $p.CloseMainWindow() | Out-Null
  Start-Sleep -Seconds 5
  if (-not $p.HasExited) { $p | Stop-Process -Force }
}
Write-Host "Stopped." -ForegroundColor Green
