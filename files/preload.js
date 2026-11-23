// preload.js - runs before the game's own JavaScript, inside the page.
//
// THE PROBLEM IT SOLVES
// The game calls require("electron").remote while it starts up. Historically
// that was a built-in part of Electron. It was removed in Electron 14 (2022)
// because it made it too easy for a web page to reach powerful native features.
//
// A separate package, @electron/remote, provides the same capability again - but
// under its own name, require("@electron/remote"), not as part of "electron".
// The game does not know about the new name and will not be changed, so this
// file puts the old name back where the game looks for it:
//
//     require("electron").remote   ->   require("@electron/remote")
//
// WHY A PRELOAD FILE
// A preload script runs in the page before any of the page's own scripts, which
// is the only moment early enough to patch this. For the patch to be visible to
// the game, contextIsolation must be off - shim.js sets that.

const electron = require('electron');

// Attach the module where the game expects to find it. Guarded so that running
// this twice, or under an Electron that still has remote built in, does nothing.
if (!electron.remote) {
  electron.remote = require('@electron/remote');
}
