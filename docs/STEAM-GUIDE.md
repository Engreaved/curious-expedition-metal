# Steam guide — paste-ready

This file is not part of the program. It is the text for a Steam Community guide.

Steam guides use BBCode. Copy everything between the markers below into the
guide body, using Steam's "source"/BBCode view if it offers one.

Suggested title:

    Run natively on Apple Silicon — Metal, over 120 fps, no Rosetta

Suggested short description:

    Swap the game's 2018 Intel-only runtime for a modern native Apple Silicon one.
    Runs at 121 fps at 1920x1080 instead of a 640x360 buffer through Rosetta.
    No game files are redistributed. Free, fan-made, non-commercial.

--- BEGIN BBCode ---

[b]Fully vibecoded: no human took part in writing a single line of it.[/b] It runs The Curious Expedition natively on Metal on Apple M1 chips, on MacBooks from M1 to M6, with no Rosetta translation.

[h1]The problem[/h1]

The Curious Expedition ships an Electron runtime from November 2018. That binary is [b]Intel-only[/b], so on every Apple Silicon Mac it runs through Rosetta, and it draws the game into a [b]640x360[/b] buffer that is then stretched to your screen. The graphics path it uses is old OpenGL, not Metal.

The game looks soft and works the laptop harder than it needs to.

[h1]What this does[/h1]

It runs the same game files on a [b]native Apple Silicon[/b] Electron, so:

[list]
[*]No Rosetta translation
[*]1920x1080 instead of 640x360
[*]121 fps instead of ~60
[*]Metal instead of OpenGL
[/list]

Nothing about the game changes. Same files, same saves, same content.

[h1]What you need[/h1]

[list]
[*]Apple Silicon MacBook (M1 through M6)
[*]macOS 11 or newer
[*]The Curious Expedition already installed in Steam
[/list]

[h1]Install — one double-click[/h1]

[list]
[*]On the project page, click the green [b]Code[/b] button, then [b]Download ZIP[/b].
[*]Double-click the downloaded zip to unpack it.
[*]Open the unpacked folder and double-click [b]Install.command[/b].
[*]Wait well under a minute; it downloads roughly 115 MB.
[*]Open [b]Curious Expedition (Metal)[/b] from your Applications folder.
[/list]

No questions, no password, nothing to type.

If macOS refuses to open Install.command, it is Gatekeeper checking a downloaded script, because the project has no Apple signing certificate. Approve it once.

Most reliable: open Terminal, type [b]bash [/b] (with a trailing space), drag Install.command from Finder into the Terminal window, and press Return. Gatekeeper does not gate scripts started that way.

Otherwise: right-click Install.command -> [b]Open[/b] -> [b]Open[/b], or allow it under System Settings -> Privacy & Security -> "Open Anyway" if that option is missing.

The app the installer creates needs no approval at all, because it is built on your own Mac.

[h1]Uninstall[/h1]

Double-click [b]Uninstall.command[/b] in the same folder. It removes the runtime and the launcher and puts the game back exactly as Steam shipped it. Your saves are never touched.

[h1]Honestly measured[/h1]

On an M1 Pro:

[list]
[*]Architecture: Intel via Rosetta -> native Apple Silicon
[*]Frame rate: ~60 -> 121 fps
[*]Render resolution: 640x360 -> 1920x1080
[/list]

CPU use goes [b]up[/b] rather than down, because it draws twice the frames at nine times the pixels. Per frame it is cheaper. This is a smoothness and sharpness fix, not a promise of a cooler laptop.

[h1]Limitations[/h1]

[list]
[*]Tested on one machine only (M1 Pro, macOS 27.2, game 1.4.1.2). M2-M6 are untested, though the code has nothing machine-specific in it.
[*]Verified: world map, party, inventory, combat, saving.
[*]Not verified: gallery, online/IO features, anything that uses the game's servers.
[*]No Steam overlay, achievements or cloud sync when launched from Applications.
[*]Steam's "Verify integrity of game files" restores the original launcher.
[/list]

[h1]Credits and why this exists[/h1]

The Curious Expedition was made by [b]Maschinen-Mensch[/b]. All game content, artwork, music and code belong to them.

[list]
[*][url=https://store.steampowered.com/app/358130/]Buy the game on Steam[/url]
[*][url=https://www.maschinen-mensch.com]Maschinen-Mensch[/url]
[/list]

This is a fan project. There is no money in it: no donations, no ads, no telemetry, nothing sent anywhere. It was made for fun in spare time, by someone who bought the game and hopes you will buy it too if you enjoy it. The repository contains no game files at all - the game is read from the copy you already own.

Not affiliated with or endorsed by Maschinen-Mensch, Valve, or the Electron project.

--- END BBCode ---
