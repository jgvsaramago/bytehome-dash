import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ha_client/ha_websocket_client.dart';
import '../../providers/calendar_entities_provider.dart';
import '../../providers/energy_entities_provider.dart';
import '../../providers/ev_cars_provider.dart';
import '../../providers/ha_providers.dart';
import '../../providers/individual_sensors_provider.dart';
import '../../providers/rooms_provider.dart';
import '../../providers/temperature_entities_provider.dart';
import 'assistant_config.dart';
import 'calendar_data.dart';
import 'casa_data.dart';
import 'chores_data.dart';
import 'family_data.dart';
import 'house_config.dart';
import 'meals_data.dart';
import 'messages_data.dart';
import 'todo_data.dart';
import 'vacuum_data.dart';

/// Applies a setting saved in HA's sidebar panel as soon as it's saved,
/// instead of at the next restart: re-reads just that key and swaps it in.
/// Watched by the shell, so it lives as long as the app.
///
/// Tasks and list icons aren't here — this screen edits those itself, and
/// they already reload whenever their page is opened. Meals are, because
/// the conversation agent plans them too (add_to_meal_plan).
final settingsLiveReloadProvider = Provider<void>((ref) {
  final sub = ref.watch(haWebSocketClientProvider).settingsUpdates.listen((key) {
    _reload(ref, key).catchError((Object e) => debugPrint('[settings] live reload of $key failed: $e'));
  });
  ref.onDispose(sub.cancel);
});

const _keys = [
  'family_members',
  'calendar_entities',
  'temperature_entities',
  'rooms',
  'house_screen',
  'energy_entities',
  'individual_sensors',
  'weather_station',
  'todo_lists',
  'assistant',
  'ev_cars',
  'vacuums',
];

Future<void> _reload(Ref ref, String key) async {
  if (key == 'meal_plan') {
    await ref.read(mealPlanProvider.notifier).load();
    return;
  }
  // Also written by the assistant's tools (integration), not only screens.
  if (key == 'chores') {
    await ref.read(choresProvider.notifier).load();
    return;
  }
  if (key == 'family_messages') {
    await ref.read(familyMessagesProvider.notifier).load();
    return;
  }
  if (key == HaWebSocketClient.allSettings) {
    await Future.wait([for (final k in _keys) _reload(ref, k)]);
    return;
  }
  Future<T> fresh<T>(FutureProvider<T> saved) {
    ref.invalidate(saved);
    return ref.read(saved.future);
  }

  switch (key) {
    case 'family_members':
      ref.read(familyConfigProvider.notifier).state = await fresh(savedFamilyProvider);
      ref.read(calendarRefreshProvider.notifier).state++;
    case 'calendar_entities':
      ref.read(calendarEntriesProvider.notifier).state = await fresh(savedCalendarEntriesProvider);
      ref.read(calendarRefreshProvider.notifier).state++;
    case 'temperature_entities':
      ref.read(temperatureEntityConfigProvider.notifier).state = await fresh(savedTemperatureEntityConfigProvider);
    case 'rooms':
      ref.read(roomsProvider.notifier).state = await fresh(savedRoomsProvider);
    case 'house_screen' || 'house_scenes' || 'house_locks' || 'house_cameras':
      ref.read(houseConfigProvider.notifier).state = await fresh(savedHouseConfigProvider);
    case 'energy_entities':
      ref.read(energyEntityConfigProvider.notifier).state = await fresh(savedEnergyEntityConfigProvider);
    case 'individual_sensors':
      ref.read(individualSensorsProvider.notifier).state = await fresh(savedIndividualSensorsProvider);
    case 'weather_station':
      ref.read(weatherStationProvider.notifier).state = await fresh(savedWeatherStationProvider);
    case 'todo_lists':
      ref.read(todoListIdsProvider.notifier).state = await fresh(savedTodoListIdsProvider);
    case 'assistant':
      ref.read(assistantConfigProvider.notifier).state = await fresh(savedAssistantConfigProvider);
    case 'vacuums' || 'vacuum_entities':
      ref.read(vacuumConfigProvider.notifier).state = await fresh(savedVacuumConfigProvider);
    case 'ev_cars':
      ref.read(carsConfigProvider.notifier).state = await fresh(savedCarsConfigProvider);
  }
}
