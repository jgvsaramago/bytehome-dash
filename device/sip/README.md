# Kiosk as a Hikvision indoor extension (interim SIP responder)

**Retired (2026-10-26).** The app registers itself now
(`lib/src/services/sip_extension_io.dart`, enabled by `SIP_SERVER`,
`SIP_NUMBER` and `SIP_PASSWORD` in `/etc/bytehomedash.env`), and both can't
hold UDP 5060. Keep `hik-sip-ext.service` disabled; this script stays as a
standalone test tool. It only tried to register once, right after boot, so
on the Rock 5B it came up before the intercom network and never registered.

Registers the kiosk to the main station (KH8350) as indoor extension
the extension number it provisioned over the reverse-engineered Protocol-2.0 SIP path: plain
RFC-3261 REGISTER + MD5 digest, where the password is the **main station's
admin password** (`SIP_PASSWORD` in `/etc/bytehomedash.env`). An incoming
`INVITE` is the doorbell; `hik_extension.py` can answer, unlock (in-dialog
`INFO Signal=#`) and hang up. The kiosk must have a port on the intercom network (`192.168.100.x`, see
`../README.md`).

This is the **interim** responder; the long-term path is the in-app Dart
`sip_extension` service (lib/src/services/). It registers standalone — it does
not need a second Hikvision indoor station. Appearing in the KH8350's *device list* is separate
(the binary Hik SDK on port 8000, RSA-authenticated) and not required to
register or receive calls.

## Install
    sudo mkdir -p /usr/local/lib/hik-sip
    sudo cp hik_extension.py /usr/local/lib/hik-sip/
    sudo cp hik-sip-ext.service /etc/systemd/system/
    sudo systemctl daemon-reload && sudo systemctl enable --now hik-sip-ext

Logs: `journalctl -u hik-sip-ext -f`
