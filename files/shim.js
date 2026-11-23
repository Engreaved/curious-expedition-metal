// @name: electron-node-integration-shim
// @description: Runs a legacy Electron-3-era renderer (2018 web game) under a modern Electron by re-enabling nodeIntegration, disabling contextIsolation, and restoring the removed remote module via @electron/remote. Usage: Electron shim.js <absolute path to entry .html>. Easy to get wrong: modern Electron defaults nodeIntegration off and contextIsolation on (page dies with "__dirname is not defined"), and drops the remote module (page dies with "Cannot read properties of undefined (reading 'app')" and hangs on its loading screen), so BOTH must be restored or the game stalls half-initialised.
// @tags: electron, legacy, nodeintegration, remote, launcher, macos, game

const { app, BrowserWindow } = require('electron');
const path = require('path');
const remoteMain = require('@electron/remote/main');
remoteMain.initialize();

const page = process.argv[2] || path.join(__dirname, 'play-electron.html');

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
      webSecurity: false,
      preload: path.join(__dirname, 'preload.js'),
    },
  });
  remoteMain.enable(win.webContents);
  win.loadFile(page);
});

app.on('window-all-closed', () => app.quit());
