import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/ha_entity.dart';
import '../../providers/ha_providers.dart';
import '../../services/voice_narrator.dart';
import '../../services/voice_satellite.dart';
import '../../utils/optimistic.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../browser/browser.dart';
import '../data/assistant_config.dart';
import '../data/family_data.dart';
import '../data/messages_data.dart';
import '../data/house_models.dart';
import '../data/kiosk_entities.dart';
import '../data/dates.dart';
import '../data/todo_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/recado_widgets.dart';
import 'intercom_modal.dart';
import 'kitchen_modal.dart';
import 'nabu_mascot.dart';

/// Opens Nabu, the assistant. From the nav bar ([byVoice] false) it starts
/// listening straight away, as if the wake word had been said — or, with no
/// voice satellite to listen with, opens the keyboard.
Future<void> showAssistant(BuildContext context, {bool byVoice = false}) async {
  if (AssistantModal.isOpen) return;
  AssistantModal.isOpen = true;
  try {
    await showKModal(context, (_) => AssistantModal(byVoice: byVoice));
  } finally {
    AssistantModal.isOpen = false;
  }
}

/// Gets the Assistente's spoken status lines ready (synthesised once, in
/// the assistant's voice), so the first slow answer already has them.
Future<void> prepareAssistantVoice(WidgetRef ref) async {
  try {
    // Connected first: the pipeline lookup waits with haReady, which re-runs
    // it on connecting, and a future taken before that never completes.
    for (var i = 0; i < 60 && !ref.read(entitiesProvider).hasValue; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    final pipeline = await ref.read(_pipelineProvider.future);
    final config = ref.read(connectionConfigProvider);
    if (config == null || pipeline == null) {
      debugPrint('[narrator] not prepared: ${config == null ? 'no HA connection settings' : 'no Assist pipeline'}');
      return;
    }
    VoiceNarrator.instance.prepare(baseUrl: config.baseUrl, token: config.accessToken, pipeline: pipeline);
  } catch (e) {
    debugPrint('[narrator] not prepared: $e');
  }
}

/// Who the voice satellite last heard, as the integration reports it (the
/// `speaker` action of `bytehomedash/subscribe_assistant`): "pending" when a
/// request starts, then the person recognised by voice, if any. Kept here
/// because the first request's report can arrive before the wake word has
/// opened the Assistente.
class _Heard {
  const _Heard({required this.pending, this.name});

  final bool pending;

  /// The person (as named in Pessoas) — null when nobody was recognised.
  final String? name;
}

final _heard = ValueNotifier<(_Heard, DateTime)?>(null);

/// Starts following who is speaking, for the Assistente's chip and
/// "Enviar para o telemóvel". Once, at start-up.
void trackAssistantSpeaker(WidgetRef ref) {
  ref.read(haWebSocketClientProvider).assistantEvents.listen((e) {
    if (e['action'] != 'speaker') return;
    final pending = e['status'] == 'pending';
    _heard.value = (_Heard(pending: pending, name: pending || e['identified'] != true ? null : e['name'] as String?), DateTime.now());
  });
}

/// HA's preferred Assist pipeline — typed requests go to its conversation
/// agent, the same one the voice satellite talks to.
final _pipelineProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  await haReady(ref);
  try {
    final r = await ref.read(haWebSocketClientProvider).command('assist_pipeline/pipeline/list');
    if (r is! Map) return null;
    for (final p in (r['pipelines'] as List? ?? const []).whereType<Map>()) {
      if (p['id'] == r['preferred_pipeline']) return p.cast<String, dynamic>();
    }
  } catch (_) {}
  return null;
});

/// A web page the conversation agent showed (its ByteHomeDash tools read
/// the page's own data: schema.org or its preview).
class _WebCard {
  _WebCard(Map<String, dynamic> j)
    : url = j['url'] as String? ?? '',
      title = j['title'] as String? ?? '',
      image = j['image'] as String?,
      site = j['site'] as String?,
      rating = (j['rating'] as num?)?.toDouble(),
      ratingCount = (j['rating_count'] as num?)?.toInt(),
      minutes = (j['minutes'] as num?)?.toInt(),
      price = (j['price'] as num?)?.toDouble(),
      currency = j['currency'] as String?,
      priceRange = j['price_range'] as String?,
      cuisine = j['cuisine'] as String?,
      address = j['address'] as String?,
      kind = j['kind'] as String? ?? 'page',
      date = DateTime.tryParse(j['date'] as String? ?? ''),
      section = j['section'] as String?,
      channel = j['channel'] as String?,
      duration = (j['duration'] as num?)?.toInt(),
      views = (j['views'] as num?)?.toInt(),
      servings = j['servings'] as String?;

  final String url, title, kind;
  final String? image, site, currency, priceRange, cuisine, address, section, channel, servings;
  final double? rating, price;
  final int? ratingCount, minutes, duration, views;
  final DateTime? date;

  String get host => Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url;
}

/// The row's heading: what kind of results these are.
String _webLabel(List<_WebCard> cards) {
  final kinds = {for (final c in cards) c.kind};
  return switch (kinds.length == 1 ? kinds.first : '') {
    'recipe' => l10n.assistantWebRecipes,
    'place' => l10n.assistantWebPlaces,
    'video' => l10n.assistantWebVideos,
    'news' => l10n.assistantWebNews,
    'product' => l10n.assistantWebProducts,
    _ => l10n.assistantWebOther,
  };
}

/// A link on its way to a phone, then sent.
enum _Send { sending, sent }

/// What one of the agent's tools did (the integration's `result` event):
/// an event made, a task added or done, meals planned or a "Substituo?",
/// a recado, a page sent, the doorbell calls — or the shopping items Assist
/// added. Shown as a row under the answer, some with an action.
class _Result {
  _Result(Map<String, dynamic> j)
    : kind = j['kind'] as String? ?? '',
      title = j['title'] as String? ?? '',
      state = j['state'] as String? ?? '',
      undo = j['undo'] as String?,
      confirm = j['confirm'] as String?,
      url = j['url'] as String?,
      pageTitle = j['page_title'] as String?,
      messageId = j['message_id'] as String?,
      yesText = j['yes_text'] as String? ?? l10n.assistantMealsReplaced,
      noText = j['no_text'] as String? ?? l10n.assistantMealsKept,
      chips = [for (final c in j['chips'] as List? ?? const []) '$c'],
      lines = [for (final l in (j['lines'] as List? ?? const []).whereType<Map>()) l.cast<String, dynamic>()];

  final String kind, title, state, yesText, noText;
  final String? undo, confirm, url, pageTitle, messageId;
  final List<String> chips;
  final List<Map<String, dynamic>> lines;

  /// 'desfeito', 'visto', 'sim' or 'nao' once acted on.
  String? answer;
  bool busy = false;
}

class _Msg {
  const _Msg.user(this.text)
    : user = true,
      entityIds = const [],
      url = null,
      cards = const [],
      results = const [],
      writing = false,
      searching = false,
      skeletons = 0;
  const _Msg.bot(this.text, [this.entityIds = const [], this.url, this.cards = const [], this.results = const []])
    : user = false,
      writing = false,
      searching = false,
      skeletons = 0;
  const _Msg._bot(this.text, this.entityIds, this.url, this.cards, this.results, this.writing, this.searching, this.skeletons) : user = false;

  _Msg copyWith({String? text, List<String>? entityIds, List<_WebCard>? cards, List<_Result>? results, bool? writing, bool? searching, int? skeletons}) =>
      _Msg._bot(
        text ?? this.text,
        entityIds ?? this.entityIds,
        url,
        cards ?? this.cards,
        results ?? this.results,
        writing ?? this.writing,
        searching ?? this.searching,
        skeletons ?? this.skeletons,
      );

  final bool user;
  final String text;

  /// What the agent's tools did — a row each, under the answer.
  final List<_Result> results;

  /// Still being written (the voice reply streams in): with a note, and
  /// [skeletons] cards still on their way.
  final bool writing;
  final bool searching;
  final int skeletons;

  /// Web results shown under the answer, numbered for "abre a segunda".
  final List<_WebCard> cards;

  /// What the assistant acted on or answered about — a row each.
  final List<String> entityIds;

  /// A site the answer points to: a row with "Abrir", and it opens at once.
  final String? url;
}

/// The design's stages: ouvir, pensar, falar ("A responder"), pronto.
enum _Stage { listening, thinking, speaking, ready }

List<String> get _suggestions => [l10n.assistantSuggestWeather, l10n.assistantSuggestDinner, l10n.assistantSuggestDoorbell, l10n.assistantSuggestLightsOff];
const _keyboardIcon = '<rect x="2.5" y="6" width="19" height="12" rx="2.5"/><path d="M6 10h.01M10 10h.01M14 10h.01M18 10h.01M7 14h10"/>';
const _stopIcon = '<path d="M7 7h10v10H7z"/>';
const _muteIcon = '<path d="M4 9v6h4l5 4V5L8 9zM17 9l5 5M22 9l-5 5"/>';
const _globeIcon = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z"/>';
const _sendIcon = '<path d="M12 19V5M6 11l6-6 6 6"/>';
const _waveIcon = '<path d="M4 10v4M8 7v10M12 4v16M16 8v8M20 11v2"/>';
const _phoneIcon = '<path d="M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM11 18h2"/>';
const _playIcon = '<path d="M8 5v14l11-7z"/>';
const _kindIcons = {
  'recipe': '<path d="M7 3v8a2 2 0 0 0 2 2v8M11 3v8a2 2 0 0 1-2 2M9 3v6M17 21V3c-2 1.5-3 4-3 7v4h3"/>',
  'place': '<path d="M12 21s7-6.2 7-11.5A7 7 0 0 0 5 9.5C5 14.8 12 21 12 21zM12 12a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z"/>',
  'video': '<path d="M4 6h16v12H4z"/>',
  'news': '<path d="M4 5h13v14H6a2 2 0 0 1-2-2zM17 9h3v8a2 2 0 0 1-2 2M7 9h7M7 13h7"/>',
  'article': '<path d="M4 5h13v14H6a2 2 0 0 1-2-2zM17 9h3v8a2 2 0 0 1-2 2M7 9h7M7 13h7"/>',
  'product': '<path d="M6 7h12l-1 13H7zM9 7V5a3 3 0 0 1 6 0v2"/>',
};

/// The design's "AssistenteNabu": a full-screen, frosted conversation with
/// Home Assistant's Assist and its owl. Speech belongs to Linux Voice
/// Assistant on this Pi ([VoiceSatellite]) — this mirrors its
/// listening/thinking/speaking state and what it heard and answered, and
/// the mic button starts/stops a pipeline. Requests can also be typed (the
/// only way while the Pi has no mic); those go straight to the pipeline's
/// conversation agent and come back with a row per entity it touched.
class AssistantModal extends ConsumerStatefulWidget {
  const AssistantModal({super.key, this.byVoice = false});

  /// Opened by the wake word — LVA is already listening.
  final bool byVoice;

  static bool isOpen = false;

  @override
  ConsumerState<AssistantModal> createState() => _AssistantModalState();
}

class _AssistantModalState extends ConsumerState<AssistantModal> {
  static final _satellite = VoiceSatellite.instance;

  /// "Respostas faladas" — kept while the app runs.
  static bool _speakReplies = true;

  final _messages = <_Msg>[];
  final _draft = TextEditingController();
  final _focus = FocusNode();
  StreamSubscription<SatelliteEvent>? _voice;
  StreamSubscription<Map<String, dynamic>>? _cardsSub;

  /// Cards that arrived before the answer they belong to (the agent shows
  /// them, then speaks), and the backstop that shows them alone.
  List<_WebCard>? _cardsForNext;
  List<_Result>? _resultsForNext;
  Timer? _cardsAlone;

  /// Who is speaking, recognised by voice; kept for the rest of the
  /// conversation. [_recognizing]: the first request is being identified.
  String? _speaker;
  bool _recognizing = false;

  /// Cards sent (or being sent) to a phone, by URL; the people with a phone
  /// to send to (name → device), asked for on the first send.
  final _sent = <String, _Send>{};
  Map<String, String>? _phones;

  /// The card the chooser ("Para quem envio?") is open for.
  _WebCard? _choosing;

  /// "Enviado para o telemóvel de …", with "Outra pessoa" for [_sentCard].
  String? _sentToast;
  _WebCard? _sentCard;
  Timer? _sentToastTimer;

  /// The typing bar and keyboard are up.
  bool _typing = false;

  /// A typed request is waiting for the agent.
  bool _pending = false;
  int _request = 0;
  String? _conversationId;

  /// Index of the answer still being written out.
  int? _revealing;

  /// Closes the Assistente after this long without a touch, a keystroke or
  /// anything from the voice satellite — but never mid-conversation.
  static const _idleClose = Duration(seconds: 45);
  Timer? _idle;

  void _activity() {
    _idle?.cancel();
    _idle = Timer(_idleClose, _onIdle);
  }

  void _onIdle() {
    if (!mounted) return;
    // Listening, thinking, speaking or still writing out: wait for quiet.
    if (_stage != _Stage.ready) {
      _activity();
      return;
    }
    _close();
  }

  /// Live state of the entities the answers point at, with taps on their
  /// rows shown at once and undone if HA doesn't follow.
  Map<String, HaEntity> _real = const {};
  late final _layer = OptimisticLayer<HaEntity>(
    real: (id) => _real[id],
    onChanged: () {
      if (mounted) setState(() {});
    },
    notConfirmed: l10n.assistantNotConfirmed,
  );

  @override
  void initState() {
    super.initState();
    _voice = _satellite.events.listen(_onVoice);
    _cardsSub = ref.read(haWebSocketClientProvider).assistantEvents.listen(_onAssistantEvent);
    if (_heard.value case (final h, final at) when DateTime.now().difference(at) < const Duration(seconds: 20)) _onHeard(h);
    _heard.addListener(_onHeardChanged);
    _prepareNarrator();
    _satellite.phase.addListener(_onPhase);
    _focus.addListener(_onFocus);
    _draft.addListener(_activity);
    _activity();
    ref.listenManual(entitiesProvider, (_, next) => _onEntities(next.valueOrNull), fireImmediately: true);
    // Woken by the wake word with recados unseen: Nabu shows them first.
    if (widget.byVoice) _recadosFirst();
    if (!widget.byVoice) {
      if (_satellite.available.value) {
        if (_satellite.phase.value == SatellitePhase.idle) _satellite.startListening();
      } else {
        _openTyping();
      }
    }
  }

  @override
  void dispose() {
    _voice?.cancel();
    _cardsSub?.cancel();
    _cardsAlone?.cancel();
    _streamPoll?.cancel();
    _sentToastTimer?.cancel();
    _heard.removeListener(_onHeardChanged);
    _narration?.cancel();
    VoiceNarrator.instance.stop();
    _idle?.cancel();
    _satellite.phase.removeListener(_onPhase);
    _focus.removeListener(_onFocus);
    OnScreenKeyboardController.instance.detach(_draft);
    _layer.dispose();
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  Set<String> get _shownIds => {for (final m in _messages) ...m.entityIds};

  void _onEntities(Map<String, HaEntity>? all) {
    if (all == null) return;
    final ids = _shownIds;
    final next = {
      for (final id in ids)
        if (all[id] case final e?) id: e,
    };
    // Only redraw when one of the entities on screen changed, not on every
    // sensor tick the house sends.
    final changed = next.length != _real.length || next.entries.any((e) => !identical(_real[e.key], e.value));
    _real = next;
    _layer.settle();
    if (changed && mounted) setState(() {});
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      OnScreenKeyboardController.instance.attach(
        _draft,
        options: KeyboardOptions(
          suggestions: (_) => [l10n.assistantKeyTurnOn, l10n.assistantKeyTurnOff, l10n.assistantKeyWhatIs, l10n.assistantKeyHowMuch, l10n.assistantKeyPlay],
          onSuggest: (w) {
            final t = _draft.text;
            final next = '${t.isEmpty || t.endsWith(' ') ? t : '$t '}$w ';
            _draft.value = TextEditingValue(
              text: next,
              selection: TextSelection.collapsed(offset: next.length),
            );
          },
          doneLabel: l10n.assistantSend,
          onDone: () => _send(_draft.text),
        ),
      );
    } else {
      OnScreenKeyboardController.instance.detach(_draft);
      if (_typing && mounted) setState(() => _typing = false);
    }
  }

  void _openTyping() {
    if (_satellite.phase.value == SatellitePhase.listening) _satellite.stop();
    setState(() => _typing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _closeTyping() => OnScreenKeyboardController.instance.close();

  /// The satellite's phase a moment ago. (Carrying a conversation on is
  /// HA's call: a reply that asks something comes back with
  /// continue_conversation, and the satellite listens again by itself.)
  SatellitePhase _lastPhase = SatellitePhase.idle;

  // --- Spoken status while the agent works --------------------------------

  Timer? _narration;
  DateTime _turnStart = DateTime.now();
  DateTime? _lastSaid;
  final _saidThisTurn = <NarratorStatus>{};
  int _stillSaid = 0;

  Future<void> _prepareNarrator() => prepareAssistantVoice(ref);

  void _startNarration() {
    _narration?.cancel();
    _turnStart = DateTime.now();
    _lastSaid = null;
    _saidThisTurn.clear();
    _stillSaid = 0;
    _narration = Timer.periodic(const Duration(seconds: 1), (_) => _narrate());
  }

  void _stopNarration() {
    _narration?.cancel();
    _narration = null;
    VoiceNarrator.instance.stop();
  }

  void _say(NarratorStatus status) {
    _saidThisTurn.add(status);
    _lastSaid = DateTime.now();
    if (status == NarratorStatus.stillWorking) _stillSaid++;
    VoiceNarrator.instance.say(status);
  }

  /// Once a second while the agent works: what it is doing comes from HA's
  /// live record of this voice run (its reasoning, a `web_search_call`).
  /// Thinking past 2.5 s gets a line; a web search gets its own; a long wait
  /// gets "ainda estou a ver" at most twice.
  Future<void> _narrate() async {
    if (!mounted || _satellite.phase.value != SatellitePhase.thinking) return;
    final now = DateTime.now();
    final elapsed = now.difference(_turnStart);
    if (!_saidThisTurn.contains(NarratorStatus.searching) && await _isSearching()) {
      if (mounted && _satellite.phase.value == SatellitePhase.thinking) _say(NarratorStatus.searching);
      return;
    }
    final quiet = now.difference(_lastSaid ?? _turnStart);
    if (_saidThisTurn.isEmpty && elapsed >= const Duration(milliseconds: 2500)) {
      _say(NarratorStatus.thinking);
    } else if (_saidThisTurn.isNotEmpty && _stillSaid < 2 && quiet >= const Duration(seconds: 15)) {
      _say(NarratorStatus.stillWorking);
    }
  }

  Future<bool> _isSearching() async {
    try {
      final id = (await ref.read(_pipelineProvider.future))?['id'];
      if (id is! String) return false;
      final ha = ref.read(haWebSocketClientProvider);
      final list = await ha.command('assist_pipeline/pipeline_debug/list', {'pipeline_id': id});
      final runs = ((list as Map?)?['pipeline_runs'] as List? ?? const []).whereType<Map>().toList();
      if (runs.isEmpty) return false;
      final run = runs.last;
      final started = DateTime.tryParse(run['timestamp'] as String? ?? '');
      if (started == null || started.isBefore(_turnStart.subtract(const Duration(seconds: 10)))) return false;
      final debug = await ha.command('assist_pipeline/pipeline_debug/get', {'pipeline_id': id, 'pipeline_run_id': run['pipeline_run_id']});
      for (final e in ((debug as Map?)?['events'] as List? ?? const []).whereType<Map>()) {
        final delta = (e['data'] as Map?)?['chat_log_delta'];
        if (delta is! Map) continue;
        for (final call in (delta['tool_calls'] as List? ?? const []).whereType<Map>()) {
          if ('${call['tool_name']}'.contains('search')) return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // --- The answer as it is written ---------------------------------------
  //
  // A voice reply is spoken while the agent is still writing it (HA streams
  // it to text-to-speech), but its text only reaches the satellite once the
  // agent has finished — half a minute later after a web search. HA's live
  // record of the run already has the text so far, so it's shown from there
  // and replaced by the final answer when that arrives.

  Timer? _streamPoll;
  DateTime _streamStart = DateTime.now();

  /// The answer being written out, while it is.
  int? _streamIdx;
  bool _streamBusy = false;

  void _startStream() {
    _streamPoll?.cancel();
    _streamIdx = null;
    _streamStart = DateTime.now();
    _streamPoll = Timer.periodic(const Duration(milliseconds: 700), (_) => _pollStream());
  }

  void _stopStream() {
    _streamPoll?.cancel();
    _streamPoll = null;
  }

  Future<void> _pollStream() async {
    if (!mounted || _streamBusy) return;
    if (_satellite.phase.value == SatellitePhase.idle && DateTime.now().difference(_streamStart) > const Duration(seconds: 5)) {
      _stopStream();
      return;
    }
    _streamBusy = true;
    try {
      final got = await _streamedText();
      if (!mounted || _streamPoll == null || got == null || got.text.isEmpty) return;
      final cards = _cardsForNext;
      final results = _resultsForNext;
      _cardsForNext = null;
      _resultsForNext = null;
      _cardsAlone?.cancel();
      setState(() {
        _pending = false;
        if (_streamIdx case final i?) {
          final m = _messages[i];
          final c = cards ?? m.cards;
          _messages[i] = m.copyWith(
            text: got.text,
            cards: c,
            results: [...m.results, ...?results],
            searching: got.searching,
            skeletons: c.isEmpty ? got.pendingCards : 0,
          );
        } else {
          final c = cards ?? const <_WebCard>[];
          _messages.add(_Msg._bot(got.text, const [], null, c, [...?results], true, got.searching, c.isEmpty ? got.pendingCards : 0));
          _streamIdx = _messages.length - 1;
          _revealing = null;
        }
      });
    } finally {
      _streamBusy = false;
    }
  }

  /// What the agent has written so far in this turn's voice run: its
  /// answer's text deltas (not its reasoning or tool calls); whether it
  /// searched the web; and how many cards a show_web_results call it made is
  /// still fetching.
  Future<({String text, bool searching, int pendingCards})?> _streamedText() async {
    try {
      final id = (await ref.read(_pipelineProvider.future))?['id'];
      if (id is! String) return null;
      final ha = ref.read(haWebSocketClientProvider);
      final list = await ha.command('assist_pipeline/pipeline_debug/list', {'pipeline_id': id});
      final runs = ((list as Map?)?['pipeline_runs'] as List? ?? const []).whereType<Map>().toList();
      if (runs.isEmpty) return null;
      final run = runs.last;
      final started = DateTime.tryParse(run['timestamp'] as String? ?? '');
      if (started == null || started.isBefore(_streamStart.subtract(const Duration(seconds: 30)))) return null;
      final debug = await ha.command('assist_pipeline/pipeline_debug/get', {'pipeline_id': id, 'pipeline_run_id': run['pipeline_run_id']});
      final out = StringBuffer();
      var newMessage = false;
      var searching = false;
      var pendingCards = 0;
      for (final e in ((debug as Map?)?['events'] as List? ?? const []).whereType<Map>()) {
        final delta = (e['data'] as Map?)?['chat_log_delta'];
        if (delta is! Map) continue;
        if (delta['role'] != null) newMessage = true;
        for (final call in (delta['tool_calls'] as List? ?? const []).whereType<Map>()) {
          final name = '${call['tool_name']}';
          if (name.contains('search')) searching = true;
          if (name.endsWith('show_web_results')) pendingCards = ((call['tool_args'] as Map?)?['urls'] as List?)?.length ?? 0;
        }
        if (delta['role'] == 'tool_result' && '${delta['tool_name']}'.endsWith('show_web_results')) pendingCards = 0;
        if (delta['content'] case final String piece when piece.isNotEmpty) {
          // Text before and after a tool call are separate messages.
          if (newMessage && out.isNotEmpty && !out.toString().endsWith(' ')) out.write(' ');
          newMessage = false;
          out.write(piece);
        }
      }
      return (text: out.toString().trim(), searching: searching, pendingCards: pendingCards);
    } catch (e) {
      debugPrint('[assistant] streamed text: $e');
      return null;
    }
  }

  void _onPhase() {
    _activity();
    final phase = _satellite.phase.value;
    if (phase == SatellitePhase.thinking && _lastPhase != SatellitePhase.thinking) _startNarration();
    if (phase != SatellitePhase.thinking && _lastPhase == SatellitePhase.thinking) _stopNarration();
    // Spoken replies off: let the answer show, but cut the speaker.
    if (phase == SatellitePhase.speaking && !_speakReplies) _satellite.stop();
    _lastPhase = phase;
  }

  void _onVoice(SatelliteEvent e) {
    if (!mounted) return;
    _activity();
    switch (e) {
      case SatelliteWake():
        if (_typing) _closeTyping();
      case SatelliteHeard(:final text):
        setState(() {
          _revealing = null;
          _messages.add(_Msg.user(text));
        });
        _startStream();
      case SatelliteReply(:final text):
        _stopStream();
        _answer(text, const [], replace: _streamIdx);
        _streamIdx = null;
        _addVoiceTargets(text);
      case SatelliteError():
        _stopStream();
        _streamIdx = null;
        _answer(l10n.assistantDidntUnderstand, const []);
    }
  }

  static String? _speechOf(Map response) => (((response['speech'] as Map?)?['plain'] as Map?)?['speech'] as String?)?.trim();

  /// The entities an intent response acted on or answered about (its
  /// `data.success` targets), at most four.
  static List<String> _actedOn(Map response) {
    final success = ((response['data'] as Map?)?['success'] as List?) ?? const [];
    return [
      for (final t in success.whereType<Map>())
        if (t['type'] == 'entity' && t['id'] is String) t['id'] as String,
    ].take(4).toList();
  }

  /// A spoken reply reaches the screen through the satellite as text only.
  /// What it acted on is in HA's debug record of that voice run (the same
  /// intent response a typed request gets), so the widgets are added from
  /// there: the newest runs of the preferred pipeline, matched by the reply.
  Future<void> _addVoiceTargets(String speech) async {
    try {
      final id = (await ref.read(_pipelineProvider.future))?['id'];
      if (id is! String) return;
      final ha = ref.read(haWebSocketClientProvider);
      final list = await ha.command('assist_pipeline/pipeline_debug/list', {'pipeline_id': id});
      final runs = ((list as Map?)?['pipeline_runs'] as List? ?? const []).whereType<Map>().toList();
      for (final run in runs.reversed.take(3)) {
        final debug = await ha.command('assist_pipeline/pipeline_debug/get', {'pipeline_id': id, 'pipeline_run_id': run['pipeline_run_id']});
        final events = ((debug as Map?)?['events'] as List? ?? const []).whereType<Map>();
        final end = events.where((e) => e['type'] == 'intent-end').firstOrNull;
        final response = ((end?['data'] as Map?)?['intent_output'] as Map?)?['response'];
        if (response is! Map || _speechOf(response) != speech.trim()) continue;
        final ids = _actedOn(response);
        final i = _messages.lastIndexWhere((m) => !m.user && m.text == speech);
        if (i < 0 || !mounted) return;
        if (_listItemsAdded(events) case final shop?) setState(() => _messages[i] = _messages[i].copyWith(results: [..._messages[i].results, shop]));
        if (ids.isEmpty) return;
        setState(() => _messages[i] = _messages[i].copyWith(entityIds: ids));
        _onEntities(ref.read(entitiesProvider).valueOrNull);
        return;
      }
    } catch (e) {
      debugPrint('[assistant] voice reply targets: $e');
    }
  }

  /// Items Assist's own list tool added in this run (it isn't one of the
  /// integration's tools, so its result comes from HA's record of the run).
  _Result? _listItemsAdded(Iterable<Map> events) {
    final items = <String>[];
    String? list;
    for (final e in events) {
      final delta = (e['data'] as Map?)?['chat_log_delta'];
      if (delta is! Map) continue;
      for (final call in (delta['tool_calls'] as List? ?? const []).whereType<Map>()) {
        if (!'${call['tool_name']}'.endsWith('HassListAddItem')) continue;
        final args = (call['tool_args'] as Map?) ?? const {};
        if (args['item'] case final String item when item.trim().isNotEmpty) items.add(item.trim());
        if (args['name'] case final String n) list = n;
      }
    }
    if (items.isEmpty) return null;
    final name = list ?? l10n.assistantDefaultList;
    final pending = ref.read(todoListsProvider).where((l) => l.name.toLowerCase() == name.toLowerCase()).firstOrNull?.pending;
    return _Result({
      'kind': 'shop',
      'title': l10n.assistantItemsAdded(items.length, name),
      'state': pending == null ? name : l10n.assistantItemsPending(name, pending),
      'chips': items,
    });
  }

  void _onAssistantEvent(Map<String, dynamic> e) {
    if (!mounted) return;
    _activity();
    switch (e['action']) {
      case 'cards':
        final cards = [for (final c in (e['cards'] as List? ?? const []).whereType<Map>()) _WebCard(c.cast<String, dynamic>())];
        if (cards.isEmpty) return;
        // The answer is already being written out: they go under it.
        if (_streamIdx case final i?) {
          final m = _messages[i];
          setState(() => _messages[i] = m.copyWith(cards: cards, skeletons: 0));
          return;
        }
        _cardsForNext = cards;
        _cardsAlone?.cancel();
        _cardsAlone = Timer(const Duration(seconds: 15), () {
          if (mounted && _cardsForNext != null) _answer(e['title'] as String? ?? l10n.assistantResults, const []);
        });
      case 'open':
        if (e['url'] case final String url) _openSite(url);
      // "Próximo passo" over the kitchen view: step aside so the step shows.
      // (Otherwise the shell closes everything and opens it.)
      case 'recipe' || 'kitchen' when KitchenModal.isOpen:
        _close();
      // Sent by the agent (its send_to_phone tool): shown like a tap on the card's button.
      // Sent by the agent: the card shows "Enviado"; its result row says to whom.
      case 'sent':
        if (e['url'] case final String url) setState(() => _sent[url] = _Send.sent);
      case 'result':
        if (e['result'] case final Map r) _addResult(_Result(r.cast<String, dynamic>()));
      // "Sim" said to a "Substituo?": the open questions are answered.
      case 'result_answer':
        setState(() {
          for (final r in _messages.expand((m) => m.results)) {
            if (r.kind == 'meal_question' && r.answer == null) r.answer = '${e['answer']}';
          }
        });
    }
  }

  /// A tool's result goes under the answer being written, or the next one
  /// (tools run before the agent answers).
  void _addResult(_Result r) {
    if (_streamIdx case final i?) {
      setState(() => _messages[i] = _messages[i].copyWith(results: [..._messages[i].results, r]));
      return;
    }
    (_resultsForNext ??= []).add(r);
    _cardsAlone?.cancel();
    _cardsAlone = Timer(const Duration(seconds: 15), () {
      if (mounted && (_resultsForNext != null || _cardsForNext != null)) _answer(l10n.assistantDone, const []);
    });
  }

  void _recadosFirst() {
    final unseen = ref.read(familyMessagesProvider.notifier).unseen.reversed.take(3).toList();
    if (unseen.isEmpty) return;
    _messages.add(
      _Msg.bot(l10n.recadoGreeting(unseen.length), const [], null, const [], [
        for (final m in unseen)
          _Result({
            'kind': 'recado',
            'title': [
              if (m.from case final f?) l10n.recadoRowFrom(f) else l10n.recadoRow,
              if (m.to case final to?) l10n.recadoRowTo(to) else l10n.recadoRowToEveryone,
            ].join(' · '),
            'state': '${l10n.recadoQuoted(m.text)} · ${recadoWhen(m.at, lower: true)}',
            'message_id': m.id,
          }),
      ]),
    );
  }

  void _onHeardChanged() {
    if (_heard.value case (final h, _)) _onHeard(h);
  }

  /// The chip waits for the first request's result; after that, the person
  /// stays for the conversation (a later request nobody was recognised in
  /// doesn't take them away).
  void _onHeard(_Heard h) {
    if (!mounted) return;
    setState(() {
      if (h.pending) {
        _recognizing = _speaker == null;
      } else {
        _recognizing = false;
        if (h.name case final name?) _speaker = name;
      }
    });
  }

  /// "Enviar para o telemóvel": straight to whoever is speaking, else the
  /// chooser.
  Future<void> _sendCard(_WebCard c) async {
    if (_sent[c.url] == _Send.sending) return;
    _activity();
    final phones = await _loadPhones();
    if (!mounted) return;
    if (_speaker case final who? when phones.containsKey(who)) {
      unawaited(_sendTo(c, who));
    } else {
      setState(() {
        _sentToast = null;
        _choosing = c;
      });
    }
  }

  Future<Map<String, String>> _loadPhones() async {
    if (_phones case final p?) return p;
    try {
      final r = await ref.read(haWebSocketClientProvider).command('bytehomedash/phones');
      return _phones = {for (final p in (r as List? ?? const []).whereType<Map>()) '${p['name']}': '${p['device'] ?? ''}'};
    } catch (e) {
      debugPrint('[assistant] phones: $e');
      return const {};
    }
  }

  /// Shown as sending at once; "Enviado" once HA has handed it to the
  /// phone's notify service, back to the plain button if it couldn't.
  Future<void> _sendTo(_WebCard c, String who) async {
    _sentToastTimer?.cancel();
    setState(() {
      _choosing = null;
      _sentToast = null;
      _sent[c.url] = _Send.sending;
    });
    try {
      await ref.read(haWebSocketClientProvider).command('bytehomedash/send_to_phone', {'name': who, 'url': c.url, 'title': c.title});
      if (!mounted) return;
      setState(() {
        _sent[c.url] = _Send.sent;
        _sentToast = l10n.assistantSentToPhone(who);
        _sentCard = c;
      });
      _sentToastTimer = Timer(const Duration(milliseconds: 4500), () {
        if (mounted) setState(() => _sentToast = null);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sent.remove(c.url));
      KToast.error(e);
    }
  }

  /// [replace]: the answer shown while it was written, now complete — no
  /// writing-out animation again.
  void _answer(String text, List<String> ids, {int? replace}) {
    final url = RegExp(r'https?://[^\s<>"\)]+').firstMatch(text)?.group(0)?.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
    final streamed = replace != null && replace < _messages.length ? _messages[replace] : null;
    final cards = _cardsForNext ?? streamed?.cards ?? const <_WebCard>[];
    final results = [...?streamed?.results, ...?_resultsForNext];
    _cardsForNext = null;
    _resultsForNext = null;
    _cardsAlone?.cancel();
    setState(() {
      _pending = false;
      final m = _Msg.bot(text, ids, cards.isEmpty ? url : null, cards, results);
      if (streamed != null) {
        _messages[replace!] = m;
      } else {
        _messages.add(m);
        _revealing = _messages.length - 1;
      }
    });
    if (ids.isNotEmpty) _onEntities(ref.read(entitiesProvider).valueOrNull);
    // Asking for a site opens it straight away. The browser sits below every
    // modal, so the Assistente steps aside to show it.
    if (url != null) _openSite(url);
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty) return;
    _closeTyping();
    _draft.clear();
    if (_satellite.phase.value != SatellitePhase.idle) _satellite.stop();
    final req = ++_request;
    setState(() {
      _revealing = null;
      _messages.add(_Msg.user(text));
      _pending = true;
    });
    try {
      final r = await () async {
        final pipe = await ref.read(_pipelineProvider.future);
        return ref.read(haWebSocketClientProvider).command('conversation/process', {
          'text': text,
          if (pipe?['language'] case final String l) 'language': l,
          if (pipe?['conversation_engine'] case final String a) 'agent_id': a,
          if (_conversationId case final c?) 'conversation_id': c,
        });
      }().timeout(const Duration(seconds: 20));
      if (!mounted || req != _request) return;
      final result = r is Map ? r.cast<String, dynamic>() : const <String, dynamic>{};
      _conversationId = result['conversation_id'] as String? ?? _conversationId;
      final response = (result['response'] as Map?)?.cast<String, dynamic>() ?? const {};
      final speech = _speechOf(response);
      _answer(speech == null || speech.isEmpty ? l10n.assistantDone : speech, _actedOn(response));
    } catch (_) {
      if (!mounted || req != _request) return;
      _answer(l10n.assistantNoConnection, const []);
    }
  }

  _Stage get _stage => switch (_satellite.phase.value) {
    SatellitePhase.listening => _Stage.listening,
    SatellitePhase.thinking => _Stage.thinking,
    SatellitePhase.speaking => _Stage.speaking,
    SatellitePhase.idle when _pending => _Stage.thinking,
    SatellitePhase.idle when _revealing != null => _Stage.speaking,
    SatellitePhase.idle => _Stage.ready,
  };

  void _tapMic() {
    switch (_stage) {
      case _Stage.listening:
        _satellite.stop();
      case _Stage.thinking || _Stage.speaking:
        // Interromper: the answer shows in full, nothing more is said.
        if (_satellite.phase.value != SatellitePhase.idle) _satellite.stop();
        _request++;
        setState(() {
          _pending = false;
          _revealing = null;
        });
      case _Stage.ready:
        if (_typing) _closeTyping();
        _satellite.startListening();
    }
  }

  void _openSite(String url) {
    Browser.open(context, url: url);
    _closeTyping();
    closeOwnRoute(context);
  }

  void _close() {
    _closeTyping();
    closeOwnRoute(context);
  }

  void _toggle(HaEntity e) {
    final on = !e.isOn;
    unawaited(
      _layer
          .run([
            expectEntity(e.entityId, state: on ? 'on' : 'off'),
          ], () => ref.read(haWebSocketClientProvider).callService(e.domain, on ? 'turn_on' : 'turn_off', target: {'entity_id': e.entityId}))
          .catchError((Object _) {}),
    );
  }

  void _playPause(HaEntity e) {
    final playing = e.state == 'playing';
    unawaited(
      _layer
          .run([
            expectEntity(e.entityId, state: playing ? 'paused' : 'playing'),
          ], () => ref.read(haWebSocketClientProvider).callService('media_player', 'media_play_pause', target: {'entity_id': e.entityId}))
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      child: ListenableBuilder(listenable: Listenable.merge([_satellite.available, _satellite.phase]), builder: (context, _) => _build(context)),
    );
  }

  Widget _build(BuildContext context) {
    final voice = _satellite.available.value;
    final stage = _stage;
    final chat = _messages.isNotEmpty;
    final fresh = !chat && _satellite.phase.value == SatellitePhase.idle;
    final (status, statusFg, blink) = switch (stage) {
      _Stage.listening => (l10n.assistantStatusListening, KColors.accentFg, const Duration(milliseconds: 1200)),
      _Stage.thinking => (l10n.assistantStatusThinking, KColors.amberInk, const Duration(milliseconds: 800)),
      _Stage.speaking => (l10n.assistantStatusSpeaking, KColors.accentFg, null),
      _Stage.ready => (l10n.assistantStatusReady, KColors.ink2, null),
    };
    final phase = switch (stage) {
      _Stage.listening => l10n.assistantPhaseListening,
      _Stage.thinking => l10n.assistantPhaseThinking,
      _Stage.speaking => l10n.assistantStatusSpeaking,
      _Stage.ready when fresh => l10n.assistantPhaseReadyFresh,
      _Stage.ready => l10n.assistantPhaseReadyMore,
    };
    final glass = KColors.card.withValues(alpha: 0.78);

    final route = ModalRoute.of(context);
    final anim = route?.animation ?? const AlwaysStoppedAnimation(1.0);

    final content = Stack(
      children: [
        Column(
          children: [
            // Barra de topo
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 56, 56, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Consumer(builder: (context, ref, _) => Text(ref.watch(assistantConfigProvider).name, style: KText.d(40, spacing: -0.5))),
                        const SizedBox(height: 4),
                        Text(l10n.assistantSubtitle, style: KText.s(18, color: KColors.muted)),
                      ],
                    ),
                  ),
                  if (_recognizing)
                    Container(
                      height: 52,
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.fromLTRB(14, 0, 20, 0),
                      decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(26)),
                      child: Row(
                        children: [
                          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: KColors.muted)),
                          const SizedBox(width: 10),
                          Text(
                            l10n.assistantRecognisingVoice,
                            style: KText.s(18, weight: FontWeight.w600, color: KColors.muted),
                          ),
                        ],
                      ),
                    )
                  else if (_speaker case final who?)
                    Padding(padding: const EdgeInsets.only(right: 14), child: _speakerChip(who)),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.fromLTRB(16, 0, 20, 0),
                    decoration: BoxDecoration(color: glass, borderRadius: BorderRadius.circular(26)),
                    child: Row(
                      children: [
                        KBlink(
                          enabled: blink != null,
                          period: blink ?? const Duration(milliseconds: 1200),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: statusFg, shape: BoxShape.circle),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          status,
                          style: KText.s(19, weight: FontWeight.w700, color: statusFg),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  KCircleButton(icon: KIcons.close, size: 72, iconSize: 28, stroke: 2.2, bg: glass, border: null, onTap: _close),
                ],
              ),
            ),
            // A Nabu
            AnimatedPadding(
              duration: const Duration(milliseconds: 600),
              curve: kEase,
              padding: EdgeInsets.only(top: chat ? 8 : 64),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: kEase,
                    width: chat ? 300 : 440,
                    height: chat ? 300 : 440,
                    child: NabuMascot(
                      mood: switch (stage) {
                        _Stage.listening => NabuMood.listening,
                        _Stage.thinking => NabuMood.thinking,
                        _Stage.speaking => NabuMood.speaking,
                        _Stage.ready => NabuMood.idle,
                      },
                      talking: _speakReplies && _satellite.phase.value == SatellitePhase.speaking,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(phase, style: KText.d(34, color: stage == _Stage.listening ? KColors.accentFg : KColors.ink2)),
                ],
              ),
            ),
            Expanded(child: chat ? _chat(stage) : _fresh(stage, voice)),
            // Comandos
            AnimatedPadding(
              duration: const Duration(milliseconds: 340),
              curve: kEase,
              padding: EdgeInsets.only(top: 24, bottom: _typing ? 720 : 96),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  KCircleButton(icon: _keyboardIcon, size: 80, iconSize: 32, stroke: 1.9, bg: glass, border: null, onTap: _typing ? _closeTyping : _openTyping),
                  const SizedBox(width: 56),
                  _MicButton(
                    listening: stage == _Stage.listening,
                    stop: stage == _Stage.thinking || stage == _Stage.speaking,
                    enabled: voice || stage == _Stage.thinking || stage == _Stage.speaking,
                    onTap: _tapMic,
                  ),
                  const SizedBox(width: 56),
                  KCircleButton(
                    icon: _speakReplies ? KIcons.volHigh : _muteIcon,
                    size: 80,
                    iconSize: 32,
                    bg: glass,
                    fg: _speakReplies ? KColors.ink : KColors.disabledFg,
                    border: null,
                    onTap: () {
                      setState(() => _speakReplies = !_speakReplies);
                      _onPhase();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        // Escrever: barra de texto por cima do teclado da app
        if (_typing) Positioned(left: 0, right: 0, bottom: 600, child: _SlideIn(child: _typingBar())),
        if (_sentToast case final text?)
          Positioned(
            left: 0,
            right: 0,
            bottom: 330,
            child: Center(child: _SlideIn(fadeOnly: true, child: _sentToastBar(text))),
          ),
        if (_choosing case final c?) ...[
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _choosing = null),
              child: const ColoredBox(color: Color(0x5917191C)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 300,
            child: Center(child: _SlideIn(child: _chooser(c))),
          ),
        ],
      ],
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final reversing = anim.status == AnimationStatus.reverse;
        final t = reversing ? Curves.easeIn.transform(anim.value) : kEase.transform(anim.value);
        final dy = reversing ? 30 * (1 - t) : 40 * (1 - t);
        return Stack(
          children: [
            Positioned.fill(
              child: Opacity(opacity: Curves.ease.transform(anim.value), child: _backdrop()),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(0, dy), child: child),
              ),
            ),
          ],
        );
      },
      // The typing bar's TextField needs a Material above it.
      child: Material(type: MaterialType.transparency, child: content),
    );
  }

  /// Frosted glass over the app, with a soft glow behind Nabu. Always the
  /// design's "lite" glass (no live blur): a full-screen backdrop blur
  /// under an animated owl is more than the Pi's GPU can keep up with.
  Widget _backdrop() {
    final page = KColors.page;
    final glow = KColors.accent;
    return GestureDetector(
      onTap: _close,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.45, 1],
            colors: [page.withValues(alpha: 0.93), page.withValues(alpha: 0.96), Color.lerp(page, KColors.accentSoft, 0.7)!.withValues(alpha: 0.98)],
          ),
        ),
        foregroundDecoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.7), radius: 0.54, colors: [glow.withValues(alpha: 0.16), glow.withValues(alpha: 0)]),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// A ouvir, before anything was said: the prompt in large type and
  /// suggestions to tap.
  Widget _fresh(_Stage stage, bool voice) {
    final prompt = stage == _Stage.listening || !voice ? (voice ? l10n.assistantPromptSay : l10n.assistantPromptType) : l10n.assistantPromptTapMic;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(120, 72, 120, 0),
      child: Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: prompt),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(padding: const EdgeInsets.only(left: 6), child: _Caret(width: 4, height: 52)),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: KText.d(56, weight: FontWeight.w400, height: 1.2, spacing: -0.5, color: KColors.faint),
          ),
          const SizedBox(height: 48),
          Text(
            l10n.assistantExamplesHeading,
            style: KText.s(15, weight: FontWeight.w700, spacing: 1, color: KColors.muted),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final g in _suggestions)
                  KPress(
                    onTap: () => _send(g),
                    child: Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.82), borderRadius: BorderRadius.circular(32)),
                      child: Center(
                        widthFactor: 1,
                        child: Text(g, style: KText.s(21, weight: FontWeight.w600)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Conversa: newest at the bottom, the list kept scrolled to it as
  /// answers are written out; content fades out under the edges.
  Widget _chat(_Stage stage) {
    // Fades the list itself (mask-image), so the edges melt into whatever
    // glass is behind them in either theme.
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (r) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: [0, 40 / r.height, 1 - 40 / r.height, 1],
        colors: const [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
      ).createShader(r),
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                reverse: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  // Only vertical padding here: a row of web cards runs the
                  // full width of the screen; everything else is inset.
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _messages.length; i++) ...[
                          if (i > 0) const SizedBox(height: 22),
                          _SlideIn(key: ValueKey(i), child: _messages[i].user ? _inset(_userBubble(_messages[i].text)) : _botMessage(i)),
                        ],
                        if (stage == _Stage.thinking) ...[
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(left: _inner + 72),
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                              decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.9), borderRadius: _botRadius),
                              child: const _Dots(),
                            ),
                          ),
                        ],
                        if (stage == _Stage.listening) ...[const SizedBox(height: 22), _inset(_userBubble(l10n.assistantPromptSay, live: true))],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The conversation's side margin.
  static const _inner = 120.0;

  Widget _inset(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _inner),
    child: child,
  );

  static const _userRadius = BorderRadius.only(
    topLeft: Radius.circular(30),
    topRight: Radius.circular(30),
    bottomRight: Radius.circular(10),
    bottomLeft: Radius.circular(30),
  );
  static const _botRadius = BorderRadius.only(
    topLeft: Radius.circular(10),
    topRight: Radius.circular(30),
    bottomRight: Radius.circular(30),
    bottomLeft: Radius.circular(30),
  );

  Widget _userBubble(String text, {bool live = false}) => Align(
    alignment: Alignment.centerRight,
    child: FractionallySizedBox(
      widthFactor: 0.72,
      alignment: Alignment.centerRight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(color: live ? KColors.accent.withValues(alpha: 0.12) : KColors.accent, borderRadius: _userRadius),
          child: Text(
            text,
            style: KText.s(24, height: 1.38, color: live ? KColors.accentFg : KColors.onAccent).copyWith(fontStyle: live ? FontStyle.italic : null),
          ),
        ),
      ),
    ),
  );

  Widget _botMessage(int i) {
    final m = _messages[i];
    final revealing = _revealing == i;
    if (m.cards.isEmpty && m.skeletons == 0) return _inset(_botBubble(i, m, revealing));
    // The bubble's text starts past Nabu's avatar; the cards line up with it.
    const start = _inner + 72;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _inset(_botBubble(i, m, revealing)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: start + 6),
          child: Text(
            m.cards.isEmpty ? l10n.assistantWebLoading : _webLabel(m.cards),
            style: KText.s(15, weight: FontWeight.w700, spacing: 1, color: KColors.muted),
          ),
        ),
        const SizedBox(height: 10),
        // Fades out at both sides of the screen; the rest is a scroll away.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => LinearGradient(
            stops: [0, 110 / r.width, 1 - 150 / r.width, 1],
            colors: const [Color(0x00000000), Color(0xFF000000), Color(0xFF000000), Color(0x00000000)],
          ).createShader(r),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(start, 2, 140, 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var n = 0; n < m.cards.length; n++) ...[if (n > 0) const SizedBox(width: 16), _webCard(m.cards[n])],
                  // Cards still being read from their pages.
                  for (var n = 0; n < m.skeletons; n++) ...[if (n > 0 || m.cards.isNotEmpty) const SizedBox(width: 16), const _CardSkeleton()],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _botBubble(int i, _Msg m, bool revealing) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 4), child: NabuAvatar()),
            const SizedBox(width: 16),
            Flexible(
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                      decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.9), borderRadius: _botRadius),
                      child: m.writing
                          ? _writing(m)
                          : _Reveal(
                              text: m.text,
                              active: revealing,
                              style: KText.s(24, height: 1.38),
                              onDone: () {
                                if (mounted && _revealing == i) setState(() => _revealing = null);
                              },
                            ),
                    ),
                    if (!revealing)
                      for (final id in m.entityIds)
                        if (_layer.view(id, _real[id]) case final e?) Padding(padding: const EdgeInsets.only(top: 12), child: _resultRow(e)),
                    if (!revealing && m.url != null) Padding(padding: const EdgeInsets.only(top: 12), child: _webRow(m.url!)),
                    if (!revealing)
                      for (final r in m.results) Padding(padding: const EdgeInsets.only(top: 12), child: _toolRow(r)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The answer while it's still being written: the text so far with a
  /// caret, and a note that the final one is on its way.
  Widget _writing(_Msg m) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text.rich(
        TextSpan(
          children: [
            TextSpan(text: m.text),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(padding: const EdgeInsets.only(left: 4), child: _Caret(width: 3, height: 26)),
            ),
          ],
        ),
        style: KText.s(24, height: 1.38),
      ),
      const SizedBox(height: 12),
      CustomPaint(size: const Size.fromHeight(1.5), painter: _DashPainter(KColors.ink.withValues(alpha: 0.12))),
      const SizedBox(height: 10),
      Row(
        children: [
          const _Dots(size: 7, accent: true),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              m.searching ? l10n.assistantSearchingAndWriting : l10n.assistantWriting,
              style: KText.s(16, weight: FontWeight.w600, color: KColors.muted),
            ),
          ),
        ],
      ),
    ],
  );

  static const _calendarIcon = '<path d="M4 6h16v14H4zM4 10h16M9 3v4M15 3v4"/>';
  static const _taskIcon = '<path d="M4 4h16v16H4zM8 12l3 3 5-6"/>';
  static const _forkIcon = '<path d="M7 3v8a2 2 0 0 0 2 2v8M11 3v8a2 2 0 0 1-2 2M9 3v6M17 21V3c-2 1.5-3 4-3 7v4h3"/>';
  static const _cartIcon = '<path d="M3 4h2l2.4 11h11L21 8H6"/>';
  static const _callIcon = '<path d="M5 4h3l2 5-2.5 1.5a11 11 0 0 0 6 6L15 14l5 2v3a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2z"/>';

  /// One of the agent's actions, under its answer (design: NabuAcoes).
  Widget _toolRow(_Result r) {
    final (icon, bg, fg) = switch (r.kind) {
      'event' => (_calendarIcon, KColors.blueTint, KColors.blue),
      'task' => (_taskIcon, KColors.accentSoft, KColors.accentFg),
      'task_done' => (KIcons.check, KColors.greenTint, KColors.greenInk),
      'meal_question' => (_forkIcon, KColors.orangeTint, KColors.orangeInk),
      'meals' => (_forkIcon, KColors.accentSoft, KColors.accentFg),
      'shop' => (_cartIcon, KColors.accentSoft, KColors.accentFg),
      'note' || 'recado' => (recadoIcon, KColors.orangeTint, KColors.orangeInk),
      'sent' => (_phoneIcon, KColors.accentSoft, KColors.accentFg),
      'calls' => (_callIcon, KColors.redTint, KColors.redInk),
      _ => (KIcons.check, KColors.chipAlt, KColors.ink2),
    };
    final (String? actionLabel, VoidCallback? action) = switch (r.kind) {
      'event' || 'task' when r.undo != null && r.answer == null => (l10n.assistantUndo, () => _undo(r)),
      'recado' when r.answer == null => (l10n.recadoSeen, () => _recadoSeen(r)),
      'sent' when r.url != null => (l10n.assistantOtherPerson, () => setState(() => _choosing = _WebCard({'url': r.url, 'title': r.pageTitle ?? r.url}))),
      'calls' => (l10n.assistantSeeHistory, _openDoorHistory),
      _ => (null, null),
    };
    final title = switch (r.answer) {
      'desfeito' => l10n.assistantResultUndone(r.title),
      'visto' => l10n.assistantResultSeen(r.title),
      _ => r.title,
    };
    return _SlideIn(
      fadeOnly: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: KIcon(icon, size: 28, color: fg),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: KText.s(21, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r.state,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: KText.s(17, color: KColors.muted),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(width: 16),
                  KButton(label: actionLabel, height: 56, fontSize: 19, padding: const EdgeInsets.symmetric(horizontal: 22), onTap: r.busy ? null : action),
                ],
              ],
            ),
            if (r.chips.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 12, 0, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in r.chips)
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(20)),
                        child: Center(
                          widthFactor: 1,
                          child: Text(c, style: KText.s(18, weight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ),
              ),
            if (r.lines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 8, 0, 0),
                child: Column(
                  children: [
                    for (final l in r.lines)
                      Container(
                        constraints: const BoxConstraints(minHeight: 48),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: KColors.ink.withValues(alpha: 0.06), width: 1.5)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 80, child: Text('${l['time']}', style: KText.d(24))),
                            const SizedBox(width: 16),
                            Expanded(child: Text('${l['label']}', style: KText.s(19))),
                            Container(
                              height: 32,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: l['tone'] == 'danger' ? KColors.redTint : KColors.greenTint,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${l['state']}',
                                style: KText.s(15, weight: FontWeight.w700, color: l['tone'] == 'danger' ? KColors.red : KColors.greenInk),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            if (r.kind == 'meal_question')
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 12, 0, 0),
                child: r.answer == null
                    ? Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          KButton.primary(label: l10n.assistantMealsYesReplace, height: 60, fontSize: 20, onTap: r.busy ? null : () => _confirmMeals(r, true)),
                          KButton(label: l10n.commonNo, height: 60, fontSize: 20, onTap: r.busy ? null : () => _confirmMeals(r, false)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              KIcon(KIcons.mic, size: 20, color: KColors.muted),
                              const SizedBox(width: 8),
                              Text(l10n.assistantMealsVoiceHint, style: KText.s(17, color: KColors.muted)),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          KIcon(KIcons.check, size: 22, stroke: 2.6, color: KColors.greenInk),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.answer == 'sim' ? r.yesText : r.noText,
                              style: KText.s(19, weight: FontWeight.w600, color: KColors.greenInk),
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _undo(_Result r) async {
    setState(() => r.busy = true);
    try {
      await ref.read(haWebSocketClientProvider).command('bytehomedash/undo', {'token': r.undo});
      if (mounted) setState(() => r.answer = 'desfeito');
    } catch (e) {
      KToast.error(e);
    } finally {
      if (mounted) setState(() => r.busy = false);
    }
  }

  Future<void> _confirmMeals(_Result r, bool replace) async {
    setState(() => r.busy = true);
    try {
      await ref.read(haWebSocketClientProvider).command('bytehomedash/confirm_meals', {'token': r.confirm, 'replace': replace});
      if (mounted) setState(() => r.answer = replace ? 'sim' : 'nao');
    } catch (e) {
      KToast.error(e);
    } finally {
      if (mounted) setState(() => r.busy = false);
    }
  }

  Future<void> _recadoSeen(_Result r) async {
    setState(() => r.answer = 'visto');
    try {
      await ref.read(familyMessagesProvider.notifier).markSeen({if (r.messageId case final id?) id});
    } catch (e) {
      if (mounted) setState(() => r.answer = null);
      KToast.error(e);
    }
  }

  /// "Ver histórico": the intercom, already on its call history.
  void _openDoorHistory() {
    if (!ref.read(hasIntercomProvider)) return;
    final nav = Navigator.of(context, rootNavigator: true);
    _close();
    WidgetsBinding.instance.addPostFrameCallback((_) => showIntercom(nav.context, history: true));
  }

  Widget _resultRow(HaEntity e) {
    const toggles = {'light', 'switch', 'fan', 'input_boolean'};
    final d = e.domain;
    final (icon, bg, fg) = switch (d) {
      _ when toggles.contains(d) => e.isOn ? (KIcons.bulb, KColors.amberTint, KColors.amberInk) : (KIcons.bulb, KColors.chipAlt, KColors.ink2),
      'media_player' => (KIcons.music, KColors.accentSoft, KColors.accentFg),
      'weather' => (weatherIcon(e.state), KColors.blueTint, KColors.blueInk),
      'climate' || 'water_heater' => (KIcons.flame, KColors.orangeTint, KColors.orangeInk),
      'cover' => (KIcons.house, KColors.blueTint, KColors.blueInk),
      'lock' => (KIcons.lock, KColors.greenTint, KColors.greenInk),
      _ => (KIcons.check, KColors.chipAlt, KColors.ink2),
    };
    final brightness = numAttr(e, 'brightness');
    final title = d == 'media_player' ? (e.attributes['media_title'] as String? ?? e.friendlyName) : e.friendlyName;
    final state = switch (d) {
      'light' =>
        e.isOn ? (brightness == null ? l10n.assistantLightOn : l10n.assistantLightOnBrightness((brightness / 255 * 100).round())) : l10n.assistantLightOff,
      _ when toggles.contains(d) => e.isOn ? l10n.commonOn : l10n.commonOff,
      'media_player' => '${e.state == 'playing' ? l10n.assistantMediaPlaying : l10n.assistantMediaPaused} · ${e.friendlyName}',
      'weather' => weatherLabel(e.state).isEmpty ? e.displayState : weatherLabel(e.state),
      'climate' => e.state == 'off' ? l10n.commonOff : l10n.assistantClimateOn(fmtDeg(numAttr(e, 'current_temperature')), fmtDeg(numAttr(e, 'temperature'))),
      'lock' => e.state == 'locked' ? l10n.assistantLocked : l10n.assistantUnlocked,
      'cover' => e.state == 'closed' ? l10n.assistantCoverClosed : l10n.assistantCoverOpen,
      _ => e.displayState,
    };
    final Widget? trailing = switch (d) {
      _ when e.isUnavailable => null,
      _ when toggles.contains(d) => _Switch(on: e.isOn, onTap: () => _toggle(e)),
      'media_player' => KCircleButton(
        icon: e.state == 'playing' ? KIcons.pauseFilled : KIcons.playFilled,
        size: 56,
        iconSize: 24,
        bg: KColors.accent,
        fg: KColors.onAccent,
        border: null,
        onTap: () => _playPause(e),
      ),
      'weather' => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(fmtDeg(numAttr(e, 'temperature')), style: KText.d(30)),
      ),
      _ => null,
    };
    return _SlideIn(
      fadeOnly: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: KIcon(icon, size: 28, color: fg),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(21, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(17, color: KColors.muted),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 16), trailing],
          ],
        ),
      ),
    );
  }

  /// One web result, from the page's own data: picture, title, rating,
  /// price, what it is (time, cuisine, channel…) and the site. Tapping
  /// opens it in the browser; the button on the picture sends it to a phone.
  Widget _webCard(_WebCard c) {
    final video = c.kind == 'video';
    final wide = video || c.kind == 'news';
    final kicker = switch (c.kind) {
      'news' || 'article' => [if (c.section case final s?) s, if (c.date case final d?) _ago(d)].join(' · '),
      _ => '',
    };
    // Not `[?a, ?b]`: null-aware elements crash the Pi's release compiler.
    final meta = switch (c.kind) {
      'recipe' => [
        if (c.minutes case final m?) _duration(m),
        if (c.servings case final v?) RegExp(r'^\d+$').hasMatch(v) ? l10n.assistantServings(int.parse(v)) : v,
      ].join(' · '),
      'place' => [if (c.cuisine case final v?) v, if (c.priceRange case final v?) v].join(' · '),
      'video' => [if (c.channel case final v?) v, if (c.views case final v?) _viewsLabel(v)].join(' · '),
      _ => '',
    };
    final price = c.price == null ? null : l10n.assistantPrice(fmtDec(c.price!, decimals: 2), c.currency == 'EUR' || c.currency == null ? '€' : c.currency!);
    final placeholder = ColoredBox(
      color: KColors.chipAlt,
      child: Center(child: KIcon(_kindIcons[c.kind] ?? _globeIcon, size: 56, stroke: 1.6, color: KColors.ink.withValues(alpha: 0.32))),
    );
    return KPress(
      onTap: () => _openSite(c.url),
      child: Container(
        width: wide ? 400 : 320,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: KColors.card,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x1417191C), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: video ? 225 : 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (c.image case final img?) Image.network(img, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder) else placeholder,
                  if (video)
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Color(0x9917191C), shape: BoxShape.circle),
                        child: const KIcon(_playIcon, size: 30, color: Colors.white, solid: true),
                      ),
                    ),
                  if (c.duration case final d? when video)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: const Color(0xBF17191C), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          _clock(d),
                          style: KText.s(15, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(right: 10, top: 10, child: _sendButton(c)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kicker.isNotEmpty) ...[
                    Text(
                      kicker,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(14, weight: FontWeight.w600, color: KColors.muted),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(20, weight: FontWeight.w600, height: 1.25),
                  ),
                  if (c.rating case final r?) ...[const SizedBox(height: 6), _stars(r, c.ratingCount)],
                  if (price != null) ...[const SizedBox(height: 6), Text(price, style: KText.d(24))],
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(16, color: KColors.muted),
                    ),
                  ],
                  if (c.kind == 'place' && c.address != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      c.address!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: KText.s(16, weight: FontWeight.w600, color: KColors.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    c.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(14, color: KColors.faint),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The rating, five stars filled to it, and how many rated. Icons, not
  /// "★": the app's fonts have no star.
  Widget _stars(double r, int? count) {
    Widget row(Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [for (var i = 0; i < 5; i++) KIcon(KIcons.star, size: 18, stroke: 1.2, color: color, solid: true)],
    );
    return Row(
      children: [
        Text(fmtDec(r), style: KText.s(16, weight: FontWeight.w700)),
        const SizedBox(width: 8),
        Stack(
          children: [
            row(const Color(0xFFD9D4CB)),
            ClipRect(
              child: Align(alignment: Alignment.centerLeft, widthFactor: (r / 5).clamp(0.0, 1.0), child: row(const Color(0xFFE8A33A))),
            ),
          ],
        ),
        if (count != null) ...[const SizedBox(width: 8), Text('(${_thousands(count)})', style: KText.s(16, color: KColors.muted))],
      ],
    );
  }

  Widget _sendButton(_WebCard c) {
    final state = _sent[c.url];
    final sent = state == _Send.sent;
    final fg = sent ? KColors.onAccent : KColors.ink;
    return KPress(
      onTap: () => _sendCard(c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        padding: EdgeInsets.fromLTRB(12, 0, sent ? 16 : 12, 0),
        decoration: BoxDecoration(
          color: sent ? KColors.accent : KColors.card.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x2E17191C), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: switch (state) {
            null => [KIcon(_phoneIcon, size: 24, color: fg)],
            _Send.sending => [SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: fg))],
            _Send.sent => [
              KIcon(KIcons.check, size: 22, stroke: 2.6, color: fg),
              const SizedBox(width: 8),
              Text(
                l10n.assistantSent,
                style: KText.s(15, weight: FontWeight.w700, color: fg),
              ),
            ],
          },
        ),
      ),
    );
  }

  Widget _speakerChip(String who) {
    final member = ref.watch(familyMembersProvider).where((m) => m.name == who).firstOrNull;
    return Semantics(
      label: l10n.assistantSpeakerSemantics(who),
      child: Container(
        height: 52,
        padding: const EdgeInsets.fromLTRB(6, 0, 18, 0),
        decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(26)),
        child: Row(
          children: [
            _personDot(who, member, 40, 18),
            const SizedBox(width: 10),
            Text(who.split(' ').first, style: KText.s(19, weight: FontWeight.w700)),
            const SizedBox(width: 10),
            KIcon(_waveIcon, size: 22, stroke: 2.2, color: KColors.accentFg),
          ],
        ),
      ),
    );
  }

  Widget _personDot(String name, FamilyMember? member, double size, double font) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: member?.color.color ?? KColors.muted, shape: BoxShape.circle),
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: KText.s(font, weight: FontWeight.w700, color: Colors.white),
    ),
  );

  Widget _sentToastBar(String text) => Container(
    height: 80,
    padding: const EdgeInsets.fromLTRB(26, 0, 12, 0),
    decoration: BoxDecoration(
      color: const Color(0xFF17191C),
      borderRadius: BorderRadius.circular(40),
      boxShadow: const [BoxShadow(color: Color(0x4D17191C), blurRadius: 30, offset: Offset(0, 10))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const KIcon(KIcons.check, size: 26, stroke: 2.6, color: Colors.white),
        const SizedBox(width: 18),
        Text(
          text,
          style: KText.s(21, weight: FontWeight.w600, color: Colors.white),
        ),
        if (_sentCard != null) ...[
          const SizedBox(width: 18),
          KPress(
            onTap: () {
              _sentToastTimer?.cancel();
              setState(() {
                _sentToast = null;
                _choosing = _sentCard;
              });
            },
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(28)),
              child: Text(
                l10n.assistantOtherPerson,
                style: KText.s(18, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  /// "Para quem envio?": the people with the Home Assistant app on their
  /// phone; whoever is speaking first.
  Widget _chooser(_WebCard c) {
    final members = ref.watch(familyMembersProvider);
    final phones = (_phones ?? const <String, String>{}).entries.toList()..sort((a, b) => (b.key == _speaker ? 1 : 0) - (a.key == _speaker ? 1 : 0));
    return Container(
      width: 640,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KColors.card,
        borderRadius: BorderRadius.circular(36),
        boxShadow: const [BoxShadow(color: Color(0x4D17191C), blurRadius: 60, offset: Offset(0, 20))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Text(_speaker == null ? l10n.assistantChooserWho : l10n.assistantChooserSendTo, style: KText.d(34)),
          ),
          if (_speaker == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
              child: Text(l10n.assistantChooserNotRecognised, style: KText.s(19, color: KColors.ink2, height: 1.4)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              '${c.title} · ${c.host}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(18, color: KColors.muted),
            ),
          ),
          if (phones.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(24)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KIcon(KIcons.info, size: 26, color: KColors.orangeInk),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(l10n.assistantChooserNoPhones, style: KText.s(19, color: KColors.orangeInk, height: 1.45)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: KButton.primary(label: l10n.assistantGotIt, height: 64, fontSize: 20, onTap: () => setState(() => _choosing = null)),
            ),
          ],
          for (final p in phones) ...[
            const SizedBox(height: 10),
            KPress(
              onTap: () => _sendTo(c, p.key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 84),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: p.key == _speaker ? KColors.accentSoft : KColors.sub, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    _personDot(p.key, members.where((m) => m.name == p.key).firstOrNull, 52, 22),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.key, style: KText.s(21, weight: FontWeight.w600)),
                          if (p.value.isNotEmpty) Text(p.value, style: KText.s(16, color: KColors.muted)),
                        ],
                      ),
                    ),
                    if (p.key == _speaker)
                      Text(
                        l10n.assistantSpeakingNow,
                        style: KText.s(15, weight: FontWeight.w600, color: KColors.accentFg),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _duration(int m) => m >= 60 ? '${m ~/ 60} h${m % 60 > 0 ? ' ${m % 60} min' : ''}' : '$m min';

  static String _clock(int s) {
    final h = s ~/ 3600, m = s % 3600 ~/ 60, sec = (s % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$sec' : '$m:$sec';
  }

  static String _thousands(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+$)'), (_) => ' ');

  static String _viewsLabel(int n) {
    if (n >= 1000000) {
      final m = n / 1000000;
      return l10n.assistantViewsMillions(fmtDec(m, decimals: n < 10000000 && !m.toStringAsFixed(1).endsWith('.0') ? 1 : 0));
    }
    return n >= 1000 ? l10n.assistantViewsThousands(n ~/ 1000) : l10n.assistantViews(n);
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 60) return l10n.assistantAgoMinutes(diff.inMinutes.clamp(1, 59));
    if (diff.inHours < 24) return l10n.assistantAgoHours(diff.inHours);
    if (diff.inDays < 7) return l10n.assistantAgoDays(diff.inDays);
    return '${d.toLocal().day}/${d.toLocal().month}/${d.toLocal().year}';
  }

  /// A site from the answer, opened in the browser.
  Widget _webRow(String url) {
    final uri = Uri.tryParse(url);
    return _SlideIn(
      fadeOnly: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
        decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: KColors.accentSoft, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: KIcon(_globeIcon, size: 28, color: KColors.accentFg),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uri?.host ?? url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(21, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(17, color: KColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            KPress(
              onTap: () => _openSite(url),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: KColors.accent, borderRadius: BorderRadius.circular(28)),
                child: Text(
                  l10n.commonOpen,
                  style: KText.s(19, weight: FontWeight.w600, color: KColors.onAccent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBar() => Padding(
    padding: const EdgeInsets.fromLTRB(120, 0, 120, 24),
    child: Container(
      height: 84,
      padding: const EdgeInsets.fromLTRB(28, 0, 12, 0),
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(42), boxShadow: KColors.shadowFloat),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _draft,
              focusNode: _focus,
              maxLines: 1,
              // flutter-pi has no IME; the on-screen keyboard is ours.
              keyboardType: TextInputType.none,
              cursorColor: KColors.accentFg,
              style: KText.s(26, height: 1.2, spacing: 0),
              onSubmitted: _send,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: l10n.assistantTypeHint,
                hintStyle: KText.s(26, color: KColors.faint, height: 1.2, spacing: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Its own listener: typed keys never reach TextField.onChanged
          // from the on-screen keyboard.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _draft,
            builder: (context, v, _) {
              final ready = v.text.trim().isNotEmpty;
              return KCircleButton(
                icon: _sendIcon,
                size: 64,
                iconSize: 28,
                stroke: 2.4,
                bg: ready ? KColors.accent : KColors.ring,
                fg: KColors.onAccent,
                border: null,
                onTap: ready ? () => _send(_draft.text) : null,
              );
            },
          ),
        ],
      ),
    ),
  );
}

/// The 136 px mic, always the accent. While listening a ring pulses out of
/// it (the design's `dcMic`: 34 px, 1.6 s, ease-out, done by 75%); while
/// thinking or answering it becomes a stop button.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.listening, required this.stop, required this.enabled, required this.onTap});

  final bool listening;
  final bool stop;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.listening) _c.repeat();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    if (widget.listening == old.listening) return;
    if (widget.listening) {
      _c.repeat();
    } else {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = KColors.accent;
    // Its own layer, so the ripple doesn't repaint the screen every frame.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          final k = Curves.easeOut.transform((v / 0.75).clamp(0.0, 1.0));
          return Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: KCircleButton(
              icon: widget.stop ? _stopIcon : KIcons.micStand,
              size: 136,
              iconSize: 56,
              bg: accent,
              fg: KColors.onAccent,
              border: null,
              shadow: [
                BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 34, offset: const Offset(0, 14)),
                if (widget.listening && v < 0.75)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.45 * (1 - k)),
                    spreadRadius: 34 * k,
                  ),
              ],
              onTap: widget.enabled ? widget.onTap : null,
            ),
          );
        },
      ),
    );
  }
}

/// 76×44 switch on a result row.
class _Switch extends StatelessWidget {
  const _Switch({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KPress(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 76,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: on ? KColors.accent : KColors.ring, borderRadius: BorderRadius.circular(22)),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 260),
        curve: kEase,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(color: KColors.onAccent, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}

/// The design's `dcSlideUp` (.35 s, rising 24 px) as a message appears, or
/// `dcFadeIn` (.3 s) with [fadeOnly].
class _SlideIn extends StatefulWidget {
  const _SlideIn({super.key, required this.child, this.fadeOnly = false});

  final Widget child;
  final bool fadeOnly;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.fadeOnly ? 300 : 350),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final t = (widget.fadeOnly ? Curves.ease : kEase).transform(_c.value);
      return Opacity(
        opacity: t,
        child: widget.fadeOnly ? child : Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
      );
    },
    child: RepaintBoundary(child: widget.child),
  );
}

/// An answer written out at the pace of speech, with a caret while it is.
/// The design adds 2 characters every 45 ms; this adds 4 every 90 ms —
/// the same pace at half the redraws, which the Pi needs.
class _Reveal extends StatefulWidget {
  const _Reveal({required this.text, required this.active, required this.style, required this.onDone});

  final String text;
  final bool active;
  final TextStyle style;
  final VoidCallback onDone;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  Timer? _timer;
  late int _n = widget.active ? 0 : widget.text.length;

  @override
  void initState() {
    super.initState();
    if (widget.active) _start();
  }

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (!widget.active && old.active) {
      _timer?.cancel();
      _n = widget.text.length;
    }
  }

  void _start() {
    _timer = Timer.periodic(const Duration(milliseconds: 90), (t) {
      if (!mounted) return t.cancel();
      if (_n >= widget.text.length) {
        t.cancel();
        widget.onDone();
        return;
      }
      setState(() => _n = (_n + 4).clamp(0, widget.text.length));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = widget.text.substring(0, _n.clamp(0, widget.text.length));
    if (!widget.active) return Text(widget.text, style: widget.style);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: shown),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(padding: EdgeInsets.only(left: 4), child: _Caret(width: 3, height: 26)),
          ),
        ],
      ),
      style: widget.style,
    );
  }
}

/// The accent caret, blinking in steps (`dcBlink 1s steps(1)`).
class _Caret extends StatefulWidget {
  const _Caret({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> {
  late final Timer _timer;
  bool _dim = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dim = !_dim);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Opacity(
      opacity: _dim ? 0.3 : 1,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: KColors.accentFg, borderRadius: BorderRadius.circular(2)),
      ),
    ),
  );
}

/// Three dots pulsing one after another (`dcBlink 1s`, .2 s apart).
class _Dots extends StatefulWidget {
  const _Dots({this.size = 12, this.accent = false});

  final double size;

  /// In the accent colour (the "A escrever…" note) instead of faint.
  final bool accent;

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ? KColors.accentFg : KColors.faint;
    final size = widget.size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) SizedBox(width: size * 0.75),
              Opacity(
                opacity: 1 - 0.7 * _wave((_c.value - i * 0.2) % 1),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static double _wave(double p) => Curves.easeInOut.transform(p < 0.5 ? p * 2 : (1 - p) * 2);
}

/// A dashed rule, across the width.
class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, size.height / 2), Offset((x + 5).clamp(0, size.width), size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}

/// A web card still being read from its page: the card's shape, its picture
/// shimmering.
class _CardSkeleton extends StatefulWidget {
  const _CardSkeleton();

  @override
  State<_CardSkeleton> createState() => _CardSkeletonState();
}

class _CardSkeletonState extends State<_CardSkeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = KColors.chipAlt, light = KColors.sub;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(h / 2)),
    );
    return Container(
      width: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: KColors.card.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment(-1 + 2 * _c.value - 1, 0), end: Alignment(1 + 2 * _c.value - 1, 0), colors: [base, light, base]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [bar(256, 18), const SizedBox(height: 10), bar(176, 18), const SizedBox(height: 10), bar(128, 14)],
            ),
          ),
        ],
      ),
    );
  }
}
