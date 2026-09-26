#!/usr/bin/env bash
# Bump the OpenAPI contract version in package.json, package-lock.json,
# openapi.yaml, and README.md.
#
# Usage:
#   ./scripts/bump-version.sh 1.1.10
#   ./scripts/bump-version.sh v1.1.10
#
# Commit and push the result before tagging. The image publish workflow
# runs when the matching v* tag is pushed, and it does not bump versions.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>   e.g. 1.1.10 or v1.1.10" >&2
  exit 1
fi

VERSION="${VERSION#v}"
if [[ ! "$VERSION" =~ ^[0-9]+(\.[0-9]+)*(-[0-9A-Za-z.]+)?$ ]]; then
  echo "Invalid version: $VERSION (expected semver like 1.1.10 or 1.1.10-rc1)" >&2
  exit 1
fi

node <<NODE
const fs = require('fs')
const version = '$VERSION'
const root = '$ROOT'

function read(name) {
  return fs.readFileSync(root + '/' + name, 'utf8')
}

function write(name, text) {
  fs.writeFileSync(root + '/' + name, text)
}

const pkgPath = 'package.json'
const pkg = JSON.parse(read(pkgPath))
pkg.version = version
write(pkgPath, JSON.stringify(pkg, null, 2) + '\n')

const lockPath = 'package-lock.json'
const lock = JSON.parse(read(lockPath))
lock.version = version
if (lock.packages && lock.packages['']) {
  lock.packages[''].version = version
}
write(lockPath, JSON.stringify(lock, null, 2) + '\n')

const specPath = 'openapi.yaml'
const spec = read(specPath)
const nextSpec = spec.replace(/^  version: .+$/m, '  version: ' + version)
if (nextSpec === spec) {
  console.error('openapi.yaml info version was not updated')
  process.exit(1)
}
write(specPath, nextSpec)

const readmePath = 'README.md'
const readme = read(readmePath)
const nextReadme = readme.replace(
  /matches app version \*\*[^*]+\*\*/,
  'matches app version **' + version + '**'
)
if (nextReadme === readme) {
  console.error('README.md version was not updated')
  process.exit(1)
}
write(readmePath, nextReadme)
NODE

echo "Bumped to $VERSION"
echo "  package.json"
echo "  package-lock.json"
echo "  openapi.yaml"
echo "  README.md"
echo "Commit these files, push the branch, then: git tag v$VERSION && git push origin v$VERSION"
