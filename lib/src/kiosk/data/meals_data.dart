import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ha_client/ha_websocket_client.dart';
import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import 'dates.dart';

enum MealType {
  pa(8 * 60),
  almoco(13 * 60),
  jantar(20 * 60);

  const MealType(this.defaultMinutes);

  final int defaultMinutes;

  String get label => switch (this) {
    MealType.pa => l10n.mealsBreakfast,
    MealType.almoco => l10n.mealsLunch,
    MealType.jantar => l10n.mealsDinner,
  };

  String get caps => label.toUpperCase();
}

/// Where a meal happens — drives the dot colour in the week grid.
enum MealPlace {
  casa,
  fora,
  encomenda;

  String get label => switch (this) {
    MealPlace.casa => l10n.mealsPlaceHome,
    MealPlace.fora => l10n.mealsPlaceOut,
    MealPlace.encomenda => l10n.mealsPlaceDelivery,
  };
}

class Meal {
  const Meal({required this.dish, this.place = MealPlace.casa, required this.time, this.note = '', this.url, this.image});

  final String dish;
  final MealPlace place;

  /// "HH:MM"
  final String time;
  final String note;

  /// The recipe's page and picture, when it was planned from a web result
  /// (the Assistente's "põe a terceira no jantar de quinta").
  final String? url;
  final String? image;

  Map<String, dynamic> toJson() => {
    'dish': dish,
    'where': place.name,
    'time': time,
    if (note.isNotEmpty) 'note': note,
    if (url != null) 'url': url,
    if (image != null) 'image': image,
  };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
    dish: json['dish'] as String? ?? '',
    place: MealPlace.values.firstWhere((p) => p.name == json['where'], orElse: () => MealPlace.casa),
    time: json['time'] as String? ?? '20:00',
    note: json['note'] as String? ?? '',
    url: json['url'] as String?,
    image: json['image'] as String?,
  );
}

String mealKey(DateTime day, MealType type) => '${KDates.key(day)}|${type.name}';

/// The family's meal plan — one entry per day and meal, kept by the kiosk
/// in the `bytehomedash` integration's shared settings store
/// (`meal_plan`), so every screen in the house sees the same week.
class MealPlanNotifier extends StateNotifier<Map<String, Meal>> {
  MealPlanNotifier(this._client) : super(const {});

  final HaWebSocketClient _client;

  static const _key = 'meal_plan';

  /// Days older than this are dropped on save, so the stored plan doesn't
  /// grow forever — still long enough to learn favourite dishes from.
  static const _keepDays = 180;

  Future<void> load() async {
    final raw = await _client.getSettings(_key);
    if (raw is! Map) return;
    state = {
      for (final e in raw.entries)
        if (e.value is Map) e.key.toString(): Meal.fromJson((e.value as Map).cast<String, dynamic>()),
    };
  }

  Future<void> put(DateTime day, MealType type, Meal? meal) async {
    final next = Map<String, Meal>.from(state);
    final key = mealKey(day, type);
    if (meal == null) {
      next.remove(key);
    } else {
      next[key] = meal;
    }
    final cutoff = KDates.key(addDays(DateTime.now(), -_keepDays));
    next.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    final before = state;
    state = next;
    try {
      await _client.setSettings(_key, {for (final e in next.entries) e.key: e.value.toJson()}).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Not saved: show the plan as it was (unless something newer landed).
      if (identical(state, next)) state = before;
      rethrow;
    }
  }
}

final mealPlanProvider = StateNotifierProvider<MealPlanNotifier, Map<String, Meal>>((ref) => MealPlanNotifier(ref.watch(haWebSocketClientProvider)));

Map<MealType, List<String>> get _defaultFavorites => {
  MealType.pa: [l10n.mealsDishToastFruit, l10n.mealsDishOatPancakes, l10n.mealsDishYogurtGranola, l10n.mealsDishPorridge, l10n.mealsDishScrambledEggs],
  MealType.almoco: [l10n.mealsDishSoupSandwich, l10n.mealsDishTunaSalad, l10n.mealsDishBitoque, l10n.mealsDishVegetablePasta, l10n.mealsDishGrilledChicken],
  MealType.jantar: [
    l10n.mealsDishBacalhauBras,
    l10n.mealsDishDuckRice,
    l10n.mealsDishBolognese,
    l10n.mealsDishRoastChicken,
    l10n.mealsDishVegetableSoup,
    l10n.mealsDishGrilledSalmon,
    l10n.mealsDishLasagne,
    l10n.mealsDishPizza,
  ],
};

/// Favourite dishes for one meal: what this family actually plans most
/// often for it, topped up with the design's suggestions.
List<String> mealFavorites(Map<String, Meal> plan, MealType type, {int count = 8}) {
  final counts = <String, int>{};
  for (final e in plan.entries) {
    if (!e.key.endsWith('|${type.name}') || e.value.place != MealPlace.casa) continue;
    counts[e.value.dish] = (counts[e.value.dish] ?? 0) + 1;
  }
  final ranked = (counts.entries.where((e) => e.value > 1).toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => e.key);
  final out = <String>[];
  for (final d in [...ranked, ..._defaultFavorites[type]!]) {
    if (!out.any((o) => o.toLowerCase() == d.toLowerCase())) out.add(d);
    if (out.length == count) break;
  }
  return out;
}
