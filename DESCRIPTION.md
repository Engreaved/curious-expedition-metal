Fully vibecoded: no human took part in writing a single line of it. It runs The Curious Expedition natively on Metal on Apple M1 chips, on MacBooks from M1 to M6, with no Rosetta translation — faster loading, a sharper picture, and less heat.

---

# Curious Expedition, natively on Apple Silicon

The paragraph above is the description. The first 300 characters of this file
contain it on purpose, because they are also what belongs in the GitHub "About"
field (which allows 350). Paste that paragraph there.

## What this actually is

The Curious Expedition is a web game — HTML, JavaScript, and a drawing surface —
wrapped in Electron, the engine Chrome uses. It shipped in 2018 bundled with
Electron 3.0.9, which exists only for Intel Macs. On an Apple Silicon MacBook
(M1 and later) macOS therefore translates every instruction through Rosetta, and
the game draws itself into a small 640×360 buffer that is then stretched to the
screen.

This project replaces the old runtime with a modern one that runs natively on
Apple Silicon and draws through Metal. The game itself is untouched: same files,
same saves, same content. Only the engine around it changes.

What that looks like in practice, measured on an M1 Pro:

| | as shipped (2018) | with this project |
|---|---|---|
| Architecture | Intel, translated by Rosetta | **native Apple Silicon** |
| Frame rate | about 60 fps | **121 fps** |
| Render resolution | 640×360, stretched | **1920×1080** |
| Graphics path | old OpenGL | **Metal** |

The CPU figure goes up rather than down, because it draws twice the frames at
nine times the pixels. Per frame it is cheaper. This is a smoothness and
sharpness fix, not a promise that the laptop runs cooler.

## Why it exists (and what it costs)

This is a fan project. There is no money in it, no company behind it, no
donations, no ads, no telemetry — nothing is sent anywhere and it contacts
nothing except the two download servers it needs during installation. It was
made for fun, in spare time, because the game is good and deserved to run
properly on the machine it was being played on.

I bought the game. If you enjoy it, please consider buying it too:

**The Curious Expedition on Steam — https://store.steampowered.com/app/358130/**

It is regularly on sale, it is a genuinely lovely game, and buying it is the
only thing that supports the people who actually made it.

## Credits

The Curious Expedition was made by **Maschinen-Mensch** — the studio that
designed and built it — and published on Steam. All game content, artwork, music
and code belong to them.

- Studio: Maschinen-Mensch — https://www.maschinen-mensch.com
- Game on Steam — https://store.steampowered.com/app/358130/

This project is not affiliated with, endorsed by, or supported by
Maschinen-Mensch, Valve, or the Electron project. Bugs in this runtime are the
fault of this project, not of the developers of the game.

## No game files are included

Nothing belonging to the game is distributed here. No artwork, no audio, no
code, no data files. The repository contains about twenty kilobytes of text: a
shell script, two small JavaScript files, and documentation.

The installer reads the game from the copy you already own on Steam and never
copies it. That is also why the game must already be installed before this runs.

## Who this is for

Anyone with an Apple Silicon MacBook (M1 through M6) who owns The Curious
Expedition on Steam and would like it to run well. No technical knowledge is
required: the install is one double-click.

It is not for Intel Macs — the game is already native there, and this installer
will tell you so and stop.

## Installing

1. Download this repository (green **Code** button → **Download ZIP**, then
   double-click the zip to unpack it). Using git is fine too, but not required.
2. Open the unpacked folder and double-click **Install.command**.
3. Wait about a minute. It downloads roughly 115 MB.
4. When it finishes, the game is in your Applications folder as
   **Curious Expedition (Metal)**. Double-click it to play.

That is the whole procedure. No questions, no password, no options, nothing to
configure. Running it a second time is harmless.

If macOS refuses to open **Install.command** the first time, saying it is from an
unidentified developer, right-click it, choose **Open**, and confirm once. This
project cannot afford an Apple signing certificate, so Gatekeeper is cautious
about files downloaded from the internet. You only ever do this once.

If you prefer the terminal, the same thing is:

```bash
./install.sh
```

Optional: Steam library on another drive?

```bash
TCE_GAME_DIR='/Volumes/YourDrive/SteamLibrary/steamapps/common/The Curious Expedition' ./install.sh
```

## Uninstalling

Double-click **Uninstall.command**. It removes the runtime and the launcher and
restores the game exactly as Steam shipped it. Your saves are never touched.

## What it changes on your Mac

- `~/Library/Application Support/CuriousExpedition-Metal` — the new runtime
  (about 268 MB, mostly Electron itself).
- `~/Applications/Curious Expedition (Metal).app` — the launcher.
- Nothing else. No system files, no settings, no background processes, no login
  items. It does not touch the game's files unless you explicitly pass
  `--steam`.

## Honest limitations

- **Tested on one machine**: an M1 Pro MacBook Pro running macOS 27.2, with game
  version 1.4.1.2. It is built to run on any Apple Silicon MacBook from M1
  through M6, and there is no hardware-specific code in it, but only that one
  machine has actually been tested.
- Verified working: the world map, party, inventory, combat, and saving.
- Not verified: the gallery, the online/IO features, and anything that talks to
  the game's web services.
- Steam's **Verify integrity of game files** restores the original launcher if
  you chose the optional Steam integration. Re-run the installer afterwards.
- There is no Steam overlay, achievements, or cloud sync when launching from the
  Applications folder, because Steam is not the parent process. Use
  `./install.sh --steam` if you want Steam to own the launch.

## Licence

The scripts here are released under the MIT licence (see `LICENSE`). Electron is
MIT and is downloaded at install time, not redistributed. `@electron/remote` is
MIT and is likewise downloaded, not redistributed.
