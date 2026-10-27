import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The browser's audio as PipeWire sees it: each sound a page plays is a
/// stream ("sink input") from the WPE web process, set here with `pactl` —
/// per stream, so the master volume (the default sink) is untouched. Streams
/// come and go as pages play, so while a browser is open [watch] follows
/// `pactl subscribe` and calls back on each new one to have it set too.
///
/// Every call is guarded: `pactl` may be missing or PipeWire not up.
class BrowserAudioStreams {
  BrowserAudioStreams(this._onNewStream);

  final void Function() _onNewStream;
  Process? _subscribe;

  /// Only WPE WebKit's own processes (WPEWebProcess and friends) — never the
  /// app itself (door call, doorbell: flutter-pi), the voice assistant or
  /// anything else, so no other volume moves.
  static bool _isBrowser(Map<String, dynamic> props) => '${props['application.process.binary'] ?? ''}'.startsWith('WPE');

  Future<void> apply({required int percent, required bool muted}) async {
    try {
      final r = await Process.run('pactl', ['-f', 'json', 'list', 'sink-inputs']);
      if (r.exitCode != 0) return;
      for (final s in (jsonDecode(r.stdout as String) as List).whereType<Map>()) {
        final props = (s['properties'] as Map?)?.cast<String, dynamic>() ?? const {};
        if (!_isBrowser(props)) continue;
        final id = '${s['index']}';
        await Process.run('pactl', ['set-sink-input-volume', id, '${percent.clamp(0, 100)}%']);
        await Process.run('pactl', ['set-sink-input-mute', id, muted ? '1' : '0']);
      }
    } catch (_) {}
  }

  void watch() {
    if (_subscribe != null) return;
    Process.start('pactl', ['subscribe']).then((p) {
      _subscribe = p;
      p.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        if (line.contains("'new' on sink-input")) _onNewStream();
      });
    }, onError: (_) {});
  }

  void unwatch() {
    _subscribe?.kill();
    _subscribe = null;
  }
}
