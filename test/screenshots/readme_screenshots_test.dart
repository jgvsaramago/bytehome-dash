// The README's screenshots, drawn by the real app with a fictional household:
// a fake Home Assistant client answers every request with sample data, so
// the whole kiosk (header, pages, nav bar) renders as on the screen.
//
// Skipped unless SCREENSHOTS=1. Run on a machine with Flutter (the board):
//
//   SCREENSHOTS=1 flutter test test/screenshots/readme_screenshots_test.dart
//
// The PNGs (720×1280, half the 1440×2560 canvas) go to build/screenshots/;
// copy the ones you want into docs/screenshots/ (most images there now come
// from the design, so don't overwrite them wholesale).
// Camera stills stay blank: there's no network in a test.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bytehomedash/src/dev/placeholder_entities.dart';
import 'package:bytehomedash/src/ha_client/ha_connection_config.dart';
import 'package:bytehomedash/src/ha_client/ha_websocket_client.dart';
import 'package:bytehomedash/src/kiosk/data/kiosk_hydration.dart';
import 'package:bytehomedash/src/kiosk/data/chores_data.dart';
import 'package:bytehomedash/src/kiosk/data/meals_data.dart';
import 'package:bytehomedash/src/kiosk/data/messages_data.dart';
import 'package:bytehomedash/src/kiosk/data/todo_data.dart';
import 'package:bytehomedash/src/kiosk/data/house_config.dart';
import 'package:bytehomedash/src/kiosk/data/family_data.dart';
import 'package:bytehomedash/src/kiosk/kiosk_shell.dart';
import 'package:bytehomedash/src/kiosk/modals/assistant_modal.dart';
import 'package:bytehomedash/src/kiosk/modals/kitchen_modal.dart';
import 'package:bytehomedash/src/kiosk/theme/kiosk_icons.dart';
import 'package:bytehomedash/src/kiosk/widgets/kiosk_nav_bar.dart';
import 'package:bytehomedash/src/l10n/l10n.dart';
import 'package:bytehomedash/src/kiosk/browser/browser.dart';
import 'package:bytehomedash/src/kiosk/modals/energy_modal.dart';
import 'package:bytehomedash/src/kiosk/modals/intercom_modal.dart';
import 'package:bytehomedash/src/kiosk/pages/lists_page.dart';
import 'package:bytehomedash/src/models/ha_area.dart';
import 'package:bytehomedash/src/music/ma_client.dart';
import 'package:bytehomedash/src/music/ma_models.dart';
import 'package:bytehomedash/src/music/music_store.dart';
import 'package:bytehomedash/src/services/door_station.dart';
import 'package:bytehomedash/src/services/doorbell_history.dart';
import 'package:bytehomedash/src/models/ha_calendar_event.dart';
import 'package:bytehomedash/src/models/ha_entity.dart';
import 'package:bytehomedash/src/models/ha_floor.dart';
import 'package:bytehomedash/src/providers/calendar_entities_provider.dart';
import 'package:bytehomedash/src/providers/calendar_entities_store.dart';
import 'package:bytehomedash/src/providers/energy_entities_provider.dart';
import 'package:bytehomedash/src/providers/energy_entities_store.dart';
import 'package:bytehomedash/src/providers/ev_cars_provider.dart';
import 'package:bytehomedash/src/providers/ev_cars_store.dart';
import 'package:bytehomedash/src/providers/ha_providers.dart';
import 'package:bytehomedash/src/providers/individual_sensors_provider.dart';
import 'package:bytehomedash/src/providers/individual_sensors_store.dart';
import 'package:bytehomedash/src/providers/rooms_provider.dart';
import 'package:bytehomedash/src/providers/rooms_store.dart';
import 'package:bytehomedash/src/providers/temperature_entities_provider.dart';
import 'package:bytehomedash/src/providers/temperature_entities_store.dart';
import 'package:bytehomedash/src/services/voice_satellite.dart';
import 'package:bytehomedash/src/theme/theme_mode_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _skip = Platform.environment['SCREENSHOTS'] != '1';
const _out = 'build/screenshots';

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);

/// Today's weekday, 0 = Monday, so today always has tasks.
final _wd = _today.weekday - 1;
final _monday = _today.subtract(Duration(days: _today.weekday - 1));
DateTime _day(int offset, [int h = 0, int m = 0]) => _monday.add(Duration(days: offset, hours: h, minutes: m));
String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ─── The household ──────────────────────────────────────────────────────

Map<String, HaEntity> _entities() {
  HaEntity e(String id, String state, [Map<String, dynamic> attrs = const {}]) =>
      HaEntity(entityId: id, state: state, attributes: attrs, lastChanged: _now, lastUpdated: _now);
  final all = buildPlaceholderEntities();
  // The demo's Portuguese names, in English.
  const names = {
    'light.demo_room_living_room': 'Living room light',
    'cover.demo_room_living_room': 'Living room blinds',
    'media_player.demo_room_living_room': 'Living room speaker',
    'binary_sensor.demo_room_bedroom_window': 'Bedroom window',
    'cover.demo_room_bedroom': 'Bedroom blinds',
    'media_player.demo_room_bedroom': 'Bedroom speaker',
    'climate.demo_room_office': 'Office AC',
    'climate.demo_room_living_room': 'Living room AC',
    'media_player.demo_room_office': 'Office speaker',
    'light.demo_room_kitchen': 'Kitchen light',
    'cover.demo_room_kitchen': 'Kitchen blinds',
    'lock.demo_room_hallway': 'Back door',
    'device_tracker.demo_tesla': 'Model Y',
    'device_tracker.demo_glc': 'GLC',
    'lock.demo_glc': 'GLC lock',
    'weather.demo_casa': 'Home',
    'sensor.demo_room_living_room_humidity': 'Humidity',
    'sensor.demo_room_kitchen_humidity': 'Humidity',
    'sensor.demo_room_office_co2': 'CO2',
  };
  for (final MapEntry(:key, :value) in names.entries) {
    final old = all[key]!;
    all[key] = e(key, old.state, {...old.attributes, 'friendly_name': value});
  }
  for (final x in [
    for (final (id, name) in [('ana', 'Ana'), ('rui', 'Rui'), ('ines', 'Inês'), ('tiago', 'Tiago'), ('family', 'Family')])
      e('calendar.$id', 'off', {'friendly_name': name, 'supported_features': 1}),
    e('todo.shopping', '5', {'friendly_name': 'Shopping'}),
    e('todo.pharmacy', '2', {'friendly_name': 'Pharmacy'}),
    e('todo.home_jobs', '3', {'friendly_name': 'House jobs'}),
    for (final (id, name) in [('front_door', 'Front door'), ('garden', 'Garden'), ('garage', 'Garage')])
      e('camera.$id', 'idle', {'friendly_name': name, 'entity_picture': '/api/camera_proxy/camera.$id?token=x'}),
    e('scene.movie_night', 'scening', {'friendly_name': 'Movie night'}),
    e('scene.good_night', 'scening', {'friendly_name': 'Good night'}),
  ]) {
    all[x.entityId] = x;
  }
  return all;
}

class _Entities extends EntitiesNotifier {
  @override
  Future<Map<String, HaEntity>> build() async => _entities();
}

HaCalendarEvent _ev(String title, DateTime start, [Duration length = const Duration(hours: 1)]) =>
    HaCalendarEvent(start: start, end: start.add(length), allDay: false, summary: title);
HaCalendarEvent _allDay(String title, DateTime day) => HaCalendarEvent(start: day, end: day.add(const Duration(days: 1)), allDay: true, summary: title);

final _events = <String, List<HaCalendarEvent>>{
  'calendar.ana': [
    _ev('Yoga', _day(0, 19)),
    _ev('Dentist', _day(1, 14)),
    _ev('Yoga', _day(2, 19)),
    _ev('Book club', _day(3, 21)),
    _ev('Hairdresser', _day(5, 11, 30)),
  ],
  'calendar.rui': [
    _ev('Team meeting', _day(1, 9, 30), const Duration(minutes: 90)),
    _ev('Football training', _day(1, 18, 30)),
    _ev('Car service', _day(3, 8, 30)),
    _ev('Football training', _day(3, 18, 30)),
    _ev('Padel with Miguel', _day(6, 10)),
    // Overnight: shows on Friday evening and again from the top of Saturday.
    _ev('Night flight', _day(4, 22), const Duration(hours: 10)),
  ],
  'calendar.ines': [
    _ev('Swimming', _day(0, 17, 30)),
    _ev('Piano lesson', _day(2, 16)),
    _ev('Swimming', _day(3, 17, 30)),
    _ev('Cinema with Sofia', _day(4, 18), const Duration(hours: 2)),
  ],
  'calendar.tiago': [_ev('Parent-teacher meeting', _day(1, 17)), _allDay('School trip', _day(4)), _ev('Birthday party', _day(5, 15), const Duration(hours: 3))],
  'calendar.family': [
    _ev('Grandma\'s birthday dinner', _day(5, 20), const Duration(hours: 3)),
    _ev('Farmers\' market', _day(5, 9, 30)),
    _ev('Bike ride', _day(6, 15)),
  ],
};

final _todos = <String, List<Map<String, dynamic>>>{
  'todo.shopping': [
    for (final (i, (name, desc)) in [
      ('Milk', '2 L'),
      ('Eggs', '1 dozen'),
      ('Tomatoes', '1 kg'),
      ('Bread', ''),
      ('Coffee', '1 pack'),
      ('Olive oil', ''),
    ].indexed)
      {'uid': 's$i', 'summary': name, 'status': i == 5 ? 'completed' : 'needs_action', 'description': desc},
  ],
  'todo.pharmacy': [
    {'uid': 'p1', 'summary': 'Sunscreen', 'status': 'needs_action'},
    {'uid': 'p2', 'summary': 'Plasters', 'status': 'needs_action'},
  ],
  'todo.home_jobs': [
    {'uid': 'h1', 'summary': 'Change the hallway bulb', 'status': 'needs_action'},
    {'uid': 'h2', 'summary': 'Clean the gutters', 'status': 'needs_action'},
    {'uid': 'h3', 'summary': 'Book the boiler check', 'status': 'needs_action'},
  ],
};

Map<String, dynamic> _meal(String dish, String time, {String where = 'casa', String? url}) => {
  'dish': dish,
  'where': where,
  'time': time,
  if (url case final u?) 'url': u,
};

Map<String, dynamic> get _mealPlan => {
  for (final (d, type, meal) in [
    (0, 'jantar', _meal('Vegetable soup', '20:00')),
    (0, 'almoco', _meal('Work canteen', '13:00', where: 'fora')),
    (1, 'jantar', _meal('Lasagne', '20:00', url: 'https://recipes.example.com/lasagne')),
    (1, 'pa', _meal('Pancakes', '08:00')),
    (2, 'jantar', _meal('Grilled salmon with rice', '20:00', url: 'https://recipes.example.com/salmon')),
    (2, 'almoco', _meal('Chicken salad', '13:00')),
    (3, 'jantar', _meal('Pizza', '20:30', where: 'encomenda')),
    (4, 'jantar', _meal('Mushroom risotto', '20:00', url: 'https://recipes.example.com/risotto')),
    (4, 'almoco', _meal('Leftover lasagne', '13:00')),
    (5, 'almoco', _meal('Barbecue at the park', '13:00', where: 'fora')),
    (5, 'jantar', _meal('Birthday dinner at Grandma\'s', '20:00', where: 'fora')),
    (6, 'almoco', _meal('Roast chicken and potatoes', '13:30', url: 'https://recipes.example.com/roast-chicken')),
    (6, 'jantar', _meal('Omelette and salad', '20:00')),
  ])
    '${_key(_day(d))}|$type': meal,
};

Map<String, dynamic> get _chores => {
  // Four today: Home's card shows four rows.
  'tasks': [
    {
      'id': 'c1',
      'title': 'Empty the dishwasher',
      'who': 'tiago',
      'days': [0, 1, 2, 3, 4, 5, 6],
    },
    {
      'id': 'c2',
      'title': 'Feed the cat',
      'who': 'inês',
      'days': [0, 1, 2, 3, 4, 5, 6],
      'due': '08:00',
    },
    {
      'id': 'c3',
      'title': 'Take out the recycling',
      'who': 'rui',
      'days': [_wd, (_wd + 3) % 7],
      'due': '21:00',
    },
    {
      'id': 'c4',
      'title': 'Water the plants',
      'who': 'ana',
      'days': [(_wd + 1) % 7, (_wd + 4) % 7],
    },
    {
      'id': 'c5',
      'title': 'Tidy your room',
      'who': 'inês',
      'days': [(_wd + 2) % 7, (_wd + 5) % 7],
    },
    {
      'id': 'c6',
      'title': 'Hoover the stairs',
      'who': 'tiago',
      'days': [(_wd + 1) % 7, (_wd + 5) % 7],
    },
    {
      'id': 'c7',
      'title': 'Laundry',
      'who': 'rui',
      'days': [(_wd + 2) % 7, (_wd + 6) % 7],
    },
    {'id': 'c8', 'title': 'Pay the water bill', 'who': 'ana', 'date': _key(_today), 'due': '18:00'},
  ],
  'done': ['${_key(_today)}|c2', '${_key(_today)}|c1'],
};

final _settings = <String, dynamic>{
  'family_members': [
    {'name': 'Ana', 'color': 'blue', 'calendarEntityId': 'calendar.ana'},
    {'name': 'Rui', 'color': 'orange', 'calendarEntityId': 'calendar.rui'},
    {'name': 'Inês', 'color': 'green', 'calendarEntityId': 'calendar.ines'},
    {'name': 'Tiago', 'color': 'purple', 'calendarEntityId': 'calendar.tiago'},
  ],
  'todo_lists': [
    {'entityId': 'todo.shopping'},
    {'entityId': 'todo.pharmacy'},
    {'entityId': 'todo.home_jobs'},
  ],
  'todo_list_icons': {'todo.shopping': 'cart', 'todo.pharmacy': 'pill', 'todo.home_jobs': 'home'},
  'house_screen': {'waterHeaterEntityId': null},
  'house_cameras': [
    {'name': 'Front door', 'entityId': 'camera.front_door'},
    {'name': 'Garden', 'entityId': 'camera.garden'},
    {'name': 'Garage', 'entityId': 'camera.garage'},
  ],
  'house_locks': [
    {'name': 'Front door', 'entityId': 'lock.front_door'},
    {'name': 'Back door', 'entityId': 'lock.demo_room_hallway'},
  ],
  'house_scenes': [
    {'name': 'Movie night', 'entityId': 'scene.movie_night'},
    {'name': 'Good night', 'entityId': 'scene.good_night'},
  ],
  'assistant': {'name': 'Nabu', 'wakePhrase': 'Ok Nabu'},
  'family_messages': [
    {
      'id': 'm1',
      'text': 'Gone to pick Inês up from swimming. Dinner is in the oven, just heat it for 10 minutes.',
      'at': _now.subtract(const Duration(minutes: 40)).toUtc().toIso8601String(),
      'to': 'Tiago',
      'from': 'Ana',
    },
    {
      'id': 'm2',
      'text': 'Grandma is coming for dinner on Saturday. Can someone buy flowers?',
      'at': _now.subtract(const Duration(hours: 5)).toUtc().toIso8601String(),
      'from': 'Rui',
      'seen_at': _now.subtract(const Duration(hours: 3)).toUtc().toIso8601String(),
      'seen_by': 'Ana',
    },
    {
      'id': 'm3',
      'text': 'The plumber is coming tomorrow between 9 and 11.',
      'at': _now.subtract(const Duration(days: 1, hours: 2)).toUtc().toIso8601String(),
      'seen_at': _now.subtract(const Duration(days: 1)).toUtc().toIso8601String(),
    },
  ],
};

final _cards = [
  {
    'kind': 'recipe',
    'url': 'https://recipes.example.com/tomato-risotto',
    'image': 'https://img.example/risotto.png',
    'title': 'Creamy tomato and mushroom risotto',
    'site': 'recipes.example.com',
    'rating': 4.7,
    'rating_count': 1280,
    'minutes': 35,
    'servings': '4',
  },
  {
    'kind': 'recipe',
    'url': 'https://cooking.example.org/shakshuka',
    'image': 'https://img.example/shakshuka.png',
    'title': 'One-pan shakshuka',
    'site': 'cooking.example.org',
    'rating': 4.8,
    'rating_count': 960,
    'minutes': 25,
    'servings': '2',
  },
  {
    'kind': 'recipe',
    'url': 'https://food.example.net/veggie-fried-rice',
    'image': 'https://img.example/rice.png',
    'title': 'Vegetable fried rice',
    'site': 'food.example.net',
    'rating': 4.5,
    'rating_count': 410,
    'minutes': 20,
    'servings': '3',
  },
];

/// Home Assistant, answered from the sample household.
class _FakeClient extends HaWebSocketClient {
  final _assistant = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get assistantEvents => _assistant.stream;

  @override
  Future<void> connect(HaConnectionConfig config) async {}

  @override
  Future<Map<String, dynamic>> getConfig() async => {'language': 'en', 'location_name': 'Home'};

  @override
  Future<dynamic> getSettings(String key) async => switch (key) {
    'meal_plan' => _mealPlan,
    'chores' => _chores,
    _ => _settings[key],
  };

  @override
  Future<void> setSettings(String key, dynamic value) async {}

  @override
  Future<List<HaCalendarEvent>> getCalendarEvents(String entityId, {required DateTime start, required DateTime end}) async => [
    for (final e in _events[entityId] ?? const <HaCalendarEvent>[])
      if (e.end.isAfter(start) && e.start.isBefore(end)) e,
  ];

  @override
  Future<List<Map<String, dynamic>>> getTodoItems(String entityId) async => _todos[entityId] ?? const [];

  @override
  Future<List<Map<String, dynamic>>> getWeatherForecasts(String entityId, {String type = 'daily'}) async {
    final f = (_entities()[entityId]?.attributes['forecast'] as List?) ?? const [];
    return [
      for (final m in f.whereType<Map>()) {...m.cast<String, dynamic>(), 'templow': ((m['temperature'] as num) - 9).round()},
    ];
  }

  @override
  Stream<HaConnectionState> get connectionState => Stream.value(HaConnectionState.connected);

  @override
  Future<dynamic> command(String type, [Map<String, dynamic> data = const {}]) async {
    switch (type) {
      case 'energy/get_prefs':
        return _energyPrefs;
      case 'recorder/statistics_during_period':
        return _energyStats(data);
      case 'energy/solar_forecast':
        return _solarForecast();
    }
    if (type != 'conversation/process') return null;
    // The agent shows its web results as cards, then answers.
    _assistant.add({'action': 'cards', 'title': 'Recipes', 'cards': _cards});
    return {
      'conversation_id': 'demo',
      'response': {
        'speech': {
          'plain': {'speech': 'Tonight it’s lasagne at 8 pm. If you fancy a change, here are three quick dinners with what’s in the fridge.'},
        },
      },
    };
  }

  @override
  Future<void> callService(String domain, String service, {Map<String, dynamic>? serviceData, Map<String, dynamic>? target}) async {}

  @override
  Future<Map<String, String>> getAreaByEntityId() async => const {};

  @override
  Future<List<HaArea>> getAreas() async => const [];

  @override
  Future<List<HaFloor>> getFloors() async => const [];
}

final _overrides = [
  haWebSocketClientProvider.overrideWith((ref) => _FakeClient()),
  entitiesProvider.overrideWith(_Entities.new),
  areaByEntityIdProvider.overrideWith((ref) async => const {}),
  connectionConfigProvider.overrideWith((ref) => const HaConnectionConfig(baseUrl: 'http://homeassistant.local:8123', accessToken: 'x')),
  // What the integration's panel would have chosen; read by the settings
  // hydration, which is skipped here.
  settingsHydrationProvider.overrideWith((ref) async {}),
  calendarEntriesProvider.overrideWith((ref) => const [CalendarEntryConfig(entityId: 'calendar.family', color: CalendarColorKey.pink)]),
  // The kiosk's own hydration, minus Home Assistant: straight from the
  // sample settings.
  kioskHydrationProvider.overrideWith((ref) async {
    // Providers can't change others while they're being created.
    await Future<void>.value();
    List<Map<String, dynamic>> list(String key) => (_settings[key] as List).cast<Map<String, dynamic>>();
    List<NamedEntity> named(String key) => list(key).map(NamedEntity.fromJson).toList();
    ref.read(familyConfigProvider.notifier).state = list('family_members').map(FamilyMemberConfig.fromJson).toList();
    ref.read(houseConfigProvider.notifier).state = HouseConfig(scenes: named('house_scenes'), locks: named('house_locks'), cameras: named('house_cameras'));
    ref.read(todoListIdsProvider.notifier).state = [for (final m in list('todo_lists')) m['entityId'] as String];
    ref.read(todoListIconsProvider.notifier).state = (_settings['todo_list_icons'] as Map).cast<String, String>();
    await ref.read(mealPlanProvider.notifier).load();
    await ref.read(choresProvider.notifier).load();
    await ref.read(familyMessagesProvider.notifier).load();
  }),
  temperatureEntityConfigProvider.overrideWith(
    (ref) => const TemperatureEntityConfig(exteriorTempEntityId: 'sensor.weather_station_outdoor_temperature', weatherStateEntityId: 'weather.demo_casa'),
  ),
  energyEntityConfigProvider.overrideWith(
    (ref) => const EnergyEntityConfig(
      gridPowerEntityId: 'sensor.demo_grid_power',
      solarPowerEntityId: 'sensor.demo_solar_power',
      batteryPowerEntityId: 'sensor.demo_battery_power',
      batterySocEntityId: 'sensor.demo_battery_soc',
      homePowerEntityId: 'sensor.demo_home_power',
    ),
  ),
  carsConfigProvider.overrideWith(
    (ref) => const CarsConfig([
      CarConfig(
        name: 'Renault Mégane E-Tech',
        batterySocEntityId: 'sensor.demo_car_left_battery',
        rangeEntityId: 'sensor.demo_car_left_range',
        chargingEntityId: 'binary_sensor.demo_car_left_charging',
      ),
      CarConfig(
        name: 'Mercedes GLC',
        kind: CarKind.fuel,
        homeEntityId: 'device_tracker.demo_glc',
        fuelEntityId: 'sensor.demo_glc_fuel',
        rangeEntityId: 'sensor.demo_glc_range',
        lockEntityId: 'lock.demo_glc',
      ),
    ]),
  ),
  individualSensorsProvider.overrideWith(
    (ref) => const [
      IndividualSensorConfig(
        name: 'Hot water',
        powerEntityId: 'sensor.demo_aqs_power',
        temperatureEntityId: 'sensor.demo_aqs_temperature',
        icon: IndividualSensorIconKey.boiler,
      ),
      IndividualSensorConfig(name: 'Fridge', powerEntityId: 'sensor.demo_fridge_power', icon: IndividualSensorIconKey.fridge),
      IndividualSensorConfig(name: 'TV', powerEntityId: 'sensor.demo_tv_power', icon: IndividualSensorIconKey.tv),
      IndividualSensorConfig(name: 'Washing machine', powerEntityId: 'sensor.demo_washer_power', icon: IndividualSensorIconKey.washer),
    ],
  ),
  areasProvider.overrideWith(
    (ref) => const [
      HaArea(
        areaId: 'living_room',
        name: 'Living room',
        floorId: 'floor0',
        temperatureEntityId: 'sensor.demo_room_living_room_temp',
        humidityEntityId: 'sensor.demo_room_living_room_humidity',
      ),
      HaArea(areaId: 'bedroom', name: 'Bedroom', floorId: 'floor0', temperatureEntityId: 'sensor.demo_room_bedroom_temp'),
      HaArea(areaId: 'office', name: 'Office', floorId: 'floor0', temperatureEntityId: 'sensor.demo_room_office_temp'),
      HaArea(
        areaId: 'kitchen',
        name: 'Kitchen',
        floorId: 'floor0',
        temperatureEntityId: 'sensor.demo_room_kitchen_temp',
        humidityEntityId: 'sensor.demo_room_kitchen_humidity',
      ),
      HaArea(areaId: 'hallway', name: 'Hallway', floorId: 'floor0', temperatureEntityId: 'sensor.demo_room_hallway_temp'),
      HaArea(
        areaId: 'attic',
        name: 'Attic',
        floorId: 'attic',
        temperatureEntityId: 'sensor.demo_room_attic_temp',
        humidityEntityId: 'sensor.demo_room_attic_humidity',
      ),
    ],
  ),
  floorsProvider.overrideWith((ref) => const [HaFloor(floorId: 'floor0', name: 'Ground floor', level: 0), HaFloor(floorId: 'attic', name: 'Attic', level: 1)]),
  roomsProvider.overrideWith(
    (ref) => const [
      RoomConfig(
        areaId: 'living_room',
        secondaryEntityId: 'sensor.demo_room_living_room_humidity',
        lightEntityId: 'light.demo_room_living_room',
        climateEntityId: 'climate.demo_room_living_room',
        coverEntityId: 'cover.demo_room_living_room',
      ),
      RoomConfig(areaId: 'bedroom', windowEntityId: 'binary_sensor.demo_room_bedroom_window', coverEntityId: 'cover.demo_room_bedroom'),
      RoomConfig(areaId: 'office', secondaryEntityId: 'sensor.demo_room_office_co2', climateEntityId: 'climate.demo_room_office'),
      RoomConfig(
        areaId: 'kitchen',
        secondaryEntityId: 'sensor.demo_room_kitchen_humidity',
        lightEntityId: 'light.demo_room_kitchen',
        coverEntityId: 'cover.demo_room_kitchen',
      ),
      RoomConfig(areaId: 'hallway', secondaryEntityId: 'lock.demo_room_hallway'),
      RoomConfig(areaId: 'attic'),
    ],
  ),
];

// ─── Pictures ───────────────────────────────────────────────────────────
// Camera stills and recipe photos, painted here and served to the app's
// image loader in place of the network.

Future<Uint8List> _paint(String name) async {
  if (name.startsWith('art')) return _paintArt(int.parse(name.substring(3)));
  const w = 640.0, h = 360.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  Paint fill(Color color) => Paint()..color = color;
  Paint grad(Offset a, Offset b, List<Color> colors) => Paint()..shader = ui.Gradient.linear(a, b, colors);
  switch (name) {
    case 'camera.front_door':
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), grad(Offset.zero, const Offset(0, h), [const Color(0xFFD9CFC0), const Color(0xFFB8AC9A)]));
      c.drawRect(const Rect.fromLTWH(0, 290, w, 70), fill(const Color(0xFF8E8578)));
      c.drawRect(const Rect.fromLTWH(250, 60, 140, 235), fill(const Color(0xFF5B3A26)));
      c.drawRect(const Rect.fromLTWH(262, 74, 116, 96), fill(const Color(0xFF6E4630)));
      c.drawRect(const Rect.fromLTWH(262, 182, 116, 100), fill(const Color(0xFF6E4630)));
      c.drawCircle(const Offset(370, 185), 6, fill(const Color(0xFFD8B65A)));
      c.drawRect(const Rect.fromLTWH(235, 296, 170, 18), fill(const Color(0xFF3F4A3A)));
      c.drawCircle(
        const Offset(200, 110),
        60,
        Paint()..shader = ui.Gradient.radial(const Offset(200, 110), 60, [const Color(0x66FFF3C4), const Color(0x00FFF3C4)]),
      );
      c.drawRect(const Rect.fromLTWH(192, 96, 16, 26), fill(const Color(0xFF2E2E2E)));
      c.drawRect(const Rect.fromLTWH(460, 230, 70, 65), fill(const Color(0xFF6F8F5A)));
    case 'camera.garden':
      c.drawRect(const Rect.fromLTWH(0, 0, w, 200), grad(Offset.zero, const Offset(0, 200), [const Color(0xFF8FB8DE), const Color(0xFFDCE9F2)]));
      c.drawRect(const Rect.fromLTWH(0, 200, w, 160), grad(const Offset(0, 200), const Offset(0, h), [const Color(0xFF7FA65A), const Color(0xFF557A3A)]));
      for (var x = 0.0; x < w; x += 40) {
        c.drawRect(Rect.fromLTWH(x, 160, 26, 50), fill(const Color(0xFFC9B79C)));
      }
      c.drawRect(const Rect.fromLTWH(455, 120, 22, 120), fill(const Color(0xFF6B4A2E)));
      c.drawCircle(const Offset(466, 105), 70, fill(const Color(0xFF4F7A3A)));
      c.drawCircle(const Offset(430, 130), 45, fill(const Color(0xFF5C8A43)));
      c.drawOval(const Rect.fromLTWH(90, 260, 160, 40), fill(const Color(0xFF8C6B4A)));
      c.drawCircle(const Offset(120, 270), 14, fill(const Color(0xFFD9534F)));
      c.drawCircle(const Offset(170, 266), 14, fill(const Color(0xFFF0C24B)));
      c.drawCircle(const Offset(215, 272), 14, fill(const Color(0xFFD9534F)));
    case 'camera.garage':
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), grad(Offset.zero, const Offset(0, h), [const Color(0xFF9EA3A8), const Color(0xFF7C8186)]));
      c.drawRect(const Rect.fromLTWH(0, 280, w, 80), fill(const Color(0xFF5E6266)));
      c.drawRect(const Rect.fromLTWH(140, 70, 360, 215), fill(const Color(0xFFE4E6E8)));
      for (var y = 70.0; y < 285; y += 36) {
        c.drawRect(Rect.fromLTWH(140, y, 360, 3), fill(const Color(0xFFB9BDC1)));
      }
      c.drawRect(const Rect.fromLTWH(130, 60, 380, 10), fill(const Color(0xFF4A4E52)));
    case 'visitor' || 'courier':
      // The door camera's wide view of the landing, someone at the door.
      final courier = name == 'courier';
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), grad(Offset.zero, const Offset(0, h), [const Color(0xFFCFC8BC), const Color(0xFFA79F92)]));
      c.drawRect(const Rect.fromLTWH(0, 280, w, 80), fill(const Color(0xFF7D766C)));
      c.drawRect(const Rect.fromLTWH(40, 40, 120, 240), fill(const Color(0xFF8A7F70)));
      c.drawRect(const Rect.fromLTWH(480, 40, 120, 240), fill(const Color(0xFF8A7F70)));
      final body = courier ? const Color(0xFFC9772B) : const Color(0xFF3E5C76);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(250, 170, 140, 190), const Radius.circular(60)), fill(body));
      c.drawCircle(const Offset(320, 130), 48, fill(const Color(0xFFE0B48F)));
      c.drawArc(const Rect.fromLTWH(272, 80, 96, 80), math.pi, math.pi, true, fill(courier ? const Color(0xFF2B2B2B) : const Color(0xFF5A3D2B)));
      if (courier) {
        c.drawRect(const Rect.fromLTWH(285, 240, 110, 80), fill(const Color(0xFFB9925E)));
        c.drawRect(const Rect.fromLTWH(285, 270, 110, 6), fill(const Color(0xFF8F6E43)));
      }
      // A fisheye vignette, as door cameras have.
      c.drawRect(
        const Rect.fromLTWH(0, 0, w, h),
        Paint()..shader = ui.Gradient.radial(const Offset(w / 2, h / 2), 380, [const Color(0x00000000), const Color(0x99000000)], [0.55, 1]),
      );
    default:
      // A dish seen from above.
      final (base, dots) = switch (name) {
        'risotto' => (const Color(0xFFE59A5B), const Color(0xFF8B5E3C)),
        'shakshuka' => (const Color(0xFFC0392B), const Color(0xFFF7DC6F)),
        'lasagne' => (const Color(0xFFD9822B), const Color(0xFFF3E3B5)),
        _ => (const Color(0xFFE8C872), const Color(0xFF6AA84F)),
      };
      c.drawRect(const Rect.fromLTWH(0, 0, w, h), fill(const Color(0xFF6D5847)));
      c.drawCircle(const Offset(w / 2, h / 2), 150, fill(const Color(0xFFF4F1EC)));
      c.drawCircle(const Offset(w / 2, h / 2), 118, fill(base));
      for (var i = 0; i < 14; i++) {
        final a = i * 0.9, r = 30.0 + (i * 37) % 80;
        c.drawCircle(Offset(w / 2 + r * math.cos(a), h / 2 + r * math.sin(a)), 11, fill(dots));
      }
  }
  final image = await rec.endRecording().toImage(w.toInt(), h.toInt());
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

/// Album art: soft gradients and shapes, a different palette each.
Future<Uint8List> _paintArt(int i) async {
  const size = 400.0;
  const palettes = [
    [Color(0xFFF6A35C), Color(0xFFC2410C)],
    [Color(0xFF6CB8A8), Color(0xFF1F4D45)],
    [Color(0xFF9BB7F0), Color(0xFF3B5BA9)],
    [Color(0xFFF2C14E), Color(0xFFB7791F)],
    [Color(0xFFC4A1F2), Color(0xFF6B46C1)],
    [Color(0xFFF59EAE), Color(0xFFB83250)],
    [Color(0xFFA7D3A6), Color(0xFF3F7D3C)],
    [Color(0xFF8FD3E8), Color(0xFF1F6F8B)],
    [Color(0xFFE8C9A0), Color(0xFF7A5230)],
    [Color(0xFFB0B7C3), Color(0xFF39404D)],
  ];
  final colors = palettes[i % palettes.length];
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(size, size), colors));
  final light = Paint()..color = const Color(0x40FFFFFF);
  switch (i % 3) {
    case 0:
      c.drawCircle(const Offset(size * 0.65, size * 0.38), size * 0.22, light);
    case 1:
      for (var k = 0; k < 5; k++) {
        c.drawRect(Rect.fromLTWH(0, size * (0.45 + k * 0.1), size, size * 0.04), light);
      }
    default:
      c.drawPath(
        Path()
          ..moveTo(0, size)
          ..lineTo(size * 0.45, size * 0.4)
          ..lineTo(size * 0.7, size * 0.7)
          ..lineTo(size, size * 0.35)
          ..lineTo(size, size)
          ..close(),
        light,
      );
  }
  final image = await rec.endRecording().toImage(size.toInt(), size.toInt());
  return (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

final _pictures = <String, Uint8List>{};

String _pictureFor(Uri uri) {
  final cam = RegExp(r'camera\.\w+').firstMatch(uri.path)?.group(0);
  return cam ?? uri.pathSegments.last.replaceAll('.png', '');
}

class _Http implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _Request(_pictures[_pictureFor(url)] ?? Uint8List(0));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Request implements HttpClientRequest {
  _Request(this._bytes);

  final Uint8List _bytes;

  @override
  Future<HttpClientResponse> close() async => _Response(_bytes);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this._bytes);

  final Uint8List _bytes;

  @override
  int get statusCode => _bytes.isEmpty ? 404 : 200;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.value(_bytes).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ─── Home Assistant's Energy dashboard ──────────────────────────────────

const _energyPrefs = {
  'energy_sources': [
    {'type': 'solar', 'stat_energy_from': 'sensor.solar_energy'},
    {'type': 'battery', 'stat_energy_from': 'sensor.battery_out', 'stat_energy_to': 'sensor.battery_in', 'capacity': 10},
    {
      'type': 'grid',
      'stat_energy_from': 'sensor.grid_in',
      'stat_energy_to': 'sensor.grid_out',
      'number_energy_price': 0.18,
      'number_energy_price_export': 0.07,
    },
  ],
};

double _sun(double h) => 2.2 * math.exp(-math.pow(h - 13, 2) / 14);

/// kWh in one hour of a sunny day, per statistic.
double _hourly(String id, double h) => switch (id) {
  'sensor.solar_energy' => _sun(h),
  'sensor.grid_in' => h < 7 || h > 20 ? 0.35 : (h >= 10 && h <= 16 ? 0.02 : 0.25),
  'sensor.grid_out' => h >= 11 && h <= 15 ? 0.7 : 0.0,
  'sensor.battery_in' => h >= 9 && h <= 14 ? 0.55 : 0.0,
  'sensor.battery_out' => h >= 18 && h <= 23 ? 0.45 : 0.0,
  _ => 0.0,
};

Map<String, List<Map<String, num>>> _energyStats(Map<String, dynamic> data) {
  final start = DateTime.parse(data['start_time'] as String).toLocal();
  final end = data['end_time'] == null ? _now : DateTime.parse(data['end_time'] as String).toLocal();
  final period = data['period'] as String;
  final ids = (data['statistic_ids'] as List).cast<String>();
  final step = switch (period) {
    'day' => const Duration(days: 1),
    '5minute' => const Duration(minutes: 5),
    _ => const Duration(hours: 1),
  };
  return {
    for (final id in ids)
      id: [
        for (var t = start; t.isBefore(end); t = t.add(step))
          {
            'start': t.millisecondsSinceEpoch,
            'change': switch (period) {
              'day' => [for (var h = 0; h < 24; h++) _hourly(id, h.toDouble())].reduce((a, b) => a + b) * (0.8 + 0.05 * (t.day % 5)),
              '5minute' => _hourly(id, t.hour + t.minute / 60) / 12,
              _ => _hourly(id, t.hour.toDouble()),
            },
          },
      ],
  };
}

Map<String, dynamic> _solarForecast() => {
  'forecast': {
    'wh_hours': {
      for (var d = 0; d < 7; d++)
        for (var h = 6; h <= 20; h++)
          _today.add(Duration(days: d, hours: h)).toUtc().toIso8601String(): (_sun(h.toDouble()) * 1000 * (1 - 0.08 * (d % 4))).round(),
    },
  },
};

// ─── Music Assistant ────────────────────────────────────────────────────

Map<String, dynamic> _art(int i) => {'path': 'https://img.example/art$i.png', 'remotely_accessible': true};

Map<String, dynamic> _item(String type, String name, int art, {String? artist, String? album, int? duration}) => {
  'uri': 'library://$type/${name.toLowerCase().replaceAll(' ', '_')}',
  'media_type': type,
  'name': name,
  'item_id': name.hashCode.abs().toString(),
  'provider': 'library',
  'provider_mappings': [
    {'provider_domain': type == 'radio' ? 'tunein' : 'spotify'},
  ],
  'artists': [
    if (artist != null) {'name': artist, 'uri': 'library://artist/$artist', 'item_id': artist.hashCode.abs().toString(), 'provider': 'library'},
  ],
  if (album case final a?) 'album': {'name': a, 'uri': 'library://album/$a'},
  if (duration case final d?) 'duration': d,
  'favorite': art.isEven,
  'image': _art(art),
};

final _track = _item('track', 'Golden Hour', 0, artist: 'The Lanterns', album: 'Summer Rooms', duration: 238);
final _nextTrack = _item('track', 'Paper Boats', 3, artist: 'Mira Vale', album: 'Low Tide', duration: 201);

final _ma = <String, Object>{
  'players/all': [
    for (final (id, name, model) in [('living', 'Living room', 'Sonos One'), ('kitchen', 'Kitchen', 'HomePod mini'), ('bedroom', 'Bedroom', 'Echo Dot')])
      {
        'player_id': id,
        'display_name': name,
        'available': true,
        'volume_level': id == 'living' ? 35 : 20,
        'type': 'player',
        'provider': 'sonos',
        'device_info': {'model': model, 'manufacturer': ''},
        'can_group_with': ['living', 'kitchen', 'bedroom'],
        'group_members': id == 'living' ? ['living', 'kitchen'] : const [],
      },
  ],
  'player_queues/all': [
    {
      'queue_id': 'living',
      // Paused: playing puts "♪ Golden Hour" in the header, and the test
      // has no font with "♪" (the screen falls back to a system font).
      'state': 'paused',
      'shuffle_enabled': false,
      'repeat_mode': 'off',
      'elapsed_time': 84.0,
      'elapsed_time_last_updated': DateTime.now().millisecondsSinceEpoch / 1000,
      'items': 14,
      'current_index': 3,
      'current_item': {'queue_item_id': 'q3', 'name': 'Golden Hour', 'duration': 238, 'media_item': _track},
      'next_item': {'queue_item_id': 'q4', 'name': 'Paper Boats', 'duration': 201, 'media_item': _nextTrack},
    },
  ],
  'music/recently_played_items': [
    _item('playlist', 'Sunday Morning', 1),
    _item('album', 'Summer Rooms', 0, artist: 'The Lanterns'),
    _item('radio', 'Coastal FM', 7),
    _item('playlist', 'Dinner Jazz', 8),
    _item('podcast', 'The Kitchen Table', 3),
    _item('artist', 'Mira Vale', 5),
  ],
  'music/playlists/library_items': [
    _item('playlist', 'Sunday Morning', 1),
    _item('playlist', 'Dinner Jazz', 8),
    _item('playlist', 'Focus', 2),
    _item('playlist', 'Kids\' Party', 4),
    _item('playlist', 'Road Trip', 6),
    _item('playlist', 'Sleepy Time', 9),
  ],
  'music/radios/library_items': [_item('radio', 'Coastal FM', 7), _item('radio', 'City Jazz Radio', 2), _item('radio', 'Classic Hits', 5)],
  'music/podcasts/library_items': [_item('podcast', 'The Kitchen Table', 3), _item('podcast', 'Tiny Science', 6)],
  'music/artists/library_items': [
    _item('artist', 'The Lanterns', 0),
    _item('artist', 'Mira Vale', 5),
    _item('artist', 'North Shore Trio', 2),
    _item('artist', 'Ana Lua', 4),
  ],
  'player_queues/items': [
    {'queue_item_id': 'q4', 'name': 'Paper Boats', 'duration': 201, 'media_item': _nextTrack},
    {'queue_item_id': 'q5', 'name': 'Lighthouse', 'duration': 187, 'media_item': _item('track', 'Lighthouse', 6, artist: 'North Shore Trio', duration: 187)},
  ],
};

class _FakeMa extends MaClient {
  _FakeMa(super.ha, super.config);

  @override
  void start() => state.value = MaConnectionState.connected;

  @override
  Future<void> stop() async {}

  @override
  Future<dynamic> call(String command, [Map<String, dynamic>? args]) async => _ma[command] ?? const [];

  @override
  String? imageUrl(MaImage? image) => image?.path;
}

final _musicOverride = maClientProvider.overrideWith(
  (ref) => _FakeMa(ref.watch(haWebSocketClientProvider), const HaConnectionConfig(baseUrl: 'http://homeassistant.local:8123', accessToken: 'x'))..start(),
);

// ─── Intercom ───────────────────────────────────────────────────────────

class _Station implements DoorStation {
  @override
  Future<Uint8List?> snapshot({int? channel, bool full = false}) async => _pictures['visitor'];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A few days of rings, with the picture of who rang.
class _CallStore implements DoorbellHistoryStore {
  @override
  Future<String?> load() async {
    Map<String, Object> call(String id, Duration ago, {bool answered = false, bool opened = false, bool indoor = false}) {
      final at = _now.subtract(ago);
      return {
        'id': id,
        'at': at.millisecondsSinceEpoch,
        'endedAt': at.add(const Duration(seconds: 40)).millisecondsSinceEpoch,
        if (answered) 'answeredAt': at.add(const Duration(seconds: 6)).millisecondsSinceEpoch,
        'answeredHere': answered && !indoor,
        'answeredIndoor': indoor,
        'doorOpened': opened,
        'hasPicture': true,
      };
    }

    return jsonEncode({
      'seenUntil': _now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
      'calls': [
        call('c1', const Duration(minutes: 25)),
        call('c2', const Duration(hours: 3), answered: true, opened: true),
        call('c3', const Duration(hours: 26), answered: true, indoor: true),
        call('c4', const Duration(days: 2, hours: 4), answered: true, opened: true),
      ],
    });
  }

  @override
  Future<Uint8List?> loadPicture(String id) async => _pictures[id == 'c2' || id == 'c4' ? 'courier' : 'visitor'];

  @override
  Future<void> save(String json) async {}

  @override
  Future<void> savePicture(String id, Uint8List jpeg) async {}

  @override
  Future<void> deletePicture(String id) async {}
}

class _Intercom extends IntercomController {
  late final _history = DoorbellHistory(station: _Station(), statuses: const Stream.empty(), storage: _CallStore());

  @override
  bool get connected => true;

  @override
  Widget? videoView() => Image.memory(_pictures['visitor']!, fit: BoxFit.cover, gaplessPlayback: true);

  @override
  ValueListenable<IntercomVideoStatus>? get videoStatus => ValueNotifier(IntercomVideoStatus.live);

  @override
  Future<Uint8List?> snapshot() async => _pictures['visitor'];

  @override
  DoorbellHistory? get history => _history;

  @override
  Future<void> answer() async {}

  @override
  Future<void> hangUp() async {}

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> unlock() async {}
}

// ─── The board's own network, kept out of Settings ──────────────────────

final class _NoNetwork extends IOOverrides {
  @override
  Directory createDirectory(String path) => path == '/sys/class/net' ? super.createDirectory('/nonexistent-net') : super.createDirectory(path);
}

// ─── Drawing ────────────────────────────────────────────────────────────

Future<void> _fonts() async {
  for (final (family, name, files) in [
    ('DM Sans', 'DMSans', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ('Outfit', 'Outfit', ['Regular', 'Medium', 'SemiBold']),
  ]) {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(rootBundle.load('assets/fonts/$name-$f.ttf'));
    }
    await l.load();
  }
}

Future<void> _pump(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Renders [child] (the kiosk by default) on the 1440×2560 canvas, lets
/// [prepare] move it to the right page or state, and saves it as [name].
Future<void> _shot(
  WidgetTester tester,
  String name, {
  Widget child = const KioskShell(),
  bool dark = false,
  List<Override> extra = const [],
  Map<String, Object> prefs = const {},
  Future<void> Function(WidgetTester tester, ProviderContainer container)? prepare,
}) async {
  await tester.runAsync(_fonts);
  if (_pictures.isEmpty) {
    await tester.runAsync(() async {
      for (final n in [
        'camera.front_door',
        'camera.garden',
        'camera.garage',
        'risotto',
        'shakshuka',
        'rice',
        'lasagne',
        'visitor',
        'courier',
        for (var i = 0; i < 10; i++) 'art$i',
      ]) {
        _pictures[n] = await _paint(n);
      }
    });
  }
  debugNetworkImageHttpClientProvider = _Http.new;
  SharedPreferences.setMockInitialValues({'app_language': 'en', ...prefs});
  await tester.runAsync(() => LocaleController.instance.load());
  ThemeModeController.instance.settings.value = ThemeSettings(preference: dark ? ThemePreference.dark : ThemePreference.light);
  ThemeModeController.instance.mode.value = dark ? Brightness.dark : Brightness.light;
  tester.view.physicalSize = const Size(1440, 2560);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (d) {
    if (Platform.environment['SCREENSHOTS_DEBUG'] == '1' && errors.isEmpty) debugPrint(d.toString().split('\n').take(40).join('\n'));
    errors.add(d.exceptionAsString().split('\n').first);
  };
  final key = GlobalKey();
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._overrides, ...extra],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // Around the navigator, so modals are in the picture too.
          builder: (context, navigator) => RepaintBoundary(key: key, child: navigator),
          home: child,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await _pump(tester, 10);
  final container = ProviderScope.containerOf(key.currentContext!);
  if (prepare != null) await prepare(tester, container);
  // Data arrives through futures; let them land and the pages settle.
  for (var i = 0; i < 4; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await _pump(tester, 10);
  }
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 0.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(_out).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
  FlutterError.onError = previous;
  // ignore: avoid_print
  print('$name: ${errors.isEmpty ? 'ok' : errors.toSet().join(' | ')}');
  // Unmount before the next test, so timers and the kitchen session stop.
  await tester.pumpWidget(const SizedBox());
  KitchenSession.instance.end();
  AssistantModal.isOpen = false;
  // Painting debug hooks must be unset before the test body ends.
  debugNetworkImageHttpClientProvider = null;
}

Future<void> Function(WidgetTester, ProviderContainer) _page(KioskPage page) => (tester, container) async {
  container.read(kioskPageProvider.notifier).state = page;
  await _pump(tester, 10);
};

void main() {
  testWidgets('home', (t) => _shot(t, 'home'), skip: _skip);
  testWidgets('home_dark', (t) => _shot(t, 'home_dark', dark: true), skip: _skip);
  testWidgets('calendar', (t) => _shot(t, 'calendar', prepare: _page(KioskPage.calendar)), skip: _skip);
  testWidgets('meals', (t) => _shot(t, 'meals', prepare: _page(KioskPage.meals)), skip: _skip);
  testWidgets('house', (t) => _shot(t, 'house', prepare: _page(KioskPage.house)), skip: _skip);
  testWidgets(
    'assistant',
    (t) => _shot(
      t,
      'assistant',
      prepare: (tester, container) async {
        unawaited(showAssistant(tester.element(find.byType(KioskShell))));
        await _pump(tester, 10);
        await tester.tap(find.text(l10n.assistantSuggestDinner));
        // No voice assistant in a test: the satellite would stay "listening".
        VoiceSatellite.instance.phase.value = SatellitePhase.idle;
        // The answer is written out as it would be spoken.
        for (var i = 0; i < 8; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
          VoiceSatellite.instance.phase.value = SatellitePhase.idle;
          await _pump(tester, 20);
        }
      },
    ),
    skip: _skip,
  );
  testWidgets('cooking', (t) {
    KitchenSession.instance.start(
      KitchenRecipe({
        'url': 'https://recipes.example.com/lasagne',
        'title': 'Classic lasagne',
        'servings': '4',
        'minutes': 75,
        'ingredients': [
          '500 g minced beef',
          '1 onion',
          '2 garlic cloves',
          '700 g tomato passata',
          '12 lasagne sheets',
          '500 ml béchamel sauce',
          '100 g grated parmesan',
        ],
        'steps': [
          'Chop the onion and garlic finely.',
          'Brown the beef with the onion and garlic over a medium heat.',
          'Add the passata, season and let it simmer for 20 minutes, stirring now and then.',
          'Layer sheets, sauce and béchamel in a baking dish, three times over.',
          'Top with parmesan and bake at 190 °C for 35 minutes.',
        ],
        'step': 3,
      }),
    );
    KitchenSession.instance.startTimer(2);
    return _shot(t, 'cooking', child: const Material(child: KitchenModal()));
  }, skip: _skip);
  testWidgets('tasks', (t) => _shot(t, 'tasks', prepare: _page(KioskPage.tasks)), skip: _skip);
  testWidgets('lists', (t) => _shot(t, 'lists', prepare: _page(KioskPage.lists)), skip: _skip);
  testWidgets(
    'messages',
    (t) => _shot(
      t,
      'messages',
      prepare: (tester, container) async {
        container.read(selectedListProvider.notifier).state = recadosListId;
        await _page(KioskPage.lists)(tester, container);
      },
    ),
    skip: _skip,
  );
  // A speaker already chosen, as on a screen that has played before.
  testWidgets(
    'music',
    (t) => _shot(t, 'music', extra: [_musicOverride], prefs: {'music_target_player': 'living'}, prepare: _page(KioskPage.music)),
    skip: _skip,
  );
  testWidgets(
    'intercom',
    (t) => _shot(
      t,
      'intercom',
      extra: [intercomControllerProvider.overrideWithValue(_Intercom())],
      prepare: (tester, container) async {
        unawaited(showIntercom(tester.element(find.byType(KioskShell)), mode: IntercomMode.ringing));
        await _pump(tester, 20);
      },
    ),
    skip: _skip,
  );
  testWidgets(
    'intercom_history',
    (t) => _shot(
      t,
      'intercom_history',
      extra: [intercomControllerProvider.overrideWithValue(_Intercom())],
      prepare: (tester, container) async {
        unawaited(showIntercom(tester.element(find.byType(KioskShell)), history: true));
        await _pump(tester, 20);
      },
    ),
    skip: _skip,
  );
  testWidgets(
    'energy',
    (t) => _shot(
      t,
      'energy',
      prepare: (tester, container) async {
        container.read(kioskPageProvider.notifier).state = KioskPage.house;
        await _pump(tester, 10);
        unawaited(showEnergyModal(tester.element(find.byType(KioskShell))));
        await _pump(tester, 20);
      },
    ),
    skip: _skip,
  );
  testWidgets(
    'settings',
    (t) => IOOverrides.runWithIOOverrides(() => _shot(t, 'settings', extra: [_musicOverride], prepare: _page(KioskPage.settings)), _NoNetwork()),
    skip: _skip,
  );
  // Last: the browser stays open across tests (its state is app-wide).
  testWidgets(
    'browser',
    (t) => _shot(
      t,
      'browser',
      prefs: {
        'browser_favorites': jsonEncode([
          {'name': 'Recipes', 'url': 'https://recipes.example.com'},
          {'name': 'School', 'url': 'https://school.example.org'},
          {'name': 'News', 'url': 'https://news.example.com'},
          {'name': 'Weather', 'url': 'https://weather.example.com'},
          {'name': 'Bus times', 'url': 'https://transit.example.com'},
          {'name': 'Library', 'url': 'https://library.example.org'},
        ]),
        'browser_recent': jsonEncode([
          {'title': 'Classic lasagne', 'url': 'https://recipes.example.com/lasagne', 'at': _now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch},
          {'title': 'Term dates', 'url': 'https://school.example.org/term-dates', 'at': _now.subtract(const Duration(hours: 20)).millisecondsSinceEpoch},
        ]),
      },
      prepare: (tester, container) async {
        Browser.open(tester.element(find.byType(KioskShell)), mode: BrowserMode.window);
        await _pump(tester, 20);
      },
    ),
    skip: _skip,
  );
  testWidgets('bubbles', (t) {
    KitchenSession.instance.start(
      KitchenRecipe({
        'url': 'https://recipes.example.com/lasagne',
        'title': 'Classic lasagne',
        'image': 'https://img.example/lasagne.png',
        'steps': ['Chop the onion.', 'Brown the beef.', 'Simmer the sauce for 20 minutes.', 'Layer and bake.'],
        'ingredients': ['500 g minced beef', '1 onion'],
        'step': 3,
      }),
    );
    KitchenSession.instance.startTimer(2);
    KitchenSession.instance.minimized = true;
    return _shot(
      t,
      'bubbles',
      prepare: (tester, container) async {
        Browser.open(tester.element(find.byType(KioskShell)), url: null, mode: BrowserMode.window);
        await _pump(tester, 20);
        await tester.tap(find.byWidgetPredicate((w) => w is KIcon && w.svg == '<path d="M6 12h12"/>').first);
        await _pump(tester, 20);
      },
    );
  }, skip: _skip);
}
