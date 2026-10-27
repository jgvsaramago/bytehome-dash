# Hikvision HCNetSDK (doorbell detection)

The kiosk learns that someone rang **this home** from its own Hikvision
indoor station (tested with a DS-KH8350). A door station may be shared by
several homes, and its call state is "ringing" for any
of them. The indoor station has no
HTTP API (ports 80 and 443 are closed), so the app reads its
`/ISAPI/VideoIntercom/callStatus?format=json` through Hikvision's HCNetSDK on
port 8000, every 0.5 s (`lib/src/services/doorbell_watcher_io.dart`, via
`dart:ffi` on a background isolate). The SDK's alarm push was tested and stays
silent for calls on this model, so polling is used instead.

The SDK is Hikvision's proprietary binary, so it is **not in this repo**. It
lives on the kiosk at `/opt/hcnetsdk` (override with `HIK_SDK_DIR`). The app sets
the SDK's own paths at start-up, so no `LD_LIBRARY_PATH` is needed.

## Install

`setup.sh` does this: Hikvision publishes the SDK only for x86 Linux and
Windows, so it downloads the aarch64 build from the repo below, pinned to
one commit, and checks every file against `SHA256SUMS` before installing it
(`HIK_SDK=0` skips it). By hand: use the aarch64 Linux build (tested: `HCNetSDKV6.1.8.101_build20211210`, as
shipped in the `lib-aarch64` folder of
https://github.com/pergolafabio/Hikvision-Addons):

```sh
sudo mkdir -p /opt/hcnetsdk
sudo cp -a lib-aarch64/. /opt/hcnetsdk/   # libhcnetsdk.so, libHCCore.so, libhpr.so,
                                          # libcrypto.so.1.1, libssl.so, HCNetSDKCom/
sudo chown -R root:root /opt/hcnetsdk
```

## Configure

In `/etc/bytehomedash.env` (mode 600; never in git):

```
INDOOR_HOST=192.168.100.2
INDOOR_USER=admin
INDOOR_PASSWORD=...
```

`INDOOR_PORT` defaults to 8000.

## When it breaks

A red banner across the top of the kiosk says the doorbell won't ring on this
screen and why: SDK missing, wrong password, indoor station unreachable, and so
on. It clears on its own once the link is back. The journal shows the same
reason under `[doorbell]`.

A wrong password or a Hikvision login lockout is retried only every 10
minutes, because each attempt during a lockout extends it.
