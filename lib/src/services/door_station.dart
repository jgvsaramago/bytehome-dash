import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../kiosk/modals/intercom_modal.dart';
import '../l10n/l10n.dart';
import '../kiosk/theme/kiosk_icons.dart';
import '../kiosk/theme/kiosk_tokens.dart';
import 'door_station_stub.dart' if (dart.library.io) 'door_station_io.dart';
import 'door_video.dart';
import 'doorbell_history.dart';
import 'doorbell_watcher.dart';
import 'sip_extension.dart';

/// Where the door station lives and how to log into it. The kiosk talks to a
/// Hikvision villa door station (DS-KV series) directly over its ISAPI HTTP
/// API — no Home Assistant in the path — reachable on the intercom VLAN the
/// Pi is bridged onto (see the hikvision-indoor-station project notes).
class DoorStationConfig {
  const DoorStationConfig({
    required this.host,
    required this.username,
    required this.password,
    this.port = 80,
    this.channel = 101,
    this.doorNo = 1,
    this.rtspChannel = 102,
  });

  final String host;
  final String username;
  final String password;
  final int port;

  /// Streaming channel for the camera: 101 = main stream, 102 = sub.
  final int channel;

  /// Which lock relay `RemoteControlDoor` opens (the KV8413 has 1–2).
  final int doorNo;

  /// RTSP channel for the live view. 102 (640×480 sub) is the default: same
  /// ~1s startup as the 1080p main but far lighter to decode and lower latency
  /// on the Pi. Its auth is disabled on the door (see project notes), so the
  /// URL carries no credentials.
  final int rtspChannel;

  String get base => 'http://$host:$port';

  /// Credential-less RTSP URL for the sub-stream (auth disabled on it).
  String get rtspUrl => 'rtsp://$host:554/Streaming/Channels/$rtspChannel';

  /// Credential-less RTSP URL for the 1080p main stream (HD toggle).
  String get rtspUrlMain => 'rtsp://$host:554/Streaming/Channels/$channel';
}

/// A Hikvision door station spoken to over ISAPI. The real implementation
/// (dart:io, [makeDoorStation] in door_station_io.dart) handles the
/// session-login auth, snapshot polling and door unlock; the web build gets
/// a no-op stub so the app still compiles for browser preview.
abstract class DoorStation {
  /// One JPEG frame from the door camera, or null if it couldn't be fetched
  /// (network blip, auth re-login in progress). Callers keep showing the
  /// previous frame rather than flashing an error on a single miss. [channel]
  /// picks the stream (101 main/HD, 102 sub/SD); defaults to the config channel.
  /// [full] asks for the stream's full 1920×1080: without it the door
  /// answers with a 704×576 still — fine for tiles, too small for the
  /// picture of who rang.
  Future<Uint8List?> snapshot({int? channel, bool full = false});

  /// Pulse the door-lock relay open. Throws on failure so the UI can toast.
  Future<void> unlock();

  /// How many "door unlocked" events the door station's own log holds, or
  /// null if it couldn't be read. Comparing two readings tells whether the
  /// door was opened in between — from this screen, an indoor station or a
  /// key fob — without trusting the door's clock (it isn't kept in sync).
  Future<int?> doorUnlockCount();

  /// Talk to whoever is at the door, the way an indoor station's live-view
  /// talk button does: opens the door's ISAPI two-way-audio session and
  /// streams the default input (the reSpeaker's echo-cancelled voice) to its
  /// speaker until [DoorTalk.close]. Throws if the door refuses (e.g. busy on
  /// another apartment's call).
  Future<DoorTalk> openTalk();

  /// Credential-less RTSP URLs of the sub (default) and main (HD) streams.
  /// Empty on the web stub.
  String get rtspUrl;
  String get rtspUrlMain;

  void dispose();
}

/// A live talk session to the door's speaker; [close] stops the microphone
/// and ends the session. Safe to call more than once.
abstract class DoorTalk {
  Future<void> close();
}

/// Builds the platform-appropriate door station client (real on the Pi,
/// no-op on web).
DoorStation createDoorStation(DoorStationConfig config) => makeDoorStation(config);

/// Drives the kiosk's existing intercom UI ([IntercomController]) from a live
/// door station: video, door-open, and sound. When the door's call reaches
/// this screen's SIP extension, answering takes the call with two-way audio;
/// otherwise the door's sound is only heard (from its RTSP stream).
class DoorStationIntercom implements IntercomController {
  // Sound comes from the sub-stream: a second session on the 1080p main
  // stream (which the video is already playing) made the door send it twice,
  // halving the video's frame rate. The sub-stream's video is tiny.
  DoorStationIntercom(this.station, {required this.doorbell, this.sip})
    : _doorAudio = DoorAudio(station.rtspUrl),
      history = DoorbellHistory(station: station, statuses: doorbell.calls) {
    _audio.addListener(() {
      _doorAudio.setPlaying(_audio.value);
      if (!_audio.value) history.stoppedListening();
    });
    // The door or the indoor station ended the call (BYE/CANCEL). Lives as
    // long as the app, like this controller.
    sip?.calls.listen((s) {
      if (s == IndoorCallStatus.idle && _talking) {
        _talking = false;
        _ended.add(null);
      }
    });
  }

  final _ended = StreamController<void>.broadcast();

  @override
  Stream<void> get callEnded => _ended.stream;

  /// This screen answered the door's SIP call and is talking.
  bool _talking = false;

  /// Talking from live view (no SIP call): the door's ISAPI talk session.
  DoorTalk? _doorTalk;

  /// Bumped whenever talk should stop, so a session that finishes opening
  /// after a hang-up or mute is closed at once.
  int _talkGen = 0;

  Future<void> _startDoorTalk() async {
    final gen = ++_talkGen;
    try {
      final t = await station.openTalk();
      if (gen != _talkGen || !_audio.value) {
        await t.close();
      } else {
        _doorTalk = t;
      }
    } catch (e) {
      // Still hear the door; the door may be busy on another call.
      debugPrint('[door talk] could not start: $e');
    }
  }

  Future<void> _stopDoorTalk() async {
    _talkGen++;
    final t = _doorTalk;
    _doorTalk = null;
    await t?.close();
  }

  final DoorStation station;

  /// This apartment's doorbell, read from the indoor station (the shared door
  /// station can't tell apartments apart).
  final DoorbellWatcher doorbell;

  /// This screen registered to the indoor station as a SIP indoor extension,
  /// when configured: the door calls it like any indoor station, which is
  /// what two-way talk goes through. While its rings are unproven the SDK
  /// poller ([doorbell]) stays the ring source.
  final SipExtension? sip;
  final DoorAudio _doorAudio;

  @override
  final DoorbellHistory history;

  @override
  bool get connected => true;

  final _videoStatus = ValueNotifier(IntercomVideoStatus.connecting);

  /// Whether the door's sound should be playing: on in a call, off while just
  /// looking (so a glance at the camera doesn't play street noise).
  final _audio = ValueNotifier(false);

  // Live RTSP video (gstreamer on the Pi), with the snapshot view as the
  // during-connect / failure fallback so there's always a picture. Its state
  // drives the modal's header badge through [videoStatus].
  @override
  Widget? videoView() => doorLiveVideo(
    station.rtspUrl,
    station.rtspUrlMain,
    status: _videoStatus,
    audio: _audio,
    fallback: DoorCameraView(station: station),
  );

  @override
  ValueListenable<IntercomVideoStatus> get videoStatus => _videoStatus;

  @override
  Future<Uint8List?> snapshot() => station.snapshot();

  // Only "ringing" and "not ringing" matter to the screen: the indoor station
  // going on-call means it was answered there, which ends the ring here.
  @override
  Stream<IntercomMode> get callEvents => doorbell.calls.map((s) => s == IndoorCallStatus.ringing ? IntercomMode.ringing : IntercomMode.view).distinct();

  @override
  ValueListenable<String?> get doorbellProblem => doorbell.problem;

  // With the door's call at this screen's SIP extension, answering takes it:
  // two-way audio, and the indoor stations stop ringing, as with any indoor
  // extension. Without it (the indoor station didn't route the call here),
  // a "call" is local: the door's sound is heard, nothing is signalled, and
  // the indoor station keeps ringing.
  @override
  Future<void> answer() async {
    final s = sip;
    if (s != null && s.activeMedia != null) {
      s.answer();
      _talking = true;
    } else {
      _audio.value = true;
      unawaited(_startDoorTalk());
    }
    history.answeredHere();
  }

  @override
  Future<void> hangUp() async {
    if (_talking) {
      sip?.hangup();
      _talking = false;
    }
    _audio.value = false;
    await _stopDoorTalk();
  }

  /// Mutes our microphone; the door is still heard. From live view, muting
  /// closes the door's talk session altogether, so nothing at all is sent.
  @override
  Future<void> setMuted(bool muted) async {
    if (_talking) {
      sip?.setMicMuted(muted);
    } else if (_audio.value) {
      if (muted) {
        await _stopDoorTalk();
      } else {
        unawaited(_startDoorTalk());
      }
    }
  }

  /// During a call answered here, opens the door from inside the call (SIP
  /// INFO with DTMF `#`), as an indoor extension's unlock button does;
  /// unconfirmed after 3 s, or outside a call, through the door's ISAPI.
  @override
  Future<void> unlock() async {
    final viaCall = _talking && (await sip?.unlockViaInfo() ?? false);
    if (!viaCall) await station.unlock();
    history.doorOpenedHere();
  }

  @override
  Duration get unlockHold => const Duration(seconds: 5);
}

/// A snapshot view of the door camera, used as the fallback while the live RTSP
/// player connects (or if it fails). Polls the JPEG `.../picture` endpoint a
/// couple of times a second and swaps frames with `gaplessPlayback` so there's
/// no flicker. The live player ([doorLiveVideo]) overlays its own status chip
/// and HD toggle on top of this, so this stays a plain image.
class DoorCameraView extends StatefulWidget {
  const DoorCameraView({super.key, required this.station, this.fps = 2});

  final DoorStation station;
  final double fps;

  @override
  State<DoorCameraView> createState() => _DoorCameraViewState();
}

class _DoorCameraViewState extends State<DoorCameraView> {
  Timer? _timer;
  Uint8List? _frame;
  bool _inFlight = false;
  bool _everLoaded = false;

  @override
  void initState() {
    super.initState();
    _tick();
    final period = Duration(milliseconds: (1000 / widget.fps).round().clamp(200, 5000));
    _timer = Timer.periodic(period, (_) => _tick());
  }

  Future<void> _tick() async {
    if (_inFlight || !mounted) return;
    _inFlight = true;
    try {
      final bytes = await widget.station.snapshot();
      if (bytes != null && bytes.isNotEmpty && mounted) {
        setState(() {
          _frame = bytes;
          _everLoaded = true;
        });
      }
    } finally {
      _inFlight = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    if (frame != null) {
      return Image.memory(frame, fit: BoxFit.cover, gaplessPlayback: true, width: double.infinity, height: double.infinity);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const KIcon(KIcons.video, size: 64, color: Color(0xFF9AA0A6), stroke: 1.5),
        const SizedBox(height: 14),
        Text(_everLoaded ? l10n.doorCameraReconnecting : l10n.doorCameraConnecting, style: KText.s(22, color: const Color(0xFF9AA0A6))),
      ],
    );
  }
}
