// Runs The Curious Expedition's 2018 renderer on a modern Electron.
//
// Three things modern Electron changed have to be undone, or the game fails in ways
// that never name the cause:
//   - nodeIntegration is off by default  -> page throws "__dirname is not defined",
//     renders a blank canvas.
//   - contextIsolation is on by default  -> the page cannot see Electron's modules.
//   - the remote module was removed (Electron 14) -> the game calls
//     remote.app.getGPUFeatureStatus() inside window.onload, so it hangs forever on
//     its loading screen and reports nothing.
//
// We also deliberately do NOT set webSecurity:false; the game loads every asset fine
// with only allow-file-access-from-files, which keeps one less protection disabled.

const { app, BrowserWindow, dialog } = require('electron');
const path = require('path');
const fs = require('fs');

const HINT = 'Re-run install.sh in the project folder to repair the runtime.';

function fatal(msg) {
  dialog.showErrorBox('Curious Expedition (Metal)', msg);
  process.exit(1);
}

try {
  require.resolve('@electron/remote');
} catch {
  // Without this the game sits on its loading screen forever with no error.
  fatal('The runtime is incomplete: @electron/remote is missing.\n\n' + HINT);
}

const remoteMain = require('@electron/remote/main');
remoteMain.initialize();

const page = process.argv[2] || path.join(__dirname, 'play-electron.html');
if (!fs.existsSync(page)) fatal('Game page not found:\n' + page + '\n\n' + HINT);

app.commandLine.appendSwitch('allow-file-access-from-files');
app.commandLine.appendSwitch('ignore-gpu-blocklist');

app.whenReady().then(() => {
  const win = new BrowserWindow({
    title: 'Curious Expedition',
    width: 1280,
    height: 720,
    useContentSize: true,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      preload: path.join(__dirname, 'preload.js'),
    },
  });
  remoteMain.enable(win.webContents);
  win.loadFile(page);
});

app.on('window-all-closed', () => app.quit());
