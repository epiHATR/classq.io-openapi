# ClassQ OpenAPI docs. Build from the repo root:
#   docker build -t classq-io-openapi .
FROM node:22-alpine AS build

WORKDIR /src

COPY package.json package-lock.json ./
RUN npm ci

COPY openapi.yaml redocly.yaml ./
RUN mkdir -p /out \
  && npx redocly build-docs openapi.yaml --output /out/index.html \
  && node --input-type=module <<'EOF'
import { createHash } from "node:crypto";
import { readFileSync, writeFileSync } from "node:fs";

const htmlPath = "/out/index.html";
let html = readFileSync(htmlPath, "utf8");
const tag = html.match(
  /<script src="(https:\/\/cdn\.redocly\.com\/[^"]+)" integrity="(sha384-[^"]+)"/
);
if (!tag) {
  console.error("Redoc script tag not found in built docs");
  process.exit(1);
}
const [, url, integrity] = tag;
const response = await fetch(url);
if (!response.ok) {
  console.error(`Failed to download ${url}: ${response.status}`);
  process.exit(1);
}
const bytes = Buffer.from(await response.arrayBuffer());
const digest = `sha384-${createHash("sha384").update(bytes).digest("base64")}`;
if (digest !== integrity) {
  console.error(`Integrity mismatch for ${url}`);
  process.exit(1);
}
writeFileSync("/out/redoc.standalone.js", bytes);
writeFileSync(htmlPath, html.replace(url, "/redoc.standalone.js"));
EOF

FROM nginx:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /out/index.html /out/redoc.standalone.js /usr/share/nginx/html/
COPY openapi.yaml /usr/share/nginx/html/openapi.yaml

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=5s --retries=5 --start-period=10s \
  CMD wget -q --spider "http://127.0.0.1:80/" || exit 1

CMD ["nginx", "-g", "daemon off;"]
