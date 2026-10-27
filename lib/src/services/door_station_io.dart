import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import 'door_station.dart';

DoorStation makeDoorStation(DoorStationConfig config) => HikDoorStation(config);

/// ISAPI client for a Hikvision villa door station.
///
/// The KV8413 rejects plain HTTP basic/digest and only accepts Hikvision's
/// salted "session login": GET the login capabilities (salt + per-attempt
/// challenge + iteration count), hash the password through that, POST it, and
/// carry the returned `WebSession…` cookie on every later call. The cookie is
/// cached and silently re-established on a 401, so a dropped session recovers
/// on the next frame without surfacing an error.
class HikDoorStation implements DoorStation {
  HikDoorStation(this.config);

  final DoorStationConfig config;
  final http.Client _http = http.Client();

  String? _cookie;
  Future<void>? _loginInFlight;

  // Backoff after failed logins. Hikvision door stations lock the source IP
  // after a handful of failed auths, and — critically — *extend* that lock on
  // every further attempt during it. The camera view polls ~2x/s, so without
  // this a wrong password or an in-progress lockout would hammer the device
  // forever and the lock would never clear. After a failure we refuse to
  // touch the device again until [_cooldownUntil], backing off further each
  // time, so the app can never be the thing keeping itself locked out.
  DateTime? _cooldownUntil;
  int _failStreak = 0;

  String _sha(String s) => sha256.convert(utf8.encode(s)).toString();

  String _tag(String body, String tag) {
    final m = RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(body);
    return m?.group(1)?.trim() ?? '';
  }

  Future<void> _login() async {
    final capUri = Uri.parse('${config.base}/ISAPI/Security/sessionLogin/capabilities?username=${Uri.encodeComponent(config.username)}');
    final cap = await _http.get(capUri).timeout(const Duration(seconds: 8));
    if (cap.statusCode != 200) {
      throw Exception('door login caps: HTTP ${cap.statusCode}');
    }
    final body = cap.body;
    final sessionId = _tag(body, 'sessionID');
    final challenge = _tag(body, 'challenge');
    final salt = _tag(body, 'salt');
    final iterations = int.tryParse(_tag(body, 'iterations')) ?? 100;
    final irreversible = _tag(body, 'isIrreversible').toLowerCase().contains('true');
    final verRaw = _tag(body, 'sessionIDVersion');
    final sessionIdVersion = verRaw.isEmpty ? '2' : verRaw;

    String hashed;
    if (irreversible) {
      hashed = _sha(config.username + salt + config.password);
      hashed = _sha(hashed + challenge);
    } else {
      hashed = _sha(config.password);
      hashed = _sha(hashed + challenge);
    }
    for (var i = 2; i < iterations; i++) {
      hashed = _sha(hashed);
    }

    final xml =
        '<SessionLogin><userName>${config.username}</userName><password>$hashed</password>'
        '<sessionID>$sessionId</sessionID><isSessionIDValidLongTerm>false</isSessionIDValidLongTerm>'
        '<sessionIDVersion>$sessionIdVersion</sessionIDVersion></SessionLogin>';

    final res = await _http
        .post(Uri.parse('${config.base}/ISAPI/Security/sessionLogin'), headers: const {'Content-Type': 'application/xml'}, body: xml)
        .timeout(const Duration(seconds: 8));
    final setCookie = res.headers['set-cookie'];
    if (res.statusCode == 200 && setCookie != null && setCookie.isNotEmpty) {
      _cookie = setCookie.split(';').first;
    } else {
      throw Exception('door login: HTTP ${res.statusCode}');
    }
  }

  Future<void> _ensureLogin() async {
    if (_cookie != null) return;
    final until = _cooldownUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      // Still backing off from a recent failure — don't touch the device, or
      // we risk extending a lockout we may already be in.
      throw Exception('door auth backing off until $until');
    }
    // Collapse concurrent callers (the snapshot timer + an unlock tap) onto a
    // single in-flight login instead of hammering the device — which also
    // matters because it locks out after a handful of failed logins.
    _loginInFlight ??= _login()
        .then(
          (_) {
            _failStreak = 0;
            _cooldownUntil = null;
          },
          onError: (Object e) {
            _failStreak++;
            final secs = (15 * _failStreak).clamp(15, 120);
            _cooldownUntil = DateTime.now().add(Duration(seconds: secs));
            throw e;
          },
        )
        .whenComplete(() => _loginInFlight = null);
    await _loginInFlight;
  }

  /// Runs [send]; if it 401s, drops the cookie, logs in again, and retries
  /// once. Returns the final response.
  Future<http.Response> _authed(Future<http.Response> Function(String cookie) send) async {
    await _ensureLogin();
    var res = await send(_cookie!);
    if (res.statusCode == 401) {
      _cookie = null;
      await _ensureLogin();
      res = await send(_cookie!);
    }
    return res;
  }

  @override
  Future<Uint8List?> snapshot({int? channel, bool full = false}) async {
    final ch = channel ?? config.channel;
    try {
      final res = await _authed(
        (cookie) => _http
            .get(
              Uri.parse('${config.base}/ISAPI/Streaming/channels/$ch/picture${full ? '?videoResolutionWidth=1920&videoResolutionHeight=1080' : ''}'),
              headers: {'Cookie': cookie},
            )
            .timeout(const Duration(seconds: 6)),
      );
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return res.bodyBytes;
      return null;
    } catch (e) {
      debugPrint('[door] snapshot failed: $e');
      return null;
    }
  }

  @override
  Future<void> unlock() async {
    const xml =
        '<RemoteControlDoor version="2.0" xmlns="http://www.isapi.org/ver20/XMLSchema">'
        '<cmd>open</cmd></RemoteControlDoor>';
    final res = await _authed(
      (cookie) => _http
          .put(
            Uri.parse('${config.base}/ISAPI/AccessControl/RemoteControl/door/${config.doorNo}'),
            headers: {'Cookie': cookie, 'Content-Type': 'application/xml'},
            body: xml,
          )
          .timeout(const Duration(seconds: 8)),
    );
    if (res.statusCode != 200) {
      throw Exception(l10n.doorOpenFailed('${res.statusCode}'));
    }
  }

  @override
  Future<DoorTalk> openTalk() async {
    final open = await _authed(
      (cookie) =>
          _http.put(Uri.parse('${config.base}/ISAPI/System/TwoWayAudio/channels/1/open'), headers: {'Cookie': cookie}).timeout(const Duration(seconds: 6)),
    );
    final session = _tag(open.body, 'sessionId');
    if (open.statusCode != 200 || session.isEmpty) {
      throw Exception(l10n.doorTalkRefused('${open.statusCode}'));
    }
    final talk = _IsapiTalk(this, session);
    try {
      await talk._start(_cookie!);
    } catch (e) {
      await talk.close();
      rethrow;
    }
    return talk;
  }

  Future<void> _closeTalk() async {
    try {
      await _authed(
        (cookie) =>
            _http.put(Uri.parse('${config.base}/ISAPI/System/TwoWayAudio/channels/1/close'), headers: {'Cookie': cookie}).timeout(const Duration(seconds: 6)),
      );
    } catch (e) {
      debugPrint('[door talk] close failed: $e');
    }
  }

  @override
  Future<int?> doorUnlockCount() async {
    // Event 5/21 is "door unlocked". The window spans the door's whole log
    // on purpose: its clock is set by hand and drifts. (The door rejects
    // years far ahead, e.g. 2037, as a "time format error", so the end is
    // only a little in the future.)
    final body =
        '{"AcsEventTotalNumCond":{"major":5,"minor":21,'
        '"startTime":"2020-01-01T00:00:00+00:00","endTime":"${DateTime.now().year + 2}-12-31T23:59:59+00:00"}}';
    try {
      final res = await _authed(
        (cookie) => _http
            .post(
              Uri.parse('${config.base}/ISAPI/AccessControl/AcsEventTotalNum?format=json'),
              headers: {'Cookie': cookie, 'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 6)),
      );
      if (res.statusCode != 200) return null;
      final total = (jsonDecode(res.body) as Map<String, dynamic>)['AcsEventTotalNum']?['totalNum'];
      return total is int ? total : null;
    } catch (e) {
      debugPrint('[door] unlock count failed: $e');
      return null;
    }
  }

  @override
  String get rtspUrl => config.rtspUrl;

  @override
  String get rtspUrlMain => config.rtspUrlMain;

  @override
  void dispose() => _http.close();
}

/// One ISAPI two-way-audio upload: G.711 μ-law from the default input,
/// streamed raw on a PUT to `audioData` (the door answers `200 OK` and keeps
/// reading for as long as the connection stays open). Anything ending —
/// [close], the mic process, or the connection — tears down all of it, so the
/// microphone can't keep going on its own.
class _IsapiTalk implements DoorTalk {
  _IsapiTalk(this._door, this._session);

  final HikDoorStation _door;
  final String _session;
  Socket? _socket;
  Process? _mic;
  bool _closed = false;

  Future<void> _start(String cookie) async {
    final c = _door.config;
    final socket = await Socket.connect(c.host, c.port, timeout: const Duration(seconds: 5));
    _socket = socket;
    socket.write(
      'PUT /ISAPI/System/TwoWayAudio/channels/1/audioData?sessionId=$_session HTTP/1.1\r\n'
      'Host: ${c.host}\r\nCookie: $cookie\r\nContent-Type: application/octet-stream\r\n'
      'Content-Length: 0\r\nConnection: keep-alive\r\n\r\n',
    );
    socket.listen((_) {}, onError: (_) => close(), onDone: close);
    // Capped at 10 minutes in case nothing ever closes it.
    final mic = await Process.start('timeout', [
      '600',
      'gst-launch-1.0',
      '-q',
      'pulsesrc',
      'server=unix:/run/user/1000/pulse/native',
      '!',
      'audioconvert',
      '!',
      'audioresample',
      '!',
      'audio/x-raw,rate=8000,channels=1',
      '!',
      'mulawenc',
      '!',
      'fdsink',
      'fd=1',
    ]);
    if (_closed) {
      mic.kill();
      return;
    }
    _mic = mic;
    mic.stdout.listen((bytes) => _socket?.add(bytes), onDone: close);
    mic.stderr.transform(utf8.decoder).listen((l) => debugPrint('[door talk] $l'));
    debugPrint('[door talk] talking to the door');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _mic?.kill();
    _mic = null;
    _socket?.destroy();
    _socket = null;
    await _door._closeTalk();
    debugPrint('[door talk] closed');
  }
}
