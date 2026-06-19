<#
.SYNOPSIS
  Installs SteamCMD (if missing) and the Icarus Dedicated Server (Steam app 2089300).
.NOTES
  Run from this folder:  .\Install-IcarusServer.ps1
  Re-run any time to update the server to the latest build.
#>
[CmdletBinding()]
param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot 'server.config.json')
)

$ErrorActionPreference = 'Stop'

function Read-Config {
  param([string]$Path)
  if (-not (Test-Path $Path)) { throw "Config not found: $Path" }
  return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
}

$cfg        = Read-Config -Path $ConfigPath
$steamDir   = $cfg.SteamCmdDir
$installDir = $cfg.InstallDir
$appId      = 2089300

Write-Host "== Icarus Dedicated Server installer ==" -ForegroundColor Cyan
Write-Host "SteamCMD dir : $steamDir"
Write-Host "Install dir  : $installDir"
Write-Host "App ID       : $appId"
Write-Host ""

# --- 1. Ensure SteamCMD ---
$steamExe = Join-Path $steamDir 'steamcmd.exe'
if (-not (Test-Path $steamExe)) {
  Write-Host "SteamCMD not found - downloading..." -ForegroundColor Yellow
  New-Item -ItemType Directory -Force -Path $steamDir | Out-Null
  $zip = Join-Path $env:TEMP 'steamcmd.zip'
  Invoke-WebRequest -Uri 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip' -OutFile $zip
  Expand-Archive -Path $zip -DestinationPath $steamDir -Force
  Remove-Item $zip -Force
  Write-Host "SteamCMD installed." -ForegroundColor Green
} else {
  Write-Host "SteamCMD already present." -ForegroundColor Green
}

# --- 2. Install / update the dedicated server (anonymous login) ---
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Write-Host ""
Write-Host "Installing/updating Icarus server (this can take a while + several GB)..." -ForegroundColor Yellow

& $steamExe +force_install_dir "$installDir" +login anonymous +app_update $appId validate +quit

if ($LASTEXITCODE -ne 0) {
  Write-Warning "SteamCMD exited with code $LASTEXITCODE. If it failed mid-download, just re-run this script - it resumes."
} else {
  Write-Host ""
  Write-Host "Done. Server installed to $installDir" -ForegroundColor Green
  Write-Host "Next: .\Open-IcarusFirewall.ps1  (once, as admin)  then  .\Start-IcarusServer.ps1" -ForegroundColor Cyan
}
