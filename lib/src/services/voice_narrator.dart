import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';

/// What the conversation agent is doing while it works, as spoken status.
enum NarratorStatus { thinking, searching, stillWorking }

/// Speaks short status lines on the screen ("Deixa-me pensar", "Vou procurar
/// na internet") while the agent works, so a long answer isn't silence.
///
/// They aren't the agent's words: text the agent writes before it has the
/// answer starts HA's streamed voice early, and a long web search then makes
/// the satellite's player time out. These are synthesised once in the
/// assistant's own voice (HA's `/api/tts_get_url` with the pipeline's TTS
/// engine and voice), cached on disk, played locally, and cut the moment
/// the real answer starts ([stop]).
class VoiceNarrator {
  VoiceNarrator._();

  static final instance = VoiceNarrator._();

  /// In the app's language; the cache is keyed by the text, so another
  /// language just synthesises its own set ([prepare] runs again for it).
  static Map<NarratorStatus, List<String>> get _phrases => {
    NarratorStatus.thinking: [l10n.narratorThinking1, l10n.narratorThinking2, l10n.narratorThinking3, l10n.narratorThinking4],
    NarratorStatus.searching: [l10n.narratorSearching1, l10n.narratorSearching2, l10n.narratorSearching3, l10n.narratorSearching4],
    NarratorStatus.stillWorking: [l10n.narratorStillWorking1, l10n.narratorStillWorking2, l10n.narratorStillWorking3, l10n.narratorStillWorking4],
  };

  final _next = <NarratorStatus, int>{};
  final _files = <String, String>{};
  Process? _playing;
  Future<void>? _preparing;
  String? _preparedFor;

  /// Synthesises every phrase once (in the background; skipped for those
  /// already on disk), so they play without waiting for the voice service.
  void prepare({required String baseUrl, required String token, required Map<String, dynamic>? pipeline}) {
    final language = l10n.localeName;
    if (kIsWeb || pipeline == null || (_preparing != null && _preparedFor == language)) return;
    _preparedFor = language;
    _preparing = _prepare(baseUrl, token, pipeline).catchError((Object e) {
      debugPrint('[narrator] could not prepare the phrases: $e');
      _preparing = null;
      _preparedFor = null;
    });
  }

  Future<void> _prepare(String baseUrl, String token, Map<String, dynamic> p) async {
    final engine = p['tts_engine'] as String?;
    if (engine == null) return;
    final language = p['tts_language'] as String? ?? p['language'] as String? ?? 'pt';
    final voice = p['tts_voice'] as String?;
    final dir = Directory('${Platform.environment['HOME'] ?? '/tmp'}/.cache/bytehomedash/narrator');
    await dir.create(recursive: true);
    for (final text in _phrases.values.expand((v) => v)) {
      final id = sha1.convert(utf8.encode('$engine|$voice|$language|$text')).toString();
      final file = File('${dir.path}/$id.mp3');
      if (!await file.exists()) {
        final res = await http.post(
          Uri.parse('$baseUrl/api/tts_get_url'),
          headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
          body: jsonEncode({
            'engine_id': engine,
            'message': text,
            'language': language,
            // Not `?voice`: null-aware map entries crash the Pi's release compiler.
            'options': {if (voice case final v?) 'voice': v},
          }),
        );
        if (res.statusCode != 200) throw Exception('tts_get_url HTTP ${res.statusCode}');
        final url = (jsonDecode(res.body) as Map)['url'] as String;
        final audio = await http.get(Uri.parse(url));
        if (audio.statusCode != 200 || audio.bodyBytes.isEmpty) throw Exception('audio HTTP ${audio.statusCode}');
        await file.writeAsBytes(audio.bodyBytes);
      }
      _files[text] = file.path;
    }
    debugPrint('[narrator] ${_files.length} phrases ready');
  }

  /// Says one line for [status], a different wording each time.
  Future<void> say(NarratorStatus status) async {
    final options = _phrases[status]!;
    final i = _next[status] ?? 0;
    _next[status] = (i + 1) % options.length;
    final path = _files[options[i]];
    if (path == null) return;
    stop();
    try {
      _playing = await Process.start('gst-launch-1.0', [
        '-q',
        'filesrc',
        'location=$path',
        '!',
        'decodebin',
        '!',
        'audioconvert',
        '!',
        'audioresample',
        '!',
        'pulsesink',
        'server=unix:/run/user/1000/pulse/native',
      ]);
      debugPrint('[narrator] ${options[i]}');
    } catch (e) {
      debugPrint('[narrator] could not play: $e');
    }
  }

  /// Cuts whatever is being said — the real answer is starting.
  void stop() {
    _playing?.kill();
    _playing = null;
  }
}
