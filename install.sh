#!/bin/bash
# @name: tce-metal-install
# @description: Installs a native arm64 Electron runtime for The Curious Expedition plus a double-clickable launcher. Downloads pinned Electron 45.4.1 and @electron/remote 2.1.4; touches no game files unless --steam is passed, which repoints Steam's Play button and keeps a run_app.sh.pre-metal backup. Easy to get wrong: the preload resolves @electron/remote relative to its own directory, so the runtime layout (node_modules sitting beside shim.js) must be preserved, and ELECTRON_RUN_AS_NODE must never leak in or Electron runs as plain node.
# @tags: electron, metal, arm64, installer, macos, game
set -euo pipefail

ELECTRON_VERSION="45.4.1"
REMOTE_VERSION="2.1.4"
RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
APP="$HOME/Applications/Curious Expedition (Metal).app"
HERE="$(cd "$(dirname "$0")" && pwd)"

WANT_STEAM=0
[ "${1:-}" = "--steam" ] && WANT_STEAM=1

die() { echo "error: $*" >&2; exit 1; }

[ "$(uname -m)" = "arm64" ] || die "this build targets Apple Silicon (arm64). On Intel the shipped runtime is already native."
[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 11 ] || die "macOS 11 or newer is required"

GAME="$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition"
[ -f "$GAME/app/play-electron.html" ] || die "The Curious Expedition not found at: $GAME (install it from Steam first)"

echo "game:    $GAME"
echo "runtime: $RUNTIME"

mkdir -p "$RUNTIME" "$HOME/Applications"

if [ ! -x "$RUNTIME/electron/Electron.app/Contents/MacOS/Electron" ]; then
  echo "downloading Electron $ELECTRON_VERSION (arm64) ..."
  tmp="$(mktemp -d)"
  curl -fL --retry 3 --progress-bar -o "$tmp/electron.zip" \
    "https://github.com/electron/electron/releases/download/v$ELECTRON_VERSION/electron-v$ELECTRON_VERSION-darwin-arm64.zip"
  rm -rf "$RUNTIME/electron"
  mkdir -p "$RUNTIME/electron"
  unzip -q -o "$tmp/electron.zip" -d "$RUNTIME/electron"
  rm -rf "$tmp"
fi

if [ ! -d "$RUNTIME/node_modules/@electron/remote" ]; then
  echo "downloading @electron/remote $REMOTE_VERSION ..."
  tmp="$(mktemp -d)"
  curl -fL --retry 3 --progress-bar -o "$tmp/remote.tgz" \
    "https://registry.npmjs.org/@electron/remote/-/remote-$REMOTE_VERSION.tgz"
  tar -xzf "$tmp/remote.tgz" -C "$tmp"
  mkdir -p "$RUNTIME/node_modules/@electron"
  rm -rf "$RUNTIME/node_modules/@electron/remote"
  mv "$tmp/package" "$RUNTIME/node_modules/@electron/remote"
  rm -rf "$tmp"
fi

cp "$HERE/files/shim.js" "$RUNTIME/shim.js"
cp "$HERE/files/preload.js" "$RUNTIME/preload.js"

# --- launcher app ---
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>Curious Expedition (Metal)</string>
	<key>CFBundleDisplayName</key><string>Curious Expedition (Metal)</string>
	<key>CFBundleIdentifier</key><string>local.tce.metal</string>
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

cat > "$APP/Contents/MacOS/launch" <<'LAUNCH'
#!/bin/bash
# Paths resolve at run time so the bundle works for any user, not just the installer's.
set -eu
BASE="$HOME/Library/Application Support/CuriousExpedition-Metal"
GAME="$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition/app/play-electron.html"
EL="$BASE/electron/Electron.app/Contents/MacOS/Electron"
[ -x "$EL" ]   || { echo "runtime missing: $EL (re-run install.sh)" >&2; exit 1; }
[ -f "$GAME" ] || { echo "game files missing: $GAME" >&2; exit 1; }
unset ELECTRON_RUN_AS_NODE
cd "$BASE"
exec "$EL" "$BASE/shim.js" "$GAME"
LAUNCH
chmod +x "$APP/Contents/MacOS/launch"

if [ "$WANT_STEAM" = "1" ]; then
  [ -f "$GAME/run_app.sh.pre-metal" ] || cp "$GAME/run_app.sh" "$GAME/run_app.sh.pre-metal"
  cat > "$GAME/run_app.sh" <<'STEAM'
#!/bin/bash
# Repointed at the arm64 Metal runtime by install.sh --steam.
# Restore with uninstall.sh, or with Steam's Verify integrity of game files.
GAME_DIR="$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition"
RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
unset ELECTRON_RUN_AS_NODE
exec "$RUNTIME/electron/Electron.app/Contents/MacOS/Electron" "$RUNTIME/shim.js" "$GAME_DIR/app/play-electron.html"
STEAM
  chmod +x "$GAME/run_app.sh"
  echo "Steam Play repointed (backup: run_app.sh.pre-metal)"
fi

echo
echo "installed."
echo "  launch:  open \"$APP\""
echo "  remove:  ./uninstall.sh"
