// Sets up a fresh clone: checks xcodegen, creates the local signing file from
// the example if it is missing, then generates the Xcode project.
//
// Usage: node scripts/bootstrap.ts   (Node 22.18 or newer runs .ts directly)

import { spawnSync } from "node:child_process";
import { copyFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const local = join(root, "Config", "Signing.local.xcconfig");
const example = `${local}.example`;

function fail(message: string): never {
  console.error(`error: ${message}`);
  process.exit(1);
}

if (spawnSync("xcodegen", ["--version"], { stdio: "ignore" }).status !== 0) {
  fail("xcodegen not found. Install it with: brew install xcodegen");
}

if (existsSync(local)) {
  console.log(`==> ${local} already exists, leaving it alone`);
} else {
  copyFileSync(example, local);
  console.log(`==> Created ${local} from the example.`);
  console.log("    Edit it: set DEVELOPMENT_TEAM and BUNDLE_ID_PREFIX.");
}

const result = spawnSync("xcodegen", ["generate", "--spec", "project.yml"], {
  cwd: root,
  stdio: "inherit",
});
if (result.status !== 0) {
  fail("xcodegen generate failed");
}
console.log("==> Generated MacroSpotlightIntents.xcodeproj");
