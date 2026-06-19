# 🪐 Icarus Dedicated Server Toolkit

PowerShell scripts to install, configure, launch, and firewall an **Icarus** (RocketWerkz) dedicated server on **Windows**. The Icarus dedicated server is Windows-only, so this runs natively on your PC — no Docker or VPS required (though a VPS works too; see below).

> Verified against the official RocketWerkz [IcarusDedicatedServer wiki](https://github.com/RocketWerkz/IcarusDedicatedServer/wiki/Server-Setup). Steam app ID **2089300**.

## TL;DR

```powershell
# 1. Edit server.config.json  (set AdminPassword at minimum)
# 2. Install (downloads SteamCMD + server, several GB):
.\Install-IcarusServer.ps1
# 3. Open the local firewall (run PowerShell as Administrator):
.\Open-IcarusFirewall.ps1
# 4. Start it:
.\Start-IcarusServer.ps1
#    -> first run creates ServerSettings.ini + the world. Stop, then Start again
#       to apply your name/passwords (the server generates that file on first boot).
```

Your friends join from Icarus → **Join Game / Dedicated Servers** → connect by your IP and the game port, entering the join password if set.

## Files

| File | Does |
|------|------|
| `server.config.json` | **The one file you edit.** Name, ports, players, passwords, prospect (world) settings. |
| `Install-IcarusServer.ps1` | Downloads SteamCMD if missing, installs/updates app 2089300. Re-run to update. |
| `Open-IcarusFirewall.ps1` | Adds inbound UDP firewall rules for the game + query ports. **Run as Admin.** |
| `Start-IcarusServer.ps1` | Patches `ServerSettings.ini`, builds the launch command, starts the server. |
| `Stop-IcarusServer.ps1` | Gracefully stops the server process. |
| `ServerSettings.ini.template` | Reference copy of the keys the server uses (the live file is auto-generated under the install dir). |

## Configuration (`server.config.json`)

- **ServerName** → in-game session name.
- **InstallDir / SteamCmdDir** → where things install (default `C:\IcarusServer`, `C:\SteamCMD`).
- **Port / QueryPort** → defaults **17777** (game) and **27015** (query), both UDP.
- **MaxPlayers / JoinPassword / AdminPassword** → written into `ServerSettings.ini`. **Set AdminPassword** — in Icarus you become server admin by entering this password in-game (there is no SteamID admin list).
- **Prospect** → the world/save. `Type` is the map/scenario, `Difficulty`, `Hardcore`, `SaveName`. First launch **creates** it; later launches **resume** it. Delete the hidden `.prospect-created` marker in this folder to force a fresh world.

## How admin works

Icarus grants admin via the **AdminPassword**, not a Steam ID. Join your server, open the admin/console panel in-game, enter the password, and you get admin commands (spawn prospects, kick, etc.).

## Internet vs LAN

- **LAN / same network:** firewall script is enough.
- **Friends over the internet:** also **port-forward UDP 17777 and 27015** on your router to this PC's local IPv4 (`ipconfig`). Give friends your public IP (`https://ifconfig.me`). A static local IP / DHCP reservation for this PC keeps the forward from breaking on reboot.
- **Always-on / not on your gaming PC:** rent a Windows VPS (4+ cores, 8–16 GB RAM, 20+ GB disk for the world). The same scripts work there. Note the dedicated server cannot run on Linux natively — use a Windows VPS or the community Docker images (Wine-based) if you want Linux.

## Updating

Re-run `.\Install-IcarusServer.ps1` whenever Icarus patches. Stop the server first.

## Troubleshooting

- **Server not visible to friends:** confirm both UDP ports are forwarded *and* firewalled, and that you shared the right public IP + game port. Query port is for the server browser; game port is for actually connecting.
- **Passwords not taking effect:** the file is generated on first boot — start once, stop, start again.
- **Won't start / corrupt files:** re-run the installer with `validate` (it already does) to repair.
- **Wrong prospect/map:** stop, delete `.prospect-created`, fix `Prospect` in the config, start again.

---

*Not affiliated with RocketWerkz. Verified against their official wiki; recipe/prospect option names can change between patches — check in-game if something is rejected.*
