import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

import { getJsAsset, renderApiReference } from "@scalar/server-side-rendering";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const spec = await readFile(join(root, "openapi.yaml"), "utf8");
const out = join(root, "dist");

const html = await renderApiReference({
  pageTitle: "ClassQ.io API",
  cdn: "/scalar.js",
  config: {
    content: spec,
    agent: { disabled: true },
  },
});

await mkdir(out, { recursive: true });
await writeFile(join(out, "index.html"), html);
await writeFile(join(out, "scalar.js"), getJsAsset());
await writeFile(join(out, "openapi.yaml"), spec);

console.log(`Wrote Scalar docs to ${out}`);
