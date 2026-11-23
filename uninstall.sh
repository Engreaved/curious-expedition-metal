#!/bin/bash
# @name: tce-metal-uninstall
# @description: Removes the arm64 Electron runtime and launcher, and restores Steam's original run_app.sh from run_app.sh.pre-metal if the installer repointed it. Leaves the game and save files untouched. Easy to get wrong: the restore must only happen when the backup exists, and the backup must be moved (not copied) so a second uninstall cannot resurrect a stale launcher.
# @tags: electron, metal, uninstall, macos, game
set -euo pipefail

RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
APP="$HOME/Applications/Curious Expedition (Metal).app"
GAME="$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition"

rm -rf "$RUNTIME" "$APP"

if [ -f "$GAME/run_app.sh.pre-metal" ]; then
  mv "$GAME/run_app.sh.pre-metal" "$GAME/run_app.sh"
  chmod +x "$GAME/run_app.sh"
  echo "Steam launcher restored to the original."
fi

echo "removed. The game itself and your saves were not touched."
