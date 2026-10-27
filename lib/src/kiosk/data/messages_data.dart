import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ha_client/ha_websocket_client.dart';
import '../../providers/ha_providers.dart';

/// A message left for someone through the assistant ("deixa um recado à
/// Rita: …"): in Listas › Recados, and in a modal each time a screen
/// wakes while it's unseen. It stays (seen) until deleted or 7 days old.
class FamilyMessage {
  const FamilyMessage({required this.id, required this.text, required this.at, this.to, this.from, this.seenAt, this.seenBy});

  final String id;
  final String text;
  final DateTime at;

  /// The person it's for (as named in Pessoas); null for everyone.
  final String? to;

  /// Who left it; null when their voice wasn't recognised.
  final String? from;

  final DateTime? seenAt;

  /// Who marked it seen, when known (by voice); null from a tap.
  final String? seenBy;

  bool get seen => seenAt != null;

  /// Days until it's deleted.
  int get daysLeft => 7 - DateTime.now().difference(at).inDays;

  factory FamilyMessage.fromJson(Map<String, dynamic> j) => FamilyMessage(
    id: j['id'] as String? ?? '',
    text: j['text'] as String? ?? '',
    at: DateTime.tryParse(j['at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    to: j['to'] as String?,
    from: j['from'] as String?,
    seenAt: DateTime.tryParse(j['seen_at'] as String? ?? '')?.toLocal(),
    seenBy: j['seen_by'] as String?,
  );
}

/// The messages in the integration's shared store (`family_messages`,
/// written by its leave_message tool and read by every screen).
class FamilyMessagesNotifier extends StateNotifier<List<FamilyMessage>> {
  FamilyMessagesNotifier(this._client) : super(const []);

  final HaWebSocketClient _client;

  static const _key = 'family_messages';
  static const _keep = Duration(days: 7);

  Future<void> load() async {
    final raw = await _client.getSettings(_key);
    final cutoff = DateTime.now().subtract(_keep);
    state = [
      if (raw is List)
        for (final m in raw.whereType<Map>()) FamilyMessage.fromJson(m.cast<String, dynamic>()),
    ].where((m) => m.id.isNotEmpty && m.text.isNotEmpty && m.at.isAfter(cutoff)).toList();
  }

  /// A message written on this screen (Listas › Recados): the integration
  /// stores it like one left by voice and, with [phone], notifies the
  /// recipient's phone (everyone's but the sender's when [to] is null).
  /// Shown at once; taken back if the integration doesn't take it.
  Future<void> add({required String text, String? to, String? from, bool phone = true}) async {
    final before = state;
    final draft = FamilyMessage(id: 'local-${DateTime.now().microsecondsSinceEpoch}', text: text.trim(), at: DateTime.now(), to: to, from: from);
    state = [...state, draft];
    try {
      await _client.command('bytehomedash/leave_message', {'text': text.trim(), 'to': to, 'from': from, 'phone': phone});
    } catch (_) {
      state = before;
      rethrow;
    }
    // Every screen reloads on the store's change event; this one too, in
    // case that arrives before the command's answer.
    await load();
  }

  List<FamilyMessage> get unseen => state.where((m) => !m.seen).toList();

  /// Marks [ids] (all unseen when null) seen, for every screen.
  Future<void> markSeen([Set<String>? ids]) => _edit((m) {
    if (m['seen_at'] != null || (ids != null && !ids.contains(m['id']))) return m;
    return {...m, 'seen_at': DateTime.now().toUtc().toIso8601String()};
  });

  Future<void> delete(String id) => _edit((m) => m['id'] == id ? null : m);

  /// Rewrites the stored list (read fresh: another screen or the assistant
  /// may have changed it), showing the result at once and undoing it if the
  /// save fails.
  Future<void> _edit(Map<String, dynamic>? Function(Map<String, dynamic>) change) async {
    final before = state;
    final raw = await _client.getSettings(_key);
    final next = [
      if (raw is List)
        for (final m in raw.whereType<Map>())
          if (change(m.cast<String, dynamic>()) case final kept?) kept,
    ];
    state = [for (final m in next) FamilyMessage.fromJson(m)].where((m) => m.id.isNotEmpty).toList();
    try {
      await _client.setSettings(_key, next);
    } catch (_) {
      state = before;
      rethrow;
    }
  }
}

final familyMessagesProvider = StateNotifierProvider<FamilyMessagesNotifier, List<FamilyMessage>>(
  (ref) => FamilyMessagesNotifier(ref.watch(haWebSocketClientProvider)),
);
