import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/doorbell_ringer.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/music_widgets.dart';

const _building = '<path d="M4 21V6l8-3 8 3v15M2 21h20M8 9h2M14 9h2M8 13h2M14 13h2M10 21v-4h4v4"/>';

/// Definições › Intercomunicador (design "DefinicoesIntercom"): the tone
/// this screen rings with, each one playable, and how loud.
///
/// The design has a tone per door (apartment and building); this screen
/// only hears the building's intercom ring, so there's a single list.
class SettingsIntercomView extends StatefulWidget {
  const SettingsIntercomView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SettingsIntercomView> createState() => _SettingsIntercomViewState();
}

class _SettingsIntercomViewState extends State<SettingsIntercomView> {
  final _ringer = DoorbellRinger.instance;

  /// While dragging, before it's saved.
  int? _volume;

  @override
  void dispose() {
    // Leaving the page doesn't leave a preview playing.
    if (_ringer.previewing.value != null) _ringer.stop();
    super.dispose();
  }

  /// Plays [id] from the start, even if it's the one already playing.
  void _replay(String id) {
    if (_ringer.previewing.value != null) _ringer.stop();
    _ringer.preview(id);
  }

  void _openAdd() {
    final own = _ringer.customTones.value.length;
    showKModal<void>(
      context,
      (ctx) => KModal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.settingsAddTone, style: KText.modalTitle),
                      const SizedBox(height: 8),
                      Text(l10n.settingsAddToneSub, style: KText.s(20, color: KColors.muted, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                KCircleButton(icon: KIcons.close, size: 64, iconSize: 26, stroke: 2.2, bg: KColors.chip, border: null, onTap: () => Navigator.of(ctx).pop()),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 36, 56, 36),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: KColors.chip, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: KIcon(KIcons.music, size: 44, color: KColors.muted, stroke: 1.7),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.settingsAddToneNotHere, textAlign: TextAlign.center, style: KText.d(34)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.settingsAddToneHow(ringtoneGroupLabel(customRingtoneGroup).toLowerCase()),
                    textAlign: TextAlign.center,
                    style: KText.s(20, color: KColors.muted, height: 1.45),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.settingsOwnTones(own), style: KText.s(20, color: KColors.muted)),
                  ),
                  KButton.primary(
                    label: l10n.commonDone,
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: Listenable.merge([_ringer.settings, _ringer.previewing, _ringer.customTones]),
        builder: (context, _) {
          final s = _ringer.settings.value;
          final playing = _ringer.previewing.value;
          final volume = _volume ?? s.volume;
          final all = _ringer.all;
          final playingName = all.where((r) => r.id == playing).firstOrNull?.name;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(36),
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
                          Text(l10n.settingsIntercom, style: KText.d(46, spacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(l10n.settingsIntercomPageSub, style: KText.s(20, color: KColors.muted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    KButton.primary(
                      label: l10n.settingsAddTone,
                      icon: KIcons.plus,
                      height: 72,
                      padding: const EdgeInsets.fromLTRB(24, 0, 32, 0),
                      onTap: _openAdd,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                _Card(
                  icon: _building,
                  title: l10n.intercomBuildingDoor,
                  sub: l10n.settingsBuildingDoorToneSub,
                  trailing: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(18)),
                    child: Text(
                      l10n.settingsToneCount(all.length),
                      style: KText.s(17, weight: FontWeight.w600, color: KColors.muted),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (g, group) in ringtoneGroups.where((g) => all.any((r) => r.group == g)).indexed) ...[
                        Padding(
                          padding: EdgeInsets.fromLTRB(4, g == 0 ? 4 : 22, 4, 12),
                          child: Text(ringtoneGroupLabel(group).toUpperCase(), style: KText.label),
                        ),
                        for (final (i, pair) in _pairs(all.where((r) => r.group == group).toList()).indexed) ...[
                          if (i > 0) const SizedBox(height: 8),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _toneRow(pair.$1, s.ringtone, playing)),
                                const SizedBox(width: 12),
                                Expanded(child: pair.$2 == null ? const SizedBox.shrink() : _toneRow(pair.$2!, s.ringtone, playing)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _Card(
                  icon: KIcons.volHigh,
                  title: l10n.settingsToneVolume,
                  sub: l10n.settingsToneVolumeSub,
                  trailing: Text.rich(
                    TextSpan(
                      text: '$volume',
                      style: KText.d(46, spacing: -0.5),
                      children: [
                        TextSpan(
                          text: '%',
                          style: KText.d(26, color: KColors.muted),
                        ),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          KIcon(KIcons.volLow, size: 28, color: KColors.muted, stroke: 2),
                          const SizedBox(width: 20),
                          Expanded(
                            child: KSlider(
                              value: volume / 100,
                              height: 56,
                              trackHeight: 12,
                              knob: 40,
                              track: KColors.border,
                              fill: KColors.accent,
                              onChanged: (v) => setState(() => _volume = (v * 100).round()),
                              onEnd: (v) async {
                                setState(() => _volume = null);
                                await _ringer.choose(volume: (v * 100).round());
                                // Letting go plays the tone at its new volume.
                                _replay(playing ?? _ringer.settings.value.ringtone);
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          KIcon(KIcons.volHigh, size: 28, color: KColors.muted, stroke: 2),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (playingName != null) ...[
                              const RepaintBoundary(child: _Wave()),
                              const SizedBox(width: 12),
                              Text(
                                l10n.settingsTonePlaying(playingName, s.volume),
                                style: KText.s(18, weight: FontWeight.w600, color: KColors.accentFg),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _toneRow(Ringtone r, String chosen, String? playing) {
    final on = r.id == chosen;
    final isPlaying = playing == r.id;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
      decoration: BoxDecoration(
        color: on ? KColors.accentSoft : KColors.tile,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: on ? KColors.accent : KColors.accent.withValues(alpha: 0), width: 3, strokeAlign: BorderSide.strokeAlignInside),
      ),
      child: Row(
        children: [
          // Tapping the row only chooses; the round button plays.
          Expanded(
            child: KPress(
              onTap: on ? null : () => _ringer.choose(ringtone: r.id),
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? KColors.accent : KColors.tile,
                        border: Border.all(color: on ? KColors.accent : KColors.ring, width: 3),
                      ),
                      alignment: Alignment.center,
                      child: on ? KIcon(KIcons.check, size: 22, color: KColors.onAccent, stroke: 3) : null,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  r.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: KText.s(22, weight: FontWeight.w600),
                                ),
                              ),
                              if (r.custom) ...[
                                const SizedBox(width: 10),
                                Container(
                                  height: 26,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(color: KColors.chip, borderRadius: BorderRadius.circular(13)),
                                  child: Text(
                                    l10n.settingsToneMine,
                                    style: KText.s(14, weight: FontWeight.w700, color: KColors.muted),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            r.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: KText.s(17, color: KColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          KPress(
            onTap: () => _ringer.preview(r.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPlaying ? KColors.accent : KColors.tile,
                border: Border.all(color: isPlaying ? KColors.accent : KColors.border, width: 1.5),
              ),
              alignment: Alignment.center,
              child: KIcon(isPlaying ? KIcons.stopFilled : KIcons.playFilled, size: 26, color: isPlaying ? KColors.onAccent : KColors.ink, filled: true),
            ),
          ),
        ],
      ),
    );
  }
}

List<(Ringtone, Ringtone?)> _pairs(List<Ringtone> list) => [for (var i = 0; i < list.length; i += 2) (list[i], i + 1 < list.length ? list[i + 1] : null)];

/// A card on the page: round icon tile, title and sub, [trailing] on the
/// right, then [child].
class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.sub, required this.trailing, required this.child});

  final String icon;
  final String title;
  final String sub;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: KColors.tile, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: KIcon(icon, size: 32, color: KColors.accentFg, stroke: 1.9),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KText.d(34)),
                  const SizedBox(height: 2),
                  Text(sub, style: KText.s(17, color: KColors.muted, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 24),
            trailing,
          ],
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

/// Three bars bouncing while a tone plays (the design's `dcWave`).
class _Wave extends StatefulWidget {
  const _Wave();

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = KColors.accentFg;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => SizedBox(
        height: 20,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Container(
                width: 4,
                // 0.25 → 1 → 0.25 over a second, each bar 0.2 s behind.
                height: 20 * (0.25 + 0.75 * Curves.easeInOut.transform(1 - ((_c.value - i * 0.2) % 1 * 2 - 1).abs())),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
