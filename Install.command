#!/bin/bash
#
# Double-click this file to install.
#
# macOS runs a ".command" file in Terminal when you double-click it, which is
# why this exists: it means a non-technical person never has to type anything.
# It simply runs install.sh next to it and keeps the window open at the end so
# the result can be read.
#
# FIRST TIME ONLY, FOR SOME PEOPLE: if macOS says it "cannot be opened because
# it is from an unidentified developer", that is Gatekeeper being cautious about
# a file downloaded from the internet. Right-click this file, choose Open, and
# confirm once. It will not ask again. This project cannot pay Apple the yearly
# fee for a signing certificate, so this is expected.

# Work from the folder this file lives in, whatever that is.
cd "$(dirname "$0")" || exit 1

echo "  Installing the Apple Silicon runtime for The Curious Expedition"
echo "  -------------------------------------------------------------"
echo ""

# Run the real installer. Its own messages appear here.
./install.sh
status=$?

echo ""
if [ "$status" -eq 0 ]; then
  echo "  Finished successfully."
else
  echo "  Something went wrong - the message above explains what."
  echo "  Nothing was left half-installed in a way you need to clean up by hand."
fi

echo ""
echo "  You can close this window now (press Return, or Command-W)."
# Wait for the user, then exit with the real result rather than with whatever
# the wait returned: closing the window (or piping input) makes "read" fail,
# and that must not look like a failed install.
read -r _ || true
exit "$status"
