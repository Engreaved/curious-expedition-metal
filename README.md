Fully vibecoded: no human took part in writing a single line of it. It runs The Curious Expedition natively on Metal on Apple Silicon Macs (M1 through M6), with no Rosetta translation.

# Curious Expedition on Metal

The game ships with a 2018 Intel-only Electron runtime, so on an Apple Silicon
Mac every frame is translated by Rosetta and drawn into a 640×360 buffer that is
then stretched to your screen. This project swaps that runtime for a modern
native one. The game is untouched — same files, same saves — only the engine
around it changes.

Rosetta is also on a clock. Apple's own developer notice states that **macOS 27 is
the final release to support Rosetta**, and that Intel-only apps will no longer
run on Apple silicon after it ([Apple](https://developer.apple.com/news/?id=w5ngl9k2)).
This is not only a speed fix — it is what keeps a 2018 game playable on this Mac
at all.

| | as shipped (2018) | with this project |
|---|---|---|
| Architecture | Intel, via Rosetta | **native Apple Silicon** |
| Frame rate | about 60 fps | **up to 120 fps** (your display's refresh) |
| Render resolution | 640×360, stretched | **1920×1080** |
| Graphics path | old OpenGL | **Metal** |

## Install (one double-click)

1. Download this repository: green **Code** button → **Download ZIP**, then
   double-click the zip to unpack it. (git works too, but is not needed.)
2. Double-click **Install.command** in the unpacked folder.
3. Press **Play** in Steam as usual. The installer points Steam's launcher at the
   new runtime, so Steam still owns the launch.

   The game is also in *your user* Applications folder (`~/Applications`, not
   `/Applications`) if you would rather start it there — use Spotlight (⌘-Space).
   That location is deliberate: no administrator password is needed to write
   there. Use `./install.sh --no-steam` to leave Steam's launcher alone.

No questions, no password, no configuration, nothing to type. Usually well under
a minute, with roughly 115 MB of downloads. Running it twice is harmless.

### If macOS refuses to open Install.command

This project cannot pay for an Apple signing certificate, so macOS treats the
downloaded script as untrusted. You approve it **once**, then it never asks
again. Two ways, in order of reliability:

1. **Run it from Terminal instead.** Open Terminal, type `bash ` (with a trailing
   space), drag `Install.command` from Finder into the Terminal window, and press
   Return. Gatekeeper does not gate scripts started this way, so nothing is
   blocked. This is the method most likely to just work.
2. **Approve it in Finder.** Right-click `Install.command` → **Open** → **Open**.
   On recent macOS versions that option is missing and you instead allow it under
   **System Settings → Privacy & Security → "Open Anyway"** after the first attempt.

The app the installer *creates* — **Curious Expedition (Metal)** — needs no
approval at all: macOS only gates files that arrived from the internet, and this
one is built on your own Mac.

Steam library on another drive:
`TCE_GAME_DIR='/path/to/The Curious Expedition' ./install.sh`.

## Uninstall

Double-click **Uninstall.command**. It removes the runtime and launcher. If you
had used `--steam`, it also restores the original launcher from the backup, so the
game ends up exactly as Steam shipped it. Your saves are never touched.

## What it touches

- `~/Library/Application Support/CuriousExpedition-Metal` — the new runtime (~270 MB)
- `~/Applications/Curious Expedition (Metal).app` — the launcher
- **Steam's own `run_app.sh`**, inside the game folder, rewritten so the Play
  button starts the new runtime. The original is copied to
  `run_app.sh.pre-metal` first and Uninstall restores it.

The third item is what keeps Steam in charge. Steam stays the parent process, so
playtime is counted, the overlay can attach, and cloud save sync still applies —
which is the whole point of doing it that way.

Pass `--no-steam` and the game folder is left completely untouched; then launch
from the Applications folder instead.

Nothing else. No system files, no background processes, no analytics, nothing
sent anywhere.

## No game files here

This repository ships about forty kilobytes of text and **no game content**. The
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

## Network and telemetry

- **The runtime makes no network calls.** `shim.js` and `preload.js` contain no fetch,
  no HTTP client, nothing. The only file that uses `curl` is `install.sh`, twice, to
  download the two pinned files during installation.
- **Chromium's own background services are switched off** in `shim.js`
  (`disable-background-networking`, `disable-component-update`,
  `disable-domain-reliability`, `disable-sync`, `no-pings`), so the engine does not
  check for component updates or report anything. These switches affect Electron's
  internals only; the game's own requests still work.
- **The one dependency downloaded at install time**, `@electron/remote`, is 18 KB of
  JavaScript with no dependencies and no network code.
- **Measured, with the game running**: the entire process tree held exactly **one**
  outbound connection, to `217.160.0.118` — which is `maschinen-mensch.com` and
  `curious-expedition.com`, the developer's own site, opened by the game's own code.
  Nothing of ours, and nothing third-party.

Nothing is sent anywhere by this project. There is no analytics, no crash upload, no
update check, and no identifier of any kind.

## Security, plainly

What the installer does that involves trust:

- Both downloads are HTTPS **and verified against hashes pinned inside
  `install.sh` itself** — not against a checksum fetched from the server that
  served the file. That distinction matters: a checksum downloaded beside the
  download only catches a corrupted transfer, because anything able to replace
  the file could replace the checksum too. With the hash in the script, swapping
  the file means editing code you can read. Verified in both directions: a real
  download passes, and a deliberately wrong hash stops the install and leaves
  nothing behind.
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

Full explanation and measurements: [DESCRIPTION.md](DESCRIPTION.md).
Known bugs, caveats and untested areas: [KNOWN-ISSUES.md](KNOWN-ISSUES.md).
Ready-to-paste Steam guide: [docs/STEAM-GUIDE.md](docs/STEAM-GUIDE.md).

## Licence

MIT — see [LICENSE](LICENSE). Electron and `@electron/remote` are MIT and are
downloaded at install time, never redistributed.
