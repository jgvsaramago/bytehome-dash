import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';

/// A voice the assistant recognises (Linux Voice Assistant's speaker id).
class EnrolledVoice {
  const EnrolledVoice({required this.id, required this.name, required this.samples});

  final String id;
  final String name;
  final int samples;
}

/// What enrolling made of the takes: how many the profile now holds, and
/// which takes the model rejected (too little speech).
class EnrolResult {
  const EnrolResult({required this.samples, required this.rejected});

  final int samples;
  final int rejected;
}

/// Enrols household voices from the screen, through the voice assistant's
/// own tool (`python -m linux_voice_assistant.speaker_id --json`, on this
/// board): it stores embeddings only, and the running assistant picks the
/// change up before the next request. Takes are recorded from the
/// reSpeaker's voice channel and deleted once enrolled.
class VoiceEnrolment {
  VoiceEnrolment._();

  static final instance = VoiceEnrolment._();

  static String get _dir => '${Platform.environment['HOME'] ?? ''}/linux-voice-assistant';

  /// Whether the voice assistant (with speaker id) is installed here.
  bool get available => !kIsWeb && File('$_dir/linux_voice_assistant/speaker_id/__main__.py').existsSync();

  Future<Map<String, dynamic>> _cli(List<String> args) async {
    final r = await Process.run('$_dir/.venv/bin/python', ['-m', 'linux_voice_assistant.speaker_id', '--json', ...args], workingDirectory: _dir);
    final line = (r.stdout as String).trim().split('\n').where((l) => l.startsWith('{')).lastOrNull;
    if (line == null) throw Exception(l10n.voicesErrorNoResponse((r.stderr as String).trim()));
    final out = (jsonDecode(line) as Map).cast<String, dynamic>();
    if (out['ok'] != true) throw Exception(out['error'] ?? l10n.voicesErrorUnknown);
    return out;
  }

  Future<List<EnrolledVoice>> list() async {
    final out = await _cli(['list']);
    if (out['incompatible'] case final String why) {
      throw Exception(l10n.voicesErrorIncompatible(why));
    }
    return [
      for (final s in (out['speakers'] as List? ?? const []).whereType<Map>())
        EnrolledVoice(id: '${s['id']}', name: '${s['name']}', samples: (s['samples'] as num?)?.toInt() ?? 0),
    ];
  }

  /// A new profile for [id] (replacing any), or more samples for it.
  Future<EnrolResult> enrol(String id, String name, List<String> wavs, {bool add = false}) async {
    final out = await _cli([
      if (add) 'add' else 'enroll',
      id,
      if (!add) ...['--name', name, '--replace'],
      ...wavs,
    ]);
    final report = (out['report'] as List? ?? const []).whereType<Map>();
    return EnrolResult(samples: (out['samples'] as num?)?.toInt() ?? 0, rejected: report.where((r) => r['ok'] != true).length);
  }

  Future<void> delete(String id) => _cli(['delete', id]);

  /// The id a person's voice is enrolled under: their name, lowercase,
  /// without accents ("Inês Sá" → "ines_sa").
  static String idFor(String name) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
    const to = 'aaaaaeeeeiiiiooooouuuucn';
    final lower = name.toLowerCase().split('').map((c) {
      final i = from.indexOf(c);
      return i < 0 ? c : to[i];
    }).join();
    final id = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
    final safe = id.isEmpty ? 'pessoa' : id;
    return safe.length > 32 ? safe.substring(0, 32) : safe;
  }
}

/// One take from the microphone: 16 kHz mono PCM16 from the reSpeaker's
/// voice channel (the same one the assistant hears), with a live level.
class VoiceTake {
  VoiceTake._(this._process);

  final Process _process;
  final _pcm = BytesBuilder(copy: false);

  /// 0–1, for the level meter.
  final level = ValueNotifier<double>(0);

  /// `--latency-msec`: parec otherwise buffers ~2 s before passing any
  /// audio on, which the level meter (and a short take) would miss.
  static Future<VoiceTake> start() async {
    final p = await Process.start('parec', ['--device=respeaker_voice', '--format=s16le', '--rate=16000', '--channels=1', '--raw', '--latency-msec=50']);
    final take = VoiceTake._(p);
    p.stdout.listen(take._onData);
    p.stderr.drain<void>();
    return take;
  }

  void _onData(List<int> chunk) {
    _pcm.add(chunk);
    final samples = Int16List.sublistView(Uint8List.fromList(chunk.length.isEven ? chunk : chunk.sublist(0, chunk.length - 1)));
    if (samples.isEmpty) return;
    var sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    final rms = math.sqrt(sum / samples.length) / 32768;
    // Speech sits around 0.02–0.2: a log-ish scale fills the meter usefully.
    level.value = (math.log(1 + rms * 200) / math.log(41)).clamp(0.0, 1.0);
  }

  /// Ends the take and writes it to [path] as a WAV file; returns how many
  /// seconds of it are speech (same rule as the assistant's: frames louder
  /// than the quiet ones).
  Future<double> stop(String path) async {
    _process.kill();
    await _process.exitCode;
    level.value = 0;
    final pcm = _pcm.takeBytes();
    final header = ByteData(44)
      ..setUint32(0, 0x52494646) // RIFF
      ..setUint32(4, 36 + pcm.length, Endian.little)
      ..setUint32(8, 0x57415645) // WAVE
      ..setUint32(12, 0x666d7420) // fmt
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, 16000, Endian.little)
      ..setUint32(28, 32000, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(36, 0x64617461) // data
      ..setUint32(40, pcm.length, Endian.little);
    await File(path).writeAsBytes([...header.buffer.asUint8List(), ...pcm]);
    return _speechSeconds(Int16List.sublistView(pcm.length.isEven ? pcm : pcm.sublist(0, pcm.length - 1)));
  }

  static double _speechSeconds(Int16List samples) {
    const frame = 480; // 30 ms
    final n = samples.length ~/ frame;
    if (n == 0) return 0;
    final rms = List<double>.generate(n, (f) {
      var sum = 0.0;
      for (var i = f * frame; i < (f + 1) * frame; i++) {
        sum += samples[i] * samples[i];
      }
      return math.sqrt(sum / frame) / 32768;
    });
    final sorted = [...rms]..sort();
    final floor = sorted[(n * 0.2).floor()], loud = sorted[math.min(n - 1, (n * 0.8).floor())];
    final cut = math.max(math.min(floor * 3, loud * 0.5), 0.004);
    return rms.where((r) => r > cut).length * frame / 16000;
  }
}
