import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/ha_entity.dart';
import '../../providers/ha_providers.dart';
import '../../providers/temperature_entities_provider.dart';
import 'casa_data.dart';
import 'kiosk_entities.dart';

/// The weather entity the forecast modal reads — the one chosen in the
/// integration's Meteorologia, same as the header's.
final forecastEntityIdProvider = Provider<String?>((ref) => ref.watch(temperatureEntityConfigProvider.select((c) => c.weatherStateEntityId)));

/// An IPMA weather warning: [level] 1 green … 4 red.
class WeatherWarning {
  const WeatherWarning({required this.level, this.type, this.start, this.end});

  final int level;
  final String? type;
  final DateTime? start;
  final DateTime? end;
}

/// The UV index the modal can show without an hourly UV forecast.
/// [dayMax] — IPMA's figure is the day's forecast peak, not "now".
class UvReading {
  const UvReading(this.value, {required this.dayMax});

  final double value;
  final bool dayMax;
}

class WeatherExtras {
  const WeatherExtras({this.warning, this.fireRisk, this.uv});

  final WeatherWarning? warning;

  /// IPMA's fire risk class, 1 (reduzido) … 5 (máximo).
  final int? fireRisk;
  final UvReading? uv;
}

/// Warnings, fire risk and UV from the sensors chosen in the integration's
/// Meteorologia (IPMA's, typically), else (UV only) the weather station's
/// UV sensor or the weather entity's `uv_index`. A field is null when nothing provides it, and the
/// modal then leaves that card out.
final weatherExtrasProvider = Provider.autoDispose<WeatherExtras>((ref) {
  final config = ref.watch(temperatureEntityConfigProvider);
  HaEntity? live(String? id) => id == null ? null : ref.watch(entitiesProvider.select((a) => a.valueOrNull?[id]));
  final alert = live(config.warningEntityId);
  final fire = live(config.fireRiskEntityId);

  WeatherWarning? warning;
  if (alert != null && !alert.isUnavailable) {
    final level = switch (alert.state) {
      'green' => 1,
      'yellow' => 2,
      'orange' => 3,
      'red' => 4,
      _ => null,
    };
    DateTime? at(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
    final type = alert.attributes['awarenessTypeName'];
    if (level != null) {
      warning = WeatherWarning(
        level: level,
        type: type is String && type.isNotEmpty ? type : null,
        start: at(alert.attributes['startTime']),
        end: at(alert.attributes['endTime']),
      );
    }
  }

  final fireLevel = numState(fire)?.round();

  UvReading? uv;
  if (numState(live(config.uvEntityId)) case final v?) {
    uv = UvReading(v, dayMax: true);
  } else {
    final entities = ref.watch(kioskEntitiesProvider);
    final stationUv = ref.watch(weatherStationProvider)[StationRole.uv];
    final weatherId = ref.watch(forecastEntityIdProvider);
    final v = numState(entities[stationUv ?? '']) ?? numAttr(entities[weatherId ?? ''], 'uv_index');
    if (v != null) uv = UvReading(v, dayMax: false);
  }

  return WeatherExtras(warning: warning, fireRisk: fireLevel != null && fireLevel >= 1 && fireLevel <= 5 ? fireLevel : null, uv: uv);
});
