import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../data/casa_data.dart';
import '../data/dates.dart';
import '../data/vacuum_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/house_widgets.dart';
import '../widgets/kiosk_widgets.dart';
import 'history_modal.dart';

/// Opens the robots' modal on [start] (an index into [vacuumsProvider]).
Future<void> showVacuumModal(BuildContext context, {int start = 0}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder<void>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => VacuumModal(start: start),
    transitionsBuilder: (_, _, _, child) => child,
  ),
);

/// A state's colours: background, text, dot.
typedef _Tone = (Color, Color, Color);

_Tone get _ok => (KColors.greenTint, KColors.greenInk, KColors.green);
_Tone get _info => (KColors.blueTint, KColors.blueInk, KColors.grid);
_Tone get _warm => (KColors.orangeTint, KColors.orangeInk, KColors.orange);
_Tone get _danger => (KColors.redTint, KColors.red, KColors.red);
_Tone get _neutral => (KColors.chipAlt, KColors.ink2, KColors.faint2);

/// The map's backdrop (the design's `--map-bg`).
Color get _mapBg => KColors.isDark ? KColors.sub : const Color(0xFFEEF1F4);

const _play = '<path d="M8 5v14l11-7z"/>';
const _pause = '<path d="M7 5h4v14H7zM13 5h4v14h-4z"/>';
const _stop = '<path d="M6 6h12v12H6z"/>';
const _home = '<path d="M3 11l9-7 9 7M5 10v10h14V10"/>';
const _alert = '<path d="M12 3l9.5 17h-19zM12 10v4M12 17.5h.01"/>';
const _bolt = '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>';
const _drop = '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/>';
const _wind = '<path d="M4 8h10a3 3 0 1 0-3-3M4 12h15a3 3 0 1 1-3 3M4 16h7"/>';
const _bin = '<path d="M4 6h16l-2 14H6zM9 10v6M15 10v6"/>';
const _locate = '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><path d="M12 7v3M12 13h.01"/>';

const _modeIcons = {
  'sweeping': '<path d="M4 18h10a4 4 0 0 0 0-8H9M9 10V5M6 5h6M18 18h2"/>',
  'mopping': '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11zM9 15a3 3 0 0 0 3 3"/>',
  'sweeping_and_mopping': '<path d="M4 18h9a4 4 0 0 0 0-8H8M8 10V5M5 5h6M18 9s3 3.5 3 5.5a3 3 0 0 1-6 0C15 12.5 18 9 18 9z"/>',
  'mopping_after_sweeping': '<path d="M3 12h7M7 9l3 3-3 3M17 6s4 4.5 4 7a4 4 0 0 1-8 0c0-2.5 4-7 4-7z"/>',
};

String _num(double v) => v == v.roundToDouble() ? '${v.round()}' : fmtDec(v);
String _hm(int m) {
  final x = ((m % 1440) + 1440) % 1440;
  return '${(x ~/ 60).toString().padLeft(2, '0')}:${(x % 60).toString().padLeft(2, '0')}';
}

String _duration(int minutes) => minutes >= 60 ? '${minutes ~/ 60} h ${minutes % 60} min' : '$minutes min';

/// The modal (the design's "Aspiradores"): one robot in focus, the others
/// peeking at the side — swipe or use the tabs above to change.
class VacuumModal extends ConsumerStatefulWidget {
  const VacuumModal({super.key, this.start = 0});

  final int start;

  @override
  ConsumerState<VacuumModal> createState() => _VacuumModalState();
}

class _VacuumModalState extends ConsumerState<VacuumModal> {
  late int _idx = widget.start;
  double _dx = 0;
  bool _dragging = false;

  void _go(int i, int n) => setState(() {
    _idx = i.clamp(0, n - 1);
    _dx = 0;
    _dragging = false;
  });

  @override
  Widget build(BuildContext context) {
    final robots = ref.watch(vacuumsProvider);
    final anim = ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0);
    if (robots.isEmpty) return const SizedBox.shrink();
    final n = robots.length;
    final idx = _idx.clamp(0, n - 1);
    void close() => Navigator.of(context).maybePop();

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final reversing = anim.status == AnimationStatus.reverse;
        final t = reversing ? Curves.easeIn.transform(anim.value) : kEase.transform(anim.value);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: close,
                child: Opacity(
                  opacity: Curves.ease.transform(anim.value),
                  child: ColoredBox(color: KColors.scrim),
                ),
              ),
            ),
            Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(offset: Offset(0, (reversing ? 40 : 56) * (1 - t)), child: child),
            ),
          ],
        );
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: n > 1 ? (_) => setState(() => _dragging = true) : null,
              onHorizontalDragUpdate: n > 1
                  ? (d) => setState(() {
                      final edge = (idx == 0 && _dx + d.delta.dx > 0) || (idx == n - 1 && _dx + d.delta.dx < 0);
                      _dx += edge ? d.delta.dx * 0.3 : d.delta.dx;
                    })
                  : null,
              onHorizontalDragEnd: n > 1 ? (_) => _go(_dx < -120 ? idx + 1 : (_dx > 120 ? idx - 1 : idx), n) : null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, r) in robots.indexed)
                    AnimatedPositioned(
                      key: ValueKey(r.entityId),
                      duration: _dragging ? Duration.zero : const Duration(milliseconds: 450),
                      curve: kEase,
                      left: 280 + (i - idx) * 920 + _dx,
                      top: 0,
                      width: 880,
                      bottom: 0,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 450),
                        curve: kEase,
                        scale: i == idx ? 1 : 0.94,
                        alignment: i < idx ? Alignment.topRight : Alignment.topLeft,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          opacity: i == idx ? 1 : 0.55,
                          // The whole card scrolls, under the robot tabs.
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(0, n > 1 ? 224 : 132, 0, 160),
                            child: Stack(
                              children: [
                                _VacuumCard(robot: r, onClose: close),
                                if (i != idx)
                                  Positioned.fill(
                                    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _go(i, n)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Above the cards, which scroll beneath it.
          if (n > 1)
            Positioned(
              top: 132,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(36)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, r) in robots.indexed) ...[
                        if (i > 0) const SizedBox(width: 4),
                        KPress(
                          onTap: () => _go(i, n),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            decoration: BoxDecoration(color: i == idx ? KColors.ink : Colors.transparent, borderRadius: BorderRadius.circular(30)),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(color: _dot(r.state), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  r.name,
                                  style: KText.s(20, weight: FontWeight.w600, color: i == idx ? KColors.card : KColors.ink),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Color _dot(VacState s) => switch (s) {
  VacState.docked => KColors.green,
  VacState.cleaning || VacState.returning => KColors.grid,
  VacState.paused => KColors.orange,
  VacState.error => KColors.red,
  VacState.idle => KColors.faint2,
};

enum _Tab { cleaning, base, maintenance, more }

/// One robot's card.
class _VacuumCard extends ConsumerStatefulWidget {
  const _VacuumCard({required this.robot, required this.onClose});

  final VacuumInfo robot;
  final VoidCallback onClose;

  @override
  ConsumerState<_VacuumCard> createState() => _VacuumCardState();
}

class _VacuumCardState extends ConsumerState<_VacuumCard> {
  _Tab _tab = _Tab.cleaning;

  /// The rooms to clean, in the order they were picked.
  final List<int> _sel = [];

  /// The last command sent, while HA hasn't confirmed it.
  String? _sent;
  bool _locating = false;
  String? _asking;

  VacuumActions get _actions => ref.read(vacuumActionsProvider);

  @override
  void initState() {
    super.initState();
    if (widget.robot.drying) _tab = _Tab.base;
  }

  void _run(String label, Future<void> Function() f) {
    setState(() => _sent = label);
    f().catchError(KToast.error);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.robot;
    final pending = _actions.isPending(r.entityId) ? _sent : null;
    return Container(
      decoration: BoxDecoration(
        color: KColors.card,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          if (KColors.isDark) const BoxShadow(color: Color(0x0FFFFFFF), spreadRadius: 1),
          BoxShadow(color: KColors.isDark ? const Color(0x80000000) : const Color(0x1F17191C), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(r),
              const SizedBox(height: 20),
              _banner(r, pending),
              if (r.worn.isNotEmpty) ...[const SizedBox(height: 20), _wornNotice(r)],
              if (r.role('camera.map') case final map?) ...[const SizedBox(height: 20), _map(r, map)],
              const SizedBox(height: 20),
              _stats(r),
              const SizedBox(height: 20),
              _mainActions(r, pending),
              const SizedBox(height: 20),
              _tabs(r),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_tab),
                  child: switch (_tab) {
                    _Tab.cleaning => _cleaningTab(r),
                    _Tab.base => _baseTab(r),
                    _Tab.maintenance => _maintenanceTab(r),
                    _Tab.more => _moreTab(r),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────

  Widget _header(VacuumInfo r) {
    final b = r.battery;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: KText.modalTitle),
                if (r.where.isNotEmpty) ...[const SizedBox(height: 2), Text(r.where, style: KText.s(18, color: KColors.muted))],
              ],
            ),
          ),
          if (b != null) ...[
            KHistoryTap(
              target: r.role('sensor.battery_level') == null
                  ? null
                  : HistoryTarget(entityId: r.role('sensor.battery_level')!, label: l10n.vacuumBatteryHistory(r.name), unit: '%', kind: HistoryKind.battery),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    _BatteryGlyph(pct: b),
                    const SizedBox(width: 10),
                    Text('$b%', style: KText.s(20, weight: FontWeight.w600)),
                    if (r.charging) ...[const SizedBox(width: 6), KIcon(_bolt, size: 18, color: KColors.green, filled: true, stroke: 0)],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          KPress(
            onTap: _locating
                ? null
                : () {
                    setState(() => _locating = true);
                    _actions.locate(r).catchError(KToast.error).whenComplete(() {
                      Future<void>.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _locating = false);
                      });
                    });
                  },
            child: Container(
              height: 56,
              padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
              decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
              child: Row(
                children: [
                  if (_locating) const _Spinner(size: 20) else const KIcon(_locate, size: 24, stroke: 2),
                  const SizedBox(width: 8),
                  Text(l10n.vacuumLocate, style: KText.s(18, weight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          KCircleButton(icon: KIcons.close, size: 56, iconSize: 24, stroke: 2.2, bg: KColors.chip, border: null, onTap: widget.onClose),
        ],
      ),
    );
  }

  // ─── What it's doing ─────────────────────────────────────────────────

  Widget _banner(VacuumInfo r, String? pending) {
    final room = r.room ?? '';
    final session = l10n.vacuumSession(r.area == null ? '—' : _num(r.area!), '${r.mins ?? '—'}');
    final setup = [
      if (r.modes.isNotEmpty) r.modes.where((m) => m.key == r.mode).firstOrNull?.label ?? '',
      if (r.geniusOn) 'CleanGenius',
    ].where((s) => s.isNotEmpty).join(' · ');
    final (_Tone tone, String title, String sub, String icon, int? pct) = switch (r.state) {
      VacState.error => (
        _danger,
        r.errorText ?? l10n.vacuumStateError,
        [vacErrors[r.errorCode]?.$2 ?? '', if (room.isNotEmpty) l10n.vacuumStoppedIn(room)].where((s) => s.isNotEmpty).join(' '),
        _alert,
        null,
      ),
      VacState.cleaning => (
        _info,
        room.isEmpty ? l10n.vacuumStateCleaning : l10n.vacuumCleaningRoom(room),
        [if (setup.isNotEmpty) setup, session].join(' · '),
        _play,
        r.progress,
      ),
      VacState.paused => (_warm, room.isEmpty ? l10n.vacuumStatePaused : l10n.vacuumPausedRoom(room), l10n.vacuumPausedHint, _pause, r.progress),
      VacState.returning => (_info, l10n.vacuumStateReturning, l10n.vacuumCleaningFinished(session), _home, null),
      VacState.idle => (_neutral, l10n.vacuumIdleTitle, room.isEmpty ? l10n.vacuumIdleOffBase : l10n.vacuumIdleInRoom(room), _stop, null),
      VacState.docked when r.wash == 'washing' => (_info, l10n.vacuumDockedWashing, l10n.vacuumDockedWashingHint, _drop, null),
      VacState.docked when r.drying => (
        _info,
        l10n.vacuumDockedDrying,
        r.dryLeft == null ? l10n.vacuumDryingHint : l10n.vacuumDryingLeftHint(_duration(r.dryLeft!)),
        _wind,
        r.dryPct,
      ),
      VacState.docked when r.emptying => (_info, l10n.vacuumDockedEmptying, l10n.vacuumDockedEmptyingHint, _bin, null),
      VacState.docked => (
        _ok,
        r.charging ? l10n.vacuumDockedCharging : l10n.vacuumDockedFull,
        [l10n.vacuumLastCleaning(session), if (room.isNotEmpty) room].join(' · '),
        _bolt,
        null,
      ),
    };
    final (bg, fg, _) = tone;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
      child: DefaultTextStyle(
        style: KText.s(17, color: fg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: KIcon(icon, size: 28, color: fg, stroke: 2)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: KText.s(24, weight: FontWeight.w700, color: fg),
                      ),
                      if (sub.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Opacity(
                          opacity: 0.85,
                          child: Text(sub, style: KText.s(17, color: fg, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pct != null) ...[const SizedBox(width: 16), Text('$pct%', style: KText.d(40, color: fg))],
              ],
            ),
            if (pct != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 10,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: KColors.card.withValues(alpha: 0.6))),
                      FractionallySizedBox(
                        widthFactor: (pct / 100).clamp(0.0, 1.0),
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(5)),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (pending != null) ...[
              const SizedBox(height: 12),
              _DashedTop(
                color: fg,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      _Spinner(size: 18, color: fg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.vacuumPendingConfirm(pending),
                          style: KText.s(17, weight: FontWeight.w600, color: fg),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _wornNotice(VacuumInfo r) {
    final (bg, fg, _) = _warm;
    final text = l10n.vacuumMaintenanceNotice(r.worn.map((p) => '${p.label.toLowerCase()} ${p.pct.round()}%').join(', '));
    return KPress(
      onTap: () => setState(() => _tab = _Tab.maintenance),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            KIcon(_alert, size: 24, color: fg, stroke: 2.2),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: KText.s(18, weight: FontWeight.w600, color: fg),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              l10n.vacuumSeeMaintenance,
              style: KText.s(18, weight: FontWeight.w600, color: fg),
            ),
            KIcon(KIcons.chevronRight, size: 20, color: fg, stroke: 2.2),
          ],
        ),
      ),
    );
  }

  /// The robot's own live map (`camera.*_map`), refreshed while it moves.
  Widget _map(VacuumInfo r, String mapId) {
    final live = r.state == VacState.cleaning || r.state == VacState.returning;
    return Stack(
      children: [
        HaCameraTile(
          key: ValueKey('$mapId-$live'),
          entityId: mapId,
          label: null,
          height: 860,
          radius: 28,
          fit: BoxFit.contain,
          background: _mapBg,
          every: live ? const Duration(seconds: 5) : null,
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: const Color(0xE6FFFFFF), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: live ? KColors.green : const Color(0xFFA3A7AE), shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  live ? l10n.vacuumMapLive : l10n.vacuumMap,
                  style: KText.s(14, weight: FontWeight.w600, color: const Color(0xFF3B4046)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stats(VacuumInfo r) {
    final now = r.state.busy && r.state != VacState.returning;
    HistoryTarget? h(String role, String label, String unit) =>
        r.role(role) == null ? null : HistoryTarget(entityId: r.role(role)!, label: l10n.vacuumStatHistory(label, r.name), unit: unit);
    final stats = <(String, String, String, HistoryTarget?)>[
      (
        r.area == null ? '—' : _num(r.area!),
        'm²',
        now ? l10n.vacuumAreaCleaned : l10n.vacuumLastCleaningLabel,
        h('sensor.cleaned_area', l10n.vacuumAreaCleaned, 'm²'),
      ),
      ('${r.mins ?? '—'}', 'min', now ? l10n.vacuumTime : l10n.vacuumDuration, h('sensor.cleaning_time', l10n.vacuumCleaningTime, 'min')),
      if (now)
        ('${r.progress ?? '—'}', '%', l10n.vacuumDone, h('sensor.cleaning_progress', l10n.vacuumProgress, '%'))
      else
        ('${r.count ?? '—'}', '', l10n.vacuumTotalCleanings, h('sensor.cleaning_count', l10n.vacuumCleanings, '')),
    ];
    return Row(
      children: [
        for (final (i, (value, unit, label, history)) in stats.indexed)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(left: BorderSide(color: KColors.divider, width: 1.5)),
              ),
              child: KHistoryTap(
                target: history,
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: value,
                        children: [
                          if (unit.isNotEmpty)
                            TextSpan(
                              text: ' $unit',
                              style: KText.d(19, color: KColors.muted),
                            ),
                        ],
                      ),
                      style: KText.d(38, height: 1.1),
                    ),
                    const SizedBox(height: 2),
                    Text(label, style: KText.s(16, color: KColors.muted)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Start, pause, stop, home ────────────────────────────────────────

  Widget _mainActions(VacuumInfo r, String? pending) {
    final a = _actions;
    final selN = _sel.length;
    final startLabel = selN == 0 ? l10n.vacuumCleanAll : l10n.vacuumCleanRooms(selN);
    final buttons = <(String, String, bool, bool, Future<void> Function())>[
      ...switch (r.state) {
        VacState.cleaning => [(l10n.vacuumPause, _pause, true, true, () => a.pause(r)), (l10n.vacuumReturnToBase, _home, false, false, () => a.home(r))],
        VacState.paused => [
          (l10n.vacuumResume, _play, true, true, () => a.start(r, const [])),
          (l10n.vacuumStop, _stop, false, true, () => a.stop(r)),
          (l10n.vacuumBase, _home, false, false, () => a.home(r)),
        ],
        VacState.returning => [(l10n.vacuumPause, _pause, true, true, () => a.pause(r)), (l10n.vacuumStop, _stop, false, true, () => a.stop(r))],
        VacState.error => [(l10n.vacuumResume, _play, true, true, () => a.start(r, const [])), (l10n.vacuumReturnToBase, _home, false, false, () => a.home(r))],
        VacState.idle => [(startLabel, _play, true, true, () => a.start(r, List.of(_sel))), (l10n.vacuumReturnToBase, _home, false, false, () => a.home(r))],
        VacState.docked => [(startLabel, _play, true, true, () => a.start(r, List.of(_sel)))],
      },
    ];
    return Row(
      children: [
        for (final (i, (label, icon, primary, filled, run)) in buttons.indexed) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(
            flex: primary ? 14 : 10,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: pending != null && pending != label ? 0.5 : 1,
              child: KPress(
                onTap: pending != null ? null : () => _run(label, run),
                child: Container(
                  height: 88,
                  decoration: BoxDecoration(
                    color: primary ? KColors.accent : KColors.tile,
                    borderRadius: BorderRadius.circular(44),
                    border: primary ? null : Border.all(color: KColors.border, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (pending == label)
                        _Spinner(size: 26, color: primary ? KColors.onAccent : KColors.ink)
                      else
                        KIcon(icon, size: 30, color: primary ? KColors.onAccent : KColors.ink, filled: filled, stroke: filled ? 0 : 2),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          pending == label ? '$label…' : label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(24, weight: FontWeight.w600, color: primary ? KColors.onAccent : KColors.ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _tabs(VacuumInfo r) => _Segments(
    children: [
      for (final (t, label) in [
        (_Tab.cleaning, l10n.vacuumTabCleaning),
        (_Tab.base, l10n.vacuumBase),
        (_Tab.maintenance, l10n.vacuumTabMaintenance),
        (_Tab.more, l10n.vacuumTabMore),
      ])
        _Segment(
          on: _tab == t,
          height: 60,
          onTap: () => setState(() => _tab = t),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: KText.s(19, weight: FontWeight.w600)),
              if (t == _Tab.maintenance && r.worn.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: KColors.orange, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        ),
    ],
  );

  // ─── Limpeza ─────────────────────────────────────────────────────────

  Widget _optionRow(VacuumInfo r, String role, List<VacOption> options, String? current) {
    final id = r.role(role);
    final waiting = _actions.isPending(id);
    return _Segments(
      children: [
        for (final o in options)
          _Segment(
            on: current == o.key,
            onTap: current == o.key ? null : () => _actions.select(id, o.key).catchError(KToast.error),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (waiting && current == o.key) ...[const _Spinner(size: 16), const SizedBox(width: 8)],
                Flexible(
                  child: Text(
                    o.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(19, weight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cleaningTab(VacuumInfo r) {
    final busy = r.state.busy;
    final selN = _sel.length;
    final blocks = <Widget>[
      if (r.rooms.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(selN == 0 ? l10n.vacuumRoomsHeaderNone : l10n.vacuumRoomsHeaderSome(selN, r.rooms.length), style: KText.label)),
                KPress(
                  onTap: busy
                      ? null
                      : () => setState(() {
                          if (_sel.isEmpty) {
                            _sel.addAll(r.rooms.map((x) => x.id));
                          } else {
                            _sel.clear();
                          }
                        }),
                  child: SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(selN == 0 ? l10n.vacuumSelectAll : l10n.vacuumClearSelection, style: KText.s(17, weight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final room in r.rooms)
                  Builder(
                    builder: (context) {
                      final order = _sel.indexOf(room.id) + 1;
                      final on = order > 0;
                      return KPress(
                        onTap: busy ? null : () => setState(() => on ? _sel.remove(room.id) : _sel.add(room.id)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 56,
                          padding: EdgeInsets.fromLTRB(on ? 10 : 20, 0, 20, 0),
                          decoration: BoxDecoration(color: on ? KColors.accent : KColors.sub, borderRadius: BorderRadius.circular(28)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (on) ...[
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(color: KColors.onAccent.withValues(alpha: 0.25), shape: BoxShape.circle),
                                  child: Center(
                                    child: Text(
                                      '$order',
                                      style: KText.s(15, weight: FontWeight.w600, color: KColors.onAccent),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                room.name,
                                style: KText.s(18, weight: FontWeight.w600, color: on ? KColors.onAccent : KColors.ink),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      if (r.geniuses.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('CLEANGENIUS', style: KText.label)),
                Text(l10n.vacuumGeniusSubtitle, style: KText.s(16, color: KColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            _optionRow(r, 'select.cleangenius', r.geniuses, r.genius),
            if (r.geniusOn) ...[const SizedBox(height: 10), Text(l10n.vacuumGeniusHint, style: KText.s(17, color: KColors.muted, height: 1.45))],
          ],
        ),
      if (!r.geniusOn) ...[
        if (r.modes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.vacuumCleaningModeLabel, style: KText.label),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, m) in r.modes.indexed) ...[if (i > 0) const SizedBox(width: 10), Expanded(child: _modeTile(r, m))],
                ],
              ),
            ],
          ),
        if (r.suctions.isNotEmpty && r.mode != 'mopping')
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.vacuumSuctionLabel, style: KText.label),
              const SizedBox(height: 10),
              _optionRow(r, 'select.suction_level', r.suctions, r.suction),
            ],
          ),
        if (r.humidities.isNotEmpty && r.mode != 'sweeping')
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.vacuumMopHumidityLabel, style: KText.label),
              const SizedBox(height: 10),
              _optionRow(r, 'select.mop_pad_humidity', r.humidities, r.humidity),
              if (r.wetness != null) ...[const SizedBox(height: 10), _wetness(r)],
            ],
          ),
        if (r.routes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.vacuumRouteLabel, style: KText.label),
              const SizedBox(height: 10),
              _optionRow(r, 'select.cleaning_route', r.routes, r.route),
            ],
          ),
      ],
    ];
    return _gapped(blocks, 22);
  }

  Widget _modeTile(VacuumInfo r, VacOption m) {
    final on = r.mode == m.key;
    final waiting = on && _actions.isPending(r.role('select.cleaning_mode'));
    final fg = on ? KColors.accentFg : KColors.ink;
    return KPress(
      onTap: on ? null : () => _actions.select(r.role('select.cleaning_mode'), m.key).catchError(KToast.error),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: on ? KColors.accentSoft : KColors.sub,
          borderRadius: BorderRadius.circular(22),
          border: on ? Border.all(color: KColors.accent, width: 2.5) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (waiting) _Spinner(size: 26, color: fg) else KIcon(_modeIcons[m.key] ?? _modeIcons['sweeping']!, size: 28, color: fg, stroke: 1.9),
            const SizedBox(height: 8),
            Text(
              m.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: KText.s(17, weight: FontWeight.w600, color: fg, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wetness(VacuumInfo r) {
    final v = r.wetness!;
    final id = r.role('number.wetness_level');
    final pct = r.wetMax > r.wetMin ? (v - r.wetMin) / (r.wetMax - r.wetMin) : 0.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
      child: Row(
        children: [
          Text(l10n.vacuumFineTune, style: KText.s(17, color: KColors.muted)),
          const SizedBox(width: 16),
          KStepButton(plus: false, size: 52, enabled: v > r.wetMin, onTap: () => _actions.number(id, v - 1).catchError(KToast.error)),
          const SizedBox(width: 16),
          Expanded(
            child: _Track(fraction: pct, color: KColors.grid, height: 12, knob: 32),
          ),
          const SizedBox(width: 16),
          KStepButton(plus: true, size: 52, enabled: v < r.wetMax, onTap: () => _actions.number(id, v + 1).catchError(KToast.error)),
          SizedBox(
            width: 72,
            child: Text.rich(
              TextSpan(
                text: '$v',
                children: [
                  TextSpan(
                    text: '/${r.wetMax}',
                    style: KText.s(16, color: KColors.muted),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
              style: KText.d(28),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Base ────────────────────────────────────────────────────────────

  Widget _baseTab(VacuumInfo r) {
    final docked = r.state == VacState.docked;
    String installed(String raw) => raw == 'installed' ? l10n.vacuumInstalled : (raw == 'not_installed' || raw == 'missing' ? l10n.vacuumMissing : _cap(raw));
    final chips = <(String, String, _Tone, String, bool, String?)>[
      if (r.wash != null)
        (
          l10n.vacuumStation,
          '<path d="M3 21h18M5 21V9l7-5 7 5v12M9 21v-6h6v6"/>',
          r.wash == 'idle' ? _neutral : _info,
          switch (r.wash) {
            'idle' => l10n.vacuumStationIdle,
            'washing' => l10n.vacuumStationWashing,
            'drying' => l10n.vacuumStationDrying,
            _ => _cap(r.wash!),
          },
          r.wash != 'idle',
          r.role('sensor.self_wash_base_status'),
        ),
      if (r.role('sensor.auto_empty_status') != null)
        (
          l10n.vacuumAutoEmpty,
          _bin,
          r.emptying ? _info : _neutral,
          r.emptying ? l10n.vacuumEmptying : l10n.vacuumAutoEmptyIdle,
          r.emptying,
          r.role('sensor.auto_empty_status'),
        ),
      for (final t in r.tanks)
        (
          t.label,
          switch (t.key) {
            'clean_water_tank_status' => _drop,
            'dirty_water_tank_status' => '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11zM7 14h10"/>',
            'dust_bag_status' => '<path d="M6 7h12l-1 13H7zM9 7V5a3 3 0 0 1 6 0v2"/>',
            _ => '<path d="M9 3h6v4l2 3v11H7V10l2-3zM9 14h6"/>',
          },
          t.key == 'clean_water_tank_status' && r.lowWater ? _warm : (t.raw == 'installed' ? _ok : _danger),
          t.key == 'clean_water_tank_status' && r.lowWater ? l10n.vacuumLowWater : installed(t.raw),
          false,
          t.entityId,
        ),
    ];
    final buttons = <(String, String, String?, String?, String?)>[
      (l10n.vacuumActionEmptyBin, '<path d="M4 6h16l-2 14H6zM12 10v6M9 13l3 3 3-3"/>', 'button.start_auto_empty', 'sensor.auto_empty_status', 'emptying'),
      (l10n.vacuumActionWashMop, _drop, 'button.self_clean', 'sensor.self_wash_base_status', 'washing'),
      (l10n.vacuumActionDryMop, _wind, 'button.manual_drying', 'sensor.self_wash_base_status', 'drying'),
      (
        l10n.vacuumActionCleanBase,
        '<path d="M3 11l9-7 9 7M5 10v10h14V10M9 15h6"/>',
        'button.base_station_cleaning',
        'sensor.self_wash_base_status',
        'cleaning',
      ),
    ].where((b) => r.role(b.$3!) != null).toList();

    return _gapped([
      if (r.drying)
        Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: BoxDecoration(color: _info.$1, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.vacuumDryingMop,
                      style: KText.s(20, weight: FontWeight.w700, color: _info.$2),
                    ),
                  ),
                  Text(
                    r.dryLeft == null ? '${r.dryPct ?? 0}%' : l10n.vacuumDryingProgress(r.dryPct ?? 0, _duration(r.dryLeft!)),
                    style: KText.s(17, weight: FontWeight.w600, color: _info.$2),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Track(fraction: (r.dryPct ?? 0) / 100, color: _info.$2, height: 10, background: KColors.card.withValues(alpha: 0.6)),
            ],
          ),
        ),
      if (chips.isNotEmpty) ...[
        Text(l10n.vacuumStationLabel, style: KText.label),
        _grid([
          for (final (label, icon, tone, value, blink, entityId) in chips)
            KHistoryTap(
              target: entityId == null
                  ? null
                  : HistoryTarget(
                      entityId: entityId,
                      label: l10n.vacuumBaseHistory(label),
                      kind: HistoryKind.states,
                      stateLabel: (raw) => raw == 'installed' ? l10n.vacuumInstalled : _cap(raw),
                    ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(14)),
                      child: Center(child: KIcon(icon, size: 24, color: KColors.ink2, stroke: 1.9)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KText.s(18, weight: FontWeight.w600),
                      ),
                    ),
                    KStateChip(label: value, bg: tone.$1, fg: tone.$2, dot: tone.$3, blink: blink),
                  ],
                ),
              ),
            ),
        ], 10),
      ],
      if (buttons.isNotEmpty) ...[
        Text(l10n.vacuumBaseActionsLabel, style: KText.label),
        _grid([
          for (final (label, icon, button, status, shows) in buttons)
            Opacity(
              opacity: docked ? 1 : 0.4,
              child: KPress(
                onTap: !docked || _actions.isPending(r.role(status!))
                    ? null
                    : () => _actions.press(r.role(button!), statusId: r.role(status), shows: shows).catchError(KToast.error),
                child: Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: KColors.tile,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: KColors.border, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      if (_actions.isPending(r.role(status!)) && (r.wash == shows || (shows == 'emptying' && r.emptying)))
                        const _Spinner(size: 26)
                      else
                        KIcon(icon, size: 28, stroke: 1.9),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(label, style: KText.s(19, weight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ], 12),
      ],
    ], 20);
  }

  // ─── Manutenção ──────────────────────────────────────────────────────

  Widget _maintenanceTab(VacuumInfo r) {
    if (r.parts.isEmpty) return Text(l10n.vacuumNoWearInfo, style: KText.s(18, color: KColors.muted));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, p) in r.parts.indexed)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        final tone = p.pct <= 0 ? _danger : (p.pct < 20 ? _warm : null);
                        return Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: tone?.$1 ?? KColors.sub, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: KIcon(p.icon, size: 26, color: tone?.$2 ?? KColors.ink2, stroke: 1.9)),
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KHistoryTap(
                        target: p.entityId == null
                            ? null
                            : HistoryTarget(entityId: p.entityId!, label: l10n.vacuumPartLifeHistory(p.label), unit: '%', kind: HistoryKind.percent),
                        child: _partBar(p),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (p.resetId != null)
                      KPress(
                        onTap: () => setState(() => _asking = _asking == p.key ? null : p.key),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: KColors.tile,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: KColors.border, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              if (_actions.isPending(p.entityId)) ...[const _Spinner(size: 18), const SizedBox(width: 8)],
                              Text(l10n.vacuumReset, style: KText.s(17, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                if (_asking == p.key) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.key == 'sensor_dirty' || p.key == 'wheel_dirty'
                                ? l10n.vacuumResetAskClean(p.label.toLowerCase())
                                : l10n.vacuumResetAskReplace(p.label.toLowerCase()),
                            style: KText.s(17, height: 1.4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        KPress(
                          onTap: () => setState(() => _asking = null),
                          child: SizedBox(
                            height: 52,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Center(
                                child: Text(l10n.commonCancel, style: KText.s(17, weight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
                        KPress(
                          onTap: () {
                            setState(() => _asking = null);
                            _actions.reset(p).catchError(KToast.error);
                          },
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            decoration: BoxDecoration(color: KColors.accent, borderRadius: BorderRadius.circular(26)),
                            child: Center(
                              child: Text(
                                l10n.vacuumResetTo100,
                                style: KText.s(17, weight: FontWeight.w600, color: KColors.onAccent),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _partBar(VacPart p) {
    final zero = p.pct <= 0;
    final tone = zero ? _danger : (p.pct < 20 ? _warm : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(p.label, style: KText.s(20, weight: FontWeight.w600)),
            ),
            Text(
              p.left.isEmpty ? '${p.pct.round()}%' : (zero ? '${p.pct.round()}% · ${p.left}' : l10n.vacuumPartLeft(p.pct.round(), p.left)),
              style: KText.s(17, weight: FontWeight.w600, color: tone?.$2 ?? KColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Track(fraction: p.pct / 100, color: tone?.$3 ?? KColors.green, height: 10, minWidth: zero ? 0 : 6),
      ],
    );
  }

  // ─── Mais ────────────────────────────────────────────────────────────

  Widget _moreTab(VacuumInfo r) {
    final a = _actions;
    Widget switchRow(String title, String sub, bool on, String? id, {bool first = false}) => Container(
      padding: EdgeInsets.fromLTRB(0, first ? 4 : 18, 0, 18),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KText.s(21, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(sub, style: KText.s(16, color: KColors.muted)),
              ],
            ),
          ),
          KPress(
            onTap: () => a.toggle(id, !on).catchError(KToast.error),
            child: KSwitch(on: on),
          ),
        ],
      ),
    );
    Widget time(String label, int minutes, String? id) => Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: KText.s(15, color: KColors.muted)),
                Text(_hm(minutes), style: KText.d(30)),
              ],
            ),
          ),
          KStepButton(plus: false, size: 52, onTap: () => a.time(id, minutes - 30).catchError(KToast.error)),
          const SizedBox(width: 10),
          KStepButton(plus: true, size: 52, onTap: () => a.time(id, minutes + 30).catchError(KToast.error)),
        ],
      ),
    );
    final totals = <(String, String)>[
      if (r.count != null) (l10n.vacuumCleanings, '${r.count}'),
      if (r.totalArea != null) (l10n.vacuumTotalArea, '${_num(r.totalArea!)} m²'),
      if (r.totalMins != null) (l10n.vacuumTotalTime, '${r.totalMins! ~/ 60} h ${r.totalMins! % 60} min'),
      if (r.lastAt != null) (l10n.vacuumLastCleaningLabel, ptWhen(r.lastAt!)),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r.dnd != null) ...[
          switchRow(l10n.vacuumDnd, l10n.vacuumDndHint, r.dnd!, r.role('switch.dnd'), first: true),
          if (r.dnd! && r.dndStart != null && r.dndEnd != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                children: [
                  Expanded(child: time(l10n.vacuumStartsAt, r.dndStart!, r.role('time.dnd_start'))),
                  const SizedBox(width: 12),
                  Expanded(child: time(l10n.vacuumEndsAt, r.dndEnd!, r.role('time.dnd_end'))),
                ],
              ),
            ),
        ],
        if (r.childLock != null) switchRow(l10n.vacuumChildLock, l10n.vacuumChildLockHint, r.childLock!, r.role('switch.child_lock'), first: r.dnd == null),
        if (r.volume != null) _VolumeRow(volume: r.volume!, onSet: (v) => a.number(r.role('number.volume'), v).catchError(KToast.error)),
        if (totals.isNotEmpty)
          Container(
            padding: const EdgeInsets.only(top: 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.vacuumStatsLabel, style: KText.label),
                const SizedBox(height: 12),
                _grid([
                  for (final (label, value) in totals)
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: KText.s(15, color: KColors.muted)),
                          const SizedBox(height: 2),
                          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.d(30)),
                        ],
                      ),
                    ),
                ], 10),
              ],
            ),
          ),
      ],
    );
  }

  // ─── Layout helpers ──────────────────────────────────────────────────

  static Widget _gapped(List<Widget> children, double gap) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
    ],
  );

  /// Two columns.
  static Widget _grid(List<Widget> children, double gap) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i += 2) ...[
        if (i > 0) SizedBox(height: gap),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: gap),
              Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
            ],
          ),
        ),
      ],
    ],
  );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

/// The pill of segments (the design's radio groups on `card`).
class _Segments extends StatelessWidget {
  const _Segments({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(34)),
    child: Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: 4), Expanded(child: children[i])],
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.on, required this.child, this.onTap, this.height = 60});

  final bool on;
  final Widget child;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) => KPress(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: height,
      decoration: BoxDecoration(
        color: on ? KColors.tile : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: on ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
      ),
      child: Center(child: child),
    ),
  );
}

/// A rounded bar with an optional round knob at its end.
class _Track extends StatelessWidget {
  const _Track({required this.fraction, required this.color, required this.height, this.knob, this.background, this.minWidth = 0});

  final double fraction;
  final Color color;
  final double height;
  final double? knob;
  final Color? background;
  final double minWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final f = fraction.clamp(0.0, 1.0);
      final w = (box.maxWidth * f).clamp(minWidth, box.maxWidth);
      return SizedBox(
        height: knob ?? height,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(color: background ?? KColors.border, borderRadius: BorderRadius.circular(height / 2)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: w,
              height: height,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(height / 2)),
            ),
            if (knob != null)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                left: (box.maxWidth * f) - knob! / 2,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: KColors.dark.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

/// The volume, dragged along its track; sent when the finger lifts.
class _VolumeRow extends StatefulWidget {
  const _VolumeRow({required this.volume, required this.onSet});

  final int volume;
  final ValueChanged<int> onSet;

  @override
  State<_VolumeRow> createState() => _VolumeRowState();
}

class _VolumeRowState extends State<_VolumeRow> {
  int? _drag;

  @override
  Widget build(BuildContext context) {
    final v = _drag ?? widget.volume;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.vacuumVoiceVolume, style: KText.s(21, weight: FontWeight.w600)),
              ),
              Text('$v%', style: KText.d(26)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              int at(Offset p) => (p.dx / box.maxWidth * 100).clamp(0, 100).round();
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) => setState(() => _drag = at(d.localPosition)),
                onHorizontalDragUpdate: (d) => setState(() => _drag = at(d.localPosition)),
                onHorizontalDragEnd: (_) {
                  if (_drag != null) widget.onSet(_drag!);
                  setState(() => _drag = null);
                },
                onTapUp: (d) => widget.onSet(at(d.localPosition)),
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: _Track(fraction: v / 100, color: KColors.accent, height: 12, knob: 36),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BatteryGlyph extends StatelessWidget {
  const _BatteryGlyph({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 20,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 20,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: KColors.muted, width: 2.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (pct / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(color: pct > 20 ? KColors.green : KColors.red, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
        ),
        Positioned(
          left: 38,
          top: 6.5,
          child: Container(
            width: 3,
            height: 7,
            decoration: BoxDecoration(
              color: KColors.muted,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.size, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: 3, color: color ?? KColors.ink),
  );
}

/// A dashed hairline above [child] (the pending line in the state banner).
class _DashedTop extends StatelessWidget {
  const _DashedTop({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _DashPainter(color), child: child);
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, 0), Offset((x + 5).clamp(0, size.width), 0), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
