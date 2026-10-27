import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../../services/doorbell_history.dart';
import '../../services/screen_power_controller.dart';
import '../data/house_models.dart';
import '../data/kiosk_entities.dart';
import '../data/dates.dart';
import '../modals/history_modal.dart';
import '../modals/intercom_modal.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import 'kiosk_header.dart';
import 'kiosk_widgets.dart';

/// The status pills beside the "Casa" title: locks, alarm (when there is
/// one) and how many lights are on.
class HouseStatusChips extends ConsumerWidget {
  const HouseStatusChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locks = ref.watch(locksProvider).where((l) => l.available).toList();
    final alarm = ref.watch(alarmProvider);
    final lights = ref.watch(lightsOnProvider);
    final open = locks.where((l) => !l.secured).length;

    Widget pill(String icon, String text, Color bg, Color fg) => Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(26)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KIcon(icon, size: 24, color: fg),
          const SizedBox(width: 10),
          Text(
            text,
            style: KText.s(20, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locks.isNotEmpty)
          open == 0
              ? pill(KIcons.lock, l10n.houseAllLocked, KColors.greenTint, KColors.greenInk)
              : pill(KIcons.lockOpen, l10n.houseAccessesOpen(open), KColors.amberTint, KColors.amberInk),
        if (alarm != null) ...[
          const SizedBox(width: 12),
          switch (alarm.mode) {
            _ when alarm.triggered => pill(KIcons.shield, l10n.houseAlarmTriggered, KColors.red, KColors.onAccent),
            AlarmMode.off => pill(KIcons.shield, l10n.houseAlarmOff, KColors.chip, KColors.ink2),
            AlarmMode.home => pill(KIcons.shield, l10n.houseAlarmHome, KColors.blueTint, KColors.blueInk),
            AlarmMode.away => pill(KIcons.shield, l10n.houseAlarmAway, KColors.redTint, KColors.redInk),
          },
        ],
        const SizedBox(width: 12),
        pill(KIcons.bulb, lights == 0 ? l10n.houseLightsOff : l10n.houseLightsOn(lights), KColors.amberTint, KColors.amberInk),
      ],
    );
  }
}

/// A card's state chip (top-right of its header): a dot and a word in one
/// state's -bg/-fg/-dot colours. The dot blinks only while something is
/// happening now (heating, charging); [icon] replaces the dot (a lock).
class KStateChip extends StatelessWidget {
  const KStateChip({super.key, required this.label, required this.bg, required this.fg, required this.dot, this.blink = false, this.icon, this.showDot = true});

  final String label;
  final Color bg;
  final Color fg;
  final Color dot;
  final bool blink;
  final String? icon;
  final bool showDot;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    height: 34,
    padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(17)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          KIcon(icon!, size: 15, color: fg, stroke: 2.4)
        else if (showDot)
          KBlink(
            enabled: blink,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
        if (icon != null || showDot) const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          style: KText.s(15, weight: FontWeight.w700, color: fg),
        ),
      ],
    ),
  );
}

/// A card footer's text action ("Ver todos ›"): 15/600 on a 48 px touch
/// target taller than the 20 px line it sits on.
class KTextAction extends StatelessWidget {
  const KTextAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KPress(
    onTap: onTap,
    child: Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: KText.s(15, weight: FontWeight.w600)),
          const SizedBox(width: 2),
          KIcon(KIcons.chevronRight, size: 18, color: KColors.ink, stroke: 2.2),
        ],
      ),
    ),
  );
}

/// "Água quente": the hot-water tank's temperature against its target,
/// whether it's heating, and its power draw.
class WaterHeaterCard extends StatelessWidget {
  const WaterHeaterCard({super.key, required this.info});

  final WaterHeaterInfo info;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, dot) = switch (info.state) {
      'heating' => (l10n.houseWaterHeating, KColors.orangeTint, KColors.orangeInk, KColors.orange),
      'off' => (l10n.houseWaterOff, KColors.chipAlt, KColors.ink2, KColors.faint),
      _ => (l10n.houseWaterReady, KColors.greenTint, KColors.greenInk, KColors.green),
    };
    final fraction = info.temp != null && info.target != null && info.target! > 0 ? info.temp! / info.target! : 0.0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.houseHotWater, style: KText.s(24, weight: FontWeight.w600)),
              ),
              KStateChip(label: label, bg: bg, fg: fg, dot: dot, blink: info.state == 'heating'),
            ],
          ),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(18)),
                child: Center(child: KIcon(KIcons.boiler, size: 32, color: KColors.ink2, stroke: 1.7)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        KHistoryTap(
                          target: info.tempId == null
                              ? null
                              : HistoryTarget(entityId: info.tempId!, label: l10n.houseHotWaterTemperature, unit: '°C', kind: HistoryKind.temp),
                          child: Text.rich(
                            TextSpan(
                              text: info.temp == null ? '--' : '${info.temp!.round()}',
                              children: [TextSpan(text: ' ºC', style: KText.d(24))],
                            ),
                            style: KText.d(44, height: 1),
                          ),
                        ),
                        const Spacer(),
                        if (info.target != null) Text(l10n.houseWaterTarget('${info.target!.round()}'), style: KText.s(16, color: KColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    KProgress(
                      value: fraction,
                      height: 12,
                      track: KColors.border,
                      gradient: LinearGradient(colors: [KColors.amber, KColors.orange]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            [l10n.houseHeatPump, if (info.powerKw != null) '${fmtDec(info.powerKw!)} kW'].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KText.s(15, color: KColors.muted),
          ),
        ],
      ),
    );
  }
}

/// The building-door camera tile that opens the intercom.
///
/// Shows a still from the door camera, refreshed every 15 minutes — just
/// enough to see the tile is alive, without keeping a stream open. A failed
/// fetch retries after a minute; until the first still arrives (or with no
/// door station at all) it shows the plain icon and label.
class GateCameraTile extends ConsumerStatefulWidget {
  const GateCameraTile({super.key, required this.height, required this.onTap, this.compact = false});

  final double height;
  final VoidCallback onTap;

  /// The narrow Início tile (352 wide) rather than Casa's camera-grid one.
  final bool compact;

  @override
  ConsumerState<GateCameraTile> createState() => _GateCameraTileState();
}

class _GateCameraTileState extends ConsumerState<GateCameraTile> {
  /// The missed-call pill is white over the camera image in both themes, so
  /// its red is the light theme's `danger` too.
  static const _missedRed = Color(0xFFB42318);
  static const _expandIcon = '<path d="M14 4h6v6M10 20H4v-6M20 4l-7 7M4 20l7-7"/>';

  static const _retryAfter = Duration(minutes: 1);

  /// Retries a failed fetch; a good still is only replaced when the screen
  /// next turns on.
  Timer? _retry;
  Uint8List? _still;

  @override
  void initState() {
    super.initState();
    ScreenPowerController.instance.isOn.addListener(_onScreen);
    _refresh();
  }

  void _onScreen() {
    if (ScreenPowerController.instance.isOn.value) _refresh();
  }

  Future<void> _refresh() async {
    _retry?.cancel();
    final bytes = await ref.read(intercomControllerProvider).snapshot();
    if (!mounted) return;
    if (bytes != null && bytes.isNotEmpty) setState(() => _still = bytes);
    if (bytes == null) _retry = Timer(_retryAfter, _refresh);
  }

  @override
  void dispose() {
    ScreenPowerController.instance.isOn.removeListener(_onScreen);
    _retry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(intercomControllerProvider).history;
    // Início's caption says how long ago the bell last rang; the minute tick
    // keeps "há 2 min" current.
    final now = widget.compact ? watchNow(ref) : null;
    if (history == null) return _tile(0, null, now);
    return ValueListenableBuilder<int>(
      valueListenable: history.unseenMissed,
      builder: (context, missed, _) =>
          ValueListenableBuilder<List<DoorbellCall>>(valueListenable: history.calls, builder: (context, calls, _) => _tile(missed, calls.firstOrNull?.at, now)),
    );
  }

  /// "há 2 min" since the last ring.
  static String _ago(DateTime at, DateTime now) {
    final mins = now.difference(at).inMinutes;
    if (mins < 1) return l10n.houseJustNow;
    if (mins < 60) return l10n.houseMinutesAgo(mins);
    final hours = mins ~/ 60;
    if (hours < 24) return l10n.houseHoursAgo(hours);
    return l10n.houseDaysAgo(hours ~/ 24);
  }

  Widget _tile(int missed, DateTime? lastRing, DateTime? now) {
    final still = _still;
    final compact = widget.compact;
    final missedLabel = l10n.houseMissedCalls(missed);
    // Over the camera image, so fixed in both themes.
    final missedPill = Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KIcon(KIcons.phoneMissed, size: 18, color: _missedRed, stroke: 2.2),
          const SizedBox(width: 8),
          Text(
            missedLabel,
            style: KText.s(17, weight: FontWeight.w700, color: _missedRed),
          ),
        ],
      ),
    );
    return KPress(
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: KColors.camera, borderRadius: BorderRadius.circular(compact ? 20 : 22)),
        child: Stack(
          children: [
            if (still != null)
              Positioned.fill(
                child: LayoutBuilder(
                  // Decode at the tile's size, not the camera's 1080p.
                  builder: (context, c) =>
                      Image.memory(still, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (c.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()),
                ),
              )
            else
              const Center(child: KIcon(KIcons.video, size: 26, color: KColors.cameraText, stroke: 1.8)),
            // Início: the whole tile opens the intercom, so it only carries a
            // round expand mark top-right; missed calls take the "Porta do
            // Prédio" caption's place at the bottom. Casa: one of the camera
            // grid's tiles, ringed in the accent, with an "Intercomunicador"
            // tag (or the missed calls).
            if (compact) ...[
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0x8C17191C), shape: BoxShape.circle),
                  child: const Center(child: KIcon(_expandIcon, size: 22, color: Colors.white, stroke: 2.2)),
                ),
              ),
              if (missed > 0)
                Positioned(left: 12, bottom: 12, child: missedPill)
              else
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    alignment: Alignment.bottomLeft,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x002C3036), Color(0xB317191C)]),
                    ),
                    child: Text.rich(
                      TextSpan(
                        text: l10n.houseBuildingDoor,
                        children: [
                          if (lastRing != null && now != null)
                            TextSpan(
                              text: ' · ${_ago(lastRing, now)}',
                              style: KText.s(17, weight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.75)),
                            ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(17, weight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
            ] else ...[
              CameraCaption(label: l10n.houseBuildingDoor, icon: KIcons.phone),
              const Positioned(left: 10, top: 10, child: LiveBadge()),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
                  decoration: BoxDecoration(color: missed > 0 ? Colors.white : KColors.accent, borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KIcon(missed > 0 ? KIcons.phoneMissed : KIcons.phone, size: 16, color: missed > 0 ? _missedRed : KColors.onAccent, stroke: 2.2),
                      const SizedBox(width: 6),
                      Text(
                        missed > 0 ? l10n.houseMissedShort(missed) : l10n.houseIntercom,
                        style: KText.s(15, weight: FontWeight.w700, color: missed > 0 ? _missedRed : KColors.onAccent),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: KColors.accent, width: 4),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The red "AO VIVO" badge on a camera tile.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: KColors.red, borderRadius: BorderRadius.circular(14)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KBlink(
          period: const Duration(milliseconds: 1200),
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(color: KColors.onAccent, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          l10n.cameraLive,
          style: KText.s(13, weight: FontWeight.w700, color: KColors.onAccent),
        ),
      ],
    ),
  );
}

/// A camera tile's name, bottom-left over a dark fade.
class CameraCaption extends StatelessWidget {
  const CameraCaption({super.key, required this.label, this.icon, this.size = 17});

  final String label;
  final String? icon;
  final double size;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    bottom: 0,
    child: Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      alignment: Alignment.bottomLeft,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x0017191C), Color(0xBF17191C)]),
      ),
      child: Row(
        children: [
          if (icon != null) ...[KIcon(icon!, size: size - 1, color: Colors.white, stroke: 2.2), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(size, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A Home Assistant camera as a still — refreshed every [every], or, with no
/// [every], only each time the screen turns on. HA's `camera_proxy` snapshot, authorised by the token HA puts in the
/// entity's own `entity_picture`.
///
/// HA scales the snapshot down to the tile's width (`width=`) and it's
/// decoded at that size, rather than fetching and decoding a full-res
/// frame each time for a 150 px tile; each superseded frame is evicted, or
/// the image cache would keep every one of them (each has a new URL).
class HaCameraTile extends ConsumerStatefulWidget {
  const HaCameraTile({
    super.key,
    required this.entityId,
    required this.label,
    required this.height,
    this.live = false,
    this.every,
    this.radius = 22,
    this.labelSize = 17,
    this.ring,
    this.fit = BoxFit.cover,
    this.background,
  });

  final String entityId;

  /// The name along the bottom; none for the camera modal's big view.
  final String? label;
  final double height;

  /// Shows the "AO VIVO" badge.
  final bool live;

  /// How often the still refreshes; null refreshes it only when the screen
  /// turns on.
  final Duration? every;
  final double radius;
  final double labelSize;

  /// A selection ring (the camera modal's strip).
  final Color? ring;

  /// How the still fills the tile: a vacuum's map is shown whole.
  final BoxFit fit;

  /// Behind the still; the dark camera surface by default.
  final Color? background;

  @override
  ConsumerState<HaCameraTile> createState() => _HaCameraTileState();
}

class _HaCameraTileState extends ConsumerState<HaCameraTile> {
  Timer? _timer;
  int _tick = 0;
  ImageProvider? _shown;

  @override
  void initState() {
    super.initState();
    final every = widget.every;
    if (every != null) {
      _timer = Timer.periodic(every, (_) {
        if (mounted && ScreenPowerController.instance.isOn.value) setState(() => _tick++);
      });
    } else {
      ScreenPowerController.instance.isOn.addListener(_onScreen);
    }
  }

  void _onScreen() {
    if (mounted && ScreenPowerController.instance.isOn.value) setState(() => _tick++);
  }

  @override
  void dispose() {
    ScreenPowerController.instance.isOn.removeListener(_onScreen);
    _timer?.cancel();
    _shown?.evict();
    super.dispose();
  }

  ImageProvider _image(String url, int width) {
    final next = ResizeImage(NetworkImage(url), width: width);
    if (next != _shown) {
      // The previous frame stays on screen until this one arrives
      // (gaplessPlayback); dropping it from the cache doesn't affect that.
      _shown?.evict();
      _shown = next;
    }
    return next;
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(kioskEntitiesProvider.select((m) => m[widget.entityId]));
    final base = ref.watch(connectionConfigProvider)?.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final picture = e?.attributes['entity_picture'] as String?;
    final url = base == null || picture == null || e!.isUnavailable ? null : '$base$picture';
    return Container(
      height: widget.height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: widget.background ?? KColors.camera, borderRadius: BorderRadius.circular(widget.radius)),
      foregroundDecoration: widget.ring == null
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: widget.ring!, width: 3),
            ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            LayoutBuilder(
              builder: (context, box) {
                final w = (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
                return Image(
                  image: _image('$url&width=$w&_=$_tick', w),
                  fit: widget.fit,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              },
            )
          else
            Center(
              child: Text(l10n.cameraUnavailable, style: KText.s(16, color: KColors.cameraText)),
            ),
          if (widget.label != null) CameraCaption(label: widget.label!, size: widget.labelSize),
          if (widget.live) const Positioned(left: 10, top: 10, child: LiveBadge()),
        ],
      ),
    );
  }
}
