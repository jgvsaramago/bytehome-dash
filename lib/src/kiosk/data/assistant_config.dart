import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/ha_providers.dart';

/// What the voice assistant is called on the screen, matching its wake
/// word — chosen in the integration's "Assistente de voz" (which takes them
/// from the voice satellite's wake word).
class AssistantConfig {
  const AssistantConfig({this.name = 'Nabu', this.wakePhrase = 'Ok Nabu'});

  final String name;
  final String wakePhrase;
}

final assistantConfigProvider = StateProvider<AssistantConfig>((ref) => const AssistantConfig());

final savedAssistantConfigProvider = FutureProvider<AssistantConfig>((ref) async {
  await haReady(ref);
  final raw = await ref.read(haWebSocketClientProvider).getSettings('assistant');
  String? text(String k) => raw is Map && raw[k] is String && (raw[k] as String).trim().isNotEmpty ? (raw[k] as String).trim() : null;
  const fallback = AssistantConfig();
  return AssistantConfig(name: text('name') ?? fallback.name, wakePhrase: text('wakePhrase') ?? fallback.wakePhrase);
});
