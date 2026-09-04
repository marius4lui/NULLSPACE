const fs = require('node:fs');
const path = require('node:path');
const validator = require('gltf-validator');
const root = path.resolve(__dirname, '../../..');
const asset = path.join(root, 'art/exported/listener/listener.glb');
validator.validateBytes(new Uint8Array(fs.readFileSync(asset)), {uri: 'listener.glb'}).then(report => {
  fs.writeFileSync(path.join(__dirname, 'evidence/khronos_validation.json'), JSON.stringify(report, null, 2) + '\n');
  console.log(JSON.stringify(report.issues, null, 2));
  if (report.issues.numErrors || report.issues.numWarnings) process.exitCode = 1;
}).catch(error => { console.error(error); process.exitCode = 1; });
