#!/usr/bin/env node
"use strict";
// Official Khronos validator plus project source-to-runtime/scale/UV budget checks.
const fs = require("node:fs/promises");
const path = require("node:path");
const crypto = require("node:crypto");
const validator = require("gltf-validator");

const root = path.resolve(__dirname, "../../..");
const exported = path.join(root, "art/exported/environment");
const runtime = path.join(root, "game/assets/environment");
const evidence = path.join(root, "evidence/environment/m4");
const hash = (bytes) => crypto.createHash("sha256").update(bytes).digest("hex");

async function main() {
  const manifest = JSON.parse(await fs.readFile(path.join(exported, "environment_manifest.json"), "utf8"));
  const reports = [];
  const failures = [];
  for (const name of Object.keys(manifest.modules).sort()) {
    const file = name + ".gltf";
    const content = await fs.readFile(path.join(exported, file));
    const gltf = JSON.parse(content);
    const report = await validator.validateString(content.toString("utf8"), {
      uri: file,
      maxIssues: 100,
      externalResourceFunction: async (uri) => new Uint8Array(await fs.readFile(path.join(exported, decodeURIComponent(uri)))),
    });
    let primitives = 0;
    let triangles = 0;
    let exportedVertices = 0;
    for (const mesh of gltf.meshes || []) {
      for (const primitive of mesh.primitives) {
        primitives += 1;
        exportedVertices += gltf.accessors[primitive.attributes.POSITION].count;
        triangles += gltf.accessors[primitive.indices].count / 3;
        for (const required of ["POSITION", "NORMAL", "TANGENT", "TEXCOORD_0", "TEXCOORD_1"]) {
          if (primitive.attributes[required] === undefined) failures.push(`${name}: missing ${required}`);
        }
      }
    }
    for (const node of gltf.nodes || []) {
      if ((node.scale || [1, 1, 1]).some((value) => value <= 0)) failures.push(`${name}: nonpositive scale`);
    }
    for (const entry of [...(gltf.buffers || []), ...(gltf.images || []), {uri: file}]) {
      if (!entry.uri || entry.uri.startsWith("data:")) continue;
      const sourcePath = path.join(exported, decodeURIComponent(entry.uri));
      const runtimePath = path.join(runtime, decodeURIComponent(entry.uri));
      if (hash(await fs.readFile(sourcePath)) !== hash(await fs.readFile(runtimePath))) failures.push(`${name}: runtime bytes differ for ${entry.uri}`);
    }
    if (report.issues.numErrors) failures.push(`${name}: ${report.issues.numErrors} Khronos errors`);
    reports.push({name, sourceSha256: hash(content), ...manifest.modules[name], exportedVertices, triangles, primitives,
      khronos: {errors: report.issues.numErrors, warnings: report.issues.numWarnings, infos: report.issues.numInfos,
        messages: report.issues.messages},
    });
    await fs.writeFile(path.join(evidence, name + "_khronos.json"), JSON.stringify(report, null, 2) + "\n");
  }
  for (const box of manifest.collision_boxes) {
    if (box.size.some((dimension) => !Number.isFinite(dimension) || dimension <= 0.00001)) failures.push(`Invalid collision: ${box.name}`);
  }
  const result = {tool: "Khronos glTF-Validator", version: validator.version(), timestamp: new Date().toISOString(),
    scope: "Asset correctness and staging only; this is not visual, experiential or milestone acceptance.",
    modules: reports, collisionBoxes: manifest.collision_boxes.length, fixtureInstances: manifest.fixtures.length,
    shadowedFixtures: manifest.fixtures.filter((fixture) => fixture.shadow).length,
    failures, result: failures.length ? "FAIL" : "PASS"};
  await fs.writeFile(path.join(evidence, "asset_validation.json"), JSON.stringify(result, null, 2) + "\n");
  console.log(JSON.stringify({result: result.result, assets: reports.length, fixtureInstances: result.fixtureInstances,
    collisionBoxes: result.collisionBoxes, errors: reports.reduce((sum, item) => sum + item.khronos.errors, 0),
    warnings: reports.reduce((sum, item) => sum + item.khronos.warnings, 0), failures}, null, 2));
  if (failures.length) process.exitCode = 1;
}
main().catch((error) => {console.error(error); process.exitCode = 1;});
