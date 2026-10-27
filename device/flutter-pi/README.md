# Patched flutter-pi (live door video, in-app browser)

The kiosk runs flutter-pi from `master` of
https://github.com/jgvsaramago/flutter-pi: upstream `master` (based on
`release/1.1.1`, the version `flutterpi_tool` 0.12.0 bundles for Flutter
3.44.6) plus one commit per change below, on top, each explaining why, and a `BYTEHOMEDASH.md`
summary. Change flutter-pi there, not here.

## Live door video

The kiosk's live door-camera video needs a patched flutter-pi. Stock flutter-pi
1.1.1 can't play a live RTSP stream through its gstreamer video player:

1. **`initialized` never fires for a live source.** flutter-pi only reports a
   player as ready once it knows duration and seekability. For live streams it
   fakes those, but only when `is_live` is set, and `is_live` is only set when
   the initial `set_state(PAUSED)` returns `NO_PREROLL` synchronously. `rtspsrc`
   connects asynchronously, so it returns `ASYNC`. Fix: treat any
   unknown-duration stream as unbounded and non-seekable (`fetch_duration`,
   `fetch_seeking`).
2. **No frames in PAUSED.** flutter-pi parks pipelines in PAUSED until Dart
   calls `play()`, and Dart only calls `play()` after `initialized`. A live
   source produces no data in PAUSED, so caps never reach the appsink. Fix:
   custom-pipeline players start straight in PLAYING (`init`).
3. **1080p system-memory frames can't be uploaded.** To hand a system-memory
   frame to EGL, flutter-pi copies it into a GBM buffer allocated as one row
   `frame_size` pixels wide, which is past the GPU's maximum width for any real
   frame. Fix: a 4096-byte-wide linear buffer with as many rows as needed
   (same contiguous bytes).
4. **`setVolume` does nothing.** `gstplayer_set_volume` is an unimplemented
   stub upstream. Fix: it sets the `volume` property of the pipeline element
   named `volume`, which the app puts in front of the door audio's sink.

Commit "gstreamer video player: make live RTSP streams play" on the fork.

## Install

`../setup.sh` builds the fork's branch with the WPE plugin and
installs it to `/usr/local/bin/flutter-pi`, which is what the service runs,
not the copy inside the app bundle, so app deploys never overwrite it. A
reimage does, so re-run `setup.sh` after one.

Check: `grep -ac "GBM BO stride" /usr/local/bin/flutter-pi` prints 1 or more.

## Don't use the hardware HEVC decoder

The door camera's H.265 stream made the Pi 5's HEVC kernel driver
(`rpi_hevc_dec`) hang in `hevc_d_h265_stop`. The process was stuck in the
kernel where even SIGKILL couldn't touch it, freezing the kiosk and blocking a
clean reboot. The Pi therefore software-decodes the H.264 main stream
(`avdec_h264`, about 10% of total CPU at 1080p25). Boards with a hardware H.264
decoder GStreamer can drive (the Rock 5B's `rkvdec`) use it instead, with
software as the fallback. Keep both door streams on
H.264; the neighbours' indoor station needs the sub-stream (ch102) on H.264
regardless.

## In-app browser (WPE WebKit web view)

`src/plugins/wpe_webview.c` on the fork (commit "Add a WPE WebKit web view
plugin") is a flutter-pi plugin that renders web pages with WPE
WebKit off-screen and hands each frame to Flutter as a GPU texture (the
`WebViewController` / `WebViewSurface` in `lib/src/services/web_view.dart`,
shown in a popup by `lib/src/kiosk/browser/browser.dart`). wpebackend-fdo
is initialised on flutter-pi's own EGLDisplay, so frames arrive as EGLImages
and are never copied through the CPU. WebKit runs on its own thread with its
own GMainContext.

`../setup.sh` builds it into the same patched binary.

The fork's commit "platformchannel: fix quotes in strings sent to Dart" fixes a bug in flutter-pi's JSON encoder, which
writes every `"` inside a string as `\t`. Any string sent to Dart with a quote
in it arrives garbled: page titles, and the JSON the web view sends when a
text field in a page is tapped (which is how the on-screen keyboard knows to
open). The decoder going the other way leaves strings escaped, so the plugin
unescapes what it receives itself.

Written against WPE WebKit 2.48
(Debian 13); with 2.54+ only the frame source needs to move to the
WPEPlatform API. To open the browser without touching the screen, publish
`browser` to `bytehomedash/<screen name>/sheet/open` over MQTT.
