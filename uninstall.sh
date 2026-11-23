#!/bin/bash
#
# UNINSTALLER for the "Curious Expedition on Metal" runtime swap.
#
# Curious Expedition by Maschinen-Mensch. Unofficial, not affiliated with them.
#
# Removes exactly what install.sh created:
#   1. the downloaded runtime in ~/Library/Application Support/CuriousExpedition-Metal
#   2. the launcher app in ~/Applications
#   3. if the installer repointed Steam's Play button, the original launcher is
#      put back from the backup it made.
#
# WHAT IT DELIBERATELY LEAVES ALONE
#   The game itself, and your saves in ~/Documents/TheCuriousExpedition.
#   After this runs, the game is exactly as Steam shipped it.
#
# HOW TO RUN IT
#   Double-click "Uninstall.command", or from Terminal: ./uninstall.sh

set -euo pipefail

RUNTIME="$HOME/Library/Application Support/CuriousExpedition-Metal"
APP="$HOME/Applications/Curious Expedition (Metal).app"
GAME="$HOME/Library/Application Support/Steam/steamapps/common/The Curious Expedition"

# If the game is installed somewhere else, this file will still be found via the
# runtime's own record of where it was.
if [ -f "$RUNTIME/game-path" ]; then
  GAME="$(cat "$RUNTIME/game-path")"
fi

# Step 1: remove the runtime and the launcher. Both are things we created, so
# removing them cannot lose the user's data.
rm -rf "$RUNTIME" "$APP"

# Step 2: if Steam's Play button was repointed, put the original back.
# "mv" rather than "cp" on purpose: once restored, the backup is gone, so a
# second run of this script cannot resurrect an old launcher by accident.
if [ -f "$GAME/run_app.sh.pre-metal" ]; then
  mv "$GAME/run_app.sh.pre-metal" "$GAME/run_app.sh"
  chmod +x "$GAME/run_app.sh"
  echo "  Steam's Play button restored to the original launcher."
fi

echo ""
echo "  Removed. Your game and your save files were not touched."
echo ""
