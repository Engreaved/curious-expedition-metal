// Restores require('electron').remote for a pre-Electron-14 renderer.
//
// The game calls require("electron").remote.app.getGPUFeatureStatus() while loading.
// @electron/remote is a separate module name, so the alias has to be attached to the
// electron module itself. contextIsolation:false is what lets the page see this patch.
const electron = require('electron');

if (!electron.remote) {
  electron.remote = require('@electron/remote');
}
