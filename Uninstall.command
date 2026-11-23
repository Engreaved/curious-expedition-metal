#!/bin/bash
#
# Double-click this file to remove the runtime swap and go back to the game as
# Steam shipped it. Runs uninstall.sh next to it.
#
# Curious Expedition by Maschinen-Mensch. Unofficial, not affiliated with them.
#
# Same Gatekeeper note as Install.command: if macOS refuses to open it the first
# time, right-click the file, choose Open, and confirm once.

cd "$(dirname "$0")" || exit 1

echo "  Removing the Apple Silicon runtime for The Curious Expedition"
echo "  ------------------------------------------------------------"
echo ""

./uninstall.sh
status=$?

echo ""
if [ "$status" -eq 0 ]; then
  echo "  Finished."
else
  echo "  Something went wrong - the message above explains what."
fi

echo ""
echo "  You can close this window now (press Return, or Command-W)."
# Wait for the user, then exit with the real result rather than with whatever
# the wait returned: closing the window (or piping input) makes "read" fail,
# and that must not look like a failed install.
read -r _ || true
exit "$status"
