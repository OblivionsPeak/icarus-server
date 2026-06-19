<#
.SYNOPSIS
  Launches the Icarus Dedicated Server using values from server.config.json.
.DESCRIPTION
  - Patches ServerSettings.ini (name / passwords / players / shutdown) if it
    already exists. The server GENERATES that file on first launch, so on a
    brand-new install the first run creates it; run Start again to apply your
    passwords. This is by design (RocketWerkz: settings are generated on first
    prospect/lobby).
  - First launch creates the prospect (world). Later launches resume it.
.NOTES
  .\Start-IcarusServer.ps1
#>
[CmdletBinding()]
param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot 'server.config.json')
)
$ErrorActionPreference = 'Stop'

$cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$exe = Join-Path $cfg.InstallDir 'IcarusServer.exe'
if (-not (Test-Path $exe)) {
  throw "IcarusServer.exe not found at $exe. Run .\Install-IcarusServer.ps1 first."
}

# --- Patch ServerSettings.ini if present (replace existing keys only) ---
$iniDir  = Join-Path $cfg.InstallDir 'Icarus\Saved\Config\WindowsServer'
$iniPath = Join-Path $iniDir 'ServerSettings.ini'

function Set-IniKey {
  param([string[]]$Lines, [string]$Key, [string]$Value)
  $found = $false
  $out = foreach ($line in $Lines) {
    if ($line -match "^\s*$([regex]::Escape($Key))\s*=") { $found = $true; "$Key=$Value" }
    else { $line }
  }
  if (-not $found) { $out += "$Key=$Value" }   # appends under last section if missing
  return $out
}

if (Test-Path $iniPath) {
  Write-Host "Applying settings to $iniPath" -ForegroundColor Cyan
  $lines = Get-Content -LiteralPath $iniPath
  $lines = Set-IniKey $lines 'SessionName'                     $cfg.ServerName
  $lines = Set-IniKey $lines 'JoinPassword'                    $cfg.JoinPassword
  $lines = Set-IniKey $lines 'AdminPassword'                   $cfg.AdminPassword
  $lines = Set-IniKey $lines 'MaxPlayers'                      $cfg.MaxPlayers
  $lines = Set-IniKey $lines 'ShutdownIfNotJoinedFor'          $cfg.ShutdownIfNotJoinedFor
  $lines = Set-IniKey $lines 'ShutdownIfEmptyFor'              $cfg.ShutdownIfEmptyFor
  $lines = Set-IniKey $lines 'AllowNonAdminsToLaunchProspects' ($cfg.AllowNonAdminsToLaunchProspects.ToString().ToLower())
  $lines = Set-IniKey $lines 'AllowNonAdminsToDeleteProspects' ($cfg.AllowNonAdminsToDeleteProspects.ToString().ToLower())
  # Write UTF-8 without BOM (avoid PS 5.1 mojibake / BOM issues)
  [System.IO.File]::WriteAllLines($iniPath, $lines, (New-Object System.Text.UTF8Encoding($false)))
} else {
  Write-Warning "ServerSettings.ini not generated yet. The first launch creates it; STOP the server after it boots, then run Start again to apply your passwords/name."
}

# --- Build launch args (verified RocketWerkz parameters) ---
$launchArgs = @(
  "-SteamServerName=`"$($cfg.ServerName)`"",
  "-PORT=$($cfg.Port)",
  "-QueryPort=$($cfg.QueryPort)",
  "-Log"
)

# Prospect handling: we deliberately do NOT auto-create a world via the CLI,
# because prospect/map IDs are version-specific and easy to get wrong (a bad ID
# fails the launch). Instead the server boots and -ResumeProspect auto-loads the
# last world if one exists; otherwise it waits in a lobby. Create your FIRST
# world IN-GAME: connect with the Icarus client, enter the AdminPassword, and
# create/launch a prospect from the prospect menu (the dropdowns guarantee valid
# values). Restarts then resume it automatically.
$launchArgs += "-ResumeProspect"
Write-Host "Booting (will resume last world if one exists, else wait in lobby for in-game creation)." -ForegroundColor Green

Write-Host ""
Write-Host "Launching: $exe $($launchArgs -join ' ')" -ForegroundColor Cyan
Write-Host "(A log window will open. Close it / Ctrl+C here to stop, or use Stop-IcarusServer.ps1)" -ForegroundColor DarkGray
& $exe @launchArgs
