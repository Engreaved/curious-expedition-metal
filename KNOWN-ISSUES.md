# Known bugs, caveats and rough edges

**Curious Expedition by Maschinen-Mensch.** This file documents an unofficial
third-party wrapper around their game; the bugs below belong to the wrapper.

Everything here was either observed while building this, or is an honest
limitation of what it can do. Nothing is hidden to look better.

Each entry says what you will see, why it happens, and what to do about it.
Entries marked **[seen]** were reproduced on the development machine; entries
marked **[expected]** follow from how the pieces work but were not reproduced.

---

## Before you start

### 1. The first double-click of Install.command may do nothing at all **[seen]**
**What you see:** you double-click `Install.command` and absolutely nothing
happens. No window, no error, no explanation.
**Why:** macOS marks files downloaded from the internet as quarantined, and
Gatekeeper refuses to run an unsigned script from a quarantine. This project has
no Apple signing certificate, so it cannot avoid that. The silence is macOS, not
this project.
**What to do:** open Terminal, type `bash ` (with a trailing space), drag
`Install.command` from Finder into the Terminal window and press Return.
Gatekeeper does not gate scripts started that way. Alternatively right-click the
file → **Open** → **Open**, or allow it under System Settings → Privacy &
Security → "Open Anyway".
**Not affected:** the app the installer creates. That is built on your own Mac,
so it is never quarantined and never prompts.

### 2. It refuses to run on an Intel Mac **[seen]**
**What you see:** "this Mac is not Apple Silicon".
**Why:** deliberate. Intel Macs already run the game natively; this project
exists only to escape Rosetta.
**What to do:** nothing. Play the game as Steam installed it.

### 3. macOS older than 11 is refused **[seen]**
Electron 45 does not support it. There is no build for those systems.

### 3a. The app is not where Finder says "Applications" is **[seen]**
**What you see:** you install, then open Finder → Applications and see nothing
new, and conclude it failed.
**Why:** the app is installed into *your user* Applications folder,
`~/Applications`, not the system-wide `/Applications` that the Finder sidebar
points at. That is deliberate — writing to `/Applications` needs an
administrator password, and this installer asks for none.
**What to do:** press ⌘-Space, type "Curious Expedition", press Return. It is
also in Launchpad.

---

## While playing

### 4. No Steam overlay, achievements, playtime or cloud sync **[seen]**
**What you see:** the Steam overlay never appears; hours are not counted;
achievements may not unlock; cloud saves do not sync.
**Why:** when you launch from Applications, Steam is not the parent process, so
its overlay cannot attach and it does not consider the game "running".
**What to do:** run the installer once with `--steam` so Steam starts the new
runtime itself. That restores Steam ownership of the launch. Note item 5.

### 4a. The installer changes Steam's launcher by default **[seen]**
**What you see:** the game folder contains `run_app.sh.pre-metal` and `run_app.sh`
now mentions the Metal runtime.
**Why:** that is how Steam's Play button ends up starting the new runtime. It is
the default because pressing Play is how the game is actually played.
**What to do:** nothing. `Uninstall.command` restores the original. If you never
want the game folder touched, reinstall with `./install.sh --no-steam`.

### 5. Steam's "Verify integrity of game files" undoes the Steam integration **[expected]**
**What you see:** after verifying files in Steam, Play goes back to the old slow
runtime, or shows the old "OS Error 0" failure.
**Why:** verifying rewrites `run_app.sh`, which is the file the installer
repoints.
**What to do:** re-run `Install.command` (or `./install.sh --steam`).

### 6. The game may create a save folder inside the runtime folder **[seen]**
**What you see:** a folder `TheCuriousExpedition` appears inside
`~/Library/Application Support/CuriousExpedition-Metal/`.
**Why:** the game looks for its save data in `~/Documents/TheCuriousExpedition`
first, and if a particular file is not there it also tries a path relative to
the folder it was started in. The launcher starts it inside the runtime folder,
so that fallback can land there.
**What to do:** usually nothing — your real saves in ~/Documents still load and
still take priority (verified). If you ever see progress "reset", check which of
the two folders is newer before assuming data was lost.
**Note:** two copies of the game running at once can write the same save files
and corrupt them. The game does not lock its saves, so avoid launching it twice.

### 7. It uses more CPU than the old runtime **[seen]**
**What you see:** Activity Monitor shows a busy renderer; the machine gets warm.
**Why:** the modern runtime runs at 120 fps on ProMotion displays and renders at
1920×1080 instead of a 640×360 buffer. That is twice the frames at nine times
the pixels. Renderer CPU measured 47.8% versus 29.4% before; per frame it is
cheaper, but per second it is more work.
**What to do:** close the game when you are not playing. Unlike the original
runtime, this one does not disable background throttling, so a hidden window
settles down instead of rendering flat out.

### 7a. The frame rate caps at your display's refresh **[seen]**
**What you see:** 60 fps on a 60 Hz MacBook Air or an external 60 Hz monitor, not
the 120 some screenshots show.
**Why:** the game draws once per screen refresh. It has no internal frame limiter
above that, so a 120 Hz ProMotion panel gets about 120 and a 60 Hz panel gets
about 60. The 121 fps figure measured on this machine is its 120 Hz display, not
a guarantee.
**What to do:** nothing. It is already drawing as fast as the screen can show.

### 8. Steam achievements and the Workshop cannot work in this runtime **[seen]**
**What you see:** achievements never unlock; the Workshop button does nothing; the
log says `GREENWORKS failed init`.
**Why:** the game talks to Steam through `app/lib/greenworks-osx64.node`, a native
module shipped with the game. Inspected with REA, it has three properties that each
block it on Apple Silicon on their own:

- **x86_64 only.** The loader refuses it outright: `incompatible architecture (have
  'x86_64', need 'arm64e, arm64')`.
- **Built against V8, not N-API.** It imports 47 `v8::` symbols and zero `napi_`
  symbols, so it is ABI-locked to one Electron major. It cannot be reused across
  versions without a rebuild.
- **It needs `@loader_path/libsteam_api.dylib`**, and the copy shipped with the game
  is `i386 + x86_64` — no arm64 slice. A rebuilt addon would still have nothing to
  link against.

So this is not a recompile. It needs the Steamworks SDK, which ships arm64 libraries
only from SDK 1.52 onward, is distributed to partners under Valve's agreement, and
cannot be redistributed by a third party — plus the greenworks source ported from
NAN to a current V8.
**What to do:** understand the trade. The original runtime has achievements
precisely because it runs x86_64 under Rosetta with a matching ABI — that is what
you give up for native speed. Playtime, the overlay and cloud save sync do **not**
depend on this module, and they work when Steam launches the game, which the
installer sets up by default.

### 9. The app has no custom icon **[seen]**
It shows the generic application icon. Cosmetic only; fixing it would mean
shipping artwork this project does not own.

---

## Untested, and therefore unknown

### 10. Only one machine has run this **[seen]**
An M1 Pro MacBook Pro, macOS 27.2, game version 1.4.1.2. The project claims M1
through M6 because it contains nothing machine-specific, but **M2, M3, M4, M5
and M6 have not been tested**. If you have one and something breaks, that is new
information rather than a known problem.

### 11. Several in-game features were never exercised **[expected]**
Verified working: the world map, party, inventory, combat, saving and loading.
**Never tested:** the gallery, the online/IO features, and anything that talks to
the game's web services. Those may work, may hang, or may fail quietly.

### 12. Fullscreen and window keys were not tested **[expected]**
The game asks Electron to change fullscreen state through the remote module the
preload file restores. That mechanism is present and the calls resolve, but the
actual fullscreen toggle was not pressed during testing.

---

## Maintenance

### 13. Electron is pinned and does not update itself **[by design]**
The runtime is Electron 45.4.1 exactly. That makes behaviour predictable and the
checksum meaningful, but security fixes for Electron do not arrive on their own.
To update: change `ELECTRON_VERSION` and `REMOTE_VERSION` in `install.sh`,
delete the runtime folder, re-run the installer, and test the game before
publishing.

### 14. Installing needs an internet connection **[seen]**
About 115 MB is downloaded. With no connection the installer stops with a clear
message and changes nothing.

### 15. Moving the game breaks the launcher **[expected]**
The installer records where the game is at install time. If you move the Steam
library afterwards, the launcher will report that the game files are missing.
**What to do:** re-run the installer from the new location.

---

## If something goes wrong

1. **The game's own log** is the first place to look:
   `The Curious Expedition/tce-log.txt` inside the Steam game folder. It records
   what loaded and which save paths were tried.
2. **Check the runtime starts at all** (prints a version number):
   `~/Library/Application Support/CuriousExpedition-Metal/electron/Electron.app/Contents/MacOS/Electron --version`
3. **Undo everything** with `Uninstall.command`. The game and your saves are never
   touched by the installer, so this always returns you to the stock game.
