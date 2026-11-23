# Curious Expedition — native Apple Silicon (Metal) runtime

Runs The Curious Expedition on a **modern, native arm64 Electron** instead of the
Electron 3.0.9 (2018) binary the game ships, which is x86_64-only and runs under
Rosetta 2.

No game files are modified unless you ask for it, and no game files are distributed.

## Why

The shipped runtime is Electron 3.0.9 / Chromium 66 from November 2018. On Apple
Silicon that means every frame is translated by Rosetta, the GPU path is
deprecated OpenGL rather than Metal, and the game rasterises a **640×360** buffer
that is then upscaled to your display.

Measured here (M1 Pro, macOS 27.2):

| | shipped Electron 3.0.9 | this build (Electron 45.4.1) |
|---|---|---|
| architecture | x86_64 under Rosetta | **arm64 native** |
| frame rate | ~60 fps | **121 fps** (ProMotion) |
| render resolution | 640×360 buffer | **1920×1080** |
| renderer CPU | 29% | 48% |

The CPU figure is *higher* because it renders twice the frames at nine times the
pixels — per frame it is cheaper. This is a smoothness and sharpness fix, not a
promise of a cooler laptop; at 120 fps the machine does twice the work per second.

## Requirements

- Apple Silicon Mac (M1 or later)
- macOS 11 or newer
- The Curious Expedition installed through Steam

## Install

```bash
git clone <this repo>
cd curious-expedition-metal
./install.sh
```

This downloads Electron 45.4.1 (arm64) and `@electron/remote` 2.1.4 into
`~/Library/Application Support/CuriousExpedition-Metal`, and creates
`~/Applications/Curious Expedition (Metal).app`. Double-click that to play.

To make **Steam's own Play button** use the new runtime:

```bash
./install.sh --steam
```

That backs up the original launcher to `run_app.sh.pre-metal` first.

## Uninstall

```bash
./uninstall.sh
```

Removes the runtime and launcher and restores the original `run_app.sh`. The game
and your saves are untouched.

## How it works

The game is a web app (Canvas 2D, no WebGL) wrapped in Electron. Two things it
relies on were removed from Electron since 2018, and both must be restored or it
breaks in confusing ways:

1. **Node integration in the renderer** is off by default. Without it the page
   dies with `__dirname is not defined` and renders a blank canvas.
2. **The `remote` module** was removed in Electron 14. The game calls
   `require("electron").remote.app.getGPUFeatureStatus()` while loading, so
   without it the game **hangs forever on its loading screen** with no error.

`files/shim.js` creates the window with `nodeIntegration`, `contextIsolation:
false` and loads the game's own `play-electron.html`. `files/preload.js` aliases
`@electron/remote` back onto the `electron` module so the game's
`require("electron").remote` calls resolve.

The game is never copied — it is loaded in place from your Steam library.

## Known limitations

- **No Steam integration.** `greenworks` fails to initialise (`ugcGetItems` is
  undefined), and launching from the .app bypasses Steam, so no overlay,
  achievements, playtime or cloud sync on that path. With `--steam` Steam stays
  the parent process and tracks the game normally. Your saves are local files in
  `~/Documents/TheCuriousExpedition` and work in both runtimes.
- **Steam → Verify integrity of game files** will overwrite `run_app.sh` and undo
  the `--steam` integration. Re-run `./install.sh --steam`.
- Chromium 66 → 14x is a large jump. The world map, party, inventory, combat and
  saving are verified. The gallery, the online/IO features and the Parse-backed
  services were **not** exercised.
- Tested on exactly one machine (M1 Pro, macOS 27.2, game 1.4.1.2). Your mileage
  may vary; please report what breaks.

## Licence and attribution

The shim scripts here are MIT (see `LICENSE`). Electron is MIT and is downloaded
at install time, not redistributed. `@electron/remote` is MIT, also downloaded.

The Curious Expedition is © Maschinen-Mensch. This project contains no game
assets and is not affiliated with or endorsed by Maschinen-Mensch, GOG or Valve.
