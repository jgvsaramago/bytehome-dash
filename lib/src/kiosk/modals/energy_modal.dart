import 'dart:math' as math;
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/weekly_forecast_provider.dart';
import '../data/casa_data.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';

Future<void> showEnergyModal(BuildContext context) => showKModal(context, (_) => const EnergyModal());

// Series are the energy tokens; the light theme's deeper "-ink" shades
// and warm fills come from the design, the dark ones from the series
// tokens (rule: dark charts use the lighter data colours).
bool get _dark => KColors.isDark;
Color get _sun => KColors.solar;
Color get _sunInk => _dark ? KColors.solar : const Color(0xFF8A560C);
Color get _sunTop => _dark ? KColors.solar.withValues(alpha: .6) : const Color(0xFFE9B35A);
Color get _use => _dark ? KColors.faint : const Color(0xFF9AA0A6);
Color get _export => KColors.grid;
Color get _battery => KColors.battery;
Color get _batteryInk => _dark ? KColors.battery : const Color(0xFF12663E);
Color get _batteryTrack => _dark ? KColors.border : const Color(0xFFDCE8DF);
Color get _tomorrowBg => _dark ? KColors.amberTint : const Color(0xFFFFF4E0);

String _eur(double v) => '${fmtDec(v, decimals: 2)} €';

/// Casa › Energia › "Ver mais": today's totals, hour by hour against the
/// solar forecast, the next days' forecast, battery and grid, what's
/// drawing power now and the last 7 days — HA's Energy dashboard data.
class EnergyModal extends ConsumerWidget {
  const EnergyModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(energyStatsProvider).valueOrNull;
    final now = ref.watch(energyInfoProvider);
    final tariff = ref.watch(tariffNowProvider);
    final days = ref.watch(weeklyForecastProvider).valueOrNull ?? const <WeeklyForecastDay>[];
    final today = DateTime.now();
    final t = stats?.today;

    Widget h3(String text, {Widget? trailing}) => Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(text, style: KText.cardTitle)),
        ?trailing,
      ],
    );
    Widget legend(List<(Widget, String)> items) => Row(
      children: [
        for (final (i, (mark, label)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 18),
          mark,
          const SizedBox(width: 8),
          Text(label, style: KText.s(17, color: KColors.muted)),
        ],
      ],
    );
    Widget box(Color c, {double w = 12, double h = 14}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
    );
    Widget card({required Widget child, EdgeInsets padding = const EdgeInsets.all(22)}) => Container(
      padding: padding,
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
      child: child,
    );
    Widget kv(String k, String v) => Row(
      children: [
        Expanded(
          child: Text(k, style: KText.s(18, color: KColors.muted)),
        ),
        Text(v, style: KText.s(18, weight: FontWeight.w600)),
      ],
    );

    final forecastToday = stats?.forecastFor(today);
    final savings = t == null ? null : stats!.savings(t);
    final kpis = [
      (l10n.energySolarTodayLabel, t == null ? '--' : ptKwh(t.solar), 'kWh', forecastToday == null ? '' : l10n.energyOfForecast(ptKwh(forecastToday)), _sunInk),
      (
        l10n.energyConsumptionLabel,
        t == null ? '--' : ptKwh(t.consumption),
        'kWh',
        stats?.yesterdaySoFar == null ? '' : l10n.energyYesterdayThisTime(ptKwh(stats!.yesterdaySoFar!.consumption)),
        KColors.ink,
      ),
      (l10n.energySelfUseLabel, t?.selfUse == null ? '--' : '${(t!.selfUse! * 100).round()}', '%', l10n.energyCameFromSunOrBattery, _batteryInk),
      (l10n.energySavingsLabel, savings == null ? '--' : fmtDec(savings, decimals: 2), '€', l10n.energySavingsVsGrid, KColors.ink),
    ];

    final batteryUntil = batteryLastsUntil(now, stats);
    final sunAt = solarCoversHomeAt(now, stats);
    final bat = now.batteryKw;
    final batteryRows = [
      if (bat != null)
        (l10n.energyNow, bat > 0.05 ? l10n.energyBatterySupplying(ptKw(bat)) : (bat < -0.05 ? l10n.energyBatteryCharging(ptKw(bat)) : l10n.energyBatteryIdle)),
      if (batteryUntil != null) (l10n.energyBatteryLastsUntil, KDates.hm(batteryUntil)),
      if (bat != null && bat > 0.05 && sunAt != null) (l10n.energyBatteryRechargesAt, l10n.energyBatteryRechargesWithSun(KDates.hm(sunAt))),
      if (stats?.capacity != null) (l10n.energyCapacity, '${ptKwh(stats!.capacity!)} kWh'),
    ];
    final grid = now.gridKw;
    final (gridLabel, gridBg, gridFg) = grid == null || grid.abs() < 0.05
        ? (l10n.energyGridIdle, KColors.chipAlt, KColors.ink2)
        : grid > 0
        ? (l10n.energyGridImporting(ptKw(grid)), KColors.blueTint, KColors.blueInk)
        : (l10n.energyGridSelling(ptKw(grid)), KColors.greenTint, KColors.greenInk);
    final importCost = t == null ? null : (t.cost ?? (stats!.price == null ? null : t.gridIn * stats.price!));
    final gridRows = [
      if (t != null) (l10n.energyImportedToday, '${ptKwh(t.gridIn)} kWh${importCost == null ? '' : ' · ${_eur(importCost)}'}'),
      if (t != null) (l10n.energySoldToday, '${ptKwh(t.gridOut)} kWh'),
      if (tariff != null) (l10n.energyTariffNow, tariff),
      if (stats?.price != null) (l10n.energyPriceNow, '${fmtDec(stats!.price!, decimals: 3)} €/kWh'),
    ];

    final loadColors = [KColors.orange, KColors.blue, _battery, KColors.purple];
    final loads = [
      for (final (i, c) in now.consumers.indexed)
        if (c.kw != null) (c.name, c.kw!, loadColors[i % loadColors.length]),
    ];
    if (now.homeKw != null) {
      final rest = now.homeKw! - loads.fold<double>(0, (a, l) => a + l.$2);
      if (rest > 0.01) loads.add((l10n.energyOther, rest, _use));
    }
    final loadMax = loads.fold<double>(0.01, (a, l) => math.max(a, l.$2));

    final week = stats?.week ?? const [];
    final weekMax = week.fold<double>(1, (a, d) => math.max(a, math.max(d.amounts.solar, math.max(d.amounts.consumption, d.amounts.gridOut))));
    final weekTotal = week.fold(const EnergyAmounts(), (a, d) => a + d.amounts);
    final weekSavings = stats?.savings(weekTotal);

    final forecast = [
      for (var i = 0; i < 6; i++)
        if (stats?.forecastFor(addDays(today, i)) case final kwh?)
          (
            i == 0 ? l10n.commonToday : (i == 1 ? l10n.commonTomorrow : KDates.abbrTitle[addDays(today, i).weekday - 1]),
            kwh,
            i < days.length ? days[i].condition : null,
            i == 1,
          ),
    ];
    final fcMax = forecast.fold<double>(1, (a, f) => math.max(a, f.$2));

    final sections = <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, (label, value, unit, sub, color)) in kpis.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(
              child: card(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: KText.label),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: value,
                        children: [
                          TextSpan(
                            text: ' $unit',
                            style: KText.s(18, weight: FontWeight.w600, color: KColors.muted),
                          ),
                        ],
                      ),
                      style: KText.d(36, color: color, height: 1.05),
                    ),
                    const SizedBox(height: 6),
                    Text(sub, style: KText.s(15, color: KColors.muted, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      if (stats != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            h3(
              l10n.energyTodayByHour,
              trailing: legend([
                (box(_sun, w: 18, h: 4), l10n.energySolar),
                if (stats.forecastSlots.isNotEmpty) (SizedBox(width: 18, height: 4, child: CustomPaint(painter: _DashPainter(_sun))), l10n.energyForecast),
                (box(_use), l10n.energyConsumption),
              ]),
            ),
            const SizedBox(height: 14),
            SizedBox(height: 300, child: _TodayChart(stats: stats)),
          ],
        ),
      if (forecast.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            h3(l10n.energySolarForecastTitle),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (day, kwh, condition, tomorrow)) in forecast.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      decoration: BoxDecoration(color: tomorrow ? _tomorrowBg : KColors.sub, borderRadius: BorderRadius.circular(22)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(day, maxLines: 1, style: KText.s(20, weight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              KIcon(weatherIcon(condition), size: 28, color: _sun, stroke: 1.8),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 90,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: (kwh / fcMax).clamp(0.04, 1.0),
                                widthFactor: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_sunTop, _sun]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text.rich(
                            TextSpan(
                              text: ptKwh(kwh),
                              children: [
                                TextSpan(
                                  text: ' kWh',
                                  style: KText.s(15, weight: FontWeight.w600, color: KColors.muted),
                                ),
                              ],
                            ),
                            style: KText.d(28),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 39,
                            child: Text(weatherLabel(condition), maxLines: 2, style: KText.s(15, color: KColors.muted, height: 1.3)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      if (now.soc != null || grid != null)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (now.soc != null)
                Expanded(
                  child: card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(l10n.energyBattery, style: KText.s(24, weight: FontWeight.w600)),
                            ),
                            Text('${now.soc!.round()}%', style: KText.d(34, color: _batteryInk)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        KProgress(value: now.soc! / 100, height: 16, track: _batteryTrack, fill: _battery),
                        for (final (k, v) in batteryRows) ...[const SizedBox(height: 14), kv(k, v)],
                      ],
                    ),
                  ),
                ),
              if (now.soc != null && grid != null) const SizedBox(width: 12),
              if (grid != null)
                Expanded(
                  child: card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(l10n.energyGrid, style: KText.s(24, weight: FontWeight.w600)),
                            ),
                            Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: gridBg, borderRadius: BorderRadius.circular(18)),
                              child: Text(
                                gridLabel,
                                style: KText.s(16, weight: FontWeight.w700, color: gridFg),
                              ),
                            ),
                          ],
                        ),
                        for (final (k, v) in gridRows) ...[const SizedBox(height: 14), kv(k, v)],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      if (loads.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            h3(
              l10n.energyConsumptionNow,
              trailing: now.homeKw == null ? null : Text(ptKw(now.homeKw!), style: KText.s(20, weight: FontWeight.w600)),
            ),
            const SizedBox(height: 14),
            for (final (i, (name, kw, color)) in loads.indexed) ...[
              if (i > 0) const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.s(20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: KProgress(value: kw / loadMax, height: 14, track: KColors.chip, fill: color),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: Text(
                      ptKw(kw),
                      textAlign: TextAlign.right,
                      style: KText.s(20, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      if (week.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            h3(
              l10n.energyLast7Days,
              trailing: legend([(box(_sun), l10n.energyProduced), (box(_use), l10n.energyConsumed), (box(_export), l10n.energyExported)]),
            ),
            const SizedBox(height: 14),
            Container(
              height: 220,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, d) in week.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Opacity(
                        opacity: i == week.length - 1 ? 0.5 : 1,
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  for (final (j, (v, c)) in [(d.amounts.solar, _sun), (d.amounts.consumption, _use), (d.amounts.gridOut, _export)].indexed) ...[
                                    if (j > 0) const SizedBox(width: 3),
                                    FractionallySizedBox(
                                      heightFactor: (v / weekMax).clamp(0.0, 1.0),
                                      child: Container(
                                        width: 22,
                                        decoration: BoxDecoration(
                                          color: c,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                KDates.abbrTitle[d.day.weekday - 1],
                                style: KText.s(15, weight: FontWeight.w600, color: KColors.muted),
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
            const SizedBox(height: 14),
            Text(
              weekSavings == null
                  ? l10n.energyWeekSummary(ptKwh(weekTotal.solar), ptKwh(weekTotal.consumption), ptKwh(weekTotal.gridOut))
                  : l10n.energyWeekSummarySavings(ptKwh(weekTotal.solar), ptKwh(weekTotal.consumption), ptKwh(weekTotal.gridOut), _eur(weekSavings)),
              style: KText.s(17, color: KColors.muted),
            ),
          ],
        ),
      if (stats == null) Text(l10n.energyNotConfigured, style: KText.s(20, color: KColors.muted)),
    ];

    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KModalHeader(
            title: l10n.energyTitle,
            subtitle: stats == null
                ? l10n.energyModalToday(KDates.longLower(today))
                : l10n.energyModalTodayUpdated(KDates.longLower(today), KDates.hm(stats.updated)),
          ),
          for (final s in sections) ...[const SizedBox(height: 28), s],
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3;
    final y = size.height / 2;
    canvas.drawPoints(PointMode.lines, [
      for (double x = 0; x < size.width; x += 8) ...[Offset(x, y), Offset(math.min(x + 4, size.width), y)],
    ], p);
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// Today's chart: consumption per hour as grey bars, the solar production
/// so far as a filled line, the forecast for the rest of the day dashed,
/// and a "now" marker.
/// Chart axis labels: ink-2 as drawn in the light, ink-3 in the dark.
Color get _axis => _dark ? KColors.faint : KColors.muted;

class _TodayChart extends StatelessWidget {
  const _TodayChart({required this.stats});

  final EnergyStats stats;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nowH = now.hour + now.minute / 60;
    final hours = stats.hours;
    // The current hour is partial: scale its kWh to an hourly rate.
    double rate(int h, double kwh) => h == hours.length - 1 ? kwh / math.max(now.minute / 60, 1 / 12) : kwh;
    final use = [for (final (h, a) in hours.indexed) rate(h, a.consumption)];
    final solar = [for (final (h, a) in hours.indexed) rate(h, a.solar)];
    final peak = stats.forecastPeak;
    final top = [...use, ...solar, ...stats.forecastSlots.map((s) => s.kw), 1.0].reduce(math.max);
    final maxKw = (top * 1.1).ceilToDouble();
    const padL = 56.0, padR = 20.0, padT = 20.0, padB = 40.0;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth - padL - padR, h = box.maxHeight - padT - padB;
        double x(double hour) => padL + hour / 24 * w;
        double y(double kw) => padT + h - kw / maxKw * h;
        return Container(
          decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChartPainter(use: use, solar: solar, forecast: stats.forecastSlots, nowH: nowH, maxKw: maxKw, x: x, y: y, bottom: padT + h),
                ),
              ),
              for (var k = 0; k <= maxKw; k += maxKw > 6 ? 2 : 1)
                Positioned(
                  left: 12,
                  top: y(k.toDouble()) - 9,
                  child: Text('$k kW', style: KText.s(14, color: _axis)),
                ),
              for (final hr in const [0, 6, 12, 18, 24])
                Positioned(
                  left: x(hr.toDouble()) - 22,
                  width: 44,
                  bottom: 10,
                  child: Text(
                    '${KDates.two(hr)}:00',
                    textAlign: TextAlign.center,
                    style: KText.s(14, color: _axis),
                  ),
                ),
              Positioned(
                left: x(nowH) - 32,
                width: 64,
                top: 8,
                child: Center(
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    // Ink on the card's colour: near-black in the light,
                    // near-white in the dark, like the "now" line.
                    decoration: BoxDecoration(color: KColors.ink, borderRadius: BorderRadius.circular(13)),
                    child: Text(
                      l10n.energyNow,
                      style: KText.s(14, weight: FontWeight.w700, color: KColors.card),
                    ),
                  ),
                ),
              ),
              if (peak != null && peak.at.isAfter(now))
                Positioned(
                  left: x(peak.at.hour + peak.at.minute / 60) - 140,
                  width: 280,
                  top: 40,
                  child: Text(
                    l10n.energyForecastPeak(ptKw(peak.kw), KDates.hm(peak.at)),
                    textAlign: TextAlign.center,
                    style: KText.s(15, weight: FontWeight.w600, color: _sunInk),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.use,
    required this.solar,
    required this.forecast,
    required this.nowH,
    required this.maxKw,
    required this.x,
    required this.y,
    required this.bottom,
  });

  final List<double> use;
  final List<double> solar;
  final List<({DateTime at, double kw})> forecast;
  final double nowH;
  final double maxKw;
  final double Function(double) x;
  final double Function(double) y;
  final double bottom;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = KColors.isDark ? KColors.divider : KColors.border
      ..strokeWidth = 1;
    for (var k = 1; k <= maxKw; k += maxKw > 6 ? 2 : 1) {
      canvas.drawLine(Offset(x(0), y(k.toDouble())), Offset(x(24), y(k.toDouble())), grid);
    }
    final bars = Paint()..color = _use.withValues(alpha: 0.75);
    final slot = x(1) - x(0);
    for (final (h, kw) in use.indexed) {
      if (kw <= 0) continue;
      final w = h == use.length - 1 ? slot * 0.42 : slot * 0.6;
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(
          x(h.toDouble()) + slot * 0.2,
          y(kw),
          x(h.toDouble()) + slot * 0.2 + w,
          bottom,
          topLeft: const Radius.circular(3),
          topRight: const Radius.circular(3),
        ),
        bars,
      );
    }

    void curve(List<Offset> pts, {required double fillAlpha, required bool dashed, required double width}) {
      if (pts.length < 2) return;
      final line = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      final area = Path.from(line)
        ..lineTo(pts.last.dx, bottom)
        ..lineTo(pts.first.dx, bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = _sun.withValues(alpha: fillAlpha));
      final stroke = Paint()
        ..color = _sun
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.round;
      if (!dashed) {
        canvas.drawPath(line, stroke);
        return;
      }
      for (final m in line.computeMetrics()) {
        for (double d = 0; d < m.length; d += 12) {
          canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), stroke);
        }
      }
    }

    // Production so far: each hour's average at its middle, from midnight.
    curve(
      [Offset(x(0), y(0)), for (final (h, kw) in solar.indexed) Offset(x(math.min(h + 0.5, nowH)), y(kw))],
      fillAlpha: _dark ? 0.24 : 0.28,
      dashed: false,
      width: 3,
    );
    final ahead = [
      for (final s in forecast)
        if (s.at.hour + s.at.minute / 60 >= nowH - 0.5) Offset(x(s.at.hour + s.at.minute / 60), y(s.kw)),
    ];
    curve(ahead, fillAlpha: 0.10, dashed: true, width: 2.5);

    final nowPaint = Paint()
      ..color = KColors.ink
      ..strokeWidth = 1.5;
    for (double d = 0; d < bottom; d += 7) {
      canvas.drawLine(Offset(x(nowH), d), Offset(x(nowH), math.min(d + 3, bottom)), nowPaint);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
