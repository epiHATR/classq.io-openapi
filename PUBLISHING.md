# Publishing

Pushing a `v*` tag builds the OpenAPI docs image and publishes it to GitHub Container Registry. Pushing a branch does not publish an image.

The workflow is **Publish image from tag** (`.github/workflows/publish-image.yml`). It checks out the tagged commit, checks that the version in that commit matches the tag, then pushes the image. It does not bump files, create a commit, or create the tag.

## Bump the version

`./scripts/bump-version.sh` sets the same version in:

- `package.json`
- `package-lock.json`
- `openapi.yaml` (`info.version`)
- `README.md`

```bash
VERSION=1.2.0
./scripts/bump-version.sh $VERSION
```

`v1.2.0` is accepted and stored as `1.2.0`. The version must look like `1.2.0` or `1.2.0-rc1`.

## Publish

Commit the bump, push the branch, then tag that same commit and push the tag. The tag has to point at the commit that contains the bumped files.

```bash
VERSION=1.2.0
./scripts/bump-version.sh $VERSION
git add package.json package-lock.json openapi.yaml README.md
git commit -m "chore: bump version to $VERSION"
git push origin HEAD
git tag v$VERSION
git push origin v$VERSION
```

`git push origin v$VERSION` starts the workflow. The tag name must match the bumped version: after bumping to `1.2.0`, the tag is `v1.2.0`.

## Image tags

The image name is `ghcr.io/epihatr/classq.io-openapi`.

| Git tag | Image tags |
| --- | --- |
| `v1.2.0` | `v1.2.0` and `latest` |
| `v1.2.0-rc1` | `v1.2.0-rc1` only |

A tag with a hyphen is a pre-release and does not move `latest`.

After the first successful run, the package is at <https://github.com/epiHATR/classq.io-openapi/pkgs/container/classq.io-openapi>.

Run the published image:

```bash
docker run --rm -p 8089:80 ghcr.io/epihatr/classq.io-openapi:latest
```

The docs are on port 80 inside the container. The OpenAPI file is at `/openapi.yaml`.

## If the workflow fails

The version check fails when the tag and the committed version differ. Bump, commit, and push that commit, then tag the new commit.

If the push to `ghcr.io` is denied, set the repository Actions workflow permissions to allow read and write so `GITHUB_TOKEN` can publish packages.
