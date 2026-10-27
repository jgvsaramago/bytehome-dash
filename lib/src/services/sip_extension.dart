import 'dart:async';

import 'package:flutter/foundation.dart';

import 'doorbell_watcher.dart';
import 'sip_extension_stub.dart' if (dart.library.io) 'sip_extension_io.dart' as impl;

/// How to register the Pi as a native Hikvision **indoor extension**.
///
/// This is the reverse-engineered Protocol-2.0 path (validated on the live
/// KH8350, see the hikvision-indoor-station project notes): a plain RFC-3261
/// SIP UA that REGISTERs to the main station's `sipServer` with MD5 digest —
/// the "password" is simply the device **admin password**, and the number is
/// the extension number the station provisioned (an 11-digit number). The Pi
/// must sit **on the intercom VLAN** (same subnet as [server] and the door
/// station's media), or the INVITE/RTP never reach it.
///
/// Replaces the HCNetSDK polling watcher: an incoming `INVITE` *is* the ring,
/// so this also satisfies [DoorbellWatcher]. No proprietary SDK, no port-8000.
class SipExtensionConfig {
  const SipExtensionConfig({
    required this.server,
    required this.number,
    required this.password,
    this.serverPort = 5065,
    this.localPort = 5060,
    this.audioPort = 20000,
    this.videoPort = 20002,
    this.mac = '02:11:22:33:44:55',
    this.expires = 900,
    this.ringTimeout = const Duration(seconds: 60),
  });

  /// The main station's intercom-side IP, which runs the SIP registrar
  /// (`sipServer` on [serverPort]). (`SIP_SERVER`).
  final String server;
  final int serverPort;

  /// The provisioned extension number (digest username).
  final String number;

  /// The device admin password — doubles as the SIP registration password.
  final String password;

  /// The UDP port our UA listens on for SIP (the door sends the INVITE here).
  final int localPort;

  /// Local RTP ports advertised in our answer SDP (audio, then video).
  final int audioPort;
  final int videoPort;

  /// MAC reported in the `<regXML>` body (cosmetic; the station keys auth on
  /// the number + password, not this).
  final String mac;

  /// Registration lifetime, seconds; we re-register well before it lapses.
  final int expires;

  /// Safety backstop: if an incoming call is neither answered here nor
  /// cancelled by the station (e.g. the main station answered and no CANCEL
  /// reached us) within this long, the ring is cleared so the UI can't ring
  /// forever. The station's own CANCEL/BYE normally clears it far sooner.
  final Duration ringTimeout;
}

/// The door's RTP endpoints for the active call, parsed from its INVITE SDP.
/// The media layer (GStreamer) uses these to receive video/audio and to send
/// our microphone back for two-way talk.
@immutable
class SipCallMedia {
  const SipCallMedia({required this.doorIp, required this.audioPort, required this.videoPort});

  /// Where the door streams from / listens (SDP `c=`), e.g. `192.168.100.1`.
  final String doorIp;
  final int audioPort;
  final int videoPort;
}

/// A SIP indoor extension registered to the Hikvision main station.
///
/// It is a [DoorbellWatcher] — [calls] emits [IndoorCallStatus.ringing] on an
/// incoming `INVITE`, [IndoorCallStatus.onCall] once [answer]ed, and
/// [IndoorCallStatus.idle] on hangup — and additionally exposes the call
/// controls and media endpoints the native path needs.
abstract class SipExtension implements DoorbellWatcher {
  /// The door's RTP endpoints while a call is up, else null.
  SipCallMedia? get activeMedia;

  /// Answer the current incoming call: `200 OK` + our SDP, then two-way
  /// audio (the door through the default output, the default input to the
  /// door). No-op if idle.
  void answer();

  /// Stops/resumes sending our microphone to the door during a call; the
  /// door is still heard.
  void setMicMuted(bool muted);

  /// End the current call with `BYE`. No-op if idle.
  void hangup();

  /// Open the door *during a call* via in-dialog `INFO` (DTMF `#`), the way a
  /// real indoor extension's unlock button does. True once the door confirms
  /// it (`200 OK`); false if no call is up or no confirmation came. (ISAPI
  /// unlock still works anytime via the door-station client.)
  Future<bool> unlockViaInfo();
}

/// Starts the extension (registers + keep-alive) on the Pi; a no-op stub on
/// web so the app still builds for browser preview.
SipExtension startSipExtension(SipExtensionConfig config) => impl.startSipExtension(config);

/// The doorbell as a real indoor extension gets it: the door's SIP call.
///
/// The main station forwards the door's INVITE to every registered extension
/// (confirmed with a real press, 2026-10-25), from the door's own identity —
/// so a ring is only ever the door; the indoor station calling out (a
/// live-view talk) sends extensions nothing. CANCEL/BYE end it.
///
/// [indoor], the HCNetSDK poller of the main station, rings nothing here: it
/// only adds that a ring was answered on the indoor station (its "onCall"
/// during our ring), for the call history, and doubles as a link check.
class SipDoorbell implements DoorbellWatcher {
  SipDoorbell(this.sip, {this.indoor}) {
    sip.calls.listen((s) {
      switch (s) {
        case IndoorCallStatus.ringing:
          _ringing = true;
          _answeredHere = false;
          _out.add(s);
        case IndoorCallStatus.onCall:
          // Answered on this screen; the history hears that from the
          // intercom itself, so it isn't reported as answered indoors.
          _answeredHere = true;
        case IndoorCallStatus.idle:
          _ringing = false;
          _out.add(s);
      }
    });
    indoor?.calls.listen((s) {
      if (s == IndoorCallStatus.onCall && _ringing && !_answeredHere) _out.add(s);
    });
    sip.problem.addListener(_updateProblem);
    indoor?.problem.addListener(_updateProblem);
    _updateProblem();
  }

  final SipExtension sip;
  final DoorbellWatcher? indoor;
  final _out = StreamController<IndoorCallStatus>.broadcast();
  final _problem = ValueNotifier<String?>(null);
  bool _ringing = false;
  bool _answeredHere = false;

  void _updateProblem() => _problem.value = sip.problem.value ?? indoor?.problem.value;

  @override
  Stream<IndoorCallStatus> get calls => _out.stream;

  @override
  ValueListenable<String?> get problem => _problem;

  @override
  void dispose() {
    sip.dispose();
    indoor?.dispose();
    _out.close();
    _problem.dispose();
  }
}
