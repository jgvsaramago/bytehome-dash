import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../../services/voice_enrolment.dart';
import '../../services/voice_satellite.dart';
import '../data/family_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';

const _mic = '<path d="M9 3h6v11H9zM5 11a7 7 0 0 0 14 0M12 18v3"/>';
const _people = '<path d="M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM2 21v-1a6 6 0 0 1 6-6h2a6 6 0 0 1 6 6v1M17 3.5a4 4 0 0 1 0 7.5M22 21v-1a6 6 0 0 0-4-5.6"/>';
const _warning = '<path d="M12 3l9.5 17h-19zM12 10v4M12 17.5h.01"/>';
const _alert = '<path d="M12 7v6M12 16.5h.01M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z"/>';
const _padlock = '<path d="M6 11h12v10H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3"/>';

/// Definições › Vozes reconhecidas (design: DefinicoesVozes): the people the
/// voice assistant knows by voice, so "o meu calendário" means theirs. Each
/// person (from Pessoas, in the ByteHomeDash panel) can have their voice
/// registered, improved with more samples, or deleted. Registering also sets
/// their "Identificação por voz" in Pessoas, which links the voice to their
/// calendar and list.
class SettingsVoicesView extends ConsumerStatefulWidget {
  const SettingsVoicesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<SettingsVoicesView> createState() => _SettingsVoicesViewState();
}

class _SettingsVoicesViewState extends ConsumerState<SettingsVoicesView> {
  final _enrolment = VoiceEnrolment.instance;
  Map<String, EnrolledVoice>? _voices;
  bool _unavailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_enrolment.available) {
      setState(() => _unavailable = true);
      return;
    }
    try {
      final list = await _enrolment.list();
      if (mounted) setState(() => _voices = {for (final v in list) v.id: v});
    } catch (e) {
      if (mounted) setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
    }
  }

  /// Sets (or clears) the person's "Identificação por voz" in Pessoas, so the
  /// integration links the recognised voice to their calendar and list.
  Future<void> _link(String name, String? speakerId) async {
    final client = ref.read(haWebSocketClientProvider);
    final raw = await client.getSettings('family_members');
    if (raw is! List) return;
    final updated = [
      for (final m in raw.whereType<Map>())
        if ((m['name'] as String? ?? '').trim() == name) {...m.cast<String, dynamic>(), 'speakerId': speakerId ?? ''} else m,
    ];
    await client.setSettings('family_members', updated);
  }

  Future<void> _register(FamilyMember m, {required bool add}) async {
    final done = await showKModal<bool>(context, (_) => _EnrolModal(member: m, add: add, link: _link));
    if (done == true) await _load();
  }

  Future<void> _delete(FamilyMember m) async {
    final ok = await showKModal<bool>(
      context,
      (ctx) => KModal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.voicesDeleteTitle(m.name), style: KText.d(40)),
            const SizedBox(height: 20),
            Text(l10n.voicesDeleteBody, style: KText.s(22, color: KColors.muted, height: 1.45)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                KButton(label: l10n.commonCancel, height: 72, padding: const EdgeInsets.symmetric(horizontal: 40), onTap: () => Navigator.of(ctx).pop(false)),
                const SizedBox(width: 14),
                KButton(
                  label: l10n.commonDelete,
                  icon: KIcons.trash,
                  iconSize: 26,
                  iconStroke: 2.1,
                  height: 72,
                  weight: FontWeight.w700,
                  bg: KColors.redTint,
                  fg: KColors.redInk,
                  border: null,
                  padding: const EdgeInsets.fromLTRB(32, 0, 40, 0),
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await _enrolment.delete(VoiceEnrolment.idFor(m.name));
      await _link(m.name, null);
      KToast.show(l10n.voicesDeleted(m.name));
      await _load();
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(familyMembersProvider);
    return Container(
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 36, 36, 180),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KCircleButton(icon: KIcons.chevronLeft, size: 72, iconSize: 32, stroke: 2.2, bg: KColors.page, border: null, onTap: widget.onBack),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.voicesTitle, style: KText.d(46, spacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(l10n.voicesSubtitle, style: KText.s(20, color: KColors.muted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (_unavailable)
              _alert(l10n.voicesNotInstalledTitle, l10n.voicesNotInstalledBody)
            else if (_error case final error?)
              _alert(l10n.voicesLoadError, error)
            else if (_voices == null)
              _box([
                SizedBox(width: 52, height: 52, child: CircularProgressIndicator(strokeWidth: 5, color: KColors.accent)),
                const SizedBox(height: 22),
                Text(l10n.voicesLoading, style: KText.s(21, color: KColors.muted)),
              ])
            else if (members.isEmpty)
              _box([
                Container(
                  width: 104,
                  height: 104,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: KColors.tile, shape: BoxShape.circle),
                  child: KIcon(_people, size: 48, stroke: 1.8, color: KColors.muted),
                ),
                const SizedBox(height: 20),
                Text(l10n.voicesNoPeopleTitle, style: KText.d(34)),
                const SizedBox(height: 20),
                Text(
                  l10n.voicesNoPeopleBody,
                  textAlign: TextAlign.center,
                  style: KText.s(21, color: KColors.muted, height: 1.5),
                ),
              ])
            else ...[
              for (var i = 0; i < members.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 24),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _person(members[i])),
                      const SizedBox(width: 24),
                      Expanded(child: i + 1 < members.length ? _person(members[i + 1]) : const SizedBox()),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: KIcon(_padlock, size: 22, color: KColors.faint),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(l10n.voicesPrivacyNote, style: KText.s(17, color: KColors.faint, height: 1.5)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// The loading and empty states: a tall card, centred.
  Widget _box(List<Widget> children) => Container(
    constraints: const BoxConstraints(minHeight: 520),
    padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 48),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: children),
  );

  Widget _alert(String title, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
    decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(28)),
    child: Row(
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(22)),
          child: KIcon(_warning, size: 36, stroke: 2.1, color: KColors.orangeInk),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: KText.s(24, weight: FontWeight.w700, color: KColors.orangeInk),
              ),
              const SizedBox(height: 4),
              Text(text, style: KText.s(19, color: KColors.orangeInk.withValues(alpha: 0.9), height: 1.45)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _person(FamilyMember m) {
    final voice = _voices![VoiceEnrolment.idFor(m.name)];
    final has = voice != null && voice.samples > 0;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(member: m, size: 80, fontSize: 36),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: KText.d(34, height: 1.15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (has) ...[KIcon(KIcons.check, size: 22, stroke: 2.6, color: KColors.accentFg), const SizedBox(width: 8)],
                        Expanded(
                          child: Text(
                            has ? l10n.voicesRegistered(voice.samples) : l10n.voicesNotRecognised,
                            style: KText.s(18, weight: has ? FontWeight.w600 : FontWeight.w400, color: has ? KColors.accentFg : KColors.faint, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Spacer(),
          Row(
            children: [
              if (!has)
                KButton.primary(
                  label: l10n.voicesRegister,
                  icon: _mic,
                  height: 72,
                  padding: const EdgeInsets.fromLTRB(26, 0, 32, 0),
                  gap: 12,
                  onTap: () => _register(m, add: false),
                )
              else ...[
                KButton(
                  label: l10n.voicesMoreSamples,
                  icon: KIcons.plus,
                  height: 64,
                  fontSize: 21,
                  padding: const EdgeInsets.fromLTRB(22, 0, 28, 0),
                  onTap: () => _register(m, add: true),
                ),
                const Spacer(),
                KCircleButton(icon: KIcons.trash, size: 64, iconSize: 26, stroke: 2, bg: KColors.tile, fg: KColors.muted, onTap: () => _delete(m)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.member, required this.size, required this.fontSize});

  final FamilyMember member;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: member.color.color, shape: BoxShape.circle),
    child: Text(
      member.initial,
      style: KText.d(fontSize, weight: FontWeight.w600, color: Colors.white),
    ),
  );
}

/// Reading phrases aloud, one take each. Varied on purpose: a voice is
/// recognised better from ordinary requests than from one sentence repeated.
List<String> get _phrases => [l10n.voicesPhrase1, l10n.voicesPhrase2, l10n.voicesPhrase3, l10n.voicesPhrase4, l10n.voicesPhrase5];

const _takeSeconds = 6;
const _minSpeechSeconds = 1.5;

enum _Step { intro, ready, recording, retry, saving, done, failed }

class _EnrolModal extends StatefulWidget {
  const _EnrolModal({required this.member, required this.add, required this.link});

  final FamilyMember member;
  final bool add;
  final Future<void> Function(String name, String? speakerId) link;

  @override
  State<_EnrolModal> createState() => _EnrolModalState();
}

class _EnrolModalState extends State<_EnrolModal> with SingleTickerProviderStateMixin {
  late final int _count = widget.add ? 3 : _phrases.length;
  late final int _first = widget.add ? 2 : 0;
  _Step _step = _Step.intro;
  int _index = 0;
  int _left = _takeSeconds;
  VoiceTake? _take;
  Timer? _timer;
  Directory? _dir;
  final _files = <String>[];
  String _message = '';
  bool? _wasMuted;

  /// The level meter: the last [_bars] levels, newest on the right.
  static const _bars = 28;
  final _levels = ValueNotifier<List<double>>(List.filled(_bars, 0));
  late final _blink = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  String get _phrase => _phrases[(_first + _index) % _phrases.length];

  @override
  void dispose() {
    _timer?.cancel();
    _blink.dispose();
    _take?.stop('${Directory.systemTemp.path}/discard.wav').ignore();
    _cleanUp();
    super.dispose();
  }

  /// The voice assistant mustn't react to the phrases while recording.
  void _muteAssistant() {
    final sat = VoiceSatellite.instance;
    if (!sat.available.value || _wasMuted != null) return;
    _wasMuted = sat.muted.value;
    if (_wasMuted == false) sat.setMuted(true);
  }

  void _cleanUp() {
    if (_wasMuted == false) VoiceSatellite.instance.setMuted(false);
    _wasMuted = null;
    try {
      _dir?.deleteSync(recursive: true);
    } catch (_) {}
    _dir = null;
  }

  Future<void> _record() async {
    _muteAssistant();
    _dir ??= await Directory.systemTemp.createTemp('voz-');
    try {
      _take = await VoiceTake.start();
    } catch (e) {
      setState(() {
        _step = _Step.failed;
        _message = l10n.voicesMicError('$e');
      });
      return;
    }
    final take = _take!;
    _levels.value = List.filled(_bars, 0);
    take.level.addListener(() => _levels.value = [..._levels.value.skip(1), take.level.value]);
    _blink.repeat(reverse: true);
    setState(() {
      _step = _Step.recording;
      _left = _takeSeconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (--_left > 0) {
        setState(() {});
        return;
      }
      t.cancel();
      _finishTake();
    });
  }

  Future<void> _finishTake() async {
    final take = _take!;
    _take = null;
    _blink.stop();
    final path = '${_dir!.path}/take${_files.length + 1}.wav';
    final speech = await take.stop(path);
    if (!mounted) return;
    if (speech < _minSpeechSeconds) {
      File(path).deleteSync();
      setState(() => _step = _Step.retry);
      return;
    }
    _files.add(path);
    if (_files.length < _count) {
      setState(() {
        _index++;
        _step = _Step.ready;
      });
      return;
    }
    await _save();
  }

  Future<void> _save() async {
    setState(() => _step = _Step.saving);
    final id = VoiceEnrolment.idFor(widget.member.name);
    try {
      final r = await VoiceEnrolment.instance.enrol(id, widget.member.name, _files, add: widget.add);
      await widget.link(widget.member.name, id);
      _cleanUp();
      if (!mounted) return;
      setState(() {
        _step = _Step.done;
        _message = r.rejected > 0
            ? l10n.voicesRejectedTakes(r.rejected, r.samples)
            : widget.add
            ? l10n.voicesSamplesAdded(_files.length, _firstName)
            : l10n.voicesSamplesKept(r.samples, _firstName);
      });
    } catch (e) {
      _cleanUp();
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _message = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  void _close(bool done) {
    _cleanUp();
    Navigator.of(context).pop(done);
  }

  String get _firstName => widget.member.name.split(' ').first;

  bool get _busy => _step == _Step.recording || _step == _Step.saving;

  @override
  Widget build(BuildContext context) {
    final m = widget.member;
    final mic = KIcon(_mic, size: 28, stroke: 2.1, color: KColors.onAccent);
    return KModal(
      dismissible: !_busy,
      onDismiss: () => _close(_step == _Step.done),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(member: m, size: 64, fontSize: 28),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.add ? l10n.voicesMoreSamplesOf(_firstName) : l10n.voicesRegisterOf(_firstName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.d(40, spacing: -0.5, height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Text(switch (_step) {
                      _Step.intro => l10n.voicesIntroSummary(_count),
                      _Step.saving => l10n.voicesAlmostDone,
                      _Step.done => l10n.commonDone,
                      _Step.failed => l10n.voicesSomethingWrong,
                      _ => l10n.voicesPhraseOf(_index + 1, _count),
                    }, style: KText.s(20, color: KColors.muted)),
                  ],
                ),
              ),
              if (!_busy) KCircleButton(icon: KIcons.close, size: 64, bg: KColors.page, border: null, onTap: () => _close(_step == _Step.done)),
            ],
          ),
          if (_step case _Step.ready || _Step.recording || _Step.retry || _Step.saving) ...[const SizedBox(height: 28), _progress()],
          const SizedBox(height: 28),
          ...switch (_step) {
            _Step.intro => [
              Row(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: KColors.accentSoft, shape: BoxShape.circle),
                    child: KIcon(_mic, size: 56, stroke: 1.9, color: KColors.accentFg),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.voicesIntroBody(m.name, _count), style: KText.s(26, height: 1.45)),
                        const SizedBox(height: 12),
                        Text(l10n.voicesIntroTakeLength(_takeSeconds), style: KText.s(20, color: KColors.muted, height: 1.45)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  KButton(label: l10n.commonCancel, height: 80, padding: const EdgeInsets.symmetric(horizontal: 36), onTap: () => _close(false)),
                  const SizedBox(width: 14),
                  _primary(
                    l10n.voicesStart,
                    KIcon(KIcons.chevronRight, size: 28, stroke: 2.2, color: KColors.onAccent),
                    () => setState(() => _step = _Step.ready),
                    after: true,
                  ),
                ],
              ),
            ],
            _Step.ready => [
              _phraseCard(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.voicesReadyHint, style: KText.s(20, color: KColors.muted, height: 1.4)),
                  ),
                  const SizedBox(width: 20),
                  _primary(l10n.voicesRecord, mic, _record),
                ],
              ),
            ],
            _Step.retry => [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(22)),
                child: Row(
                  children: [
                    KIcon(_warning, size: 28, stroke: 2.1, color: KColors.orangeInk),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.voicesRetry,
                        style: KText.s(21, weight: FontWeight.w600, color: KColors.orangeInk),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _phraseCard(),
              const SizedBox(height: 28),
              Align(alignment: Alignment.centerRight, child: _primary(l10n.voicesRecordAgain, mic, _record)),
            ],
            _Step.recording => [
              _phraseCard(),
              const SizedBox(height: 28),
              SizedBox(
                height: 80,
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: FadeTransition(
                        opacity: Tween(begin: 1.0, end: 0.25).animate(_blink),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: Color(0xFFD92D20), shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.voicesRecording(_left),
                      style: KText.s(24, weight: FontWeight.w700, color: KColors.red),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: RepaintBoundary(child: _meter())),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(l10n.voicesRecordingEnds(_takeSeconds), style: KText.s(18, color: KColors.faint)),
            ],
            _Step.saving => [
              SizedBox(
                height: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 64, height: 64, child: CircularProgressIndicator(strokeWidth: 6, color: KColors.accent)),
                    const SizedBox(height: 24),
                    Text(l10n.voicesSaving, style: KText.s(24, color: KColors.muted)),
                  ],
                ),
              ),
            ],
            _Step.done || _Step.failed => [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: _step == _Step.done ? KColors.greenTint : KColors.redTint, shape: BoxShape.circle),
                      child: _step == _Step.done
                          ? KIcon(KIcons.check, size: 64, stroke: 2.6, color: KColors.greenInk)
                          : KIcon(_alert, size: 64, stroke: 2.2, color: KColors.red),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _step == _Step.failed
                          ? l10n.voicesRegisterFailed
                          : widget.add
                          ? l10n.voicesDoneBetter(_firstName)
                          : l10n.voicesDoneNew(_firstName),
                      textAlign: TextAlign.center,
                      style: KText.d(36, height: 1.25),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: KText.s(21, color: KColors.muted, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Align(alignment: Alignment.centerRight, child: _primary(l10n.commonDone, null, () => _close(_step == _Step.done))),
            ],
          },
        ],
      ),
    );
  }

  Widget _primary(String label, Widget? icon, VoidCallback onTap, {bool after = false}) => KPress(
    onTap: onTap,
    child: Container(
      height: 80,
      padding: EdgeInsets.fromLTRB(icon == null || after ? 40 : 32, 0, after ? 32 : 40, 0),
      decoration: BoxDecoration(color: KColors.accent, borderRadius: BorderRadius.circular(40)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null && !after) ...[icon, const SizedBox(width: 12)],
          Text(
            label,
            style: KText.s(24, weight: FontWeight.w600, color: KColors.onAccent),
          ),
          if (icon != null && after) ...[const SizedBox(width: 12), icon],
        ],
      ),
    ),
  );

  /// One bar per phrase: done in the accent, the current one red while
  /// recording, orange when it must be read again.
  Widget _progress() => Row(
    children: [
      for (var k = 0; k < _count; k++) ...[
        if (k > 0) const SizedBox(width: 10),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 10,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: k < _index || _step == _Step.saving
                  ? KColors.accent
                  : k > _index
                  ? KColors.border
                  : switch (_step) {
                      _Step.recording => const Color(0xFFD92D20),
                      _Step.retry => KColors.orange,
                      _ => KColors.muted,
                    },
            ),
          ),
        ),
      ],
    ],
  );

  Widget _meter() => ValueListenableBuilder<List<double>>(
    valueListenable: _levels,
    builder: (_, levels, _) => Row(
      children: [
        for (var b = 0; b < levels.length; b++) ...[
          if (b > 0) const SizedBox(width: 5),
          Expanded(
            child: Align(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: (80 * (0.12 + 0.88 * levels[b])).clamp(8.0, 80.0),
                decoration: BoxDecoration(color: levels[b] > 0.66 ? KColors.accent : KColors.accentFg, borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _phraseCard() => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 40),
    decoration: BoxDecoration(
      color: KColors.sub,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: _step == _Step.recording ? const Color(0xFFD92D20) : Colors.transparent, width: 3),
    ),
    child: Text(l10n.voicesPhraseQuoted(_phrase), style: KText.d(42, weight: FontWeight.w400, height: 1.32, spacing: -0.3)),
  );
}
