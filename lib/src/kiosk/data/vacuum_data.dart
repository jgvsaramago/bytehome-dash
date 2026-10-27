import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ha_client/ha_websocket_client.dart';
import '../../l10n/l10n.dart';
import '../../models/ha_entity.dart';
import '../../providers/ha_providers.dart';
import '../../utils/optimistic.dart';
import 'house_models.dart';
import 'kiosk_entities.dart';

/// A robot vacuum as chosen in the integration (ByteHomeDash › Aspiradores)
/// plus its device's other entities by role (`select.suction_level` → id),
/// which the integration finds on its own (`vacuum_entities`).
class VacuumConfig {
  const VacuumConfig({required this.entityId, this.name = '', this.where = '', this.roles = const {}});

  final String entityId;
  final String name;
  final String where;
  final Map<String, String> roles;
}

class VacuumConfigStore {
  VacuumConfigStore(this._client);

  final HaWebSocketClient _client;

  Future<List<VacuumConfig>> read() async {
    final raw = await _client.getSettings('vacuums');
    final derived = await _client.getSettings('vacuum_entities');
    final roles = derived is Map ? derived : const {};
    return [
      if (raw is List)
        for (final m in raw.whereType<Map>())
          if (m['entityId'] case final String id when id.isNotEmpty)
            VacuumConfig(
              entityId: id,
              name: (m['name'] as String? ?? '').trim(),
              where: (m['where'] as String? ?? '').trim(),
              roles: {
                for (final e in ((roles[id] as Map?) ?? const {}).entries)
                  if (e.key is String && e.value is String) e.key as String: e.value as String,
              },
            ),
    ];
  }
}

final vacuumConfigStoreProvider = Provider<VacuumConfigStore>((ref) => VacuumConfigStore(ref.watch(haWebSocketClientProvider)));

final savedVacuumConfigProvider = FutureProvider<List<VacuumConfig>>((ref) async {
  await haReady(ref);
  return ref.watch(vacuumConfigStoreProvider).read();
});

final vacuumConfigProvider = StateProvider<List<VacuumConfig>>((ref) => const []);

// ─── What a robot is doing ─────────────────────────────────────────────

enum VacState { docked, cleaning, paused, returning, idle, error }

VacState _stateOf(String s) => switch (s) {
  'cleaning' => VacState.cleaning,
  'paused' => VacState.paused,
  'returning' => VacState.returning,
  'error' => VacState.error,
  'docked' => VacState.docked,
  _ => VacState.idle,
};

extension VacStateText on VacState {
  String get label => switch (this) {
    VacState.docked => l10n.vacuumStateDocked,
    VacState.cleaning => l10n.vacuumStateCleaning,
    VacState.paused => l10n.vacuumStatePaused,
    VacState.returning => l10n.vacuumStateReturning,
    VacState.idle => l10n.vacuumStateIdle,
    VacState.error => l10n.vacuumStateError,
  };

  bool get busy => this == VacState.cleaning || this == VacState.paused || this == VacState.returning || this == VacState.error;
}

/// One choice of a `select.*` the modal shows as a segment.
typedef VacOption = ({String key, String label});

/// A consumable: life left and its reset button.
class VacPart {
  const VacPart({required this.key, required this.icon, required this.pct, required this.left, this.entityId, this.resetId});

  final String key;
  String get label => switch (key) {
    'main_brush' => l10n.vacuumPartMainBrush,
    'side_brush' => l10n.vacuumPartSideBrush,
    'filter' => l10n.vacuumPartFilter,
    'sensor_dirty' => l10n.vacuumPartSensors,
    'wheel_dirty' => l10n.vacuumPartWheels,
    'scale_inhibitor' => l10n.vacuumPartScaleInhibitor,
    _ => _cap(key),
  };
  final String icon;
  final double pct;

  /// "172 h", "22 dias".
  final String left;
  final String? entityId;
  final String? resetId;
}

class VacuumInfo {
  const VacuumInfo({
    required this.config,
    required this.name,
    required this.where,
    required this.state,
    required this.battery,
    required this.charging,
    required this.room,
    required this.progress,
    required this.area,
    required this.mins,
    required this.errorCode,
    required this.errorText,
    required this.rooms,
    required this.mode,
    required this.modes,
    required this.suction,
    required this.suctions,
    required this.humidity,
    required this.humidities,
    required this.route,
    required this.routes,
    required this.genius,
    required this.geniuses,
    required this.wetness,
    required this.wetMin,
    required this.wetMax,
    required this.wash,
    required this.emptying,
    required this.tanks,
    required this.lowWater,
    required this.dryPct,
    required this.dryLeft,
    required this.parts,
    required this.dnd,
    required this.dndStart,
    required this.dndEnd,
    required this.childLock,
    required this.volume,
    required this.count,
    required this.totalArea,
    required this.totalMins,
    required this.lastAt,
  });

  final VacuumConfig config;
  String get entityId => config.entityId;
  String? role(String key) => config.roles[key];

  final String name;
  final String where;
  final VacState state;
  final int? battery;
  final bool charging;

  /// Where it is (or last was).
  final String? room;
  final int? progress;

  /// This session's (or, docked, the last one's) area and minutes.
  final double? area;
  final int? mins;
  final String? errorCode;
  final String? errorText;

  /// The current map's rooms: segment id → name.
  final List<({int id, String name})> rooms;

  final String? mode;
  final List<VacOption> modes;
  final String? suction;
  final List<VacOption> suctions;
  final String? humidity;
  final List<VacOption> humidities;
  final String? route;
  final List<VacOption> routes;
  final String? genius;
  final List<VacOption> geniuses;
  final int? wetness;
  final int wetMin;
  final int wetMax;

  /// The station: `idle`, `washing`, `drying`, … (null without one).
  final String? wash;
  final bool emptying;

  /// Label → installed, for the clean/dirty water tanks, dust bag and
  /// detergent the station reports.
  final List<({String key, String label, String raw, String? entityId})> tanks;
  final bool lowWater;
  final int? dryPct;
  final int? dryLeft;
  final List<VacPart> parts;

  final bool? dnd;

  /// Minutes after midnight.
  final int? dndStart;
  final int? dndEnd;
  final bool? childLock;
  final int? volume;

  final int? count;
  final double? totalArea;
  final int? totalMins;
  final DateTime? lastAt;

  bool get geniusOn => genius != null && genius != 'off';
  bool get drying => wash == 'drying';
  List<VacPart> get worn => [
    for (final p in parts)
      if (p.pct < 20) p,
  ];
}

/// HA names a device's main entity after the device and itself, which for
/// a vacuum is the same name twice ("Zé Come-Pó  Zé Come-Pó").
String _plainName(String name) {
  final parts = name.split(RegExp(r'\s{2,}'));
  return parts.length == 2 && parts[0].trim() == parts[1].trim() ? parts[0].trim() : name;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ');

Map<String, String> get _modeLabels => {
  'sweeping': l10n.vacuumModeSweeping,
  'mopping': l10n.vacuumModeMopping,
  'sweeping_and_mopping': l10n.vacuumModeSweepingAndMopping,
  'mopping_after_sweeping': l10n.vacuumModeMoppingAfterSweeping,
};
Map<String, String> get _suctionLabels => {
  'quiet': l10n.vacuumSuctionQuiet,
  'silent': l10n.vacuumSuctionQuiet,
  'standard': l10n.vacuumStandard,
  'strong': l10n.vacuumSuctionStrong,
  'turbo': 'Turbo',
  'max': l10n.vacuumSuctionMax,
};
Map<String, String> get _humidityLabels => {'slightly_dry': l10n.vacuumMopSlightlyDry, 'moist': l10n.vacuumMopMoist, 'wet': l10n.vacuumMopWet};
Map<String, String> get _routeLabels => {
  'quick': l10n.vacuumRouteQuick,
  'standard': l10n.vacuumStandard,
  'intensive': l10n.vacuumRouteIntensive,
  'deep': l10n.vacuumDeep,
};
Map<String, String> get _geniusLabels => {'off': l10n.commonOff, 'routine_cleaning': l10n.vacuumGeniusRoutine, 'deep_cleaning': l10n.vacuumDeep};

/// The error codes worth saying in the app's language, with what to do.
Map<String, (String, String)> get vacErrors => {
  'main_brush_stuck': (l10n.vacuumErrorMainBrush, l10n.vacuumErrorMainBrushFix),
  'main_brush': (l10n.vacuumErrorMainBrush, l10n.vacuumErrorMainBrushFix),
  'side_brush_stuck': (l10n.vacuumErrorSideBrush, l10n.vacuumErrorSideBrushFix),
  'side_brush': (l10n.vacuumErrorSideBrush, l10n.vacuumErrorSideBrushFix),
  'wheel_stuck': (l10n.vacuumErrorWheel, l10n.vacuumErrorWheelFix),
  'drop': (l10n.vacuumErrorDrop, l10n.vacuumErrorDropFix),
  'bumper': (l10n.vacuumErrorBumper, l10n.vacuumErrorBumperFix),
  'dust_bin': (l10n.vacuumErrorDustBin, l10n.vacuumErrorDustBinFix),
  'water_tank': (l10n.vacuumErrorWaterTank, l10n.vacuumErrorWaterTankFix),
  'low_battery': (l10n.vacuumErrorLowBattery, l10n.vacuumErrorLowBatteryFix),
};

/// The consumables, in the design's order: key, icon path (the label comes
/// from [VacPart.label]).
const _partSpecs = [
  ('main_brush', '<path d="M4 12h16M6 8l-2 4 2 4M18 8l2 4-2 4M8 12v3M12 12v3M16 12v3"/>', 'reset_main_brush'),
  ('side_brush', '<path d="M12 12l-6-6M12 12l6-6M12 12l-6 6M12 12v8M12 12a1.5 1.5 0 1 0 0 .01"/>', 'reset_side_brush'),
  ('filter', '<path d="M4 5h16l-6 8v6l-4 2v-8z"/>', 'reset_filter'),
  ('sensor_dirty', '<path d="M12 5a7 7 0 0 1 7 7M12 9a3 3 0 0 1 3 3M5 19l6-6"/>', 'reset_sensor'),
  ('wheel_dirty', '<path d="M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6"/>', 'reset_wheel'),
  ('scale_inhibitor', '<path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11zM9 13h6"/>', 'reset_scale_inhibitor'),
];

VacuumInfo _vacuum(VacuumConfig c, HaEntity v, Map<String, HaEntity> entities) {
  HaEntity? r(String key) {
    final id = c.roles[key];
    final e = id == null ? null : entities[id];
    return e == null || e.isUnavailable ? null : e;
  }

  double? n(String key) => numState(r(key));
  String? st(String key) => r(key)?.state;
  List<VacOption> opts(String key, Map<String, String> labels) {
    final raw = ((r(key)?.attributes['options'] as List?) ?? const []).whereType<String>().toList();
    // Ours first, in our order, then whatever else the robot offers.
    return [
      for (final k in labels.keys)
        if (raw.contains(k)) (key: k, label: labels[k]!),
      for (final k in raw)
        if (!labels.containsKey(k)) (key: k, label: _cap(k)),
    ];
  }

  int? minutesOf(String key) {
    final s = st(key);
    if (s == null) return null;
    final p = s.split(':');
    if (p.length < 2) return null;
    final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
    return h == null || m == null ? null : h * 60 + m;
  }

  final mapName = v.attributes['selected_map'];
  final roomsAttr = v.attributes['rooms'];
  final roomList = roomsAttr is Map ? (roomsAttr[mapName] ?? (roomsAttr.values.isNotEmpty ? roomsAttr.values.first : null)) : null;
  final rooms = [
    if (roomList is List)
      for (final m in roomList.whereType<Map>())
        if (m['id'] case final num id) (id: id.toInt(), name: (m['name'] as String? ?? l10n.vacuumRoomFallback(id.toInt()))),
  ];

  final errorCode = st('sensor.error') ?? (v.state == 'error' ? 'error' : null);
  final error = errorCode == null || errorCode == 'no_error' ? null : errorCode;
  final rawErrorText = v.attributes['error'] as String?;

  final tanks = [
    for (final (key, label) in [
      ('clean_water_tank_status', l10n.vacuumTankCleanWater),
      ('dirty_water_tank_status', l10n.vacuumTankDirtyWater),
      ('dust_bag_status', l10n.vacuumTankDustBag),
      ('detergent_status', l10n.vacuumTankDetergent),
    ])
      if (st('sensor.$key') case final s?) (key: key, label: label, raw: s, entityId: c.roles['sensor.$key']),
  ];
  final low = st('sensor.low_water_warning');

  final parts = [
    for (final (key, icon, reset) in _partSpecs)
      if (n('sensor.${key}_left') case final pct?)
        VacPart(
          key: key,
          icon: icon,
          pct: pct,
          left: () {
            final e = r('sensor.${key}_time_left');
            final t = numState(e);
            if (t == null) return '';
            final unit = e!.attributes['unit_of_measurement'] as String? ?? 'h';
            return unit == 'd' ? l10n.vacuumDaysLeft(t.round()) : '${t.round()} $unit';
          }(),
          entityId: c.roles['sensor.${key}_left'],
          resetId: c.roles['button.$reset'],
        ),
  ];

  final battery = n('sensor.battery_level') ?? numAttr(v, 'battery') ?? numAttr(v, 'battery_level');
  final last = st('sensor.cleaning_history');
  return VacuumInfo(
    config: c,
    name: c.name.isNotEmpty ? c.name : _plainName(v.friendlyName),
    where: c.where,
    state: _stateOf(v.state),
    battery: battery?.round(),
    charging: v.attributes['charging'] == true || st('sensor.charging_status') == 'charging',
    room: st('sensor.current_room'),
    progress: (n('sensor.cleaning_progress') ?? numAttr(v, 'cleaning_progress'))?.round(),
    area: n('sensor.cleaned_area'),
    mins: n('sensor.cleaning_time')?.round(),
    errorCode: error,
    errorText: error == null ? null : (vacErrors[error]?.$1 ?? (rawErrorText != null && rawErrorText.toLowerCase() != 'no error' ? rawErrorText : _cap(error))),
    rooms: rooms,
    mode: st('select.cleaning_mode'),
    modes: opts('select.cleaning_mode', _modeLabels),
    suction: st('select.suction_level'),
    suctions: opts('select.suction_level', _suctionLabels),
    humidity: st('select.mop_pad_humidity'),
    humidities: opts('select.mop_pad_humidity', _humidityLabels),
    route: st('select.cleaning_route'),
    routes: opts('select.cleaning_route', _routeLabels),
    genius: st('select.cleangenius'),
    geniuses: opts('select.cleangenius', _geniusLabels),
    wetness: n('number.wetness_level')?.round(),
    wetMin: (numAttr(r('number.wetness_level'), 'min') ?? 1).round(),
    wetMax: (numAttr(r('number.wetness_level'), 'max') ?? 32).round(),
    wash: st('sensor.self_wash_base_status'),
    emptying: (st('sensor.auto_empty_status') ?? 'idle') != 'idle',
    tanks: tanks,
    lowWater: low != null && low != 'no_warning' && low != 'off',
    dryPct: n('sensor.drying_progress')?.round(),
    dryLeft: n('sensor.drying_left')?.round(),
    parts: parts,
    dnd: r('switch.dnd')?.isOn,
    dndStart: minutesOf('time.dnd_start'),
    dndEnd: minutesOf('time.dnd_end'),
    childLock: r('switch.child_lock')?.isOn,
    volume: n('number.volume')?.round(),
    count: n('sensor.cleaning_count')?.round(),
    totalArea: n('sensor.total_cleaned_area'),
    totalMins: n('sensor.total_cleaning_time')?.round(),
    lastAt: last == null ? null : DateTime.tryParse(last)?.toLocal(),
  );
}

final vacuumsProvider = Provider<List<VacuumInfo>>((ref) {
  final entities = ref.watch(kioskEntitiesProvider);
  return [
    for (final c in ref.watch(vacuumConfigProvider))
      if (entities[c.entityId] case final v?) _vacuum(c, v, entities),
  ];
});

/// Every command the modal sends, each shown at once and kept until HA
/// confirms it (see [OptimisticLayer]).
class VacuumActions {
  VacuumActions(this._ref);

  final Ref _ref;

  KioskEntitiesNotifier get _entities => _ref.read(kioskEntitiesProvider.notifier);
  HaWebSocketClient get _client => _ref.read(haWebSocketClientProvider);

  bool isPending(String? entityId) => entityId != null && _entities.isPending(entityId);

  Future<void> _state(VacuumInfo v, String service, String state, {Map<String, dynamic>? data, String domain = 'vacuum'}) => _entities.run(
    [expectEntity(v.entityId, state: state)],
    () => _client.callService(domain, service, target: {'entity_id': v.entityId}, serviceData: data),
    timeout: const Duration(seconds: 20),
  );

  /// The chosen rooms in order, or the whole house.
  Future<void> start(VacuumInfo v, List<int> rooms) {
    if (v.state == VacState.paused || v.state == VacState.error || rooms.isEmpty) return _state(v, 'start', 'cleaning');
    return _state(v, 'vacuum_clean_segment', 'cleaning', domain: 'dreame_vacuum', data: {'segments': rooms});
  }

  Future<void> pause(VacuumInfo v) => _state(v, 'pause', 'paused');
  Future<void> stop(VacuumInfo v) => _state(v, 'stop', 'idle');
  Future<void> home(VacuumInfo v) => _state(v, 'return_to_base', 'returning');

  /// The robot beeps; nothing to wait for.
  Future<void> locate(VacuumInfo v) => _client.callService('vacuum', 'locate', target: {'entity_id': v.entityId});

  Future<void> select(String? id, String option) {
    if (id == null) return Future.value();
    return _entities.run([
      expectEntity(id, state: option),
    ], () => _client.callService('select', 'select_option', target: {'entity_id': id}, serviceData: {'option': option}));
  }

  Future<void> number(String? id, num value) {
    if (id == null) return Future.value();
    return _entities.run([
      expectEntity(id, state: '$value', confirmed: (e) => (double.tryParse(e.state) ?? -1) == value),
    ], () => _client.callService('number', 'set_value', target: {'entity_id': id}, serviceData: {'value': value}));
  }

  Future<void> toggle(String? id, bool on) {
    if (id == null) return Future.value();
    return _entities.run([
      expectEntity(id, state: on ? 'on' : 'off'),
    ], () => _client.callService('switch', on ? 'turn_on' : 'turn_off', target: {'entity_id': id}));
  }

  Future<void> time(String? id, int minutes) {
    if (id == null) return Future.value();
    final m = ((minutes % 1440) + 1440) % 1440;
    final value = '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}:00';
    return _entities.run([
      expectEntity(id, state: value),
    ], () => _client.callService('time', 'set_value', target: {'entity_id': id}, serviceData: {'time': value}));
  }

  /// A station button: shows [shows] on [statusId] until it changes.
  Future<void> press(String? buttonId, {String? statusId, String? shows}) {
    if (buttonId == null) return Future.value();
    Future<void> call() => _client.callService('button', 'press', target: {'entity_id': buttonId});
    final before = statusId == null ? null : _ref.read(kioskEntitiesProvider)[statusId]?.state;
    if (statusId == null || shows == null || before == null) return call();
    return _entities.run(
      [expectEntity(statusId, state: shows, confirmed: (e) => e.state != before)],
      call,
      timeout: const Duration(seconds: 20),
    );
  }

  /// A consumable back to 100 %.
  Future<void> reset(VacPart p) {
    final id = p.resetId;
    if (id == null) return Future.value();
    Future<void> call() => _client.callService('button', 'press', target: {'entity_id': id});
    if (p.entityId == null) return call();
    return _entities.run(
      [expectEntity(p.entityId!, state: '100', confirmed: (e) => (double.tryParse(e.state) ?? 0) >= 99)],
      call,
      timeout: const Duration(seconds: 20),
    );
  }
}

final vacuumActionsProvider = Provider<VacuumActions>((ref) => VacuumActions(ref));
