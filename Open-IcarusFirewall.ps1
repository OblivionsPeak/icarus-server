<#
.SYNOPSIS
  Adds inbound Windows Firewall rules for the Icarus game + query ports (UDP).
.NOTES
  RIGHT-CLICK > Run as Administrator (or run from an elevated PowerShell).
  This only opens your local firewall. For friends over the INTERNET you must
  also forward these UDP ports on your ROUTER to this PC's local IP. See README.
#>
[CmdletBinding()]
param(
  [string]$ConfigPath = (Join-Path $PSScriptRoot 'server.config.json')
)
$ErrorActionPreference = 'Stop'

# Elevation check
$isAdmin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
  Write-Warning "Not elevated. Re-run this script as Administrator to add firewall rules."
  exit 1
}

$cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$ports = @($cfg.Port, $cfg.QueryPort)

foreach ($p in $ports) {
  $name = "Icarus Dedicated Server UDP $p"
  $existing = Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host "Rule already exists: $name" -ForegroundColor DarkGray
    continue
  }
  New-NetFirewallRule -DisplayName $name -Direction Inbound -Action Allow `
    -Protocol UDP -LocalPort $p -Profile Any | Out-Null
  Write-Host "Added inbound UDP rule for port $p" -ForegroundColor Green
}

Write-Host ""
Write-Host "Firewall configured for game port $($cfg.Port) and query port $($cfg.QueryPort)." -ForegroundColor Cyan
Write-Host "Internet play also needs ROUTER port-forwarding of these same UDP ports. See README." -ForegroundColor Yellow
