import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import 'doorbell_watcher.dart';
import 'sip_extension.dart';

SipExtension startSipExtension(SipExtensionConfig config) => _SipUa(config)..start();

String _md5(String s) => md5.convert(utf8.encode(s)).toString();

/// The incoming call we're currently in a dialog with (one at a time — a door
/// station rings one call). Keeps what we need to reply in-dialog (answer,
/// INFO unlock, BYE).
class _Dialog {
  _Dialog({
    required this.inviteMsg,
    required this.callId,
    required this.remoteFrom,
    required this.remoteUri,
    required this.remoteAddr,
    required this.remotePort,
    required this.localTag,
    required this.media,
  });

  final String inviteMsg; // the raw INVITE, to echo Via/CSeq on provisional replies
  final String callId;
  final String remoteFrom; // their full From header (identity + their tag)
  final String remoteUri; // sip:…@…:port to address in-dialog requests to
  final InternetAddress remoteAddr;
  final int remotePort;
  final String localTag; // our To-tag, reused for in-dialog From
  final SipCallMedia media;
  int localCseq = 1;
  bool answered = false;

  /// Our 200 OK, resent until the door ACKs it (and on a repeated INVITE).
  String? ok;
  Timer? okResend;
  bool acked = false;
}

/// Pure-Dart SIP indoor extension. Event-driven over one UDP socket: REGISTER
/// with MD5 digest (admin password), re-register before expiry, and treat an
/// incoming INVITE as the doorbell.
class _SipUa implements SipExtension {
  _SipUa(this.config);

  final SipExtensionConfig config;
  final _rand = Random();

  RawDatagramSocket? _sock;
  String _localIp = '0.0.0.0';

  final _calls = StreamController<IndoorCallStatus>.broadcast();
  late final _problem = ValueNotifier<String?>(l10n.doorSipConnecting);
  Timer? _keepalive;
  Timer? _startupGrace;
  Timer? _ringTimeout;
  bool _disposed = false;

  // Registration transaction state.
  int _regCseq = 0;
  String _regCallId = '';
  String _regTag = '';
  String _regLine = '';
  bool _regAuthSent = false;
  bool _registered = false;

  _Dialog? _call;

  /// The door's answer to our unlock INFO, by CSeq.
  final _infoReplies = <String, Completer<bool>>{};

  // Two-way audio while a call is up: the door's RTP to the default output,
  // the default input (the reSpeaker's echo-cancelled voice) to the door.
  Process? _rx;
  Process? _tx;
  bool _micMuted = false;

  @override
  Stream<IndoorCallStatus> get calls => _calls.stream;

  @override
  ValueListenable<String?> get problem => _problem;

  @override
  SipCallMedia? get activeMedia => _call?.media;

  // ---------------------------------------------------------------- lifecycle
  Future<void> start() async {
    // Give the first registration a moment before shouting that it's down.
    _startupGrace = Timer(const Duration(seconds: 20), () {
      if (!_registered) _problem.value = l10n.doorSipNoConnection(config.server);
    });
    try {
      _localIp = await _resolveLocalIp();
      final s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, config.localPort);
      _sock = s;
      s.listen(_onEvent, onError: (Object e) => debugPrint('[sip] socket error: $e'));
      debugPrint('[sip] UA ${config.number} @ $_localIp:${config.localPort} -> ${config.server}:${config.serverPort}');
      _register();
      // Re-register comfortably before Expires lapses.
      final every = (config.expires * 2 / 3).clamp(30, 3600).round();
      _keepalive = Timer.periodic(Duration(seconds: every), (_) => _register());
    } catch (e) {
      debugPrint('[sip] start failed: $e');
      _problem.value = l10n.doorSipStartFailed('$e');
    }
  }

  /// The address on our side of the intercom subnet — what we put in Via/
  /// Contact/SDP so the station sends the INVITE and RTP back to us.
  Future<String> _resolveLocalIp() async {
    final serverParts = config.server.split('.');
    final prefix = serverParts.length == 4 ? '${serverParts[0]}.${serverParts[1]}.${serverParts[2]}.' : null;
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
    String? fallback;
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        fallback ??= addr.address;
        if (prefix != null && addr.address.startsWith(prefix)) return addr.address;
      }
    }
    return fallback ?? '0.0.0.0';
  }

  void _onEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final dg = _sock?.receive();
    if (dg == null) return;
    final msg = utf8.decode(dg.data, allowMalformed: true);
    try {
      _onMessage(msg, dg.address, dg.port);
    } catch (e) {
      debugPrint('[sip] handle error: $e');
    }
  }

  // ----------------------------------------------------------------- messages
  void _onMessage(String msg, InternetAddress addr, int port) {
    final start = msg.split('\r\n').first;
    if (start.startsWith('SIP/2.0')) {
      _onResponse(msg, start);
    } else {
      final method = start.split(' ').first;
      switch (method) {
        case 'INVITE':
          _onInvite(msg, addr, port);
        case 'BYE':
          _reply(msg, addr, port, '200 OK');
          debugPrint('[sip] remote hung up');
          _endCall();
        case 'CANCEL':
          _reply(msg, addr, port, '200 OK');
          _endCall();
        case 'OPTIONS':
        case 'MESSAGE':
        case 'INFO':
          _reply(msg, addr, port, '200 OK');
        case 'ACK':
          final c = _call;
          if (c != null && c.callId == (_header(msg, 'Call-ID') ?? '') && !c.acked) {
            c.acked = true;
            c.okResend?.cancel();
            debugPrint('[sip] ACK — the door has the call');
          }
        default:
          _reply(msg, addr, port, '200 OK');
      }
    }
  }

  void _onResponse(String msg, String start) {
    final cseq = _header(msg, 'CSeq') ?? '';
    if (cseq.contains('REGISTER')) {
      if (start.contains(' 401 ') || start.contains(' 407 ')) {
        if (!_regAuthSent) {
          _regAuthSent = true;
          _sendRegister(challenge: msg);
        }
      } else if (start.contains(' 200 ')) {
        if (!_registered) debugPrint('[sip] REGISTERED');
        _registered = true;
        _startupGrace?.cancel();
        _problem.value = null;
      } else if (start.contains(' 403 ')) {
        _problem.value = l10n.doorSipRegistrationRefused;
      }
    }
    if (cseq.endsWith('INFO')) {
      _infoReplies.remove(cseq)?.complete(start.contains(' 200 '));
    }
    // Responses to our BYE need no action.
  }

  // --------------------------------------------------------------- REGISTER
  static const _regBody =
      '<regXML>\n<version>V2.0.0</version>\n<regDevName>Pi Extension</regDevName>\n'
      '<regDevSerial>PI000000001</regDevSerial>\n<regDevMacAddr>{mac}</regDevMacAddr>\n</regXML>\n';

  void _register() {
    if (_disposed) return;
    // Fresh transaction each cycle.
    _regCseq++;
    _regCallId = 'reg-${config.number}-${DateTime.now().millisecondsSinceEpoch}';
    _regTag = _token();
    _regLine = _hex(14);
    _regAuthSent = false;
    _sendRegister();
  }

  void _sendRegister({String? challenge}) {
    final ruri = 'sip:${config.number}@${config.server}:${config.serverPort}';
    final to = 'Pi Extension <sip:${config.number}@$_localIp>';
    final body = _regBody.replaceFirst('{mac}', config.mac);
    _regCseq++;
    var auth = '';
    if (challenge != null) {
      final nonce = _quoted(challenge, 'nonce');
      final realm = _quoted(challenge, 'realm') ?? 'Hikvision';
      final opaque = _quoted(challenge, 'opaque');
      final ha1 = _md5('${config.number}:$realm:${config.password}');
      final ha2 = _md5('REGISTER:$ruri');
      final resp = _md5('$ha1:$nonce:$ha2');
      auth =
          'Authorization: Digest username="${config.number}", realm="$realm", '
          'nonce="$nonce", uri="$ruri", response="$resp", algorithm=MD5'
          '${opaque != null ? ', opaque="$opaque"' : ''}\r\n';
    }
    final req = StringBuffer()
      ..write('REGISTER $ruri SIP/2.0\r\n')
      ..write('Via: SIP/2.0/UDP $_localIp:${config.localPort};rport;branch=${_branch()}\r\n')
      ..write('From: $to;tag=$_regTag\r\n')
      ..write('To: $to\r\n')
      ..write('Call-ID: $_regCallId\r\n')
      ..write('CSeq: $_regCseq REGISTER\r\n')
      ..write('Contact: <sip:${config.number}@$_localIp:${config.localPort};line=$_regLine>\r\n')
      ..write(auth)
      ..write('Max-Forwards: 70\r\nUser-Agent: HKVS/2.0.0\r\n')
      ..write('Expires: ${config.expires}\r\nContent-Type: text/xml\r\n')
      ..write('Content-Length:   ${body.length}\r\n\r\n')
      ..write(body);
    _sendTo(req.toString(), InternetAddress(config.server), config.serverPort);
  }

  // ----------------------------------------------------------------- INVITE
  void _onInvite(String msg, InternetAddress addr, int port) {
    final callId = _header(msg, 'Call-ID') ?? '';
    // A re-INVITE for the call we're already in (e.g. media renegotiation):
    // acknowledge without re-ringing. Re-send 200 if we'd answered, else 180.
    final existing = _call;
    if (existing != null && existing.callId == callId) {
      final ok = existing.ok;
      if (ok != null) {
        _sendTo(ok, existing.remoteAddr, existing.remotePort);
      } else {
        _reply(msg, addr, port, '180 Ringing', toTag: existing.localTag);
      }
      return;
    }
    final body = msg.contains('\r\n\r\n') ? msg.split('\r\n\r\n').skip(1).join('\r\n\r\n') : '';
    final cIp = _re(body, r'c=IN IP4 ([\d.]+)') ?? addr.address;
    final aPort = int.tryParse(_re(body, r'm=audio (\d+)') ?? '') ?? 0;
    final vPort = int.tryParse(_re(body, r'm=video (\d+)') ?? '') ?? 0;
    final from = _header(msg, 'From') ?? '';
    final contact = _header(msg, 'Contact');
    final remoteUri = _re(contact ?? '', r'<(sip:[^>;]+)') ?? _re(from, r'<(sip:[^>;]+)') ?? 'sip:${config.server}';
    _call = _Dialog(
      inviteMsg: msg,
      callId: callId,
      remoteFrom: from,
      remoteUri: remoteUri,
      remoteAddr: addr,
      remotePort: port,
      localTag: _token(),
      media: SipCallMedia(doorIp: cIp, audioPort: aPort, videoPort: vPort),
    );
    debugPrint('[sip] INVITE from $from — media $cIp audio:$aPort video:$vPort');
    debugPrint('[sip] INVITE routing: ${_headers(msg, 'Via').length} Via, ${_headers(msg, 'Record-Route').length} Record-Route, from ${addr.address}:$port');
    _problem.value = null;
    _reply(msg, addr, port, '100 Trying');
    _reply(msg, addr, port, '180 Ringing', toTag: _call!.localTag);
    _calls.add(IndoorCallStatus.ringing);
    // Backstop: if the station never CANCELs/BYEs (e.g. the main station
    // answered and no CANCEL reached us) and we don't answer, clear the ring
    // so the UI can't ring forever.
    _ringTimeout?.cancel();
    _ringTimeout = Timer(config.ringTimeout, () {
      final c = _call;
      if (c != null && !c.answered) {
        debugPrint('[sip] ring unanswered/uncancelled after ${config.ringTimeout.inSeconds}s — clearing');
        _endCall();
      }
    });
  }

  @override
  void answer() {
    final c = _call;
    if (c == null || c.answered) return;
    final sdp = StringBuffer()
      ..write('v=0\r\n')
      ..write('o=${config.number} 0 0 IN IP4 $_localIp\r\n')
      ..write('s=Talk session\r\nc=IN IP4 $_localIp\r\nt=0 0\r\n')
      // PCMU only: the door offers G.722.1, PCMU and PCMA, and a single codec
      // in the answer is the one it then sends.
      ..write('m=audio ${config.audioPort} RTP/AVP 0 101\r\n')
      ..write('a=rtpmap:0 PCMU/8000\r\n')
      ..write('a=rtpmap:101 telephone-event/8000\r\na=sendrecv\r\n')
      ..write('m=video ${config.videoPort} RTP/AVP 96\r\n')
      ..write('a=rtpmap:96 H264/90000\r\na=recvonly\r\n');
    c.ok = _reply(
      c.inviteMsg,
      c.remoteAddr,
      c.remotePort,
      '200 OK',
      toTag: c.localTag,
      extra:
          'Contact: <sip:${config.number}@$_localIp:${config.localPort}>\r\n'
          'Content-Type: application/sdp\r\nContent-Length: ${sdp.length}\r\n',
      body: sdp.toString(),
    );
    c.answered = true;
    // RFC 3261 §13.3.1.4: over UDP the 200 is resent (T1 doubling, capped at
    // T2) until the ACK arrives, for up to 64·T1.
    var wait = const Duration(milliseconds: 500);
    var sent = Duration.zero;
    void resend() {
      c.okResend = Timer(wait, () {
        if (c.acked || _call != c) return;
        sent += wait;
        if (sent >= const Duration(seconds: 32)) {
          debugPrint('[sip] no ACK for our 200 OK — the door never took the call');
          return;
        }
        _sendTo(c.ok!, c.remoteAddr, c.remotePort);
        wait = wait * 2 > const Duration(seconds: 4) ? const Duration(seconds: 4) : wait * 2;
        resend();
      });
    }

    resend();
    _ringTimeout?.cancel();
    _calls.add(IndoorCallStatus.onCall);
    _startMedia(c.media);
    debugPrint('[sip] answered — media should flow to $_localIp:${config.audioPort}/${config.videoPort}');
  }

  @override
  Future<bool> unlockViaInfo() async {
    final c = _call;
    if (c == null || !c.answered) return false;
    const body = 'Signal=#\r\nDuration=160\r\n';
    c.localCseq++;
    final req = StringBuffer()
      ..write('INFO ${c.remoteUri} SIP/2.0\r\n')
      ..write('Via: SIP/2.0/UDP $_localIp:${config.localPort};rport;branch=${_branch()}\r\n')
      ..write('From: <sip:${config.number}@$_localIp:${config.localPort}>;tag=${c.localTag}\r\n')
      ..write('To: ${c.remoteFrom}\r\n')
      ..write('Call-ID: ${c.callId}\r\n')
      ..write('CSeq: ${c.localCseq} INFO\r\n')
      ..write('Contact: <sip:${config.number}@$_localIp:${config.localPort}>\r\n')
      ..write('Max-Forwards: 70\r\nUser-Agent: HKVS/2.0.0\r\n')
      ..write('Content-Type: application/dtmf-relay\r\nContent-Length: ${body.length}\r\n\r\n')
      ..write(body);
    final reply = Completer<bool>();
    _infoReplies['${c.localCseq} INFO'] = reply;
    _sendTo(req.toString(), c.remoteAddr, c.remotePort);
    debugPrint('[sip] unlock INFO Signal=# sent');
    final ok = await reply.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        _infoReplies.remove('${c.localCseq} INFO');
        return false;
      },
    );
    debugPrint('[sip] unlock ${ok ? 'confirmed by the door' : 'not confirmed'}');
    return ok;
  }

  @override
  void hangup() {
    final c = _call;
    if (c == null) return;
    c.localCseq++;
    final req = StringBuffer()
      ..write('BYE ${c.remoteUri} SIP/2.0\r\n')
      ..write('Via: SIP/2.0/UDP $_localIp:${config.localPort};rport;branch=${_branch()}\r\n')
      ..write('From: <sip:${config.number}@$_localIp:${config.localPort}>;tag=${c.localTag}\r\n')
      ..write('To: ${c.remoteFrom}\r\n')
      ..write('Call-ID: ${c.callId}\r\n')
      ..write('CSeq: ${c.localCseq} BYE\r\n')
      ..write('Max-Forwards: 70\r\nContent-Length: 0\r\n\r\n');
    _sendTo(req.toString(), c.remoteAddr, c.remotePort);
    debugPrint('[sip] BYE sent');
    _endCall();
  }

  void _endCall() {
    _ringTimeout?.cancel();
    _ringTimeout = null;
    _call?.okResend?.cancel();
    _stopMedia();
    if (_call == null) return;
    _call = null;
    _calls.add(IndoorCallStatus.idle);
  }

  // ------------------------------------------------------------------- media
  static const _pulse = 'server=unix:/run/user/1000/pulse/native';

  void _startMedia(SipCallMedia m) {
    _stopMedia();
    _micMuted = false;
    _gst('rx', [
      'udpsrc',
      'port=${config.audioPort}',
      'caps=application/x-rtp,media=audio,encoding-name=PCMU,payload=0,clock-rate=8000',
      '!',
      'rtpjitterbuffer',
      'latency=80',
      '!',
      'rtppcmudepay',
      '!',
      'mulawdec',
      '!',
      'audioconvert',
      '!',
      'audioresample',
      '!',
      'pulsesink',
      _pulse,
    ]).then((p) => _rx = _keep(p));
    _startMic(m);
  }

  void _startMic(SipCallMedia m) {
    if (m.audioPort == 0) return;
    _gst('tx', [
      'pulsesrc',
      _pulse,
      '!',
      'audioconvert',
      '!',
      'audioresample',
      '!',
      'audio/x-raw,rate=8000,channels=1',
      '!',
      'mulawenc',
      '!',
      'rtppcmupay',
      'pt=0',
      'min-ptime=20000000',
      'max-ptime=20000000',
      '!',
      'udpsink',
      'host=${m.doorIp}',
      'port=${m.audioPort}',
    ]).then((p) => _tx = _micMuted ? _discard(p) : _keep(p));
  }

  /// A pipeline that finished starting after the call ended is stopped.
  Process? _keep(Process? p) => _call?.answered == true ? p : _discard(p);

  Process? _discard(Process? p) {
    p?.kill();
    return null;
  }

  /// One gst-launch pipeline, capped at 10 minutes in case a call's end is
  /// never signalled.
  Future<Process?> _gst(String name, List<String> pipeline) async {
    try {
      final p = await Process.start('timeout', ['600', 'gst-launch-1.0', '-q', ...pipeline]);
      p.stdout.drain<void>();
      p.stderr.transform(utf8.decoder).listen((l) => debugPrint('[sip $name] $l'));
      debugPrint('[sip] audio $name started');
      return p;
    } catch (e) {
      debugPrint('[sip] audio $name failed: $e');
      return null;
    }
  }

  void _stopMedia() {
    _rx?.kill();
    _tx?.kill();
    _rx = null;
    _tx = null;
  }

  @override
  void setMicMuted(bool muted) {
    final c = _call;
    if (c == null || !c.answered || muted == _micMuted) return;
    _micMuted = muted;
    if (muted) {
      _tx?.kill();
      _tx = null;
    } else {
      _startMic(c.media);
    }
  }

  // ------------------------------------------------------------------ helpers
  /// Builds a status reply by echoing the request's Via/From/To/Call-ID/CSeq,
  /// adding our To-tag, and appending any [extra] headers + [body].
  /// Every Via is echoed, in order (RFC 3261 §8.2.6.2): the door's INVITE
  /// comes through the main station, and the reply finds its way back along
  /// them. A 1xx/2xx to an INVITE also echoes its Record-Route set.
  String _reply(String req, InternetAddress addr, int port, String status, {String? toTag, String extra = '', String body = ''}) {
    final vias = _headers(req, 'Via');
    final routes = req.startsWith('INVITE') && !status.startsWith('100') ? _headers(req, 'Record-Route') : const <String>[];
    final from = _header(req, 'From') ?? '';
    var to = _header(req, 'To') ?? '';
    final cid = _header(req, 'Call-ID') ?? '';
    final cseq = _header(req, 'CSeq') ?? '';
    if (!to.contains(';tag=')) to = '$to;tag=${toTag ?? _token()}';
    final res = StringBuffer()
      ..write('SIP/2.0 $status\r\n')
      ..writeAll(vias.map((v) => 'Via: $v\r\n'))
      ..writeAll(routes.map((r) => 'Record-Route: $r\r\n'))
      ..write('From: $from\r\n')
      ..write('To: $to\r\n')
      ..write('Call-ID: $cid\r\n')
      ..write('CSeq: $cseq\r\n')
      ..write('User-Agent: HKVS/2.0.0\r\n')
      ..write(extra)
      ..write('Content-Length: ${body.length}\r\n\r\n')
      ..write(body);
    _sendTo(res.toString(), addr, port);
    return res.toString();
  }

  void _sendTo(String msg, InternetAddress addr, int port) {
    final s = _sock;
    if (s == null) return;
    s.send(utf8.encode(msg), addr, port);
  }

  String? _header(String msg, String name) {
    final re = RegExp('^$name:\\s*(.+)\$', multiLine: true, caseSensitive: false);
    return re.firstMatch(msg)?.group(1)?.trim();
  }

  /// All values of a header that may repeat (one per line, or comma-joined),
  /// in order. Only the headers, not the body.
  List<String> _headers(String msg, String name) {
    final head = msg.split('\r\n\r\n').first;
    final re = RegExp('^$name:\\s*(.+)\$', multiLine: true, caseSensitive: false);
    return [for (final m in re.allMatches(head)) m.group(1)!.trim()];
  }

  String? _quoted(String msg, String key) => RegExp('$key="([^"]+)"').firstMatch(msg)?.group(1);

  String? _re(String s, String pattern) => RegExp(pattern).firstMatch(s)?.group(1);

  String _token() => _rand.nextInt(0x7fffffff).toString();
  String _branch() => 'z9hG4bK${_rand.nextInt(0x7fffffff)}';
  String _hex(int n) {
    const chars = '0123456789abcdef';
    return List.generate(n, (_) => chars[_rand.nextInt(16)]).join();
  }

  @override
  void dispose() {
    _disposed = true;
    _keepalive?.cancel();
    _startupGrace?.cancel();
    _ringTimeout?.cancel();
    _stopMedia();
    _sock?.close();
    _calls.close();
    _problem.dispose();
  }
}
