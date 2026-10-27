import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/temperature_entities_provider.dart';
import '../../providers/weekly_forecast_provider.dart';
import '../data/forecast_data.dart';
import '../data/house_models.dart';
import '../data/kiosk_entities.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_header.dart';
import '../widgets/kiosk_widgets.dart';

Future<void> showForecastModal(BuildContext context) => showKModal(context, (_) => const ForecastModal());

const _iSunrise = '<path d="M12 8V3M9 5.5L12 3l3 2.5M3 17h18M7 17a5 5 0 0 1 10 0M6 21h12"/>';
const _iSunset = '<path d="M12 3v5M9 5.5L12 8l3-2.5M3 17h18M7 17a5 5 0 0 1 10 0M6 21h12"/>';
const _iWarning = '<path d="M12 3l10 18H2zM12 10v5M12 18h.01"/>';
const _iSun = '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>';

/// Official warning / index scale colours (IPMA's yellow, orange …) — data
/// colours with no general token; brighter in the dark like the data tokens.
abstract final class _Scale {
  static Color _t(int light, int dark) => Color(KColors.isDark ? dark : light);
  static Color get green => KColors.green;
  static Color get yellow => _t(0xFFF2B705, 0xFFE8B923);
  static Color get orange => _t(0xFFF57C00, 0xFFF08A2C);
  static Color get red => _t(0xFFD32F2F, 0xFFE5544A);
  static Color get maroon => _t(0xFF7B1E1E, 0xFFB3413B);
  static Color get violet => KColors.purple;

  /// The week's cold → warm temperature bar, and the 48 h chart's line.
  static Color get cold => _t(0xFF5B9BD5, 0xFF4C8FD6);
  static Color get warm => _t(0xFFF2A93B, 0xFFE0A040);
  static Color get line => _t(0xFFE0891F, 0xFFE0A040);
}

enum _Tab { days, hours }

/// The design's "Previsão do tempo" modal, opened from the header's
/// weather: the next days (each day's range on a shared cold → warm scale)
/// or the next 48 hours (a chart to scrub plus an hour-by-hour list), with
/// IPMA's warning, the UV index and the fire risk when this HA has them.
class ForecastModal extends ConsumerStatefulWidget {
  const ForecastModal({super.key});

  @override
  ConsumerState<ForecastModal> createState() => _ForecastModalState();
}

class _ForecastModalState extends ConsumerState<ForecastModal> {
  _Tab _tab = _Tab.days;
  int _sel = 0;
  final _list = ScrollController();

  static const _headH = 44.0;
  static const _rowH = 64.0;

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  /// Brings hour [i] into view when picked on the chart (rows and day
  /// headers have fixed heights, so its offset is known).
  void _reveal(List<ForecastHour> hours, int i) {
    if (!_list.hasClients) return;
    var y = 0.0;
    for (var k = 0; k <= i; k++) {
      if (k == 0 || !_sameDay(hours[k].time, hours[k - 1].time)) y += _headH;
      if (k < i) y += _rowH;
    }
    final p = _list.position;
    // The pinned day header covers the top 44 px.
    if (y < p.pixels + _headH || y > p.pixels + p.viewportDimension - 120) {
      _list.jumpTo((y - 60).clamp(0.0, p.maxScrollExtent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = watchNow(ref);
    final entityId = ref.watch(forecastEntityIdProvider);
    final weather = ref.watch(weatherNowProvider);
    final extras = ref.watch(weatherExtrasProvider);
    final async = entityId == null ? null : ref.watch(forecastDetailProvider(entityId));
    final detail = async?.valueOrNull;
    final windUnit = (ref.watch(kioskEntitiesProvider.select((m) => m[entityId ?? '']))?.attributes['wind_speed_unit'] as String?) ?? 'km/h';

    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (final d in detail?.days ?? const <ForecastDay>[])
        if (!DateTime(d.date.year, d.date.month, d.date.day).isBefore(today)) d,
    ].take(10).toList();
    final hours = [
      for (final h in detail?.hours ?? const <ForecastHour>[])
        if (h.time.isAfter(now.subtract(const Duration(hours: 1)))) h,
    ].take(49).toList();
    final tab = hours.isEmpty ? _Tab.days : _tab;
    final sel = hours.isEmpty ? 0 : _sel.clamp(0, hours.length - 1);
    final hour = tab == _Tab.hours ? hours[sel] : null;

    final updated = detail == null ? null : KDates.hm(detail.fetchedAt);
    final dayCount = days.isEmpty ? 10 : days.length;
    final subtitle = switch ((tab, updated)) {
      (_Tab.days, final t?) => l10n.forecastSubtitleDaysUpdated(dayCount, t),
      (_Tab.days, null) => l10n.forecastSubtitleDays(dayCount),
      (_Tab.hours, final t?) => l10n.forecastSubtitleHoursUpdated(t),
      (_Tab.hours, null) => l10n.forecastSubtitleHours,
    };

    Widget body;
    if (entityId == null) {
      body = _Message(l10n.forecastNoEntity);
    } else if (detail == null) {
      body = _Message(async?.hasError ?? false ? l10n.forecastLoadFailed : l10n.forecastLoading);
    } else if (tab == _Tab.days) {
      body = days.isEmpty ? _Message(l10n.forecastUnavailable) : _DaysList(days: days, now: now, current: weather.temp);
    } else {
      body = _HoursView(
        hours: hours,
        sel: sel,
        now: now,
        controller: _list,
        onPick: (i, {bool reveal = false}) {
          if (i == _sel) return;
          setState(() => _sel = i);
          if (reveal) _reveal(hours, i);
        },
      );
    }

    final alerts = _alerts(extras, hours, hour, now, tab);
    final footnote = switch (tab) {
      _Tab.days when days.isNotEmpty && _sameDay(days.first.date, now) && weather.temp != null => l10n.forecastTodayDotHint,
      _Tab.hours => l10n.forecastHoursHint,
      _ => null,
    };

    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KModalHeader(title: l10n.forecastTitle, subtitle: subtitle),
          if (hours.isNotEmpty) ...[
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: _Tabs(
                tab: tab,
                daysLabel: days.isEmpty ? l10n.forecastTabDays : l10n.forecastTabDaysCount(days.length),
                onPick: (t) => setState(() {
                  _tab = t;
                  _sel = 0;
                }),
              ),
            ),
          ],
          const SizedBox(height: 22),
          _Summary(
            tab: tab,
            weather: weather,
            today: days.isNotEmpty && _sameDay(days.first.date, now) ? days.first : null,
            hour: hour,
            isNow: sel == 0,
            now: now,
            windUnit: windUnit,
          ),
          if (alerts.isNotEmpty) ...[
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, a) in alerts.indexed) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: a)],
              ],
            ),
          ],
          const SizedBox(height: 22),
          // Fixed height: the modal doesn't change size between the tabs.
          SizedBox(
            height: 780,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: kEase,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 16 / 780), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
              child: KeyedSubtree(key: ValueKey(tab), child: body),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 22),
            Text(
              footnote,
              textAlign: TextAlign.center,
              style: KText.s(17, color: KColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _alerts(WeatherExtras x, List<ForecastHour> hours, ForecastHour? hour, DateTime now, _Tab tab) {
    final out = <Widget>[];

    if (x.warning case final w?) {
      final colors = [_Scale.green, _Scale.yellow, _Scale.orange, _Scale.red];
      final active = w.level > 1;
      String sub = l10n.weatherNoWarnings;
      if (active) {
        final when = switch ((w.start, w.end)) {
          (final s?, _) when s.isAfter(now) => l10n.weatherWarningFrom(_when(s, now)),
          (_, final e?) => l10n.weatherWarningUntil(_when(e, now)),
          _ => '',
        };
        sub = [?w.type, if (when.isNotEmpty) when].join(' · ');
        if (sub.isEmpty) sub = l10n.weatherWarningActive;
      }
      out.add(
        _AlertCard(
          label: l10n.weatherWarningLabel,
          icon: _iWarning,
          value: [l10n.weatherWarningGreen, l10n.weatherWarningYellow, l10n.weatherWarningOrange, l10n.weatherWarningRed][w.level - 1],
          dot: colors[w.level - 1],
          segs: colors,
          lit: w.level,
          sub: sub,
          bg: active ? [KColors.amberTint, KColors.orangeTint, KColors.redTint][w.level - 2] : null,
          ring: active ? colors[w.level - 1] : null,
        ),
      );
    }

    // UV: from the hourly forecast when it carries it (then it follows the
    // picked hour), else IPMA's day peak or the station's reading.
    final uvHours = [
      for (final h in hours)
        if (h.uv != null && _sameDay(h.time, now)) h,
    ];
    ({double v, String sub})? uv;
    if (hours.isNotEmpty && hours.first.uv != null) {
      final peak = uvHours.isEmpty ? null : uvHours.reduce((a, b) => b.uv! > a.uv! ? b : a);
      final showPeak = peak != null && peak.uv! >= 1;
      final peakValue = showPeak ? '${peak.uv!.round()}' : '';
      final peakTime = showPeak ? '${KDates.two(peak.time.hour)}:00' : '';
      final h = tab == _Tab.hours ? hour! : hours.first;
      if (h.uv != null) {
        final at = '${KDates.two(h.time.hour)}:00';
        final sub = tab == _Tab.hours && h != hours.first
            ? (showPeak ? l10n.weatherUvAtHourWithMax(at, peakValue, peakTime) : l10n.weatherUvAtHour(at))
            : (showPeak ? l10n.weatherUvNowWithMax(peakValue, peakTime) : l10n.forecastNow);
        uv = (v: h.uv!, sub: sub);
      }
    } else if (x.uv case final r?) {
      uv = (v: r.value, sub: r.dayMax ? l10n.weatherUvTodayMax : l10n.forecastNow);
    }
    if (uv != null) {
      final v = uv.v.round();
      final names = [l10n.weatherUvLow, l10n.weatherLevelModerate, l10n.weatherLevelHigh, l10n.weatherLevelVeryHigh, l10n.weatherUvExtreme];
      final colors = [_Scale.green, _Scale.yellow, _Scale.orange, _Scale.red, _Scale.violet];
      final lvl = v <= 2 ? 0 : (v <= 5 ? 1 : (v <= 7 ? 2 : (v <= 10 ? 3 : 4)));
      out.add(
        _AlertCard(
          label: l10n.weatherUvLabel,
          icon: _iSun,
          value: '$v · ${v == 0 ? l10n.weatherUvNoSun : names[lvl]}',
          dot: v == 0 ? KColors.faint : colors[lvl],
          segs: colors,
          lit: v == 0 ? 0 : lvl + 1,
          sub: uv.sub,
        ),
      );
    }

    if (x.fireRisk case final f?) {
      final colors = [_Scale.green, _Scale.yellow, _Scale.orange, _Scale.red, _Scale.maroon];
      out.add(
        _AlertCard(
          label: l10n.weatherFireRiskLabel,
          icon: KIcons.flame,
          value: [l10n.weatherFireLow, l10n.weatherLevelModerate, l10n.weatherLevelHigh, l10n.weatherLevelVeryHigh, l10n.weatherFireMaximum][f - 1],
          dot: colors[f - 1],
          segs: colors,
          lit: f,
          sub: f >= 3 ? l10n.weatherFireAdvice : l10n.weatherFireTodayIpma,
          bg: f >= 3 ? KColors.orangeTint : null,
          ring: f >= 3 ? colors[f - 1] : null,
        ),
      );
    }
    return out;
  }
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "às 18:00" today, "amanhã às 06:00", else "sáb às 06:00".
String _when(DateTime t, DateTime now) {
  final hm = KDates.hm(t);
  if (_sameDay(t, now)) return l10n.weatherAtTime(hm);
  if (_sameDay(t, now.add(const Duration(days: 1)))) return l10n.weatherTomorrowAtTime(hm);
  return l10n.weatherDayAtTime(KDates.abbrLower[t.weekday - 1], hm);
}

String _dayWord(DateTime d, DateTime now) {
  if (_sameDay(d, now)) return l10n.commonToday;
  if (_sameDay(d, now.add(const Duration(days: 1)))) return l10n.commonTomorrow;
  return KDates.weekdaysShort[d.weekday - 1];
}

String _dayShort(DateTime d) => '${KDates.abbrLower[d.weekday - 1]} ${d.day}';

String _deg(double? v) => v == null ? '--' : '${v.round()}';

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, style: KText.s(20, color: KColors.muted)),
  );
}

// ─── Tabs ──────────────────────────────────────────────────────────────

class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab, required this.daysLabel, required this.onPick});

  final _Tab tab;
  final String daysLabel;
  final ValueChanged<_Tab> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: KColors.chip, borderRadius: BorderRadius.circular(34)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (t, label) in [(_Tab.days, daysLabel), (_Tab.hours, l10n.forecastTabHours)]) ...[
            if (t != _Tab.days) const SizedBox(width: 4),
            KPress(
              onTap: t == tab ? null : () => onPick(t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // In the dark the chip track is the tile colour, so the
                  // picked tab steps up to the next lighter surface.
                  color: t == tab ? (KColors.isDark ? KColors.border : KColors.card) : KColors.chip.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: t == tab && !KColors.isDark ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
                ),
                child: Text(
                  label,
                  style: KText.s(20, weight: FontWeight.w600, color: t == tab ? KColors.ink : KColors.muted),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Summary ───────────────────────────────────────────────────────────

class _Summary extends ConsumerWidget {
  const _Summary({
    required this.tab,
    required this.weather,
    required this.today,
    required this.hour,
    required this.isNow,
    required this.now,
    required this.windUnit,
  });

  final _Tab tab;
  final WeatherNow weather;
  final ForecastDay? today;
  final ForecastHour? hour;
  final bool isNow;
  final DateTime now;
  final String windUnit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String icon, temp, cond, line;
    final facts = <(String, String)>[];
    if (hour case final h?) {
      icon = weatherIcon(h.condition);
      temp = '${_deg(h.temp)}°';
      cond = weatherLabel(h.condition);
      line = isNow ? l10n.forecastNowOn(_dayShort(now)) : '${_dayWord(h.time, now)} · ${KDates.two(h.time.hour)}:00';
      if (h.rainPct != null) facts.add((KIcons.drop, l10n.forecastRain('${h.rainPct}')));
      if (h.wind != null) facts.add((KIcons.wWind, l10n.forecastWind('${h.wind!.round()}', windUnit)));
    } else {
      icon = weatherIcon(weather.condition);
      temp = weather.temp == null ? '--°' : '${weather.temp!.round()}°';
      cond = weatherLabel(weather.condition);
      line = [
        l10n.forecastNow,
        if (today?.high != null) l10n.forecastMax('${_deg(today!.high)}°'),
        if (today?.low != null) l10n.forecastMin('${_deg(today!.low)}°'),
      ].join(' · ');
      final sunId = ref.watch(temperatureEntityConfigProvider.select((c) => c.sunEntityId));
      final sun = ref.watch(kioskEntitiesProvider.select((m) => m[sunId ?? '']));
      String? at(String key) => switch (sun?.attributes[key]) {
        final String s => switch (DateTime.tryParse(s)) {
          final d? => KDates.hm(d.toLocal()),
          _ => null,
        },
        _ => null,
      };
      if (at('next_rising') case final r?) facts.add((_iSunrise, l10n.forecastSunrise(r)));
      if (at('next_setting') case final s?) facts.add((_iSunset, l10n.forecastSunset(s)));
    }

    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Row(
        children: [
          KIcon(icon, size: 64, stroke: 1.4, color: KColors.ink),
          const SizedBox(width: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 128),
            child: Text(temp, style: KText.d(72, weight: FontWeight.w400, height: 0.9, spacing: -2)),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cond,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.s(24, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.s(19, color: KColors.muted),
                ),
              ],
            ),
          ),
          if (facts.isNotEmpty) ...[
            const SizedBox(width: 24),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, (ic, text)) in facts.indexed) ...[
                  if (i > 0) const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KIcon(ic, size: 20, color: KColors.muted),
                      const SizedBox(width: 8),
                      Text(text, style: KText.s(18, color: KColors.muted)),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Warning / index cards ─────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.label,
    required this.icon,
    required this.value,
    required this.dot,
    required this.segs,
    required this.lit,
    required this.sub,
    this.bg,
    this.ring,
  });

  final String label;
  final String icon;
  final String value;
  final Color dot;
  final List<Color> segs;
  final int lit;
  final String sub;
  final Color? bg;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: bg ?? KColors.sub, borderRadius: BorderRadius.circular(22)),
      foregroundDecoration: ring == null
          ? null
          : BoxDecoration(
              border: Border.all(color: ring!, width: 3),
              borderRadius: BorderRadius.circular(22),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KIcon(icon, size: 20, color: KColors.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.label),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: KText.s(26, weight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final (i, c) in segs.indexed) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(color: i < lit ? c : c.withValues(alpha: 0.28), borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: KText.s(16, color: KColors.muted, height: 1.3),
          ),
        ],
      ),
    );
  }
}

// ─── Days ──────────────────────────────────────────────────────────────

class _DaysList extends StatelessWidget {
  const _DaysList({required this.days, required this.now, required this.current});

  final List<ForecastDay> days;
  final DateTime now;
  final double? current;

  @override
  Widget build(BuildContext context) {
    // One scale for the whole list, so the bars compare across days.
    final temps = [
      for (final d in days) ...[?d.low, ?d.high],
    ];
    final lo = temps.isEmpty ? 0.0 : temps.reduce(math.min);
    final hi = temps.isEmpty ? 1.0 : temps.reduce(math.max);
    final span = math.max(1.0, hi - lo);
    return Column(
      children: [
        for (final (i, d) in days.indexed)
          _DayRow(day: d, first: i == 0, now: now, lo: lo, span: span, current: i == 0 && _sameDay(d.date, now) ? current : null),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.first, required this.now, required this.lo, required this.span, this.current});

  final ForecastDay day;
  final bool first;
  final DateTime now;
  final double lo;
  final double span;
  final double? current;

  @override
  Widget build(BuildContext context) {
    final d = day.date;
    final rain = day.rainPct ?? 0;
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 148,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dayWord(d, now), style: KText.s(24, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text('${_dayShort(d)} ${KDates.months[d.month - 1].substring(0, 3)}', style: KText.s(16, color: KColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(width: 56, child: KIcon(weatherIcon(day.condition), size: 44, stroke: 1.6, color: KColors.ink)),
          const SizedBox(width: 18),
          SizedBox(width: 92, child: rain > 0 ? _Rain(pct: rain, size: 18, fontSize: 18) : null),
          const SizedBox(width: 18),
          SizedBox(
            width: 52,
            child: Text(
              '${_deg(day.low)}°',
              textAlign: TextAlign.right,
              style: KText.s(22, weight: FontWeight.w500, color: KColors.muted),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _RangeBar(low: day.low, high: day.high, lo: lo, span: span, current: current),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Text('${_deg(day.high)}°', style: KText.s(22, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _Rain extends StatelessWidget {
  const _Rain({required this.pct, required this.size, required this.fontSize});

  final int pct;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = pct >= 50 ? KColors.blueInk : KColors.muted;
    return Row(
      children: [
        KIcon(KIcons.drop, size: size, color: c, filled: true),
        const SizedBox(width: 6),
        Text(
          '$pct%',
          style: KText.s(fontSize, weight: FontWeight.w700, color: c),
        ),
      ],
    );
  }
}

/// A day's min–max on the week's scale; its gradient is the slice of the
/// week-wide cold → warm one it covers. Today also gets a dot at the
/// current temperature.
class _RangeBar extends StatelessWidget {
  const _RangeBar({required this.low, required this.high, required this.lo, required this.span, this.current});

  final double? low;
  final double? high;
  final double lo;
  final double span;
  final double? current;

  @override
  Widget build(BuildContext context) {
    double f(double v) => ((v - lo) / span).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final a = low == null && high == null ? null : f(low ?? high!);
        final b = low == null && high == null ? null : f(high ?? low!);
        return SizedBox(
          height: 16,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 3,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(5)),
                ),
              ),
              if (a != null && b != null)
                Positioned(
                  left: a * w,
                  width: math.max(10, (b - a) * w),
                  top: 3,
                  height: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      gradient: LinearGradient(colors: [Color.lerp(_Scale.cold, _Scale.warm, a)!, Color.lerp(_Scale.cold, _Scale.warm, b)!]),
                    ),
                  ),
                ),
              if (current != null)
                Positioned(
                  left: f(current!) * w - 8,
                  top: 0,
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: KColors.card,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: KColors.ink, spreadRadius: 3)],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── 48 hours ──────────────────────────────────────────────────────────

typedef _Pick = void Function(int i, {bool reveal});

class _HoursView extends StatelessWidget {
  const _HoursView({required this.hours, required this.sel, required this.now, required this.controller, required this.onPick});

  final List<ForecastHour> hours;
  final int sel;
  final DateTime now;
  final ScrollController controller;
  final _Pick onPick;

  @override
  Widget build(BuildContext context) {
    // Day groups for the list's sticky headers.
    final groups = <List<int>>[];
    for (var i = 0; i < hours.length; i++) {
      if (i == 0 || !_sameDay(hours[i].time, hours[i - 1].time)) groups.add([]);
      groups.last.add(i);
    }
    return Column(
      children: [
        _Chart(hours: hours, sel: sel, now: now, onPick: (i) => onPick(i, reveal: true)),
        const SizedBox(height: 14),
        Expanded(
          child: Stack(
            children: [
              CustomScrollView(
                controller: controller,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  for (final g in groups)
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(pinned: true, delegate: _DayHead(_headLabel(hours[g.first].time))),
                        SliverFixedExtentList(
                          itemExtent: 64,
                          delegate: SliverChildBuilderDelegate(
                            (context, k) => _HourRow(hour: hours[g[k]], first: g[k] == 0, on: g[k] == sel, onTap: () => onPick(g[k])),
                            childCount: g.length,
                          ),
                        ),
                      ],
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 36)),
                ],
              ),
              // The list fades out into the modal at the bottom.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 36,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [KColors.card.withValues(alpha: 0), KColors.card],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _headLabel(DateTime d) {
    final s = '${KDates.weekdaysShort[d.weekday - 1].toUpperCase()} ${d.day}';
    return _sameDay(d, now) ? l10n.forecastHeadToday(s) : s;
  }
}

class _DayHead extends SliverPersistentHeaderDelegate {
  _DayHead(this.label);

  final String label;

  @override
  double get minExtent => 44;

  @override
  double get maxExtent => 44;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: KColors.card,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      alignment: Alignment.topLeft,
      child: Text(label, style: KText.label),
    );
  }

  @override
  bool shouldRebuild(_DayHead old) => old.label != label;
}

class _HourRow extends StatelessWidget {
  const _HourRow({required this.hour, required this.first, required this.on, required this.onTap});

  final ForecastHour hour;
  final bool first;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rain = hour.rainPct ?? 0;
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: on ? KColors.accentSoft : KColors.accentSoft.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? KColors.accent : KColors.accent.withValues(alpha: 0), width: 3),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              child: Text(first ? l10n.forecastNow : '${KDates.two(hour.time.hour)}:00', style: KText.s(22, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 14),
            SizedBox(width: 48, child: KIcon(weatherIcon(hour.condition), size: 34, stroke: 1.7, color: KColors.ink)),
            const SizedBox(width: 14),
            SizedBox(width: 96, child: rain > 0 ? _Rain(pct: rain, size: 16, fontSize: 18) : null),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                weatherLabel(hour.condition),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KText.s(17, color: KColors.muted),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 72,
              child: Text('${_deg(hour.temp)}°', textAlign: TextAlign.right, style: KText.d(28)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Temperature line and rain bars for the 48 hours; tapping or dragging
/// picks the hour under the finger.
class _Chart extends StatelessWidget {
  const _Chart({required this.hours, required this.sel, required this.now, required this.onPick});

  final List<ForecastHour> hours;
  final int sel;
  final DateTime now;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final n = hours.length;
        void pick(Offset p) {
          if (n < 2) return;
          final step = (w - 2 * _ChartPainter.pad) / (n - 1);
          onPick(((p.dx - _ChartPainter.pad) / step).round().clamp(0, n - 1));
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => pick(d.localPosition),
          onHorizontalDragStart: (d) => pick(d.localPosition),
          onHorizontalDragUpdate: (d) => pick(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              height: 176,
              color: KColors.sub,
              child: CustomPaint(
                size: Size(w, 176),
                painter: _ChartPainter(
                  hours: hours,
                  sel: sel,
                  dayLabels: [for (final h in hours) _dayShort(h.time)],
                  rain: _Scale.cold,
                  line: _Scale.line,
                  sep: KColors.dashed,
                  ink: KColors.ink,
                  muted: KColors.muted,
                  dotFill: KColors.card,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.hours,
    required this.sel,
    required this.dayLabels,
    required this.rain,
    required this.line,
    required this.sep,
    required this.ink,
    required this.muted,
    required this.dotFill,
  });

  final List<ForecastHour> hours;
  final int sel;
  final List<String> dayLabels;
  final Color rain, line, sep, ink, muted, dotFill;

  static const pad = 18.0;
  static const _top = 44.0;
  static const _bottom = 112.0;

  @override
  void paint(Canvas canvas, Size size) {
    final n = hours.length;
    if (n == 0) return;
    final w = size.width, h = size.height;
    final step = n < 2 ? 0.0 : (w - 2 * pad) / (n - 1);
    double x(int i) => pad + i * step;
    final temps = [for (final q in hours) q.temp];
    final known = temps.whereType<double>().toList();
    final tmin = known.isEmpty ? 0.0 : known.reduce(math.min);
    final tmax = known.isEmpty ? 1.0 : known.reduce(math.max);
    double y(double v) => tmax == tmin ? (_top + _bottom) / 2 : _bottom - (v - tmin) / (tmax - tmin) * (_bottom - _top);

    // Rain bars along the bottom.
    final rainPaint = Paint()..color = rain.withValues(alpha: 0.45);
    for (var i = 0; i < n; i++) {
      final bh = (hours[i].rainPct ?? 0) / 100 * 34;
      if (bh < 1) continue;
      canvas.drawRect(Rect.fromLTRB(x(i) - step * 0.32, h - bh, x(i) + step * 0.32, h), rainPaint);
    }

    // Midnight separators, each with the new day's name.
    final sepPaint = Paint()
      ..color = sep
      ..strokeWidth = 1.5;
    void label(String text, double cx, double top, TextStyle style) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, top));
      tp.dispose();
    }

    final dayStyle = KText.s(14, weight: FontWeight.w700, color: muted);
    label(dayLabels.first, w * 0.05, h * 0.03, dayStyle);
    for (var i = 1; i < n; i++) {
      if (hours[i].time.day == hours[i - 1].time.day) continue;
      for (var yy = 0.0; yy < h; yy += 9) {
        canvas.drawLine(Offset(x(i), yy), Offset(x(i), math.min(h, yy + 4)), sepPaint);
      }
      label(dayLabels[i], x(i) + w * 0.042, h * 0.03, dayStyle);
    }

    // Temperature: a smooth line over a fading area.
    final pts = [
      for (var i = 0; i < n; i++)
        if (temps[i] != null) Offset(x(i), y(temps[i]!)),
    ];
    if (pts.length >= 2) {
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var k = 1; k < pts.length; k++) {
        final p = pts[k - 1], q = pts[k], cx = (p.dx + q.dx) / 2;
        path.cubicTo(cx, p.dy, cx, q.dy, q.dx, q.dy);
      }
      final area = Path.from(path)
        ..lineTo(pts.last.dx, h)
        ..lineTo(pts.first.dx, h)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [line.withValues(alpha: 0.24), line.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Highest and lowest temperatures.
    if (known.isNotEmpty) {
      final style = KText.s(16, weight: FontWeight.w700, color: ink);
      final imax = temps.indexOf(tmax), imin = temps.indexOf(tmin);
      label('${tmax.round()}°', x(imax).clamp(16, w - 16), y(tmax) - 30, style);
      if (imin != imax) label('${tmin.round()}°', x(imin).clamp(16, w - 16), y(tmin) + 8, style);
    }

    // The picked hour.
    final s = sel.clamp(0, n - 1);
    canvas.drawLine(
      Offset(x(s), 0),
      Offset(x(s), h),
      Paint()
        ..color = ink
        ..strokeWidth = 2,
    );
    if (temps[s] case final t?) {
      final c = Offset(x(s), y(t));
      canvas.drawCircle(c, 13, Paint()..color = ink);
      canvas.drawCircle(c, 9, Paint()..color = dotFill);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.hours != hours ||
      old.sel != sel ||
      old.rain != rain ||
      old.line != line ||
      old.sep != sep ||
      old.ink != ink ||
      old.muted != muted ||
      old.dotFill != dotFill;
}
