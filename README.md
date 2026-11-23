Fully vibecoded: no human took part in writing a single line of it. It runs The Curious Expedition natively on Metal on Apple M1 chips, on MacBooks from M1 to M6, with no Rosetta translation.

# Curious Expedition on Metal

The game ships with a 2018 Intel-only Electron runtime, so on an Apple Silicon
Mac every frame is translated by Rosetta and drawn into a 640×360 buffer that is
then stretched to your screen. This project swaps that runtime for a modern
native one. The game is untouched — same files, same saves — only the engine
around it changes.

| | as shipped (2018) | with this project |
|---|---|---|
| Architecture | Intel, via Rosetta | **native Apple Silicon** |
| Frame rate | about 60 fps | **121 fps** |
| Render resolution | 640×360, stretched | **1920×1080** |
| Graphics path | old OpenGL | **Metal** |

## Install (one double-click)

1. Download this repository: green **Code** button → **Download ZIP**, then
   double-click the zip to unpack it. (git works too, but is not needed.)
2. Double-click **Install.command** in the unpacked folder.
3. When it finishes, open **Curious Expedition (Metal)** from your Applications
   folder.

No questions, no password, no configuration, nothing to type. About a minute and
roughly 115 MB of downloads. Running it twice is harmless.

If macOS says **Install.command** is from an unidentified developer, right-click
it → **Open** → confirm once. This project has no Apple signing certificate, so
Gatekeeper is cautious about downloaded files. Once only.

Terminal equivalent: `./install.sh`. Steam library on another drive:
`TCE_GAME_DIR='/path/to/The Curious Expedition' ./install.sh`.

## Uninstall

Double-click **Uninstall.command**. It removes the runtime and launcher and puts
the game back exactly as Steam shipped it. Your saves are never touched.

## What it touches

- `~/Library/Application Support/CuriousExpedition-Metal` — the new runtime (~268 MB)
- `~/Applications/Curious Expedition (Metal).app` — the launcher

Nothing else. No system files, no background processes, no analytics, nothing
sent anywhere.

## No game files here

This repository ships about twenty kilobytes of text and **no game content**. The
game is read from the copy you already own on Steam and never copied. That is
why it must already be installed.

## Credits

The Curious Expedition was made by **Maschinen-Mensch**. All game content,
artwork, music and code are theirs.

- **Buy the game — https://store.steampowered.com/app/358130/**
- Studio — https://www.maschinen-mensch.com

This is a fan project. There is no money in it and nothing is sold: no
donations, no ads, no telemetry. It was made for fun, in spare time, by someone
who bought the game and would like you to buy it too if you enjoy it.

Not affiliated with or endorsed by Maschinen-Mensch, Valve, or the Electron
project.

## Security, plainly

What the installer does that involves trust:

- Both downloads are HTTPS **and checksum-verified** before anything is unpacked:
  Electron against the publisher's `SHASUMS256.txt`, `@electron/remote` against
  the SHA-512 the package registry publishes. A mismatch stops the install and
  changes nothing.
- It never asks for a password, never uses `sudo`, and never writes outside your
  home folder.
- It uses one temporary folder, deleted when the script exits however it exits.
- There is no telemetry, no analytics, and no outbound connection at run time.
  The only network access in the whole project is those two downloads during
  installation; you can read every URL in `install.sh`.

The one real trade-off, stated honestly: the game needs Node integration on and
context isolation off, because that is how it was written in 2018. That means the
game's own code runs with your normal user privileges. This is exactly the
privilege level the game already had under its original 2018 runtime — this
project does not grant it anything new — and everything it loads is a local file
you already own. No remote page is ever loaded. If you would not trust the game's
own files, you should not run either runtime.

The app bundle is unsigned. That is a limitation of not having an Apple Developer
account, not a choice: the bundle is assembled locally by the installer, which
also means macOS does not quarantine it, and all of the code that builds it is
in this repository for you to read first.

## Limitations, honestly

- Tested on one machine only: M1 Pro, macOS 27.2, game 1.4.1.2. The code has
  nothing machine-specific in it, but M2–M6 are untested.
- Verified: world map, party, inventory, combat, saving.
- Not verified: gallery, online/IO features, anything using the game's servers.
- No Steam overlay, achievements or cloud sync when launched from Applications;
  use `./install.sh --steam` if you want Steam to own the launch.
- Steam's **Verify integrity of game files** restores the original launcher;
  re-run the installer after that.

Full explanation, measurements and caveats: [DESCRIPTION.md](DESCRIPTION.md).
Ready-to-paste Steam guide: [docs/STEAM-GUIDE.md](docs/STEAM-GUIDE.md).

## Licence

MIT — see [LICENSE](LICENSE). Electron and `@electron/remote` are MIT and are
downloaded at install time, never redistributed.
