#!/bin/sh
# Builds the app on a kiosk and restarts it. Run from the repo root on the
# dev machine:
#
#   tool/deploy.sh pi@dashboard-living-room.local   # user@host; without a user,
#                                            # KIOSK_USER, else your own
#
# The build runs on the board itself (Flutter at ~/flutter there), with the
# engine tuned for it: pi5 on a Raspberry Pi 5, generic on anything else
# (the RK3588's A55 cores can't run the A76-only pi5 engine).
set -eu

HOST=${1:?usage: tool/deploy.sh <host>}
case "$HOST" in *@*) TARGET=$HOST ;; *) TARGET=${KIOSK_USER:-$USER}@$HOST ;; esac

rsync -az --delete --exclude build --exclude .dart_tool --exclude .git \
  --exclude lib/src/dev/local_ha_preview.dart ./ "$TARGET:src/bytehomedash/"

ssh "$TARGET" 'set -e
  export PATH=$PATH:$HOME/flutter/bin
  case "$(tr -d "\0" < /sys/firmware/devicetree/base/model)" in
    "Raspberry Pi 5"*) cpu=pi5; out=pi5-64 ;;
    *) cpu=generic; out=aarch64-generic ;;
  esac
  cd ~/src/bytehomedash
  flutter pub get >/dev/null
  dart run flutterpi_tool build --arch=arm64 --cpu=$cpu --release
  sudo timeout 30 systemctl stop bytehomedash || true
  rm -rf ~/bytehomedash/app
  cp -a build/flutter-pi/$out ~/bytehomedash/app
  sudo systemctl start bytehomedash
  sleep 3
  systemctl is-active bytehomedash'
