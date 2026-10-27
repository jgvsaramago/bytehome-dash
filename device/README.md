# Running ByteHomeDash on a kiosk board

> **Setting up a screen for the first time?** Follow the step-by-step [Installation guide](https://github.com/jgvsaramago/bytehomedash/wiki/Installation) in the wiki. This page is the technical reference behind it.

The app runs full-screen on [flutter-pi](https://github.com/ardera/flutter-pi),
which draws straight to the display through DRM/KMS with OpenGL ES: no X11,
no Wayland, no desktop. Two boards are supported and tested:

| | Raspberry Pi 5 | Radxa Rock 5B (RK3588) |
|---|---|---|
| OS | Raspberry Pi OS Trixie Lite (64-bit) | Armbian Trixie **Minimal**, **"current"** kernel (6.18) |
| GPU driver | `vc4`/`v3d` + Mesa | `panthor` + Mesa |
| Boot media | microSD / NVMe | NVMe, bootloader in SPI flash |
| Engine build | `--cpu=pi5` | `--cpu=generic` |
| Kernel arguments | `/boot/firmware/cmdline.txt` | `extraargs=` in `/boot/armbianEnv.txt` |
| DDC/CI (monitor brightness, standby) | works out of the box | needs the overlay in `rock5b/` (see below) |
| Door video decode | software (`avdec_h264`) | hardware (`rkvdec`, `v4l2slh264dec`), software as fallback |
| Throttling stats | `vcgencmd get_throttled` | not available (reported as unknown) |
| GPU Load sensor | DRM fdinfo (`v3d`), works as is | DRM fdinfo (`panthor`), needs `profiling=3` (set at boot by `setup.sh`) |

The app itself is the same on both: board differences are handled at setup
time (`setup.sh`) and build time (`tool/deploy.sh`), so nothing board-specific
runs in the app's hot paths.

Everything below assumes the kiosk user is the board's first user (uid 1000;
the app's audio goes to `/run/user/1000/pulse/native`).

## 1. Install the OS

**Raspberry Pi 5:** flash Raspberry Pi OS Lite (64-bit, Trixie) with
Raspberry Pi Imager, setting the hostname, user and SSH key there.

**Rock 5B:** use the Armbian *Debian Trixie Minimal* image with the
*current* (mainline) kernel, not the *vendor* (Rockchip) one. The vendor image runs Rockchip's 6.1 kernel
with the closed `libmali` GPU driver, which flutter-pi and the WPE web view
don't work well with; mainline gives the open `panthor` driver and the same
Mesa GBM/EGL stack the Pi uses (OpenGL ES 3.1, dma-buf sharing for the web
view).

The RK3588's boot ROM only boots from SPI flash, eMMC or microSD, so:

1. Flash the image to a microSD card and boot from it (with the NVMe fitted).
2. `sudo armbian-install` → *Boot from SPI – system on SATA, USB or NVMe* →
   the NVMe → **Boot from SPI/MTD flash** (not "keep boot in current media").
   It sits at ~95% for several minutes while writing SPI flash; don't
   interrupt it, a half-written bootloader needs maskrom recovery.
3. Power off, remove the card, boot. `findmnt /` shows `/dev/nvme0n1p1`.

Power it from the Raspberry Pi 5 USB-C supply (5.1 V, 5 A): in practice the
board runs on 5 V whatever the charger offers. Its SPI U-Boot (Radxa 2017.09)
doesn't negotiate PD, and enabling the fusb302 in Linux sends a PD hard reset
that cuts power (tried with a runtime overlay: instant reboot). On the Pi 5
supply the input stayed at 5.20 V or above with all cores busy and the
reSpeaker at full volume. Some chargers make it boot-loop. A charger without 12 V (a MacBook's: 5/9/15/20 V) leaves the
board on 5 V: Linux doesn't renegotiate (the fusb302 node is `status=fail`),
and 5 V at 3 A isn't enough for the RK3588 under load plus the reSpeaker's
amplifier. Loud audio alone sagged the input to 4.74 V, and video playback
with sound reset the board without a trace (2026-10-26). Check the input
voltage with `blackbox.py`'s log or
`echo "$(cat /sys/bus/iio/devices/iio:device0/in_voltage6_raw) * 1.8 / 4095 * 108.2 / 8.2" | bc -l`. Fit a heatsink: it idles around 60 °C without one.

Then on either board:

```sh
sudo hostnamectl hostname dashboard-living-room      # the screen's name, see "Naming"
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER
```

Passwordless sudo lets the deploy script restart the service, and the app's
Restart/Shut down buttons run `sudo reboot`/`sudo poweroff`.

Armbian note: `apt full-upgrade` can swap the kernel for a different point
release under the same package version (6.18.45 → 6.18.44 on 2026-10-26).
Harmless after a reboot, but until then `/lib/modules` doesn't match the
running kernel and `modprobe` fails.

## 2. Board setup

```sh
git clone https://github.com/jgvsaramago/bytehomedash.git ~/src/bytehomedash
cd ~/src/bytehomedash/device && sudo sh setup.sh
```

`setup.sh` detects the board from the device tree and is safe to re-run. It:

- installs the build and runtime packages (Mesa, GStreamer with `avdec_h264`
  and `pulsesink`, WPE WebKit 2.0, PipeWire, ddcutil, Plymouth, mDNS so
  `homeassistant.local` resolves);
- builds and installs the patched flutter-pi to `/usr/local/bin/flutter-pi`
  (see `flutter-pi/README.md` for what the patches fix) — skipped when the
  installed binary already has them, `REBUILD_FLUTTER_PI=1` forces it;
- installs `bytehomedash.service` (from the template here, with the user,
  home and `ROTATION` filled in; default `-r 270`, a portrait-mounted panel
  that scans out landscape) and adds the user to `video render input audio
  i2c`;
- installs the boot splash (`plymouth/bytehomedash`), quiets the kernel console and
  hands the display from the splash to the app without a black gap;
- sets up DDC/CI (next section);
- starts PipeWire in the kiosk user's session (lingering, so it runs without
  a login) and sets the default audio devices. With the reSpeaker XVF3800
  plugged in (USB), its speaker is the default output and `respeaker_voice`
  the default input: a mono mic made from channel 0, the board's processed
  (echo-cancelled, beamformed) signal, by `respeaker-voice.conf`. The
  firmware only runs at 16 kHz. It also has a second hardware volume
  (ALSA `PCM,1`, −20 dB by default) that PipeWire doesn't drive, so the
  speaker is quiet even at 100%; `setup.sh` maxes it and saves it with
  `alsactl store` (restored on boot and re-plug). Without it, the first HDMI output is the
  default sink. The Rock 5B otherwise defaults to its headphone jack. If the
  reSpeaker was unplugged or the monitor off, re-run later to set it.
  WirePlumber remembers the choice, so a re-plugged reSpeaker becomes the
  default again;
- installs [Linux Voice Assistant](https://github.com/OHF-Voice/linux-voice-assistant)
  (`~/linux-voice-assistant`) as `linux-voice-assistant.service`, named
  after the hostname, using the `respeaker_voice` mic ("reSpeaker Voice")
  and the default output. It's built from `main` of the fork
  https://github.com/jgvsaramago/linux-voice-assistant (upstream plus the
  changes documented there in `BYTEHOMEDASH.md`): the ESPHome device is
  named after `--name` (upstream: always `lva-<mac>`), runs no longer stick
  in "listening", and speaker identification (`--speaker-id`; the setup also
  installs its runtime and downloads its model).
  It's always installed, but enabled only when the reSpeaker is plugged in
  during the setup: without a microphone it would just restart in a loop. Add it to HA
  once: *Settings → Devices & services → Add integration → ESPHome*, the
  board's IP, port 6053 (HA may also offer it as discovered). The app talks to
  its peripheral API on `127.0.0.1:6055` for the Assistant's on-screen state.

After an unexplained reset, read the tail of
`/var/lib/blackbox/previous-boot.log` (written by `blackbox.py`, installed by
`setup.sh`): input voltage, temperatures, clocks, load and audio state once a
second, plus kernel warnings, up to the moment the board went down.

`setup.sh` also installs what the app needs from outside this repo: the
app itself from the latest release (section 6), Hikvision's HCNetSDK for
an intercom (`hcnetsdk/README.md`) and, when the file doesn't exist yet, a
`/etc/bytehomedash.env` template with every setting (section 5). With
`FLUTTER_SDK=1` it also installs the Flutter SDK (`~/flutter`,
`FLUTTER_VERSION`), to build the app on the board.

## 3. DDC/CI: monitor brightness and on/off

The app sets brightness and puts the monitor in standby over DDC/CI
(`ddcutil`, see `lib/src/services/ddc_ci.dart`), finding the bus itself with
`ddcutil detect`. The monitor must support DDC/CI (the [UPERFECT UMAX 22](https://uperfect.com/products/22-inch-monitor?variant=40452206002248) does).

**Pi 5:** the HDMI DDC lines are on a regular I2C controller. `setup.sh` only
loads `i2c-dev` at boot.

**Rock 5B:** this needs a workaround, and is the one real hardware difference.

- The RK3588's HDMI controller (Synopsys DW HDMI QP) has its own I2C engine
  that only does EDID-style "register address + byte" transfers. The
  mainline driver (`drivers/gpu/drm/bridge/synopsys/dw-hdmi-qp.c`) refuses
  the DDC/CI address 0x37 on purpose with `EOPNOTSUPP`: *"The internal I2C
  controller does not support the multi-byte read and write operations
  needed for DDC/CI."* Both HDMI ports use this controller, so switching
  ports doesn't help.
- The DDC pins, GPIO4_B7 (SCL) and GPIO4_C0 (SDA), don't line up with any
  hardware I2C controller either: their I2C alternate functions are on
  different controllers with the roles swapped.
- So `rock5b/hdmi0-ddc-gpio.dts` takes the two pins away from the HDMI
  controller and makes them a bit-banged `i2c-gpio` bus (`i2c-hdmi0-ddc`,
  usually `/dev/i2c-9`), which does any transfer. Installed as an Armbian
  user overlay (`/boot/overlay-user/hdmi0-ddc-gpio.dtbo`,
  `user_overlays=hdmi0-ddc-gpio`). If it ever fails to apply, Armbian boots
  the plain device tree.
- With the pins gone, the HDMI controller can't read the monitor's EDID, so
  `setup.sh` saves it beforehand to `/usr/lib/firmware/edid/monitor.bin` and
  the kernel loads it from there (`drm.edid_firmware=HDMI-A-1:edid/monitor.bin`).
  The display driver loads in the initramfs for the splash, so
  `rock5b/edid-initramfs-hook` copies the file in there too.

Limits on the Rock 5B:

- The monitor must be on **HDMI0** (`HDMI-A-1`).
- **A different monitor needs its EDID captured again:** remove the
  `user_overlays=` line from `/boot/armbianEnv.txt`, reboot, delete
  `/usr/lib/firmware/edid/monitor.bin`, re-run `setup.sh`, reboot.

Check from a shell: `ddcutil detect` shows the monitor with a VCP version,
`ddcutil --bus 9 getvcp 10` reads brightness, `setvcp D6 04` / `setvcp D6 01`
puts it in standby and wakes it.

## 4. Network

**Only for a Hikvision intercom.** The intercom is optional: without one,
skip this section and leave the `DOOR_*`, `INDOOR_*` and `SIP_*` lines out
of `/etc/bytehomedash.env`. The screen then shows a camera where the door
would be, Settings says the intercom is off, and `setup.sh` doesn't install
the Hikvision SDK.

The intercom devices (door station, indoor station) live on their own
network, `192.168.100.0/24` here. The kiosk needs a port on it with a static
address and **no gateway**, next to its normal home-network connection.

**Rock 5B** (onboard port + an M.2 Ethernet adapter), in
`/etc/netplan/10-dhcp-all-interfaces.yaml`, replacing Armbian's
DHCP-on-every-port default (keep a copy):

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    home:
      match: {macaddress: "<onboard port MAC>"}
      dhcp4: yes
      dhcp6: yes
      ipv6-privacy: yes
    intercom:
      match: {macaddress: "<M.2 adapter MAC>"}
      dhcp4: no
      dhcp6: no
      accept-ra: no
      link-local: []
      addresses: [192.168.100.201/24]
```

`sudo chmod 600` it, then `sudo netplan apply`. Matching by MAC keeps each
port's role if an interface gets renamed. `setup.sh` writes this file for
you with `INTERCOM_ADDR=192.168.100.201/24 HOME_MAC=… INTERCOM_MAC=…`.

**Pi 5** (Wi-Fi home network + `eth0` on the intercom network), with
NetworkManager: `sudo nmcli con mod "Wired connection 1" ipv4.method manual
ipv4.addresses 192.168.100.201/24 ipv4.never-default yes` (or run `setup.sh`
with `INTERCOM_ADDR=192.168.100.201/24`, and `INTERCOM_CON` if the
connection has another name).

Use the same address the SIP extension was registered from. The app reports
the address of the port with the default route as the device's IP.

## 5. Secrets and intercom pieces

`/etc/bytehomedash.env` (root, mode 600, never in git; `setup.sh` installs
the commented template `bytehomedash.env.example` when it's missing) holds:

```
HA_URL=http://homeassistant.local:8123
HA_TOKEN=...
MQTT_HOST=homeassistant.local
MQTT_PORT=1883
MQTT_USERNAME=...
MQTT_PASSWORD=...
DOOR_HOST=192.168.100.1
DOOR_USER=admin
DOOR_PASSWORD=...
INDOOR_HOST=192.168.100.2
INDOOR_USER=admin
INDOOR_PASSWORD=...
SIP_PASSWORD=...
```

The `DOOR_*`, `INDOOR_*` and `SIP_*` lines are only for an intercom; with
no `DOOR_HOST` the screen runs without one. Optional: `SCREEN_NAME` (see
"Naming"), `HIK_SDK_DIR`, `SIP_SERVER` etc.

- Doorbell detection needs Hikvision's HCNetSDK in `/opt/hcnetsdk`:
  `setup.sh` installs it when `INDOOR_HOST` is set (or with `HIK_SDK=1`);
  re-run it after adding the intercom. See `hcnetsdk/README.md`.
- The interim SIP indoor-extension registration: `sip/README.md`.

Moving from one board to another, copy these straight across (`sudo tar`
over SSH) together with `~/.local/share/{bytehomedash,flutter-pi,wpe}`:
doorbell history, saved settings and the web view's sign-ins.

## 6. Install the app

The released build: `setup.sh` installs it on a new board, and
`sh install-app.sh [vX.Y.Z]` updates it (latest by default). Install the
integration from the same release in HACS.

To run your own build instead, set the board up with `FLUTTER_SDK=1` (the
Flutter SDK goes on the board) and, from the repo root on the dev machine:

```sh
tool/deploy.sh pi@dashboard-living-room.local
```

It syncs the source to `~/src/bytehomedash` on the board, builds there with
the engine for that board (`pi5` on a Pi 5; `generic` elsewhere, since the
RK3588's A55 cores can't run the A76-only `pi5` engine), stops the service,
replaces `~/bytehomedash/app` and starts it again. Stop-then-copy matters:
overwriting `app.so` under a running flutter-pi has crashed it.

Logs: `journalctl -u bytehomedash -f`.

## Naming

Each screen is named by its hostname, or by `SCREEN_NAME` in
`/etc/bytehomedash.env` if set. The name is how the screen appears in the
HA sidebar panel's screen list, and it names the screen's MQTT device (its
Screen light, Theme select, Restart/Shut down buttons and vitals sensors)
and MQTT client ID, so every screen in the house gets its own. Pick one per
screen, e.g. `dashboard-living-room`, `dashboard-kitchen`. Settings stored in
the HA integration are shared by all screens.

## Board-specific notes

- **Two DRM devices on the Rock 5B:** the display (`rockchip-drm`) and the
  GPU (`panthor`, render-only), and their card numbers can swap between
  boots. flutter-pi tries each and logs a harmless "Could not create drmdev
  from …" for the GPU one.
- **Door video decoding:** the app uses a hardware H.264 decoder when
  GStreamer has one (`gst-inspect-1.0 --exists v4l2slh264dec`): on the Rock 5B
  that's `rkvdec`, and its frames go to the GPU as DMA buffers without a copy
  (flutter-pi at ~35% of one core with the intercom open, against ~103% in
  software). If the hardware pipeline doesn't start, it falls back to software
  (`avdec_h264`) for the rest of the run. The Pi 5 has no H.264 decoder and
  always uses software. Never the Pi 5's hardware HEVC decoder: it hung in the
  kernel and froze the kiosk. Keep both door streams on H.264. Details in
  `lib/src/services/door_video_io.dart` and `flutter-pi/README.md`.
- **GPU load:** the MQTT device's GPU Load sensor is the busiest GPU engine's
  share of each 30 s interval, summed over this user's DRM clients
  (`drm-engine-*` in `/proc/<pid>/fdinfo`: flutter-pi and the web view's
  WebKit processes). Panthor only records it with
  `/sys/bus/platform/drivers/panthor/*/profiling` set to 3, which `setup.sh`
  makes permanent with a tmpfiles.d entry.
- **Screenshots on the Rock 5B:** `ffmpeg -f kmsgrab` returns garbage, because
  the display scans out Arm AFBC-compressed buffers. To check what the
  decoder produces, grab a frame from the pipeline itself with `pngenc`.
- **Pi 5 booting from NVMe:** a controller reset once forced the root
  filesystem read-only; `pcie_aspm=off` in `cmdline.txt` mitigates it.
- **Pi 5 display:** HDMI only (no DSI overlay may stay enabled in
  `config.txt`, or Plymouth draws on the DSI device).
