#!/bin/bash
#
# INSTALLER for the "Curious Expedition on Metal" runtime swap.
#
# WHAT THIS IS, IN ONE PARAGRAPH
# The Curious Expedition is a web game (HTML + JavaScript drawn on a <canvas>)
# which ships inside an old copy of Electron: version 3.0.9, built in November
# 2018. That old Electron only exists for Intel Macs, so on an Apple Silicon
# MacBook (M1 and later) macOS has to translate every instruction through
# Rosetta. This script instead downloads a modern Electron that runs natively on
# Apple Silicon, adds two tiny compatibility files, and creates a normal
# double-clickable app. Nothing about the game itself is modified or copied.
#
# WHAT IT TOUCHES
#   ~/Library/Application Support/CuriousExpedition-Metal/   the new runtime
#   ~/Applications/Curious Expedition (Metal).app             the launcher
#   (only with --steam: the game's own run_app.sh, after making a backup)
#
# WHAT IT DOES NOT TOUCH
#   The game's files, your save files in ~/Documents/TheCuriousExpedition, and
#   anything belonging to Steam. The game is read from where Steam installed it.
#
# HOW TO RUN IT
#   Double-click "Install.command" in this folder, or from Terminal:
#       ./install.sh
#   No arguments are required. It asks no questions and needs no password.
#
# TO UNDO IT
#   Double-click "Uninstall.command", or run ./uninstall.sh
#
# ---------------------------------------------------------------------------
# Housekeeping: stop on any error, on any undefined variable, and on any failing
# command inside a pipe. Failing loudly beats failing halfway through.
set -euo pipefail

# Exact versions we build against. Pinned on purpose: a newer Electron could
# change behaviour under us without warning.
ELECTRON_VERSION="45.4.1"
REMOTE_VERSION="2.1.4"

# Where the pieces live. HOME is the current user's home folder.
RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
APP="$HOME/Applications/Curious Expedition (Metal).app"

# Directory this script sits in, whatever folder the user runs it from.
HERE="$(cd "$(dirname "$0")" && pwd)"

# Opt-in flag: also make Steam's own Play button use the new runtime.
# Off by default, because that is the only behaviour that edits a game file.
WANT_STEAM=0
[ "${1:-}" = "--steam" ] && WANT_STEAM=1

# One small helper so every failure prints the same readable shape and stops.
die() {
  echo "" >&2
  echo "  STOPPED: $*" >&2
  echo "" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# STEP 1 - check the machine can run what we are about to download.
# ---------------------------------------------------------------------------

# An Apple Silicon Mac reports "arm64". Intel Macs report "x86_64"; they do not
# need this project at all, because the shipped runtime is already native there.
[ "$(uname -m)" = "arm64" ] || die "this Mac is not Apple Silicon (it reports $(uname -m)).
  On an Intel Mac the game already runs natively - you do not need this project."

# Electron 45 needs macOS 11 or newer. Anything older is out of support anyway.
[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 11 ] || die "macOS 11 or newer is required (this Mac reports $(sw_vers -productVersion))."

# The tools below are part of macOS itself, so this should never fail. It is
# here so that if one is somehow missing, the message names it instead of the
# script dying with a confusing error halfway through.
for tool in curl unzip tar shasum openssl; do
  command -v "$tool" >/dev/null 2>&1 || die "required macOS tool '$tool' is missing."
done

# ---------------------------------------------------------------------------
# STEP 2 - find the game. It must already be installed through Steam.
# ---------------------------------------------------------------------------
# This is the one location Steam uses by default. If someone keeps games on an
# external drive, they can point at it directly with:
#   TCE_GAME_DIR='/Volumes/Drive/SteamLibrary/steamapps/common/The Curious Expedition' ./install.sh
GAME="${TCE_GAME_DIR:-$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition}"

# play-electron.html is the game's own entry page. Its presence proves this is
# really the game and not an empty folder.
[ -f "$GAME/app/play-electron.html" ] || die "The Curious Expedition was not found at:
    $GAME

  Install it from Steam first, then run this again.
  If your Steam library is on another drive, run it like this instead:
    TCE_GAME_DIR='/path/to/steamapps/common/The Curious Expedition' ./install.sh"

echo "  game:    $GAME"
echo "  runtime: $RUNTIME"

# Create the two folders we own. Nothing is deleted here.
mkdir -p "$RUNTIME" "$HOME/Applications"

# One scratch folder for both downloads below. It is deleted when this script
# exits, however it exits, so nothing is left behind even on a failure.
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# ---------------------------------------------------------------------------
# STEP 3 - download the modern Electron runtime (about 115 MB).
# ---------------------------------------------------------------------------
# Skipped when a working copy is already there, so re-running is cheap and safe.
if [ ! -x "$RUNTIME/electron/Electron.app/Contents/MacOS/Electron" ]; then
  echo "  downloading Electron $ELECTRON_VERSION for Apple Silicon..."

  asset="electron-v$ELECTRON_VERSION-darwin-arm64.zip"
  base="https://github.com/electron/electron/releases/download/v$ELECTRON_VERSION"

  # The runtime itself.
  curl -fL --retry 3 --progress-bar -o "$work/$asset" "$base/$asset" \
    || die "could not download Electron. Check your internet connection and try again."

  # The publisher's list of checksums. We use it to prove the download arrived
  # intact and unmodified before letting macOS run any of it.
  curl -fsSL --retry 3 -o "$work/SHASUMS256.txt" "$base/SHASUMS256.txt" \
    || die "could not download the checksum list needed to verify Electron."

  # Compare the checksum the publisher publishes with the one we computed.
  want="$(awk -v f="$asset" '$2 == "*" f {print $1}' "$work/SHASUMS256.txt")"
  have="$(shasum -a 256 "$work/$asset" | awk '{print $1}')"
  [ -n "$want" ] && [ "$want" = "$have" ] \
    || die "the Electron download did not match its published checksum, so it was not used.
  expected: ${want:-<not found in checksum list>}
  actual:   $have
  Nothing on your Mac was changed."

  # Safe to unpack now that the archive is proven.
  rm -rf "$RUNTIME/electron"
  mkdir -p "$RUNTIME/electron"
  unzip -q -o "$work/$asset" -d "$RUNTIME/electron" || die "could not unpack the Electron download."
fi

# ---------------------------------------------------------------------------
# STEP 4 - download one small helper library (about 18 KB).
# ---------------------------------------------------------------------------
# The game talks to an Electron feature called "remote" which was removed from
# Electron in 2022. This package puts it back, so the game can start.
if [ ! -d "$RUNTIME/node_modules/@electron/remote" ]; then
  echo "  downloading @electron/remote $REMOTE_VERSION..."

  curl -fL --retry 3 --progress-bar -o "$work/remote.tgz" \
    "https://registry.npmjs.org/@electron/remote/-/remote-$REMOTE_VERSION.tgz" \
    || die "could not download @electron/remote. Check your connection and try again."

  # Prove the download is exactly the file the package registry published: the
  # registry states a SHA-512 for every release, and we recompute it locally.
  curl -fsSL --retry 3 -o "$work/remote-meta.json" \
    "https://registry.npmjs.org/@electron/remote/$REMOTE_VERSION" \
    || die "could not download the metadata needed to verify @electron/remote."

  want512="$(sed -n 's/.*"integrity":"sha512-\([^"]*\)".*/\1/p' "$work/remote-meta.json" | head -1)"
  have512="$(openssl dgst -sha512 -binary "$work/remote.tgz" | openssl base64 -A)"
  [ -n "$want512" ] && [ "$want512" = "$have512" ] \
    || die "the @electron/remote download did not match its published checksum, so it was not used.
  Nothing on your Mac was changed."

  tar -xzf "$work/remote.tgz" -C "$work" || die "could not unpack @electron/remote."

  mkdir -p "$RUNTIME/node_modules/@electron"
  rm -rf "$RUNTIME/node_modules/@electron/remote"
  mv "$work/package" "$RUNTIME/node_modules/@electron/remote"
fi

# ---------------------------------------------------------------------------
# STEP 5 - prove the runtime actually starts before telling anyone it worked.
# ---------------------------------------------------------------------------
# Asking Electron for its version number runs the real binary. If the download
# was blocked by a firewall, quarantined, or damaged, this is where we find out -
# rather than the user double-clicking the game and getting a blank window.
EL_BIN="$RUNTIME/electron/Electron.app/Contents/MacOS/Electron"
[ -x "$EL_BIN" ] || die "the runtime binary is missing after unpacking: $EL_BIN"

# ELECTRON_RUN_AS_NODE makes Electron pretend to be plain Node.js. Some shells
# leak it; if it is set, Electron prints a Node version instead of its own and
# the game cannot start. We remove it for this check and inside the launcher.
got="$(env -u ELECTRON_RUN_AS_NODE "$EL_BIN" --version 2>/dev/null | head -1 || true)"
[ "$got" = "v$ELECTRON_VERSION" ] \
  || die "the new runtime did not start (it reported: '${got:-no output}').
  This usually means macOS blocked it. Nothing on your Mac was changed."

# ---------------------------------------------------------------------------
# STEP 6 - install the two compatibility files that make the game work.
# ---------------------------------------------------------------------------
# shim.js creates the game window with the settings the game expects.
# preload.js restores the "remote" feature the game calls while loading.
cp "$HERE/files/shim.js"    "$RUNTIME/shim.js"
cp "$HERE/files/preload.js" "$RUNTIME/preload.js"

# Remember where the game actually is, so the launcher does not have to guess.
printf '%s\n' "$GAME" > "$RUNTIME/game-path"

# ---------------------------------------------------------------------------
# STEP 7 - create the double-clickable app in ~/Applications.
# ---------------------------------------------------------------------------
# A ".app" is just a folder with a particular shape: a plist describing it and
# an executable to run. Ours is a short shell script, so there is nothing to
# sign and nothing to notarise; macOS runs it because it was created locally by
# this installer rather than downloaded from the internet.
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>Curious Expedition (Metal)</string>
	<key>CFBundleDisplayName</key><string>Curious Expedition (Metal)</string>
	<key>CFBundleIdentifier</key><string>local.curious-expedition.metal</string>
	<key>CFBundleExecutable</key><string>launch</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>1.0</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>LSMinimumSystemVersion</key><string>11.0</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.games</string>
</dict>
</plist>
PLIST

# The launcher itself. Paths are worked out at run time, so this keeps working
# if the user's home folder or Steam library ever moves.
cat > "$APP/Contents/MacOS/launch" <<'LAUNCH'
#!/bin/bash
# Starts the game using the new runtime. Explains itself if something is missing.
set -eu
BASE="$HOME/Library/Application Support/CuriousExpedition-Metal"
GAMEDIR="$(cat "$BASE/game-path" 2>/dev/null || echo "$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition")"
GAME="$GAMEDIR/app/play-electron.html"
ELECTRON="$BASE/electron/Electron.app/Contents/MacOS/Electron"

if [ ! -x "$ELECTRON" ]; then
  echo "The game runtime is missing. Re-run the installer, then try again." >&2
  exit 1
fi
if [ ! -f "$GAME" ]; then
  echo "The game files are missing at: $GAMEDIR" >&2
  echo "Reinstall The Curious Expedition in Steam, then try again." >&2
  exit 1
fi

unset ELECTRON_RUN_AS_NODE
cd "$BASE"
exec "$ELECTRON" "$BASE/shim.js" "$GAME"
LAUNCH

chmod +x "$APP/Contents/MacOS/launch"

# ---------------------------------------------------------------------------
# STEP 8 (optional) - make Steam's Play button use the new runtime too.
# ---------------------------------------------------------------------------
# Only with --steam. The original launcher is backed up first, and Uninstall
# puts it back. Steam's "Verify integrity of game files" also restores it.
if [ "$WANT_STEAM" = "1" ]; then
  [ -f "$GAME/run_app.sh.pre-metal" ] || cp "$GAME/run_app.sh" "$GAME/run_app.sh.pre-metal"

  cat > "$GAME/run_app.sh" <<'STEAMLAUNCH'
#!/bin/bash
# Repointed at the Apple Silicon runtime by the Metal installer.
# Restore the original with Uninstall.command, or Steam's "Verify integrity".
RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
GAMEDIR="$(cat "$RUNTIME/game-path" 2>/dev/null || echo "$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition")"
unset ELECTRON_RUN_AS_NODE
exec "$RUNTIME/electron/Electron.app/Contents/MacOS/Electron" "$RUNTIME/shim.js" "$GAMEDIR/app/play-electron.html"
STEAMLAUNCH

  chmod +x "$GAME/run_app.sh"
  echo "  Steam's Play button now uses the new runtime (backup: run_app.sh.pre-metal)"
fi

# ---------------------------------------------------------------------------
# Done.
# ---------------------------------------------------------------------------
echo ""
echo "  Installed. The game is now in your Applications folder as:"
echo "    Curious Expedition (Metal)"
echo ""
echo "  Double-click it to play. To remove everything later, run Uninstall.command."
echo ""
