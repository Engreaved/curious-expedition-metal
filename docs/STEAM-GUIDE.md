# Steam Guide — paste-ready BBCode

Steam guides take BBCode. Copy everything between the markers into the guide body
(use the "Source"/BBCode view if the editor offers one).

Title to use:

    Run natively on Apple Silicon — arm64, Metal, 120 fps (no Rosetta)

Short description to use:

    Swap the game's 2018 Electron 3 runtime for a modern native arm64 build. Runs
    at 120 fps at 1920x1080 instead of a 640x360 buffer through Rosetta. No game
    files are redistributed.

--- BEGIN BBCode ---

[h1]The problem[/h1]

The Curious Expedition ships an Electron 3.0.9 runtime from November 2018. That binary is [b]x86_64 only[/b], so on every Apple Silicon Mac it runs through Rosetta 2, and it draws the game into a [b]640x360[/b] buffer that is then upscaled to your display. Chromium 66 also predates Apple Silicon, so it reaches the GPU through the deprecated OpenGL path rather than Metal.

The result is a game that looks soft and runs hot for no good reason.

[h1]What this does[/h1]

It runs the same game files on a [b]native arm64 Electron[/b], so:

[list]
[*]No Rosetta translation
[*]1920x1080 render instead of 640x360
[*]120 fps on ProMotion displays (was ~60)
[*]Metal-backed compositing instead of OpenGL
[/list]

No game files are modified by default and none are redistributed — the game is loaded in place from your Steam library.

[h1]Requirements[/h1]

[list]
[*]Apple Silicon Mac (M1 or newer)
[*]macOS 11 or newer
[*]The Curious Expedition installed from Steam
[/list]

[h1]Install[/h1]

Open Terminal and run:

[code]
git clone https://github.com/YOUR-NAME/curious-expedition-metal
cd curious-expedition-metal
./install.sh
[/code]

Then launch [b]Curious Expedition (Metal)[/b] from your Applications folder, or from Spotlight.

If you would rather keep using Steam's Play button, run instead:

[code]
./install.sh --steam
[/code]

That repoints Steam's launcher at the new runtime and keeps a backup of the original.

[h1]Uninstall[/h1]

[code]
./uninstall.sh
[/code]

This removes the runtime and restores the original launcher. Your saves in [i]~/Documents/TheCuriousExpedition[/i] are never touched.

[h1]Measured[/h1]

On an M1 Pro (macOS 27.2):

[list]
[*]Architecture: x86_64 under Rosetta [b]→[/b] arm64 native
[*]Frame rate: ~60 fps [b]→[/b] 121 fps
[*]Render resolution: 640x360 [b]→[/b] 1920x1080
[/list]

Be honest with yourself about one thing: renderer CPU goes [b]up[/b], because it draws twice the frames at nine times the pixels. Per frame it is cheaper. This is a smoothness and sharpness fix, not a guarantee that your laptop runs cooler.

[h1]Known limitations[/h1]

[list]
[*]No Steam overlay, achievements or cloud sync when launched from the .app. Use [code]--steam[/code] if you care about those.
[*]Steam's [b]Verify integrity of game files[/b] resets the launcher. Re-run the installer afterwards.
[*]The world map, party, inventory, combat and saving are verified. The gallery, online/IO features and Parse-backed services were not tested.
[*]Tested on one machine only. If something breaks, say so.
[/list]

[h1]Credits[/h1]

The game is by Maschinen-Mensch. This is an unofficial runtime swap: it contains no game assets and is not affiliated with or endorsed by Maschinen-Mensch, GOG or Valve.

--- END BBCode ---
