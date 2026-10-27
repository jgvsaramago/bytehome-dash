import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../data/dates.dart';
import '../data/history_target.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';

export '../data/history_target.dart';

Future<void> showEntityHistory(BuildContext context, HistoryTarget target) => showKModal(context, (_) => HistoryModal(target: target));

/// Makes a value open its history (the design's `data-entity`): a soft
/// highlight while pressed, then the history modal.
class KHistoryTap extends StatefulWidget {
  const KHistoryTap({super.key, required this.target, required this.child});

  /// Null leaves [child] as it is (no entity configured).
  final HistoryTarget? target;
  final Widget child;

  @override
  State<KHistoryTap> createState() => _KHistoryTapState();
}

class _KHistoryTapState extends State<KHistoryTap> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    if (target == null) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () => showEntityHistory(context, target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _down ? KColors.dark.withValues(alpha: KColors.isDark ? 0.25 : 0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.child,
      ),
    );
  }
}

enum _Range { day, week, month }

extension on _Range {
  /// Samples and minutes between them.
  (int, int) get grid => switch (this) {
    _Range.day => (96, 15),
    _Range.week => (168, 60),
    _Range.month => (120, 360),
  };
  String get label => switch (this) {
    _Range.day => l10n.historyRange24h,
    _Range.week => l10n.historyRange7d,
    _Range.month => l10n.historyRange30d,
  };
  String get recent => switch (this) {
    _Range.day => l10n.historyLast24h,
    _Range.week => l10n.historyLast7d,
    _Range.month => l10n.historyLast30d,
  };
}

String _two(int n) => n.toString().padLeft(2, '0');
String _hm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
String _day(DateTime d) => KDates.short(d);
String _wd(DateTime d) => KDates.abbrLower[d.weekday - 1];

/// A binary entity's states when its target doesn't name them.
List<String> get _offOn => [l10n.commonOff, l10n.commonOn];

/// One period of an entity, sampled on the chart's grid.
class _Series {
  _Series({required this.times, this.values = const [], this.changes = const [], this.start, this.end});

  /// The end of each sample's slot, oldest first.
  final List<DateTime> times;

  /// Numeric: the mean of each slot (null where HA has nothing).
  final List<double?> values;

  /// Timeline: every state change in the period, the first at its start.
  final List<({String state, DateTime at})> changes;
  final DateTime? start;
  final DateTime? end;
}

/// The design's "Histórico de entidade": the value now (or under the
/// finger), 24 h / 7 d / 30 d with paging back in time, a line chart (or a
/// timeline of states) to scrub, and the period's summary. History comes
/// from HA's recorder.
class HistoryModal extends ConsumerStatefulWidget {
  const HistoryModal({super.key, required this.target});

  final HistoryTarget target;

  @override
  ConsumerState<HistoryModal> createState() => _HistoryModalState();
}

class _HistoryModalState extends ConsumerState<HistoryModal> {
  _Range _range = _Range.day;
  int _back = 0;
  int? _cursor;
  _Series? _series;
  bool _failed = false;
  int _load = 0;

  HistoryTarget get t => widget.target;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  /// The period's slots: they end on the last quarter hour, [_back] whole
  /// periods ago.
  List<DateTime> _times() {
    final (n, step) = _range.grid;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, now.hour, now.minute ~/ 15 * 15).subtract(Duration(minutes: n * step * _back));
    return [for (var i = 0; i < n; i++) end.subtract(Duration(minutes: (n - 1 - i) * step))];
  }

  Future<void> _fetch() async {
    final load = ++_load;
    setState(() {
      _series = null;
      _failed = false;
    });
    try {
      final series = await _query(_times());
      if (mounted && load == _load) setState(() => _series = series);
    } catch (_) {
      if (mounted && load == _load) setState(() => _failed = true);
    }
  }

  Future<_Series> _query(List<DateTime> times) async {
    final client = ref.read(haWebSocketClientProvider);
    final step = Duration(minutes: _range.grid.$2);
    final start = times.first.subtract(step);
    final end = times.last;
    if (t.timeline) {
      final history = await client.stateHistory([t.entityId], start: start);
      final changes = [
        for (final c in history[t.entityId] ?? const <({String state, DateTime at})>[])
          if (!c.at.isAfter(end)) c,
      ];
      return _Series(times: times, changes: changes, start: start, end: end);
    }
    // Recorder statistics (5-minute or hourly means) keep long periods
    // light; a sensor without them falls back to its raw history.
    final points = <(DateTime, double)>[];
    final raw = await client.command('recorder/statistics_during_period', {
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
      'statistic_ids': [t.entityId],
      'period': _range == _Range.day ? '5minute' : 'hour',
      'types': ['mean', 'state'],
    });
    for (final row in ((raw as Map?)?[t.entityId] as List?)?.whereType<Map>() ?? const <Map>[]) {
      final at = row['end'] ?? row['start'];
      final v = row['mean'] ?? row['state'];
      if (at is num && v is num) points.add((DateTime.fromMillisecondsSinceEpoch(at.toInt()), v.toDouble()));
    }
    if (points.isEmpty) {
      for (final p in await client.historyDuringPeriod(t.entityId, start: start, end: end)) {
        points.add((p.time, p.value));
      }
    }
    points.sort((a, b) => a.$1.compareTo(b.$1));
    // Each slot: the mean of what falls in it, else the last value before.
    final values = <double?>[];
    var i = 0;
    double? last;
    for (final slotEnd in times) {
      var sum = 0.0, count = 0;
      while (i < points.length && !points[i].$1.isAfter(slotEnd)) {
        if (points[i].$1.isAfter(slotEnd.subtract(step))) {
          sum += points[i].$2;
          count++;
        }
        last = points[i].$2;
        i++;
      }
      values.add(count > 0 ? sum / count : last);
    }
    return _Series(times: times, values: values);
  }

  void _setRange(_Range r) {
    _range = r;
    _back = 0;
    _cursor = null;
    _fetch();
  }

  void _page(int by) {
    if (_back + by < 0) return;
    _back += by;
    _cursor = null;
    _fetch();
  }

  // ─── Formatting ──────────────────────────────────────────────────────

  String _fmt(double v) {
    var d = v.abs() >= 100 ? 0 : (v.abs() >= 10 ? 1 : 2);
    if (const {HistoryKind.percent, HistoryKind.battery, HistoryKind.humidity, HistoryKind.pressure, HistoryKind.uv}.contains(t.kind)) d = 0;
    return fmtDec(v, decimals: d);
  }

  (Color, Color, String) get _look {
    final solar = t.entityId.contains('solar');
    return switch (t.kind) {
      HistoryKind.temp => (KColors.orange, KColors.orangeTint, _tempIcon),
      HistoryKind.humidity => (KColors.blue, KColors.blueTint, KIcons.drop),
      HistoryKind.power => solar ? (KColors.solar, KColors.amberTint, _boltIcon) : (KColors.grid, KColors.blueTint, _boltIcon),
      HistoryKind.energy => (KColors.battery, KColors.greenTint, _boltIcon),
      HistoryKind.battery => (KColors.green, KColors.greenTint, _batteryIcon),
      HistoryKind.wind => (KColors.ink2, KColors.chipAlt, _windIcon),
      HistoryKind.pressure => (KColors.muted, KColors.chipAlt, _gaugeIcon),
      HistoryKind.uv || HistoryKind.radiation => (KColors.solar, KColors.amberTint, KIcons.sun),
      HistoryKind.rain => (KColors.blue, KColors.blueTint, _rainIcon),
      HistoryKind.binary || HistoryKind.states => (KColors.accentFg, KColors.accentSoft, _listIcon),
      _ => (KColors.accentFg, KColors.accentSoft, _chartIcon),
    };
  }

  static const _tempIcon = '<path d="M10 4a2 2 0 1 1 4 0v10.2a4 4 0 1 1-4 0z"/>';
  static const _boltIcon = '<path d="M13 2L4 14h7l-1 8 9-12h-7z"/>';
  static const _batteryIcon = '<path d="M4 8h14v8H4zM18 11h2v2h-2"/>';
  static const _windIcon = '<path d="M3 8h11a3 3 0 1 0-3-3M3 12h15a3 3 0 1 1-3 3M3 16h7"/>';
  static const _gaugeIcon = '<path d="M4 18a8 8 0 1 1 16 0M12 18l4-6"/>';
  static const _rainIcon = '<path d="M7 14h10a4 4 0 0 0 .6-7.95A6 6 0 0 0 6.2 5.1 4.5 4.5 0 0 0 7 14zM8 18l-1 3M12 18l-1 3M16 18l-1 3"/>';
  static const _listIcon = '<path d="M4 6h16M4 12h10M4 18h6"/>';
  static const _chartIcon = '<path d="M4 18h16M7 14l3-4 3 2 4-6"/>';

  /// Timeline colours: the design's pastel states (fixed in both themes;
  /// the label on them stays dark).
  static const _palette = [Color(0xFF8FD19E), Color(0xFFF0A35E), Color(0xFF7FB3EA), Color(0xFFC9A7F0), Color(0xFFF4877C)];
  static const _binaryPalette = [Color(0xFFB9DFC2), Color(0xFFF0A35E)];

  /// Whether a raw state is the "open/on" side of a binary entity.
  static bool _isOn(String raw) => const {'on', 'open', 'opening', 'unlocked', 'unlocking', 'jammed'}.contains(raw);

  String _labelOf(String raw) {
    if (t.kind == HistoryKind.binary) {
      final s = t.states ?? _offOn;
      return _isOn(raw) ? s[1] : s[0];
    }
    return t.stateLabel?.call(raw) ?? raw;
  }

  static bool _gap(String raw) => raw == 'unavailable' || raw == 'unknown';

  /// The timeline's states in display order: binary is fixed, others in
  /// order of first appearance.
  List<String> _labels(_Series s) {
    if (t.kind == HistoryKind.binary) return t.states ?? _offOn;
    final out = <String>[];
    for (final c in s.changes) {
      if (_gap(c.state)) continue;
      final l = _labelOf(c.state);
      if (!out.contains(l)) out.add(l);
    }
    return out;
  }

  Color _colorOf(List<String> labels, String label) {
    final pal = t.kind == HistoryKind.binary ? _binaryPalette : _palette;
    return pal[math.max(0, labels.indexOf(label)) % pal.length];
  }

  /// The state in effect at [at] (null before the first known one).
  String? _stateAt(_Series s, DateTime at) {
    String? out;
    for (final c in s.changes) {
      if (c.at.isAfter(at)) break;
      out = c.state;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final (color, tint, icon) = _look;
    final s = _series;
    final (n, _) = _range.grid;
    final times = s?.times ?? _times();
    final ci = _cursor == null ? n - 1 : _cursor!.clamp(0, n - 1);
    final when = _cursor == null && _back == 0
        ? l10n.historyNow
        : (_range == _Range.day && _back == 0 ? l10n.historyTodayAt(_hm(times[ci])) : l10n.historyDayAt(_wd(times[ci]), _day(times[ci]), _hm(times[ci])));
    final last = times.last, first = times.first;
    final period = _back == 0 ? _range.recent : (_range == _Range.day ? '${_wd(last)}, ${_day(last)}' : '${_day(first)} – ${_day(last)}');

    Widget shown;
    if (s == null) {
      shown = Text(_failed ? l10n.historyNone : l10n.commonLoading, style: KText.s(26, color: KColors.muted));
    } else if (t.timeline) {
      final raw = _stateAt(s, times[ci]);
      final label = raw == null || _gap(raw) ? l10n.historyNoData : _labelOf(raw);
      final bg = raw == null || _gap(raw) ? KColors.chip : _colorOf(_labels(s), label);
      shown = Container(
        height: 56,
        padding: const EdgeInsets.fromLTRB(18, 0, 22, 0),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: Color(0x5917191C), shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: KText.s(26, weight: FontWeight.w700, color: const Color(0xFF17191C)),
            ),
          ],
        ),
      );
    } else {
      final v = s.values[ci];
      shown = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: v == null ? '—' : _fmt(v)),
            if (t.unit.isNotEmpty)
              TextSpan(
                text: ' ${t.unit}',
                style: KText.s(30, color: KColors.muted),
              ),
          ],
        ),
        style: KText.d(72, weight: FontWeight.w400, height: 1, spacing: -2),
      );
    }

    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The entity.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(20)),
                child: Center(child: KIcon(icon, size: 32, color: color, stroke: 1.9)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.label, style: KText.modalTitle.copyWith(height: 1.1)),
                    const SizedBox(height: 4),
                    Text(
                      t.entityId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 16, color: KColors.faint),
                    ),
                  ],
                ),
              ),
              KCircleButton(
                icon: KIcons.close,
                size: 64,
                iconSize: 26,
                stroke: 2.2,
                bg: KColors.chip,
                border: null,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // The value at the chosen moment (or now).
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(alignment: Alignment.centerLeft, child: shown),
                ),
                const SizedBox(width: 16),
                Text(
                  when,
                  textAlign: TextAlign.right,
                  style: KText.s(20, color: KColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Period and paging back in time.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(32)),
                child: Row(
                  children: [
                    for (final r in _Range.values) ...[
                      if (r.index > 0) const SizedBox(width: 4),
                      KPress(
                        onTap: () => _setRange(r),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: r == _range ? KColors.tile : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: r == _range ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
                          ),
                          child: Text(r.label, style: KText.s(18, weight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              KCircleButton(icon: KIcons.chevronLeft, size: 56, iconSize: 24, stroke: 2.2, onTap: () => _page(1)),
              SizedBox(
                width: 190,
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: KText.s(18, weight: FontWeight.w600),
                ),
              ),
              Opacity(
                opacity: _back > 0 ? 1 : 0.35,
                child: KCircleButton(icon: KIcons.chevronRight, size: 56, iconSize: 24, stroke: 2.2, onTap: () => _page(-1)),
              ),
              if (_back > 0) ...[
                const SizedBox(width: 12),
                KPress(
                  onTap: () => _page(-_back),
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
                    child: Text(l10n.historyNow, style: KText.s(18, weight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          _chart(s, times, color),
          const SizedBox(height: 24),
          if (s != null) _stats(s),
          const SizedBox(height: 24),
          Text(l10n.historyFooter, style: KText.s(15, color: KColors.faint)),
        ],
      ),
    );
  }

  static const _plotX = 56.0;

  Widget _chart(_Series? s, List<DateTime> times, Color color) {
    final timeline = t.timeline;
    final height = timeline ? 190.0 : 360.0;
    final n = times.length;
    final labels = s == null || !timeline ? const <String>[] : _labels(s);
    return LayoutBuilder(
      builder: (context, box) {
        final plotW = box.maxWidth - _plotX - 8;
        void scrub(Offset local) => setState(() => _cursor = (((local.dx - _plotX).clamp(0, plotW)) / plotW * (n - 1)).round());
        void unscrub() => setState(() => _cursor = null);
        String xLabel(DateTime d) => switch (_range) {
          _Range.day => _hm(d),
          _Range.week => '${_wd(d)} ${d.day}',
          _Range.month => _day(d),
        };
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => scrub(d.localPosition),
          onPanUpdate: (d) => scrub(d.localPosition),
          onPanEnd: (_) => unscrub(),
          onPanCancel: unscrub,
          child: SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ChartPainter(
                      series: s,
                      timeline: timeline,
                      color: color,
                      cursor: _cursor,
                      n: n,
                      plotX: _plotX,
                      plotW: plotW,
                      plotH: height - 36,
                      fmt: _fmt,
                      divider: KColors.divider,
                      faint: KColors.faint,
                      ink: KColors.ink,
                      surface: KColors.card,
                      track: KColors.sub,
                      stateColor: (raw) => _gap(raw) ? null : _colorOf(labels, _labelOf(raw)),
                    ),
                  ),
                ),
                for (var q = 0; q <= 4; q++)
                  Positioned(
                    left: _plotX + (q / 4 * (n - 1)).round() / (n - 1) * plotW - 60,
                    width: 120,
                    bottom: 0,
                    child: Text(
                      xLabel(times[(q / 4 * (n - 1)).round()]),
                      textAlign: TextAlign.center,
                      style: KText.s(14, color: KColors.faint),
                    ),
                  ),
                if (timeline && labels.isNotEmpty)
                  Positioned(
                    left: _plotX,
                    top: 116,
                    right: 0,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        for (final l in labels)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(color: _colorOf(labels, l), borderRadius: BorderRadius.circular(4)),
                              ),
                              const SizedBox(width: 8),
                              Text(l, style: KText.s(16, color: KColors.muted)),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stats(_Series s) {
    final (n, step) = _range.grid;
    String dur(int minutes) => minutes >= 60 ? l10n.historyDurationHm(minutes ~/ 60, minutes % 60) : l10n.historyDurationM(minutes);
    List<(String, String, String)> rows;
    if (!t.timeline) {
      final vals = s.values;
      int? mi, ma;
      var sum = 0.0, count = 0;
      for (var j = 0; j < vals.length; j++) {
        final v = vals[j];
        if (v == null) continue;
        if (mi == null || v < vals[mi]!) mi = j;
        if (ma == null || v > vals[ma]!) ma = j;
        sum += v;
        count++;
      }
      String at(int? j) => j == null ? '' : (_range == _Range.day ? l10n.historyAtTime(_hm(s.times[j])) : _day(s.times[j]));
      String val(double? v) => v == null ? '—' : '${_fmt(v)} ${t.unit}'.trim();
      rows = [
        (l10n.historyMin, val(mi == null ? null : vals[mi]), at(mi)),
        (l10n.historyAverage, val(count == 0 ? null : sum / count), l10n.historyInPeriod),
        (l10n.historyMax, val(ma == null ? null : vals[ma]), at(ma)),
      ];
    } else {
      // Time in each state, walking the changes across the period.
      final start = s.start!, end = s.end!;
      final minutes = <String, int>{};
      var entries = 0;
      DateTime? lastChange;
      String? prev;
      for (var i = 0; i < s.changes.length; i++) {
        final c = s.changes[i];
        final from = c.at.isBefore(start) ? start : c.at;
        final to = i + 1 < s.changes.length ? s.changes[i + 1].at : end;
        if (!_gap(c.state)) {
          final l = _labelOf(c.state);
          minutes[l] = (minutes[l] ?? 0) + to.difference(from).inMinutes;
          if (prev != null && prev != l) lastChange = c.at;
          if (t.kind == HistoryKind.binary && _isOn(c.state) && (prev == null || prev != l) && !c.at.isBefore(start)) entries++;
          prev = l;
        }
      }
      if (t.kind == HistoryKind.binary) {
        final on = (t.states ?? _offOn)[1];
        rows = [
          (on, l10n.historyTimes(entries), l10n.historyInPeriod),
          (l10n.historyTimeIn(on.toLowerCase()), dur(minutes[on] ?? 0), l10n.historyInTotal),
          (l10n.historyLastChange, lastChange == null ? '—' : _hm(lastChange), lastChange == null ? l10n.historyNoChanges : _day(lastChange)),
        ];
      } else {
        final total = n * step;
        rows = [for (final l in _labels(s).take(3)) (l, dur(minutes[l] ?? 0), l10n.historyPercentOfTime(((minutes[l] ?? 0) / total * 100).round()))];
      }
    }
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: i >= rows.length
                ? const SizedBox()
                : Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(15, weight: FontWeight.w600, color: KColors.muted),
                        ),
                        const SizedBox(height: 2),
                        Text(rows[i].$2, maxLines: 1, overflow: TextOverflow.ellipsis, style: KText.d(30)),
                        const SizedBox(height: 2),
                        Text(
                          rows[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(14, color: KColors.faint),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.series,
    required this.timeline,
    required this.color,
    required this.cursor,
    required this.n,
    required this.plotX,
    required this.plotW,
    required this.plotH,
    required this.fmt,
    required this.divider,
    required this.faint,
    required this.ink,
    required this.surface,
    required this.track,
    required this.stateColor,
  });

  final _Series? series;
  final bool timeline;
  final Color color;
  final int? cursor;
  final int n;
  final double plotX, plotW, plotH;
  final String Function(double) fmt;
  final Color divider, faint, ink, surface, track;
  final Color? Function(String raw) stateColor;

  double _x(int j) => plotX + j / (n - 1) * plotW;

  @override
  void paint(Canvas canvas, Size size) {
    final s = series;
    if (timeline) {
      _timeline(canvas, s);
    } else if (s != null) {
      _line(canvas, s);
    }
  }

  void _timeline(Canvas canvas, _Series? s) {
    final band = RRect.fromRectAndRadius(Rect.fromLTWH(plotX, 24, plotW, 72), const Radius.circular(14));
    canvas.save();
    canvas.clipRRect(band);
    canvas.drawRect(band.outerRect, Paint()..color = track);
    if (s != null) {
      final start = s.start!, end = s.end!;
      final span = end.difference(start).inMilliseconds;
      for (var i = 0; i < s.changes.length; i++) {
        final c = s.changes[i];
        final paint = stateColor(c.state);
        if (paint == null) continue;
        final from = c.at.isBefore(start) ? start : c.at;
        final to = i + 1 < s.changes.length ? s.changes[i + 1].at : end;
        final l = plotX + from.difference(start).inMilliseconds / span * plotW;
        final r = plotX + to.difference(start).inMilliseconds / span * plotW;
        canvas.drawRect(Rect.fromLTRB(l, 24, r, 96), Paint()..color = paint);
      }
    }
    canvas.restore();
    if (cursor != null) _cursorLine(canvas, _x(cursor!.clamp(0, n - 1)));
  }

  void _line(Canvas canvas, _Series s) {
    final known = s.values.whereType<double>().toList();
    if (known.isEmpty) return;
    var lo = known.reduce(math.min), hi = known.reduce(math.max);
    if (hi - lo < 1e-6) {
      hi += 1;
      lo -= 1;
    }
    // Round ticks: about four steps of 1, 2, 2.5 or 5 × 10ⁿ.
    final raw = (hi - lo) / 4;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final step = [1, 2, 2.5, 5, 10].map((m) => m * mag).firstWhere((m) => m >= raw, orElse: () => 10 * mag);
    lo = (lo / step).floor() * step;
    hi = (hi / step).ceil() * step;
    double y(double v) => plotH - (v - lo) / (hi - lo) * (plotH - 12) - 6;

    final grid = Paint()
      ..color = divider
      ..strokeWidth = 1.5;
    for (var v = lo; v <= hi + step / 2; v += step) {
      canvas.drawLine(Offset(0, y(v)), Offset(plotX + plotW, y(v)), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: fmt(v),
          style: KText.s(14, color: faint),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y(v) - 22));
    }

    final line = Path();
    final area = Path();
    var open = false;
    double? firstX, lastX;
    for (var j = 0; j < n; j++) {
      final v = s.values[j];
      if (v == null) {
        if (open) area.lineTo(lastX!, plotH);
        open = false;
        continue;
      }
      final p = Offset(_x(j), y(v));
      if (!open) {
        line.moveTo(p.dx, p.dy);
        area.moveTo(p.dx, plotH);
        area.lineTo(p.dx, p.dy);
        firstX ??= p.dx;
        open = true;
      } else {
        line.lineTo(p.dx, p.dy);
        area.lineTo(p.dx, p.dy);
      }
      lastX = p.dx;
    }
    if (open) area.lineTo(lastX!, plotH);
    area.close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(plotX, 0, plotW, plotH)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    if (cursor != null) {
      final j = cursor!.clamp(0, n - 1);
      final x = _x(j);
      _cursorLine(canvas, x);
      final v = s.values[j];
      if (v != null) {
        canvas.drawCircle(Offset(x, y(v)), 9, Paint()..color = surface);
        canvas.drawCircle(
          Offset(x, y(v)),
          7,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
    }
  }

  void _cursorLine(Canvas canvas, double x) {
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, plotH + 8),
      Paint()
        ..color = ink.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.series != series || old.cursor != cursor || old.plotW != plotW || old.color != color;
}
