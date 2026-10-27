import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/weekly_forecast_provider.dart';
import '../data/casa_data.dart';
import '../data/house_config.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../data/vacuum_data.dart';
import '../modals/ac_modal.dart';
import '../modals/camera_modal.dart';
import '../modals/climate_modal.dart';
import '../modals/energy_modal.dart';
import '../modals/history_modal.dart';
import '../modals/intercom_modal.dart';
import '../modals/room_modal.dart';
import '../modals/vacuum_modal.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/ac_widgets.dart';
import '../widgets/car_card.dart';
import '../widgets/energy_flow.dart';
import '../widgets/house_widgets.dart';
import '../widgets/kiosk_widgets.dart';

Future<void> _try(Future<void> f) => f.catchError(KToast.error);

// Two warm fills the token set doesn't name: a lit room's bulb chip and
// the "Amanhã" solar card. Dark: the matching dark warm tints.
Color get _litChipBg => KColors.isDark ? KColors.lightBtnBg : const Color(0xFFFFE3A6);
Color get _tomorrowBg => KColors.isDark ? KColors.amberTint : const Color(0xFFFFF4E0);

/// Casa: every room, energy, security, the weather station, climate and
/// the cars at home — surface sections down a page that scrolls from under
/// the header to beneath the translucent nav bar.
class HousePage extends ConsumerWidget {
  const HousePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomTilesProvider).isNotEmpty;
    final energy = !ref.watch(energyInfoProvider.select((e) => e.isEmpty));
    final cars = ref.watch(carsProvider);
    final vacuums = ref.watch(vacuumsProvider.select((v) => v.isNotEmpty));

    // Built all at once (not a lazy ListView) so every block's staggered
    // fade-up starts on arrival, not when it's first scrolled into view.
    var block = 0;
    Widget up(Widget child) => Padding(
      padding: EdgeInsets.only(top: block == 0 ? 0 : 24),
      child: KFadeUp(index: block++, child: child),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 168),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                up(
                  Row(
                    children: [
                      Expanded(child: Text(l10n.houseTitle, style: KText.pageTitle)),
                      const _StatusPills(),
                    ],
                  ),
                ),
                if (rooms) up(const _RoomsSection()),
                if (energy) up(const _EnergySection()),
                up(const _SecuritySection()),
                up(
                  const IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _ExteriorSection()),
                        SizedBox(width: 24),
                        Expanded(child: _AcSection()),
                      ],
                    ),
                  ),
                ),
                if (vacuums) up(const _VacuumSection()),
                if (cars.isNotEmpty)
                  up(
                    Row(
                      children: [
                        for (final (i, c) in cars.indexed) ...[
                          if (i > 0) const SizedBox(width: 24),
                          Expanded(
                            child: KCarCard(car: c, background: KColors.card, radius: 36),
                          ),
                        ],
                        if (cars.length == 1) ...[const SizedBox(width: 24), const Spacer()],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // The content fades out as it scrolls up under the header. A flat
        // gradient of the page colour rather than a mask: same look on the
        // plain background, without a full-page layer on the Pi.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 32,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [KColors.page, KColors.page.withValues(alpha: 0)]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Section (`surface`, radius 36, padding 28).
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
    child: child,
  );
}

Widget _title(String text, {String? sub}) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(text, style: KText.cardTitle),
    if (sub != null && sub.isNotEmpty) ...[const SizedBox(height: 2), Text(sub, style: KText.s(17, color: KColors.muted))],
  ],
);

Widget _more(String label, VoidCallback onTap) => KButton(
  label: label,
  icon: KIcons.chevronRight,
  iconAfter: true,
  iconSize: 22,
  height: 56,
  fontSize: 20,
  gap: 6,
  bg: KColors.chip,
  border: null,
  padding: const EdgeInsets.fromLTRB(22, 0, 16, 0),
  onTap: onTap,
);

Widget _pill(String icon, String text, Color bg, Color fg) => Container(
  height: 52,
  padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
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

/// Beside the title: doors, windows and lights at a glance.
class _StatusPills extends ConsumerWidget {
  const _StatusPills();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locks = ref.watch(locksProvider).where((l) => l.available).toList();
    final open = locks.where((l) => !l.secured).length;
    final windows = ref.watch(openWindowsProvider);
    final lights = ref.watch(lightsOnProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (locks.isNotEmpty) ...[
          open == 0
              ? _pill(KIcons.lock, l10n.houseDoorsClosed, KColors.greenTint, KColors.greenInk)
              : _pill(KIcons.lockOpen, l10n.houseDoorsOpen(open), KColors.amberTint, KColors.amberInk),
          const SizedBox(width: 12),
        ],
        windows == 0
            ? _pill(KIcons.windowOpen, l10n.houseWindowsClosed, KColors.card, KColors.ink2)
            : _pill(KIcons.windowOpen, l10n.houseWindowsOpen(windows), KColors.orangeTint, KColors.orangeInk),
        const SizedBox(width: 12),
        lights == 0
            ? _pill(KIcons.bulb, l10n.houseLightsOff, KColors.card, KColors.ink2)
            : _pill(KIcons.bulb, l10n.houseLightsOn(lights), KColors.amberTint, KColors.amberInk),
      ],
    );
  }
}

// ─── Divisões ──────────────────────────────────────────────────────────

class _RoomsSection extends ConsumerWidget {
  const _RoomsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomTilesProvider);
    final anyOn = rooms.any((r) => r.lightOn) || ref.watch(lightsOnProvider) > 0;
    final legend = [
      (KIcons.bulb, l10n.roomLights),
      (KIcons.window, l10n.roomWindow),
      (KIcons.blinds, l10n.roomBlinds),
      (KIcons.acUnit, l10n.acTitle),
      (KIcons.fan, l10n.roomVentilation),
    ];
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(l10n.roomRooms, style: KText.cardTitle),
              const SizedBox(width: 20),
              Expanded(
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      for (final (i, (icon, label)) in legend.indexed) ...[
                        if (i > 0) const SizedBox(width: 18),
                        KIcon(icon, size: 20, color: KColors.muted),
                        const SizedBox(width: 6),
                        Text(label, style: KText.s(17, color: KColors.muted)),
                      ],
                    ],
                  ),
                ),
              ),
              KButton(
                label: l10n.roomAllLightsOff,
                icon: KIcons.bulb,
                iconSize: 22,
                iconStroke: 2,
                height: 56,
                fontSize: 20,
                fg: anyOn ? KColors.ink : KColors.disabledFg,
                padding: const EdgeInsets.fromLTRB(16, 0, 22, 0),
                onTap: anyOn ? () => _try(allLightsOff(ref)) : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < rooms.length; i += 3) ...[
            if (i > 0) const SizedBox(height: 12),
            Row(
              children: [
                for (var j = i; j < i + 3; j++) ...[
                  if (j > i) const SizedBox(width: 12),
                  Expanded(child: j < rooms.length ? _RoomCard(room: rooms[j]) : const SizedBox.shrink()),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room});

  final RoomTile room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = room;
    final off = KColors.faint2;
    final offBg = KColors.tile;
    final chips = <Widget>[
      if (r.light != null)
        _Chip(
          icon: KIcons.bulb,
          solid: r.lightOn,
          bg: r.lightOn ? _litChipBg : offBg,
          fg: r.lightOn ? KColors.amberInk : off,
          label: r.lightOn ? '${r.lightsOn}' : null,
          onTap: () => _try(toggleLight(ref, r.light!.entityId, !r.lightOn)),
        ),
      if (r.window != null)
        _Chip(
          icon: r.windowOpen ? KIcons.windowOpen : KIcons.window,
          bg: r.windowOpen ? KColors.orangeTint : offBg,
          fg: r.windowOpen ? (KColors.isDark ? KColors.orangeInk : KColors.orange) : off,
          label: r.windowOpen ? l10n.houseDoorOpen : null,
        ),
      if (r.coverPosition case final pos?)
        _Chip(
          icon: pos == 0 ? KIcons.blindsClosed : KIcons.blinds,
          bg: pos > 0 ? KColors.blueTint : offBg,
          fg: pos > 0 ? (KColors.isDark ? KColors.blueInk : KColors.blue) : off,
          label: '$pos%',
        ),
      if (r.ac case final ac?)
        _Chip(
          icon: ac.on ? acModeIcon(ac.mode) : KIcons.acUnit,
          bg: ac.on ? ac.mode.tint : offBg,
          fg: ac.on ? ac.mode.ink : off,
          label: ac.on ? fmtDeg(ac.target) : null,
        ),
      if (r.vent != null)
        _Chip(icon: KIcons.fan, bg: r.ventOn ? KColors.greenTint : offBg, fg: r.ventOn ? KColors.greenInk : off, label: r.ventOn ? l10n.roomVentOn : null),
    ];
    return KPress(
      onTap: () => showRoomModal(context, r.areaId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 140,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(color: r.lightOn ? KColors.lightRoomBg : KColors.sub, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(22, weight: FontWeight.w600),
                  ),
                ),
                if (r.temp != null) ...[const SizedBox(width: 10), Text(fmtDeg(r.temp), style: KText.d(24))],
                if (r.humidity != null) ...[const SizedBox(width: 8), Text('${r.humidity!.round()}%', style: KText.s(15, color: KColors.muted))],
              ],
            ),
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  for (final (i, c) in chips.indexed) ...[if (i > 0) const SizedBox(width: 8), c],
                  if (r.note != null)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: chips.isEmpty ? 0 : 12),
                        child: Text(
                          r.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(16, color: KColors.muted),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A room's state icon: a 44 px circle, a pill with [label].
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.bg, required this.fg, this.label, this.solid = false, this.onTap});

  final String icon;
  final Color bg;
  final Color fg;
  final String? label;
  final bool solid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 44,
      constraints: const BoxConstraints(minWidth: 44),
      padding: EdgeInsets.fromLTRB(label == null ? 0 : 10, 0, label == null ? 0 : 14, 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          KIcon(icon, size: 22, color: fg, solid: solid),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: KText.s(16, weight: FontWeight.w700, color: fg),
            ),
          ],
        ],
      ),
    );
    return onTap == null ? chip : KPress(onTap: onTap, child: chip);
  }
}

// ─── Energia ───────────────────────────────────────────────────────────

class _EnergySection extends ConsumerWidget {
  const _EnergySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(energyInfoProvider);
    final stats = ref.watch(energyStatsProvider).valueOrNull;
    final days = ref.watch(weeklyForecastProvider).valueOrNull;
    final now = DateTime.now();
    final t = stats?.today;
    final forecastToday = stats?.forecastFor(now);
    final forecastTomorrow = stats?.forecastFor(addDays(now, 1));
    final sun = KColors.solar;

    final tiles = t == null
        ? const <_EnergyTile>[]
        : [
            _EnergyTile(
              label: l10n.energySolar,
              value: ptKwh(t.solar),
              unit: 'kWh',
              sub: forecastToday == null ? '' : l10n.energyOfForecast(ptKwh(forecastToday)),
              icon: KIcons.sunSmall,
              color: sun,
              bar: forecastToday == null || forecastToday <= 0 ? null : t.solar / forecastToday,
            ),
            _EnergyTile(
              label: l10n.energyConsumption,
              value: ptKwh(t.consumption),
              unit: 'kWh',
              sub: stats!.yesterdaySoFar == null ? '' : l10n.energyYesterdayThisTime(ptKwh(stats.yesterdaySoFar!.consumption)),
              icon: KIcons.homeFlat,
              color: KColors.ink,
            ),
            _EnergyTile(
              label: l10n.energySelfUse,
              value: t.selfUse == null ? '--' : '${(t.selfUse! * 100).round()}',
              unit: '%',
              sub: l10n.energyFromSunAndBattery,
              icon: KIcons.selfUse,
              color: KColors.battery,
              bar: t.selfUse,
            ),
            _EnergyTile(
              label: l10n.energyGrid,
              value: ptKwh(t.gridIn),
              unit: 'kWh',
              sub: l10n.energyImportedSold(ptKwh(t.gridOut)),
              icon: KIcons.pylon,
              color: KColors.grid,
            ),
          ];

    String? tomorrowSub;
    if (forecastTomorrow != null) {
      final sky = days != null && days.length > 1 ? weatherLabel(days[1].condition) : '';
      final diff = forecastToday == null || forecastToday <= 0 ? null : ((forecastTomorrow / forecastToday - 1) * 100).round();
      final compare = diff == null || diff == 0 ? null : (diff < 0 ? l10n.energyLessThanToday(diff.abs()) : l10n.energyMoreThanToday(diff.abs()));
      tomorrowSub = [if (sky.isNotEmpty) sky, ?compare].join(' · ');
    }

    final flow = KEnergyFlow(info: info, consumers: true, label: l10n.energyNowLabel, labelColor: KColors.muted, radius: 28);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _title(l10n.energyTitle, sub: energySummary(info, stats))),
              const SizedBox(width: 16),
              _more(l10n.houseSeeMore, () => showEnergyModal(context)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 440,
            child: tiles.isEmpty
                ? flow
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 680, child: flow),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                              child: Text(l10n.energyTodayLabel, style: KText.label),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final (i, row) in [tiles.sublist(0, 2), tiles.sublist(2)].indexed) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: row[0]),
                                          const SizedBox(width: 12),
                                          Expanded(child: row[1]),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (forecastTomorrow != null) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
                                child: Text(l10n.energyTomorrowLabel, style: KText.label),
                              ),
                              Container(
                                height: 96,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(color: _tomorrowBg, borderRadius: BorderRadius.circular(22)),
                                child: Row(
                                  children: [
                                    KIcon(
                                      days != null && days.length > 1 ? weatherIcon(days[1].condition) : KIcons.partlySun,
                                      size: 40,
                                      color: sun,
                                      stroke: 1.8,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l10n.energySolarForecast, style: KText.s(20, weight: FontWeight.w600)),
                                          if (tomorrowSub != null && tomorrowSub.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              tomorrowSub,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: KText.s(15, color: KColors.amberInk),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        text: ptKwh(forecastTomorrow),
                                        children: [
                                          TextSpan(
                                            text: ' kWh',
                                            style: KText.s(17, weight: FontWeight.w600, color: KColors.muted),
                                          ),
                                        ],
                                      ),
                                      style: KText.d(32),
                                    ),
                                  ],
                                ),
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
  }
}

/// The design's warm bar track in the light; `track` in the dark.
Color get _barTrack => KColors.isDark ? KColors.border : const Color(0xFFE9E2D3);

class _EnergyTile extends StatelessWidget {
  const _EnergyTile({required this.label, required this.value, required this.unit, required this.sub, required this.icon, required this.color, this.bar});

  final String label;
  final String value;
  final String unit;
  final String sub;
  final String icon;
  final Color color;
  final double? bar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            KIcon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: KText.s(15, weight: FontWeight.w600, color: KColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            children: [
              TextSpan(
                text: ' $unit',
                style: KText.s(17, weight: FontWeight.w600, color: KColors.muted),
              ),
            ],
          ),
          style: KText.d(32, height: 1.1),
        ),
        if (bar != null) ...[const SizedBox(height: 6), KProgress(value: bar!, height: 6, track: _barTrack, fill: color)],
        const SizedBox(height: 4),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: KText.s(15, color: KColors.muted),
        ),
      ],
    ),
  );
}

// ─── Segurança ─────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerWidget {
  const _SecuritySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locks = ref.watch(locksProvider);
    final lastOpened = ref.watch(lockLastOpenedProvider).valueOrNull ?? const <String, DateTime>{};
    final cameras = ref.watch(houseConfigProvider.select((c) => c.cameras)).take(3).toList();
    final open = locks.where((l) => l.available && !l.secured).length;
    // The intercom is optional: without it the first camera spans the row,
    // taller (design "SemIntercomCasa"), and the rest pair up below.
    final hasIntercom = ref.watch(hasIntercomProvider);
    final tiles = cameras.length + (hasIntercom ? 1 : 0);
    final wide = !hasIntercom && cameras.isNotEmpty;
    final camRows = wide ? 1 + (cameras.length / 2).floor() : ((tiles + 1) / 2).ceil();
    final camsH = tiles == 0 ? 0.0 : (wide ? 240.0 + (camRows - 1) * 186 : camRows * 176.0 + (camRows - 1) * 10);
    final locksH = locks.isEmpty ? 0.0 : locks.length * 112.0 + (locks.length - 1) * 10;
    final height = math.max(camsH, locksH);

    Widget camera(int i, double height) {
      if (i >= cameras.length) return const SizedBox.shrink();
      final c = cameras[i];
      return KPress(
        onTap: () => showCameraModal(context, c.entityId),
        child: HaCameraTile(entityId: c.entityId, label: c.name.isEmpty ? c.entityId : c.name, height: height),
      );
    }

    // Tile i of the grid: the intercom first when there is one.
    Widget camTile(int i) {
      if (!hasIntercom) return camera(i, 176);
      if (i == 0) return GateCameraTile(height: 176, onTap: () => showIntercom(context));
      return camera(i - 1, 176);
    }

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(l10n.houseSecurity, style: KText.cardTitle),
              const SizedBox(width: 16),
              Text(locks.isEmpty ? locksSetupHint : (open == 0 ? l10n.houseAllClosed : l10n.houseOpenCount(open)), style: KText.s(17, color: KColors.muted)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (locks.isNotEmpty) ...[
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        for (final (i, l) in locks.indexed) ...[
                          if (i > 0) const SizedBox(height: 10),
                          Expanded(
                            child: KHistoryTap(
                              target: l.history,
                              child: _LockTile(lock: l, lastOpened: lastOpened[l.entityId]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      if (wide) camera(0, 240),
                      for (var row = wide ? 1 : 0; row < camRows; row++) ...[
                        if (row > 0) const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: camTile(wide ? row * 2 - 1 : row * 2)),
                            const SizedBox(width: 10),
                            Expanded(child: camTile(wide ? row * 2 : row * 2 + 1)),
                          ],
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
  }
}

class _LockTile extends StatelessWidget {
  const _LockTile({required this.lock, required this.lastOpened});

  final LockInfo lock;
  final DateTime? lastOpened;

  @override
  Widget build(BuildContext context) {
    final l = lock;
    final closed = l.secured || !l.available;
    // "Portão da garagem" is masculine, "Porta…" feminine; a lock is a door.
    final feminine = l.isLock || l.name.toLowerCase().startsWith('porta');
    final state = !l.available
        ? l10n.commonUnavailable
        : !l.isLock
        ? (l.secured ? (feminine ? l10n.houseDoorClosed : l10n.houseGateClosed) : (feminine ? l10n.houseDoorOpen : l10n.houseGateOpen))
        : l.stateLabel;
    final kind = l.isLock ? 'lock' : (feminine ? 'door' : 'gate');
    final last = !l.available
        ? ''
        : closed
        ? (lastOpened == null ? '' : l10n.houseLockLastOpened(kind, ptWhen(lastOpened!.toLocal())))
        : (lastOpened == null ? l10n.houseLockOpenJustNow(kind) : l10n.houseLockOpenSince(kind, KDates.hm(lastOpened!.toLocal())));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: KColors.sub,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: closed ? Colors.transparent : KColors.lightIconBg, width: 2),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: closed ? KColors.greenTint : KColors.amberTint, borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: KIcon(
                l.kind == LockKind.garage ? KIcons.garageDoor : (l.isLock ? KIcons.lock : KIcons.door),
                size: 26,
                color: closed ? KColors.greenInk : KColors.amberInk,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: KText.s(20, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: closed ? KColors.greenTint : KColors.amberTint, borderRadius: BorderRadius.circular(16)),
                      child: Text(
                        state,
                        style: KText.s(16, weight: FontWeight.w700, color: closed ? KColors.greenInk : KColors.orangeInk),
                      ),
                    ),
                  ],
                ),
                if (last.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    last,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(15, color: KColors.muted, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Exterior ──────────────────────────────────────────────────────────

class _ExteriorSection extends ConsumerWidget {
  const _ExteriorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final x = ref.watch(exteriorProvider);
    final trendColor = switch (x.trendDir) {
      1 => KColors.orange,
      -1 => KColors.blue,
      _ => KColors.muted,
    };
    final range = [
      if (x.feels != null) l10n.houseFeelsLike('${x.feels!.round()}'),
      if (x.max != null && x.min != null) l10n.houseTodayMaxMin('${x.max}', '${x.min}'),
    ].join(' · ');
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(l10n.houseOutdoor, sub: x.period),
          const SizedBox(height: 18),
          Row(
            children: [
              KHistoryTap(
                target: x.history,
                child: Text(x.temp == null ? '--' : fmtDeg(x.temp), style: KText.d(80, weight: FontWeight.w400, height: 0.9, spacing: -2)),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (x.trend != null)
                      Row(
                        children: [
                          KIcon(x.trendDir > 0 ? KIcons.arrowUp : (x.trendDir < 0 ? KIcons.arrowDown : KIcons.minus), size: 18, color: trendColor, stroke: 2.4),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              x.trend!,
                              style: KText.s(18, weight: FontWeight.w600, color: trendColor),
                            ),
                          ),
                        ],
                      ),
                    if (range.isNotEmpty) ...[const SizedBox(height: 6), Text(KDates.cap(range), style: KText.s(18, color: KColors.muted))],
                  ],
                ),
              ),
            ],
          ),
          if (x.tiles.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (var i = 0; i < x.tiles.length; i += 3) ...[
              if (i > 0) const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = i; j < i + 3; j++) ...[
                      if (j > i) const SizedBox(width: 10),
                      Expanded(
                        child: j < x.tiles.length
                            ? KHistoryTap(
                                target: x.tiles[j].history,
                                child: _ExteriorTileView(tile: x.tiles[j]),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ExteriorTileView extends StatelessWidget {
  const _ExteriorTileView({required this.tile});

  final ExteriorTile tile;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Transform.rotate(
              angle: tile.rotation * math.pi / 180,
              child: KIcon(tile.icon, size: 18, color: tile.color),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                tile.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KText.s(15, weight: FontWeight.w600, color: KColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: tile.value,
            children: [
              if (tile.unit.isNotEmpty)
                TextSpan(
                  text: ' ${tile.unit}',
                  style: KText.s(16, weight: FontWeight.w600, color: KColors.muted),
                ),
            ],
          ),
          maxLines: 1,
          style: KText.d(28, height: 1.1),
        ),
        if (tile.sub.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            tile.sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KText.s(15, color: KColors.muted),
          ),
        ],
      ],
    ),
  );
}

// ─── Aspiradores ───────────────────────────────────────────────────────

/// The robots, summarised; a card opens the modal on that robot.
class _VacuumSection extends ConsumerWidget {
  const _VacuumSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final robots = ref.watch(vacuumsProvider);
    final cleaning = robots.where((v) => v.state == VacState.cleaning).length;
    final allDocked = robots.every((v) => v.state == VacState.docked);
    final summary = cleaning > 0
        ? l10n.vacuumCountCleaning(cleaning)
        : (allDocked
              ? (robots.length == 1 ? l10n.vacuumStateDocked : (robots.length == 2 ? l10n.vacuumBothDocked : l10n.vacuumAllDocked))
              : l10n.vacuumNoneCleaning);
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _title(l10n.vacuumTitle, sub: summary),
          const SizedBox(height: 16),
          for (var i = 0; i < robots.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _VacuumTile(robot: robots[i], index: i),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < robots.length ? _VacuumTile(robot: robots[i + 1], index: i + 1) : const SizedBox(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VacuumTile extends StatelessWidget {
  const _VacuumTile({required this.robot, required this.index});

  final VacuumInfo robot;
  final int index;

  @override
  Widget build(BuildContext context) {
    final v = robot;
    final busy = v.state == VacState.cleaning || v.state == VacState.paused || v.state == VacState.error;
    var label = v.state.label;
    var (bg, fg, dot) = switch (v.state) {
      VacState.docked => (KColors.greenTint, KColors.greenInk, KColors.green),
      VacState.cleaning || VacState.returning => (KColors.blueTint, KColors.blueInk, KColors.grid),
      VacState.paused => (KColors.orangeTint, KColors.orangeInk, KColors.orange),
      VacState.error => (KColors.redTint, KColors.red, KColors.red),
      VacState.idle => (KColors.chipAlt, KColors.ink2, KColors.faint2),
    };
    var blink = v.state == VacState.cleaning || v.state == VacState.returning;
    if (v.state == VacState.docked && v.drying) {
      label = l10n.vacuumDryingMop;
      (bg, fg, dot) = (KColors.blueTint, KColors.blueInk, KColors.grid);
      blink = true;
    }
    final big = busy ? v.progress : v.battery;
    final area = v.area == null ? '—' : (v.area! == v.area!.roundToDouble() ? '${v.area!.round()}' : fmtDec(v.area!));
    final session = l10n.vacuumSession(area, '${v.mins ?? '—'}');
    final error = v.errorText ?? l10n.vacuumStateError;
    final foot = v.state == VacState.error
        ? (v.room == null ? error : l10n.vacuumErrorInRoom(error, v.room!))
        : (busy ? l10n.vacuumBusyFoot('${v.battery ?? '—'}', area, '${v.mins ?? '—'}') : [l10n.vacuumLastCleaningShort(session), ?v.room].join(' · '));
    return KPress(
      onTap: () => showVacuumModal(context, start: index),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(24, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  KStateChip(label: label, bg: bg, fg: fg, dot: dot, blink: blink),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(18)),
                  child: Center(child: KIcon(KIcons.vacuum, size: 32, color: KColors.ink2, stroke: 1.7)),
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
                          Text.rich(
                            TextSpan(
                              text: big == null ? '--' : '$big',
                              children: [TextSpan(text: '%', style: KText.d(24))],
                            ),
                            style: KText.d(44, height: 1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              busy ? [l10n.vacuumOfCleaning, ?v.room].join(' · ') : (v.charging ? l10n.vacuumBatteryCharging : l10n.vacuumBatteryWord),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: KText.s(16, color: KColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      KProgress(value: (big ?? 0) / 100, fill: v.state == VacState.error ? KColors.red : (busy ? KColors.grid : KColors.green), height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              foot,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(15, color: KColors.muted, height: 20 / 15),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ar Condicionado ───────────────────────────────────────────────────

/// One row per AC unit, state only; a row opens that unit's controls.
class _AcSection extends ConsumerWidget {
  const _AcSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(acUnitsProvider);
    final on = units.where((u) => u.on).length;
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _title(l10n.acSectionTitle, sub: units.isEmpty ? l10n.acNone : (on == 0 ? l10n.acAllOff : l10n.acOnOfTotal(on, units.length)))),
              const SizedBox(width: 12),
              _more(l10n.houseSeeAll, () => showClimateModal(context)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final (i, u) in units.indexed) ...[if (i > 0) const SizedBox(height: 8), _AcRowButton(unit: u)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcRowButton extends StatelessWidget {
  const _AcRowButton({required this.unit});

  final AcUnit unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    return KPress(
      onTap: () => showAcModal(context, u.entityId),
      child: Container(
        height: 64,
        padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
        decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: u.on ? u.mode.tint : KColors.tile, borderRadius: BorderRadius.circular(16)),
              child: Center(child: KIcon(u.on ? acModeIcon(u.mode) : KIcons.acUnit, size: 24, stroke: 1.9, color: u.on ? u.mode.ink : KColors.faint2)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    u.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(20, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text([l10n.acNowTemp(fmtDeg(u.current)), if (u.on) u.mode.label].join(' · '), maxLines: 1, style: KText.s(15, color: KColors.muted)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            if (u.on)
              Text(fmtDeg(u.target), style: KText.d(30, color: u.mode.ink))
            else
              Text(
                l10n.commonOff,
                style: KText.s(16, weight: FontWeight.w600, color: KColors.faint),
              ),
            const SizedBox(width: 14),
            KIcon(KIcons.chevronRight, size: 20, stroke: 2.2, color: KColors.disabledFg),
          ],
        ),
      ),
    );
  }
}
