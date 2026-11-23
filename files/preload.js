// @name: electron-legacy-remote-alias
// @description: Restores require('electron').remote for a pre-Electron-14 renderer that calls it directly. Must run as a preload with contextIsolation:false and nodeIntegration:true so the page's require() resolves to the same patched electron module. Easy to get wrong: @electron/remote is a separate module name, so the alias must be attached to the electron module itself, and its main-process half must be initialize()d before app ready.
// @tags: electron, remote, legacy, preload, compatibility
const electron = require('electron');
try {
  if (!electron.remote) electron.remote = require('@electron/remote');
} catch (e) {
  console.error('remote alias failed:', e && e.message);
}
