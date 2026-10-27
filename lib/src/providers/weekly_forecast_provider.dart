import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../kiosk/data/dates.dart';
import '../l10n/l10n.dart';
import 'ha_providers.dart';
import 'temperature_entities_provider.dart';

/// One day of the Homepage's 7-day forecast card — [condition] is the raw
/// HA weather condition string (`sunny`, `partlycloudy`, `rainy`, ...); the
/// card itself maps that to an icon/colour, this provider only fetches and
/// parses. [condition]/[high]/[low] are all null when this day has no data
/// — the weather entity is unconfigured/unavailable, or the integration
/// returned fewer than 7 days — so the card still renders 7 columns with
/// "--", the same convention every other unconfigured metric in this app
/// already uses.
class WeeklyForecastDay {
  const WeeklyForecastDay({required this.date, required this.isToday, required this.condition, required this.high, required this.low});

  final DateTime date;
  final bool isToday;

  /// "Today" for the first day, the short weekday name otherwise — a getter,
  /// so it follows a language change without refetching.
  String get label => isToday ? l10n.commonToday : KDates.abbrTitle[date.weekday - 1];
  final String? condition;
  final int? high;
  final int? low;

  factory WeeklyForecastDay.empty(DateTime date, {required bool isToday}) =>
      WeeklyForecastDay(date: date, isToday: isToday, condition: null, high: null, low: null);
}

const _dayCount = 7;

/// Fetches (and periodically refreshes) the Temperaturas settings' own
/// weather entity's daily forecast via HA's `weather.get_forecasts`
/// service. Always resolves to exactly 7 entries, today first, so the card
/// never has to special-case a short or missing response.
class WeeklyForecastNotifier extends AsyncNotifier<List<WeeklyForecastDay>> {
  Timer? _refreshTimer;

  static const _refreshInterval = Duration(minutes: 30);

  @override
  Future<List<WeeklyForecastDay>> build() async {
    final entityId = ref.watch(temperatureEntityConfigProvider.select((c) => c.weatherStateEntityId));

    ref.onDispose(() => _refreshTimer?.cancel());

    final today = DateTime.now();
    final dates = [for (var i = 0; i < _dayCount; i++) today.add(Duration(days: i))];

    if (entityId == null || entityId.trim().isEmpty) {
      return [for (var i = 0; i < _dayCount; i++) WeeklyForecastDay.empty(dates[i], isToday: i == 0)];
    }

    // Waits for a live connection first, same idiom as the rest of this
    // app's HA-backed providers (`areaByEntityIdProvider`, etc.).
    await haReady(ref);
    final client = ref.read(haWebSocketClientProvider);

    // A self-rescheduling one-shot timer rather than `Timer.periodic`: each
    // rebuild's `onDispose` above cancels exactly the timer *that* build
    // registered, so there's never more than one in flight even across
    // reconnects/entity-id changes.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(_refreshInterval, ref.invalidateSelf);

    // A failed fetch (offline, integration doesn't support the service,
    // ...) falls back to the same "--" placeholder days as an unconfigured
    // entity, rather than an `AsyncError` that would leave the card with
    // zero columns instead of its usual 7 — the retry timer above still
    // fires either way.
    List<Map<String, dynamic>> forecast;
    try {
      forecast = await client.getWeatherForecasts(entityId);
    } catch (_) {
      forecast = const [];
    }

    return [
      for (var i = 0; i < _dayCount; i++) i < forecast.length ? _parseDay(dates[i], i == 0, forecast[i]) : WeeklyForecastDay.empty(dates[i], isToday: i == 0),
    ];
  }

  WeeklyForecastDay _parseDay(DateTime date, bool isToday, Map<String, dynamic> entry) {
    final high = entry['temperature'];
    final low = entry['templow'];
    return WeeklyForecastDay(
      date: date,
      isToday: isToday,
      condition: entry['condition'] as String?,
      high: high is num ? high.round() : null,
      low: low is num ? low.round() : null,
    );
  }
}

final weeklyForecastProvider = AsyncNotifierProvider<WeeklyForecastNotifier, List<WeeklyForecastDay>>(WeeklyForecastNotifier.new);

// ─── Forecast modal (daily + hourly detail) ────────────────────────────

/// One day of the forecast modal's list — fuller than [WeeklyForecastDay]:
/// the real date, unrounded temperatures and the chance of rain.
class ForecastDay {
  const ForecastDay({required this.date, this.condition, this.high, this.low, this.rainPct});

  final DateTime date;
  final String? condition;
  final double? high;
  final double? low;
  final int? rainPct;
}

/// One hour of the forecast modal's 48-hour view. [wind] is in the weather
/// entity's own `wind_speed_unit`; [uv] only when the integration forecasts it.
class ForecastHour {
  const ForecastHour({required this.time, this.condition, this.temp, this.rainPct, this.wind, this.uv});

  final DateTime time;
  final String? condition;
  final double? temp;
  final int? rainPct;
  final double? wind;
  final double? uv;
}

class ForecastDetail {
  const ForecastDetail({required this.days, required this.hours, required this.fetchedAt});

  final List<ForecastDay> days;
  final List<ForecastHour> hours;
  final DateTime fetchedAt;
}

/// The daily and hourly `weather.get_forecasts` of one weather entity, for
/// the forecast modal. Fetched when the modal opens (autoDispose) and every
/// 30 minutes while it stays open. Either list is empty when the
/// integration doesn't offer that forecast type (the modal then hides it).
final forecastDetailProvider = FutureProvider.autoDispose.family<ForecastDetail, String>((ref, entityId) async {
  await haReady(ref);
  final client = ref.read(haWebSocketClientProvider);
  final timer = Timer(const Duration(minutes: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);

  Future<List<Map<String, dynamic>>> fetch(String type) async {
    try {
      return await client.getWeatherForecasts(entityId, type: type);
    } catch (_) {
      return const [];
    }
  }

  final (daily, hourly) = await (fetch('daily'), fetch('hourly')).wait;
  double? dbl(Object? v) => v is num ? v.toDouble() : null;
  int? pct(Object? v) => v is num ? v.round() : null;
  DateTime? at(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

  return ForecastDetail(
    fetchedAt: DateTime.now(),
    days: [
      for (final e in daily)
        if (at(e['datetime']) case final date?)
          ForecastDay(
            date: date,
            condition: e['condition'] as String?,
            high: dbl(e['temperature']),
            low: dbl(e['templow']),
            rainPct: pct(e['precipitation_probability']),
          ),
    ],
    hours: [
      for (final e in hourly)
        if (at(e['datetime']) case final time?)
          ForecastHour(
            time: time,
            condition: e['condition'] as String?,
            temp: dbl(e['temperature']),
            rainPct: pct(e['precipitation_probability']),
            wind: dbl(e['wind_speed']),
            uv: dbl(e['uv_index']),
          ),
    ],
  );
});
