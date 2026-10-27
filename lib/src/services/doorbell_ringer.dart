import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'ringtone_sound.dart';

/// One of the doorbell tones in assets/ringtones, all synthesized by
/// tool/make_ringtones.py in the styles of chimes, building intercom
/// monitors and smart doorbells (none is a copy of a brand's sound).
class Ringtone {
  const Ringtone(this.id, this.group, {String? asset, String? fileName}) : _asset = asset, _fileName = fileName;

  final String id;

  /// One of [ringtoneGroups]: an id, shown by [ringtoneGroupLabel].
  final String group;
  final String? _asset;

  /// A custom tone's name, from its file.
  final String? _fileName;

  String get asset => _asset ?? 'assets/ringtones/$id.wav';

  String get name =>
      _fileName ??
      switch (id) {
        'dingdong' => l10n.doorbellToneDingdong,
        'westminster' => l10n.doorbellToneWestminster,
        'tres_tons' => l10n.doorbellToneTresTons,
        'carrilhao' => l10n.doorbellToneCarrilhao,
        'trrrim' => l10n.doorbellToneTrrrim,
        'portaria' => l10n.doorbellTonePortaria,
        'digital' => l10n.doorbellToneDigital,
        'melodia' => l10n.doorbellToneMelodia,
        'dois_toques' => l10n.doorbellToneDoisToques,
        'harpa' => l10n.doorbellToneHarpa,
        'xilofone' => l10n.doorbellToneXilofone,
        'triangulo' => l10n.doorbellToneTriangulo,
        'kalimba' => l10n.doorbellToneKalimba,
        'marimba' => l10n.doorbellToneMarimba,
        'vidro' => l10n.doorbellToneVidro,
        'pulsar' => l10n.doorbellTonePulsar,
        'bolhas' => l10n.doorbellToneBolhas,
        'retro' => l10n.doorbellToneRetro,
        'suave' => l10n.doorbellToneSuave,
        'aurora' => l10n.doorbellToneAurora,
        _ => id,
      };

  String get description => custom
      ? l10n.doorbellToneCustomDesc
      : switch (id) {
          'dingdong' => l10n.doorbellToneDingdongDesc,
          'westminster' => l10n.doorbellToneWestminsterDesc,
          'tres_tons' => l10n.doorbellToneTresTonsDesc,
          'carrilhao' => l10n.doorbellToneCarrilhaoDesc,
          'trrrim' => l10n.doorbellToneTrrrimDesc,
          'portaria' => l10n.doorbellTonePortariaDesc,
          'digital' => l10n.doorbellToneDigitalDesc,
          'melodia' => l10n.doorbellToneMelodiaDesc,
          'dois_toques' => l10n.doorbellToneDoisToquesDesc,
          'harpa' => l10n.doorbellToneHarpaDesc,
          'xilofone' => l10n.doorbellToneXilofoneDesc,
          'triangulo' => l10n.doorbellToneTrianguloDesc,
          'kalimba' => l10n.doorbellToneKalimbaDesc,
          'marimba' => l10n.doorbellToneMarimbaDesc,
          'vidro' => l10n.doorbellToneVidroDesc,
          'pulsar' => l10n.doorbellTonePulsarDesc,
          'bolhas' => l10n.doorbellToneBolhasDesc,
          'retro' => l10n.doorbellToneRetroDesc,
          'suave' => l10n.doorbellToneSuaveDesc,
          'aurora' => l10n.doorbellToneAuroraDesc,
          _ => '',
        };

  /// One of the user's own, from assets/ringtones/custom: it loops with no
  /// pause while ringing.
  bool get custom => group == customRingtoneGroup;
}

const customRingtoneGroup = 'custom';
const _classic = 'classic';
const _intercom = 'intercom';
const _modern = 'modern';
const _customFolder = 'assets/ringtones/custom/';

const ringtoneGroups = [customRingtoneGroup, _classic, _intercom, _modern];

/// A group of [ringtoneGroups] as shown in Definições.
String ringtoneGroupLabel(String group) => switch (group) {
  customRingtoneGroup => l10n.doorbellGroupCustom,
  _classic => l10n.doorbellGroupClassic,
  _intercom => l10n.doorbellGroupIntercom,
  _modern => l10n.doorbellGroupModern,
  _ => group,
};

const ringtones = [
  Ringtone('dingdong', _classic),
  Ringtone('westminster', _classic),
  Ringtone('tres_tons', _classic),
  Ringtone('carrilhao', _classic),
  Ringtone('trrrim', _classic),
  Ringtone('portaria', _intercom),
  Ringtone('digital', _intercom),
  Ringtone('melodia', _intercom),
  Ringtone('dois_toques', _intercom),
  Ringtone('harpa', _modern),
  Ringtone('xilofone', _modern),
  Ringtone('triangulo', _modern),
  Ringtone('kalimba', _modern),
  Ringtone('marimba', _modern),
  Ringtone('vidro', _modern),
  Ringtone('pulsar', _modern),
  Ringtone('bolhas', _modern),
  Ringtone('retro', _modern),
  Ringtone('suave', _modern),
  Ringtone('aurora', _modern),
];

/// The tone chosen and its volume (0-100), kept on this screen.
typedef RingerSettings = ({String ringtone, int volume});

/// Rings this screen's speakers when someone presses the doorbell, and
/// plays the tones for Definições' chooser.
///
/// A ring repeats the chosen tone until the call stops ringing (answered,
/// here or on the indoor station, or the visitor gave up) — [stop] — or for
/// [_maxRing] at most.
class DoorbellRinger {
  DoorbellRinger._();

  static final instance = DoorbellRinger._();

  static const _keyTone = 'doorbell_ringtone';
  static const _keyVolume = 'doorbell_volume';
  static const _maxRing = Duration(seconds: 30);
  static const _gap = Duration(milliseconds: 1200);

  final settings = ValueNotifier<RingerSettings>((ringtone: ringtones.first.id, volume: 70));

  /// The tone being previewed from Definições, if any.
  final previewing = ValueNotifier<String?>(null);

  /// The .wav files pasted into assets/ringtones/custom, by file name.
  final customTones = ValueNotifier<List<Ringtone>>(const []);

  List<Ringtone> get all => [...customTones.value, ...ringtones];

  Ringtone _byId(String id) => all.firstWhere((r) => r.id == id, orElse: () => ringtones.first);

  RingtoneSound? _sound;
  int _run = 0;

  Future<void> load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      customTones.value = [
        for (final asset in manifest.listAssets()..sort())
          if (asset.startsWith(_customFolder) && asset.toLowerCase().endsWith('.wav'))
            () {
              final file = asset.substring(_customFolder.length);
              final name = file.substring(0, file.length - 4).replaceAll('_', ' ').trim();
              return Ringtone('custom:$file', customRingtoneGroup, asset: asset, fileName: name);
            }(),
      ];
    } catch (e) {
      debugPrint('[ringtone] could not list the custom tones: $e');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final tone = prefs.getString(_keyTone);
      settings.value = (
        ringtone: all.any((r) => r.id == tone) ? tone! : settings.value.ringtone,
        volume: (prefs.getInt(_keyVolume) ?? settings.value.volume).clamp(0, 100),
      );
    } catch (e) {
      debugPrint('[ringtone] could not read the settings: $e');
    }
  }

  Future<void> choose({String? ringtone, int? volume}) async {
    settings.value = (ringtone: ringtone ?? settings.value.ringtone, volume: volume ?? settings.value.volume);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyTone, settings.value.ringtone);
      await prefs.setInt(_keyVolume, settings.value.volume);
    } catch (e) {
      debugPrint('[ringtone] could not save the settings: $e');
    }
  }

  /// The slider's 0-100 as gain: squared, so the low half of the slider
  /// isn't all "loud" to the ear.
  double _gain(int volume) => (volume / 100) * (volume / 100);

  Future<RingtoneSound?> _play(String id, int volume) {
    _sound?.stop();
    final tone = _byId(id);
    return playRingtone(tone.id, () => rootBundle.load(tone.asset), _gain(volume)).then((s) => _sound = s);
  }

  /// Someone rang: the chosen tone over and over until [stop]. [afterWake]
  /// waits for a monitor that was in standby, whose speakers are silent
  /// until it's back on.
  Future<void> ring({bool afterWake = false}) async {
    final run = ++_run;
    previewing.value = null;
    final until = DateTime.now().add(_maxRing);
    if (afterWake) await Future<void>.delayed(const Duration(milliseconds: 1500));
    while (run == _run && DateTime.now().isBefore(until)) {
      final s = await _play(settings.value.ringtone, settings.value.volume);
      if (s == null) return;
      await s.done;
      if (run != _run) return;
      // Your own tones loop straight on; the built-in ones leave a pause.
      if (!_byId(settings.value.ringtone).custom) await Future<void>.delayed(_gap);
    }
  }

  /// Plays [id] once at the current volume; again while it's playing stops it.
  Future<void> preview(String id) async {
    final run = ++_run;
    if (previewing.value == id) {
      stop();
      return;
    }
    previewing.value = id;
    final s = await _play(id, settings.value.volume);
    if (s == null) {
      if (run == _run) previewing.value = null;
      return;
    }
    await s.done;
    if (run == _run) previewing.value = null;
  }

  void stop() {
    _run++;
    _sound?.stop();
    _sound = null;
    previewing.value = null;
  }
}
