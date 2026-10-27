import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import 'assistant_config.dart';
import 'casa_data.dart';
import 'chores_data.dart';
import 'family_data.dart';
import 'house_config.dart';
import 'meals_data.dart';
import 'messages_data.dart';
import 'todo_data.dart';
import 'vacuum_data.dart';

/// Loads the redesign's own config and data from HA once connected — same
/// shape and reasoning as `settingsHydrationProvider` (each read is
/// independently try/caught, so one missing key never blocks the screen).
final kioskHydrationProvider = FutureProvider<void>((ref) async {
  await haReady(ref);

  try {
    // The app's language follows Home Assistant's unless Definições fixes one.
    LocaleController.instance.setHaLanguage((await ref.read(haWebSocketClientProvider).getConfig())['language'] as String?);
  } catch (_) {
    // Stays on the saved choice, or English.
  }
  try {
    ref.read(familyConfigProvider.notifier).state = await ref.read(savedFamilyProvider.future);
  } catch (_) {
    // Nobody yet — tasks and events show without a person.
  }
  try {
    ref.read(houseConfigProvider.notifier).state = await ref.read(savedHouseConfigProvider.future);
  } catch (_) {
    // Casa sections show their "configure in the panel" hints.
  }
  try {
    ref.read(vacuumConfigProvider.notifier).state = await ref.read(savedVacuumConfigProvider.future);
  } catch (_) {
    // No Aspiradores card.
  }
  try {
    ref.read(weatherStationProvider.notifier).state = await ref.read(savedWeatherStationProvider.future);
  } catch (_) {
    // The Exterior card shows the temperature only.
  }
  try {
    ref.read(todoListIdsProvider.notifier).state = await ref.read(savedTodoListIdsProvider.future);
  } catch (_) {
    // No lists until the integration has some.
  }
  try {
    final icons = await ref.read(savedTodoListIconsProvider.future);
    if (icons.isNotEmpty) ref.read(todoListIconsProvider.notifier).state = icons;
  } catch (_) {
    // Icons are guessed from list names.
  }
  try {
    ref.read(assistantConfigProvider.notifier).state = await ref.read(savedAssistantConfigProvider.future);
  } catch (_) {
    // Keeps the default name.
  }
  try {
    await ref.read(mealPlanProvider.notifier).load();
  } catch (_) {
    // An empty plan — every cell offers "Planear".
  }
  try {
    await ref.read(choresProvider.notifier).load();
  } catch (_) {
    // No tasks yet.
  }
  try {
    await ref.read(familyMessagesProvider.notifier).load();
  } catch (_) {
    // No messages shown.
  }
});
