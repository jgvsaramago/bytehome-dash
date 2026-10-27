#!/bin/sh
# Sets a board up as a ByteHomeDash kiosk: packages, the patched flutter-pi,
# the systemd service, boot splash, HDMI audio and DDC/CI monitor control.
# Supports a Raspberry Pi 5 (Raspberry Pi OS Trixie Lite) and a Radxa Rock 5B
# (Armbian Trixie Minimal, "current" kernel). Safe to re-run.
#
#   cd ~/src/bytehomedash/device && sudo sh setup.sh
#
# Env overrides: ROTATION (flutter-pi -r, default 270 = portrait panel that
# scans out landscape), REBUILD_FLUTTER_PI=1 (rebuild even if installed),
# APP_VERSION (the release to install, default the latest; APP_VERSION=none
# keeps the app as it is), FLUTTER_SDK=1 + FLUTTER_VERSION (to build the app
# on the board instead, default 3.44.6),
# FLUTTER_PI_REPO / LVA_REPO (other forks to build from), HIK_SDK=1/0
# (install or skip the Hikvision SDK; by default only for an intercom, see
# below), and for the intercom network INTERCOM_ADDR plus
# HOME_MAC + INTERCOM_MAC (Rock 5B) or INTERCOM_CON (Pi 5) — see section 4 of
# README.md.
# See README.md for what each step does and why.
set -eu

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }
KIOSK_USER=${SUDO_USER:?run with sudo from the kiosk user}
KIOSK_HOME=$(getent passwd "$KIOSK_USER" | cut -d: -f6)
KIOSK_UID=$(id -u "$KIOSK_USER")
ROTATION=${ROTATION:-270}
HERE=$(cd "$(dirname "$0")" && pwd)

MODEL=$(tr -d '\0' < /sys/firmware/devicetree/base/model)
case "$MODEL" in
  "Raspberry Pi 5"*) BOARD=pi5 ;;
  "Radxa ROCK 5B"*) BOARD=rock5b ;;
  *) echo "unsupported board: $MODEL" >&2; exit 1 ;;
esac
echo "== $MODEL ($BOARD), user $KIOSK_USER"

# --- Packages ---------------------------------------------------------------
echo "== packages"
EXTRA=""
[ "$BOARD" = rock5b ] && EXTRA="device-tree-compiler"
apt-get update -q
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
  git cmake build-essential pkg-config rsync curl unzip xz-utils ca-certificates \
  libdrm-dev libgbm-dev libegl-dev libgles-dev libsystemd-dev libinput-dev \
  libudev-dev libxkbcommon-dev libvulkan-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libwpewebkit-2.0-dev libwpe-1.0-dev libwpebackend-fdo-1.0-dev \
  libgl1-mesa-dri libegl-mesa0 libgles2 mesa-vulkan-drivers libgbm1 \
  gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-pulseaudio \
  pipewire pipewire-pulse wireplumber pulseaudio-utils rtkit \
  ddcutil plymouth plymouth-label libnss-mdns avahi-daemon python3 $EXTRA

# --- Flutter SDK, only to build the app here (FLUTTER_SDK=1) ------------------
# tool/deploy.sh builds on the board, with the same version as the dev
# machine (pubspec.lock and the AOT snapshot must match). Not needed to run
# a released app (install-app.sh, below).
if [ "${FLUTTER_SDK:-0}" = 1 ]; then
  echo "== Flutter SDK"
  FLUTTER_VERSION=${FLUTTER_VERSION:-3.44.6}
  FLUTTER_DIR=$KIOSK_HOME/flutter
  if [ "$(sudo -u "$KIOSK_USER" git -C "$FLUTTER_DIR" describe --tags 2>/dev/null)" != "$FLUTTER_VERSION" ]; then
    rm -rf "$FLUTTER_DIR"
    sudo -u "$KIOSK_USER" git clone -q --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
  fi
  sudo -u "$KIOSK_USER" "$FLUTTER_DIR/bin/flutter" --version >/dev/null
fi

# --- Hikvision HCNetSDK (the indoor station's call state) ---------------------
# Proprietary, so not in this repo. Hikvision publishes it only for x86
# Linux and Windows, not aarch64; the aarch64 build comes from the Hikvision
# add-on repo below, pinned to one commit and checked file by file against
# hcnetsdk/SHA256SUMS. See hcnetsdk/README.md.
# The intercom is optional: by default the SDK is only installed for a
# screen that has one (INTERCOM_ADDR given, or INDOOR_HOST set in
# /etc/bytehomedash.env). HIK_SDK=1 installs it anyway, HIK_SDK=0 never.
if [ -z "${HIK_SDK:-}" ]; then
  HIK_SDK=0
  if [ -n "${INTERCOM_ADDR:-}" ] || grep -qE '^[[:space:]]*INDOOR_HOST=.+' /etc/bytehomedash.env 2>/dev/null; then HIK_SDK=1; fi
fi
if [ "$HIK_SDK" != 0 ]; then
  echo "== Hikvision SDK"
  HIK_DIR=/opt/hcnetsdk
  HIK_SRC=https://raw.githubusercontent.com/pergolafabio/Hikvision-Addons/fb6abc177f62c480e39a6dbc9dbee997875c76a9/hikvision-doorbell/lib-aarch64
  SUMS="$HERE/hcnetsdk/SHA256SUMS"
  if ! (cd "$HIK_DIR" 2>/dev/null && grep -v '^#' "$SUMS" | sha256sum -c --quiet --status 2>/dev/null); then
    tmp=$(mktemp -d)
    grep -v '^#' "$SUMS" | while read -r _ f; do
      mkdir -p "$tmp/$(dirname "$f")"
      curl -fsSL --retry 3 -o "$tmp/$f" "$HIK_SRC/$f"
    done
    (cd "$tmp" && grep -v '^#' "$SUMS" | sha256sum -c --quiet) || { echo "Hikvision SDK: checksum mismatch, not installed" >&2; exit 1; }
    mkdir -p "$HIK_DIR"
    cp -a "$tmp/." "$HIK_DIR/"
    chown -R root:root "$HIK_DIR"
    rm -rf "$tmp"
    echo "installed in $HIK_DIR"
  fi
fi

# --- Intercom network: a static address on its own port, no gateway -----------
# Only with INTERCOM_ADDR set (e.g. 192.168.100.201/24, the address the SIP
# extension registers from), since the ports differ per board.
if [ -n "${INTERCOM_ADDR:-}" ]; then
  echo "== intercom network"
  if [ "$BOARD" = rock5b ]; then
    : "${HOME_MAC:?HOME_MAC (the onboard port) is needed with INTERCOM_ADDR}" "${INTERCOM_MAC:?INTERCOM_MAC is needed with INTERCOM_ADDR}"
    NP=/etc/netplan/10-dhcp-all-interfaces.yaml
    [ -f "$NP" ] && [ ! -f "$NP.armbian" ] && cp "$NP" "$NP.armbian"
    cat > "$NP" <<NETPLAN
network:
  version: 2
  renderer: networkd
  ethernets:
    home:
      match: {macaddress: "$HOME_MAC"}
      dhcp4: yes
      dhcp6: yes
      ipv6-privacy: yes
    intercom:
      match: {macaddress: "$INTERCOM_MAC"}
      dhcp4: no
      dhcp6: no
      accept-ra: no
      link-local: []
      addresses: [$INTERCOM_ADDR]
NETPLAN
    chmod 600 "$NP"
    netplan apply
  else
    nmcli con mod "${INTERCOM_CON:-Wired connection 1}" ipv4.method manual ipv4.addresses "$INTERCOM_ADDR" ipv4.never-default yes
    nmcli con up "${INTERCOM_CON:-Wired connection 1}" >/dev/null
  fi
fi

# --- Patched flutter-pi (live video, WPE web view) -------------------------
# From the fork's master: upstream plus our changes, one commit each (see
# BYTEHOMEDASH.md there and flutter-pi/README.md here).
FP=/usr/local/bin/flutter-pi
if [ "${REBUILD_FLUTTER_PI:-0}" = 1 ] || ! grep -aq "GBM BO stride" "$FP" 2>/dev/null \
    || ! grep -aq "bytehomedash/webview" "$FP"; then
  echo "== building flutter-pi"
  SRC=/usr/local/src/flutter-pi-build
  rm -rf "$SRC"
  git clone -q --depth 1 "${FLUTTER_PI_REPO:-https://github.com/jgvsaramago/flutter-pi.git}" "$SRC"
  mkdir "$SRC/build" && cd "$SRC/build"
  cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_WPE_WEBVIEW_PLUGIN=ON .. >/dev/null
  make -j"$(nproc)" >/dev/null
  timeout 30 systemctl stop bytehomedash 2>/dev/null || true
  cp flutter-pi "$FP.new" && mv -f "$FP.new" "$FP"
  cd "$HERE"
fi

# --- Service -----------------------------------------------------------------
echo "== service"
[ -f /etc/bytehomedash.env ] || install -m 600 -o root -g root /dev/null /etc/bytehomedash.env
sed -e "s|@USER@|$KIOSK_USER|g; s|@HOME@|$KIOSK_HOME|g; s|@UID@|$KIOSK_UID|g; s|@ROTATION@|$ROTATION|g" \
  "$HERE/bytehomedash.service" > /etc/systemd/system/bytehomedash.service
mkdir -p "$KIOSK_HOME/bytehomedash"
chown "$KIOSK_USER:" "$KIOSK_HOME/bytehomedash"
for g in video render input audio i2c; do
  getent group $g >/dev/null || groupadd $g
  usermod -aG $g "$KIOSK_USER"
done

# --- Boot splash + kernel arguments --------------------------------------------
echo "== boot splash"
rm -rf /usr/share/plymouth/themes/casa /usr/share/plymouth/themes/bytehomedash
cp -r "$HERE/plymouth/bytehomedash" /usr/share/plymouth/themes/bytehomedash
SPLASH="quiet splash plymouth.ignore-serial-consoles loglevel=3 logo.nologo vt.global_cursor_default=0 systemd.show_status=false rd.systemd.show_status=false udev.log_level=3 rd.udev.log_level=3"
if [ "$BOARD" = pi5 ]; then
  CMDLINE=/boot/firmware/cmdline.txt
  sed -i 's/console=tty1 /console=tty3 /' "$CMDLINE"
  grep -q ' splash' "$CMDLINE" || sed -i "s/\$/ $SPLASH/" "$CMDLINE"
  grep -q '^disable_splash=1' /boot/firmware/config.txt || echo 'disable_splash=1' >> /boot/firmware/config.txt
else
  ENV=/boot/armbianEnv.txt
  sed -i 's/^console=.*/console=serial/; s/^verbosity=.*/verbosity=0/; s/^bootlogo=.*/bootlogo=false/' "$ENV"
  grep -q ' splash' "$ENV" || sed -i "s/^extraargs=.*/& $SPLASH/" "$ENV"
fi
# The app takes the display over from the splash without a black gap:
# plymouth-quit does nothing, the service deactivates Plymouth before
# flutter-pi starts and quits it (keeping the last frame) 10 s later.
mkdir -p /etc/systemd/system/plymouth-quit.service.d /etc/systemd/system/bytehomedash.service.d
printf '[Service]\nExecStart=\nExecStart=/bin/true\n' > /etc/systemd/system/plymouth-quit.service.d/retain-splash.conf
printf '[Unit]\nAfter=plymouth-start.service\n\n[Service]\nExecStartPre=+-/usr/bin/plymouth deactivate\nExecStartPost=+-/bin/sh -c "sleep 10; /usr/bin/plymouth quit --retain-splash"\n' \
  > /etc/systemd/system/bytehomedash.service.d/plymouth.conf
systemctl disable getty@tty1.service 2>/dev/null || true

# --- DDC/CI (monitor brightness and standby) --------------------------------------
echo "== DDC/CI"
if [ "$BOARD" = pi5 ]; then
  # The Pi's HDMI DDC lines sit on a normal I2C controller; only the
  # userspace device node module is needed.
  echo i2c-dev > /etc/modules-load.d/i2c-dev.conf
else
  # RK3588: the HDMI controller's I2C engine can't do DDC/CI, so HDMI0's
  # DDC pins become a bit-banged I2C bus and the EDID comes from a file,
  # captured now while the controller can still read it.
  mkdir -p /usr/lib/firmware/edid /boot/overlay-user
  if [ ! -f /usr/lib/firmware/edid/monitor.bin ]; then
    EDID=$(ls /sys/class/drm/card*-HDMI-A-1/edid | head -1)
    [ -s "$EDID" ] || { echo "no EDID on HDMI-A-1: connect the monitor to HDMI0 and boot without the overlay" >&2; exit 1; }
    cp "$EDID" /usr/lib/firmware/edid/monitor.bin
  fi
  install -m 755 "$HERE/rock5b/edid-initramfs-hook" /etc/initramfs-tools/hooks/edid
  dtc -@ -q -I dts -O dtb -o /boot/overlay-user/hdmi0-ddc-gpio.dtbo "$HERE/rock5b/hdmi0-ddc-gpio.dts"
  grep -q '^user_overlays=' "$ENV" || echo 'user_overlays=hdmi0-ddc-gpio' >> "$ENV"
  sed -i 's| drm.edid_firmware=[^ ]*||' "$ENV"
  sed -i 's|^extraargs=.*|& drm.edid_firmware=HDMI-A-1:edid/monitor.bin|' "$ENV"
fi

if [ "$BOARD" = rock5b ]; then
  # Per-client GPU busy time in /proc/<pid>/fdinfo, for the app's GPU Load
  # sensor: panthor only keeps it with profiling on (1 cycles + 2 timestamps).
  echo 'w /sys/bus/platform/drivers/panthor/*/profiling - - - - 3' > /etc/tmpfiles.d/panthor-profiling.conf
  systemd-tmpfiles --create /etc/tmpfiles.d/panthor-profiling.conf
fi

systemctl daemon-reload
systemctl enable bytehomedash.service
plymouth-set-default-theme -R bytehomedash

# --- Audio: PipeWire in the kiosk user's session ------------------------------
# Default output and input: the reSpeaker XVF3800 when plugged in (speaker +
# its processed voice channel), otherwise output on HDMI.
echo "== audio"
loginctl enable-linger "$KIOSK_USER"
sudo -u "$KIOSK_USER" XDG_RUNTIME_DIR="/run/user/$KIOSK_UID" HERE="$HERE" sh -c '
  systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
  sleep 3
  src=$(pactl list short sources | cut -f2 | grep -m1 "^alsa_input\.usb-Seeed_Studio_reSpeaker" || true)
  if [ -n "$src" ]; then
    mkdir -p ~/.config/pipewire/pipewire.conf.d
    sed "s|@SOURCE@|$src|" "$HERE/respeaker-voice.conf" \
      > ~/.config/pipewire/pipewire.conf.d/50-respeaker-voice.conf
    systemctl --user restart pipewire pipewire-pulse wireplumber
    sleep 3
    pactl set-default-source respeaker_voice
    echo "default audio input: respeaker_voice (from $src)"
  else
    echo "no reSpeaker plugged in — default input left as is"
  fi
  sink=$(pactl list short sinks | cut -f2 | grep -m1 "^alsa_output\.usb-Seeed_Studio_reSpeaker" || true)
  [ -n "$sink" ] || sink=$(pactl list short sinks | cut -f2 | grep -m1 -i hdmi || true)
  if [ -n "$sink" ]; then
    pactl set-default-sink "$sink" && pactl set-sink-volume @DEFAULT_SINK@ 100%
    echo "default audio output: $sink"
  else
    echo "no reSpeaker or HDMI audio output yet (monitor off?) — rerun later to set it"
  fi'
# The reSpeaker has a second playback volume (ALSA "PCM",1) outside the mixer
# path PipeWire drives; left at its -20 dB default the speaker stays quiet at
# 100%. Max it and save: alsa-utils' udev rule restores it on boot and re-plug.
card=$(awk '/reSpeaker/ { print $1; exit }' /proc/asound/cards)
if [ -n "$card" ]; then
  amixer -q -c "$card" sset PCM,1 100% && alsactl store "$card"
  echo "reSpeaker hardware volume: max (card $card)"
fi

# --- Voice: Linux Voice Assistant, the ESPHome satellite HA talks to ----------
# From the fork's main: upstream plus our fixes (ESPHome name from --name;
# runs stuck in "listening" — see BYTEHOMEDASH.md there). script/setup
# builds its venv (a few minutes), again whenever pyproject.toml changes. Only
# enabled with the reSpeaker plugged in — without a mic it would just
# restart-loop. Re-run setup.sh after plugging one in.
echo "== voice assistant"
LVA_REPO=${LVA_REPO:-https://github.com/jgvsaramago/linux-voice-assistant.git}
LVA_DIR=$KIOSK_HOME/linux-voice-assistant
apt-get install -y -q libmpv-dev libasound2-plugins python3-venv python3-dev build-essential >/dev/null
[ -d "$LVA_DIR" ] || sudo -u "$KIOSK_USER" git clone -q "$LVA_REPO" "$LVA_DIR"
sudo -u "$KIOSK_USER" sh -c "cd '$LVA_DIR' && git remote set-url origin '$LVA_REPO' && git fetch -q origin \
  && git checkout -q -f -B main origin/main"
deps=$(sha256sum "$LVA_DIR/pyproject.toml" | cut -d' ' -f1)
if [ ! -x "$LVA_DIR/.venv/bin/python" ] || [ "$(cat "$LVA_DIR/.venv/.pyproject-sha" 2>/dev/null)" != "$deps" ]; then
  sudo -u "$KIOSK_USER" sh -c "cd '$LVA_DIR' && script/setup --makeflags=-j$(nproc) && echo $deps > .venv/.pyproject-sha" >/dev/null
fi
# Speaker identification: its runtime (optional dependency) and model.
sudo -u "$KIOSK_USER" sh -c "cd '$LVA_DIR' && .venv/bin/pip install -q 'sherpa-onnx>=1.12,<2' \
  && .venv/bin/python -m linux_voice_assistant.speaker_id download" >/dev/null
sed -e "s|@USER@|$KIOSK_USER|g; s|@HOME@|$KIOSK_HOME|g; s|@UID@|$KIOSK_UID|g; s|@NAME@|$(hostname)|g" \
  "$HERE/linux-voice-assistant.service" > /etc/systemd/system/linux-voice-assistant.service
systemctl daemon-reload
if [ -n "$card" ]; then
  systemctl enable linux-voice-assistant.service
  systemctl restart linux-voice-assistant.service
  echo "voice assistant on; add it in HA: ESPHome integration, $(hostname -I | cut -d' ' -f1) port 6053"
else
  echo "voice assistant installed but off (no reSpeaker)"
fi

# --- Black box: what the board was doing before an unexplained reset ---------
# Armbian keeps /var/log in RAM, so a hard reset (power dip, thermal trip)
# leaves no log at all. blackbox.py writes input voltage, temperatures,
# clocks, load and audio state once a second to /var/lib/blackbox, fsync'd.
echo "== black box"
install -m 755 "$HERE/blackbox.py" /usr/local/bin/blackbox.py
install -m 644 "$HERE/blackbox.service" /etc/systemd/system/blackbox.service
systemctl daemon-reload
systemctl enable --now blackbox.service

# --- Settings and secrets ------------------------------------------------------
# The template, with every key the app reads, when there's no file yet.
echo "== settings"
if [ ! -f /etc/bytehomedash.env ]; then
  install -m 600 -o root -g root "$HERE/bytehomedash.env.example" /etc/bytehomedash.env
  echo "fill in /etc/bytehomedash.env (template installed)"
fi

# --- The app: the released build, unless there's one already ------------------
# (tool/deploy.sh replaces it with your own build.)
if [ "${APP_VERSION:-}" != none ] && [ ! -f "$KIOSK_HOME/bytehomedash/app/app.so" ]; then
  sudo -u "$KIOSK_USER" -H sh "$HERE/install-app.sh" ${APP_VERSION:+"$APP_VERSION"}
fi

echo "== done. Fill in /etc/bytehomedash.env, install the integration in HA (HACS), reboot."
