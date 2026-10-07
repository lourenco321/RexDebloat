# RexDebloat

My personal Windows 11 setup script. Open **Windows PowerShell as Administrator**, paste the following command, and press Enter:

```powershell
irm "https://raw.githubusercontent.com/lourenco321/RexDebloat/main/rex.ps1" | iex
```

If you run it from PowerShell 7 or a non-admin window it relaunches itself in an elevated Windows PowerShell window (Win11Debloat does not support PowerShell 7).

## What it does

1. Installs Firefox, 7-Zip, Discord, Steam and the VC++ 2015+ redistributable with winget.
2. Runs [Win11Debloat](https://github.com/Raphire/Win11Debloat) by Raphire: creates a restore point, removes the default bloatware apps, disables telemetry, Bing, Copilot, Recall, widgets and suggestions, force-removes Edge, and applies the Windows 10 look (classic context menu, dark mode, left-aligned taskbar, no search / task view buttons, Explorer opens to This PC, file extensions shown, no Gallery, no mouse acceleration).
3. Accent colour on title bars and the taskbar, no recent items in Start.
4. Clears every pinned taskbar item.
5. Automatic time and time zone, High Performance power plan, screen and sleep timeouts off.
6. Uninstalls OneDrive. The `OneDrive` folder is only deleted when it is empty, so files backed up by OneDrive are never touched.
7. Downloads [BurntSushi](https://github.com/OpenByteDev/burnt-sushi) (Spotify ad blocker) into the Startup folder.
8. Sets the desktop background and lock screen to `bg.png`.

It restarts the PC at the end (15 second countdown, press any key to cancel).

Thank you for using my script and have fun :)
