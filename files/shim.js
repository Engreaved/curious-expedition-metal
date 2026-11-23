// shim.js - the small compatibility layer that lets a 2018 game run on a
// modern Electron.
//
// BACKGROUND, SO THIS FILE MAKES SENSE
// The Curious Expedition is not a normal native game. It is a web page (HTML,
// JavaScript, a drawing surface) started by Electron. Electron is the same
// engine Chrome uses, packaged so that an ordinary desktop app can be built out
// of web pages.
//
// The game shipped in 2018 inside Electron 3.0.9. Modern Electron has tightened
// three things that the game depends on, and each one breaks it in a different,
// confusing way:
//
//   1. Node integration is OFF by default.
//      In 2018 a page could use Node.js directly. The game does: it calls
//      require("electron"), and it reads __dirname to find its own folder.
//      Without Node integration the page throws "__dirname is not defined" and
//      shows a blank canvas instead of the game.
//
//   2. Context isolation is ON by default.
//      That separations between the page and Electron's internals means the
//      page cannot reach the modules it expects. We turn it off so the page sees
//      what it saw in 2018.
//
//   3. The "remote" module was REMOVED (Electron 14, 2022).
//      The game calls require("electron").remote.app.getGPUFeatureStatus()
//      while it is starting up. That call now throws, inside a load handler,
//      so the game simply never finishes loading: it sits on its loading screen
//      forever and prints no error at all. This is the single most confusing
//      failure of the whole project, and it is why preload.js exists.
//
// WHAT THIS FILE DOES
// Opens one window, with the settings above restored, and points it at the
// game's own entry page. Nothing else.
//
// USAGE (normally done for you by the launcher app):
//   Electron.app/Contents/MacOS/Electron shim.js /path/to/play-electron.html
//
// BREADCRUMBS
//   the remote patch the game actually calls -> preload.js
//   why the window options look unusual      -> webPreferences below
//   what users trip over                     -> KNOWN-ISSUES.md
//   the game's own log                       -> <game folder>/tce-log.txt

const { app, BrowserWindow, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

// Shown inside error boxes so a lost user knows what to do next.
const HINT = 'Re-run the installer (Install.command) to repair the runtime.';

// Show a message in a real dialog and stop. A dialog is used rather than a
// console message because the launcher app is double-clicked: there is no
// terminal window in front of the user to read text from.
function fatal(message) {
  dialog.showErrorBox('Curious Expedition (Metal)', message);
  process.exit(1);
}

// Fail loudly if the remote-compatibility package is missing. Without this
// check the game would hang on its loading screen and look "just slow".
try {
  require.resolve('@electron/remote');
} catch {
  fatal('The runtime is incomplete: a required file is missing.\n\n' + HINT);
}

// The remote package comes in two halves; this is the half that runs inside the
// main process and has to be started before any window exists.
const remoteMain = require('@electron/remote/main');
remoteMain.initialize();

// Which page to open. The launcher passes it as the first argument; the
// fallback keeps this file usable on its own.
const page = process.argv[2] || path.join(__dirname, 'play-electron.html');
if (!fs.existsSync(page)) {
  fatal('The game files were not found at:\n' + page + '\n\n' + HINT);
}

// Let the page read files from disk (the game loads its images and data this
// way) and ignore Chromium's graphics blacklist. We deliberately do NOT disable
// web security: with these two switches the game loads all of its assets, so
// there is no reason to switch a protection off.
app.commandLine.appendSwitch('allow-file-access-from-files');
app.commandLine.appendSwitch('ignore-gpu-blocklist');

// Electron is ready once this callback fires; before that, no window can exist.
app.whenReady().then(() => {
  const win = new BrowserWindow({
    title: 'Curious Expedition',
    width: 1280,
    height: 720,
    useContentSize: true, // the numbers above are the drawing area, not the frame
    webPreferences: {
      nodeIntegration: true,   // (1) let the page use require() and __dirname
      contextIsolation: false, // (2) let the page see Electron's modules
      preload: path.join(__dirname, 'preload.js'), // (3) restore remote
    },
  });

  // The other half of the remote package: enable it for this one window.
  remoteMain.enable(win.webContents);

  // Load the game itself.
  win.loadFile(page);
});

// Quit when the window is closed, rather than lingering invisibly. (The stock
// Electron behaviour on macOS is to stay alive; for a game that is a surprise,
// because the process keeps using battery with nothing on screen.)
app.on('window-all-closed', () => app.quit());
