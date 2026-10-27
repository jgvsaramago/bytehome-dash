#!/bin/sh
# Starts a release: checks that the app (pubspec.yaml) and the integration
# (manifest.json) have the same version, that CHANGELOG.md describes it and
# that everything is committed and pushed, then tags vX.Y.Z and pushes the
# tag. GitHub Actions (.github/workflows/release.yml) builds the app and
# publishes the release.
#
#   tool/release.sh
set -eu
cd "$(dirname "$0")/.."

app=$(sed -n 's/^version: *\([^+]*\).*/\1/p' pubspec.yaml)
integration=$(python3 -c "import json;print(json.load(open('custom_components/bytehomedash/manifest.json'))['version'])")
[ "$app" = "$integration" ] || { echo "pubspec.yaml is $app, manifest.json is $integration: make them the same" >&2; exit 1; }
grep -q "^## $app" CHANGELOG.md || { echo "CHANGELOG.md has no '## $app' section" >&2; exit 1; }
[ -z "$(git status --porcelain)" ] || { echo "commit your changes first" >&2; exit 1; }
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || { echo "push main first (it differs from origin/main)" >&2; exit 1; }
git rev-parse -q --verify "refs/tags/v$app" >/dev/null && { echo "v$app already exists: bump the version" >&2; exit 1; }

git tag -a "v$app" -m "ByteHomeDash $app"
git push -q origin "v$app"
echo "v$app pushed; the release builds at https://github.com/$(git remote get-url origin | sed -E 's#.*github.com[:/](.*)\.git$#\1#; s#.*github.com[:/](.*)$#\1#')/actions"
