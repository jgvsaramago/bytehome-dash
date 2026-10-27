#!/bin/sh
# Installs the app from a GitHub release — no Flutter SDK on the board —
# and restarts it. The build for this board: tuned for the Pi 5's cores on
# a Raspberry Pi 5, generic on anything else (Rock 5B). The download is
# checked against the release's SHA256SUMS.
#
#   sh install-app.sh            # the latest release
#   sh install-app.sh v0.1.0     # a given one
#
# Run as the kiosk user (it uses sudo to restart the service). Install the
# Home Assistant integration from the same release (HACS).
set -eu

REPO=${BYTEHOMEDASH_REPO:-jgvsaramago/bytehomedash}
TAG=${1:-$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')}
[ -n "$TAG" ] || { echo "no release found in $REPO" >&2; exit 1; }
case "$(tr -d '\0' < /sys/firmware/devicetree/base/model)" in
  "Raspberry Pi 5"*) cpu=pi5 ;;
  *) cpu=generic ;;
esac
NAME=bytehomedash-$TAG-$cpu.tar.gz
URL=https://github.com/$REPO/releases/download/$TAG

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "== app $TAG ($cpu)"
curl -fsSL --retry 3 -o "$tmp/$NAME" "$URL/$NAME"
curl -fsSL --retry 3 -o "$tmp/SHA256SUMS" "$URL/SHA256SUMS"
(cd "$tmp" && grep " $NAME\$" SHA256SUMS | sha256sum -c --quiet) || { echo "checksum mismatch, not installed" >&2; exit 1; }
mkdir "$tmp/app"
tar -C "$tmp/app" -xzf "$tmp/$NAME"

APP=$HOME/bytehomedash/app
mkdir -p "$HOME/bytehomedash"
# Stop first: replacing app.so under a running flutter-pi can crash it.
sudo timeout 30 systemctl stop bytehomedash 2>/dev/null || true
rm -rf "$APP"
mv "$tmp/app" "$APP"
echo "$TAG" > "$HOME/bytehomedash/app-version"
sudo systemctl start bytehomedash 2>/dev/null || true
echo "installed in $APP"
