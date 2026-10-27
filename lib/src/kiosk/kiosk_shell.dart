import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../music/music_store.dart';
import '../providers/ha_providers.dart';
import '../services/device_identity.dart';
import '../services/doorbell_history.dart';
import '../services/doorbell_ringer.dart';
import '../services/screen_power_controller.dart';
import '../services/voice_satellite.dart';
import '../sheets/sheet_registry.dart';
import '../utils/optimistic.dart';
import 'browser/browser.dart';
import 'data/calendar_data.dart';
import 'data/chores_data.dart';
import 'data/house_config.dart';
import 'data/kiosk_hydration.dart';
import 'data/meals_data.dart';
import 'data/messages_data.dart';
import 'data/settings_live_reload.dart';
import 'modals/assistant_modal.dart';
import 'modals/intercom_modal.dart';
import 'modals/kitchen_modal.dart';
import 'modals/recado_modal.dart';
import 'pages/calendar_page.dart';
import 'pages/home_page.dart';
import 'pages/house_page.dart';
import 'pages/lists_page.dart';
import 'pages/meals_page.dart';
import 'pages/music_page.dart';
import 'pages/settings_page.dart';
import 'pages/tasks_page.dart';
import 'theme/kiosk_icons.dart';
import 'theme/kiosk_tokens.dart';
import 'theme/theme_switch.dart';
import 'widgets/kiosk_header.dart';
import 'widgets/kiosk_nav_bar.dart';
import 'widgets/kiosk_widgets.dart';

/// How long the screen has to stay off before the page resets to Início —
/// long enough that someone briefly blocking the panel isn't yanked back
/// home mid-task.
const _resetToHomeAfterScreenOff = Duration(seconds: 5);

/// The page the shell is showing. A provider (not shell-local state) so a
/// card on one page can send the person to another — Início's "Compras"
/// opening Listas, say.
final kioskPageProvider = StateProvider<KioskPage>((ref) => KioskPage.home);

/// The redesign's frame: header, the current page, the nav bar, and the
/// toast — on the fixed 1440×2560 canvas.
class KioskShell extends ConsumerStatefulWidget {
  const KioskShell({super.key});

  @override
  ConsumerState<KioskShell> createState() => _KioskShellState();
}

class _KioskShellState extends ConsumerState<KioskShell> {
  Timer? _resetToHomeTimer;
  Timer? _calendarRefresh;
  StreamSubscription<Map<String, dynamic>>? _assistantPages;
  DoorbellHistory? _doorHistory;
  Timer? _doorPublish;
  String? _doorPublished;
  StreamSubscription<SatelliteEvent>? _voice;
  StreamSubscription<IntercomMode>? _doorbell;

  @override
  void initState() {
    super.initState();
    _doorbell = ref.read(intercomControllerProvider).callEvents?.listen(_onDoorbell);
    DoorbellRinger.instance.load();
    BrowserPrefs.load();
    // MQTT "open sheet" commands from the old dashboard: the calendar one
    // still has a home here; the rest belonged to screens this design
    // folds into Casa.
    SheetRegistry.instance.register('calendar', (_) async => _go(KioskPage.calendar));
    SheetRegistry.instance.register('temperatures', (_) async => _go(KioskPage.house));
    SheetRegistry.instance.register('ev-left', (_) async => _go(KioskPage.house));
    SheetRegistry.instance.register('ev-right', (_) async => _go(KioskPage.house));
    // The in-app browser's proof of concept, also openable from HA over
    // MQTT (`sheet/open` = `browser`) to test it without a finger on it.
    SheetRegistry.instance.register('browser', (context) async => Browser.open(context));
    // The door camera, e.g. from an HA automation when someone's at the gate.
    SheetRegistry.instance.register('intercom', (context) async {
      if (ref.read(hasIntercomProvider) && !IntercomModal.isOpen) await showIntercom(context);
    });
    SheetRegistry.instance.register('music', (_) async => _go(KioskPage.music));
    SheetRegistry.instance.register('settings', (_) async => _go(KioskPage.settings));
    // The assistant's show_on_screen and show_recipe tools.
    // The kitchen session listens first: a recipe event that starts a new
    // session (below) mustn't also count as a step of it.
    KitchenSession.instance.attach(ref.read(haWebSocketClientProvider));
    _assistantPages = ref.read(haWebSocketClientProvider).assistantEvents.listen(_onAssistantPage);
    // The doorbell calls this screen saw, for the assistant ("quem tocou hoje?").
    _doorHistory = ref.read(intercomControllerProvider).history;
    _doorHistory?.calls.addListener(_onDoorCalls);
    _onDoorCalls();
    SheetRegistry.instance.requestedId.addListener(_onSheetRequested);
    SheetRegistry.instance.closeRequests.addListener(_onCloseRequested);
    ScreenPowerController.instance.isOn.addListener(_onScreenPowerChanged);
    // Saying the wake word opens the Assistente so the conversation shows
    // on screen.
    VoiceSatellite.instance.start();
    unawaited(prepareAssistantVoice(ref));
    trackAssistantSpeaker(ref);
    OptimisticLayer.onNotConfirmed = (message) => KToast.show(message, error: true);
    _voice = VoiceSatellite.instance.events.listen((e) {
      if (e is SatelliteWake && mounted) showAssistant(context, byVoice: true);
    });
    // Calendars edited elsewhere (a phone, HA itself) show up within a few
    // minutes without anyone touching the panel.
    _calendarRefresh = Timer.periodic(const Duration(minutes: 5), (_) {
      if (ScreenPowerController.instance.isOn.value) ref.read(calendarRefreshProvider.notifier).state++;
    });
  }

  @override
  void dispose() {
    SheetRegistry.instance.requestedId.removeListener(_onSheetRequested);
    SheetRegistry.instance.closeRequests.removeListener(_onCloseRequested);
    for (final id in ['calendar', 'temperatures', 'ev-left', 'ev-right', 'music', 'settings']) {
      SheetRegistry.instance.unregister(id);
    }
    ScreenPowerController.instance.isOn.removeListener(_onScreenPowerChanged);
    _resetToHomeTimer?.cancel();
    _calendarRefresh?.cancel();
    _assistantPages?.cancel();
    _doorHistory?.calls.removeListener(_onDoorCalls);
    _doorPublish?.cancel();
    _voice?.cancel();
    _doorbell?.cancel();
    super.dispose();
  }

  /// Someone rang this apartment: wake the screen and show the door, from
  /// whatever page or modal was up. An intercom screen that's already open
  /// switches itself to "A tocar…".
  void _onDoorbell(IntercomMode event) {
    // The speakers ring for as long as the call does.
    if (event != IntercomMode.ringing) {
      DoorbellRinger.instance.stop();
      return;
    }
    if (!mounted) return;
    unawaited(DoorbellRinger.instance.ring(afterWake: !ScreenPowerController.instance.isOn.value));
    ScreenPowerController.instance.setPowered(true);
    if (IntercomModal.isOpen) return;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    showIntercom(context, mode: IntercomMode.ringing);
  }

  /// The assistant asked to show a page or a recipe: the Assistente (and any
  /// other modal) steps aside for it. A recipe step while the kitchen view
  /// is open moves that one (it follows the events itself).
  void _onAssistantPage(Map<String, dynamic> e) {
    if (!mounted) return;
    final action = e['action'];
    if ((action == 'recipe' || action == 'kitchen') && KitchenModal.isOpen) return;
    final kitchen = KitchenSession.instance;
    // «Minimiza» / «sai» while minimised: nothing to show.
    if (action == 'kitchen' && (!kitchen.active || e['command'] == 'minimize' || e['command'] == 'exit')) return;
    if (action != 'show' && action != 'recipe' && action != 'kitchen') return;
    ScreenPowerController.instance.setPowered(true);
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    if (action == 'kitchen') {
      openKitchenView(context);
      return;
    }
    if (action == 'recipe') {
      final recipe = KitchenRecipe(e);
      if (recipe.steps.isEmpty) return;
      // A recipe already cooking takes the step itself (KitchenSession).
      if (kitchen.active && kitchen.recipe.url == recipe.url) {
        openKitchenView(context);
      } else {
        showKitchen(context, recipe);
      }
      return;
    }
    switch (e['page']) {
      case 'início':
        _go(KioskPage.home);
      case 'calendário':
        _go(KioskPage.calendar);
      case 'tarefas':
        _go(KioskPage.tasks);
      case 'refeições':
        _go(KioskPage.meals);
      case 'listas':
        _go(KioskPage.lists);
      case 'casa':
        _go(KioskPage.house);
      case 'música':
        _go(KioskPage.music);
      case 'câmara da porta' when ref.read(hasIntercomProvider):
        showIntercom(context);
      case 'chamadas da porta' when ref.read(hasIntercomProvider):
        showIntercom(context, history: true);
    }
  }

  void _onDoorCalls() {
    _doorPublish?.cancel();
    _doorPublish = Timer(const Duration(seconds: 5), _publishDoorCalls);
  }

  /// Saved with the house's shared settings (`doorbell_calls`, per screen),
  /// where the integration reads it; no pictures leave the screen.
  Future<void> _publishDoorCalls() async {
    final calls = _doorHistory?.calls.value;
    if (calls == null) return;
    final mine = [
      for (final c in calls.take(50))
        {'at': c.at.toUtc().toIso8601String(), 'missed': c.missed, 'answered': c.answeredIndoor || c.answeredHere, 'door_opened': c.doorOpened},
    ];
    final json = jsonEncode(mine);
    if (json == _doorPublished) return;
    try {
      final client = ref.read(haWebSocketClientProvider);
      final raw = await client.getSettings('doorbell_calls');
      await client.setSettings('doorbell_calls', {if (raw is Map) ...raw.cast<String, dynamic>(), screenName(): mine});
      _doorPublished = json;
    } catch (e) {
      debugPrint('[door] history not published: $e');
    }
  }

  void _go(KioskPage page) {
    final current = ref.read(kioskPageProvider);
    if (current == page) return;
    // Meals and tasks are shared with other screens in the house; pick up
    // their edits whenever someone opens the page.
    if (page == KioskPage.meals || page == KioskPage.home) ref.read(mealPlanProvider.notifier).load().ignore();
    if (page == KioskPage.tasks || page == KioskPage.home) ref.read(choresProvider.notifier).load().ignore();
    // Same for the Casa mapping edited in HA's sidebar panel (locks, scenes…).
    if (page == KioskPage.house || page == KioskPage.home) {
      ref.read(houseConfigStoreProvider).read().then((c) {
        if (mounted) ref.read(houseConfigProvider.notifier).state = c;
      }).ignore();
    }
    ref.read(kioskPageProvider.notifier).state = page;
  }

  void _onScreenPowerChanged() {
    _resetToHomeTimer?.cancel();
    _resetToHomeTimer = null;
    if (ScreenPowerController.instance.isOn.value) {
      ref.read(calendarRefreshProvider.notifier).state++;
      unawaited(_recadosOnWake());
      return;
    }
    _resetToHomeTimer = Timer(_resetToHomeAfterScreenOff, () {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
      _go(KioskPage.home);
    });
  }

  /// Unseen recados open on every wake — unless the doorbell woke it (the
  /// intercom comes first) or the wake word did (the Assistente shows them
  /// itself), or the kitchen view is up.
  Future<void> _recadosOnWake() async {
    try {
      await ref.read(familyMessagesProvider.notifier).load();
    } catch (_) {
      return;
    }
    // Let a ring or the wake word open their screen first.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted || ref.read(familyMessagesProvider.notifier).unseen.isEmpty) return;
    if (IntercomModal.isOpen || AssistantModal.isOpen || KitchenModal.isOpen) return;
    unawaited(showRecados(context));
  }

  void _onSheetRequested() {
    final id = SheetRegistry.instance.requestedId.value;
    if (id == null) return;
    SheetRegistry.instance.requestedId.value = null;
    SheetRegistry.instance.dispatch(context, id);
  }

  void _onCloseRequested() => Navigator.of(context, rootNavigator: true).maybePop();

  @override
  Widget build(BuildContext context) {
    final page = ref.watch(kioskPageProvider);
    final nowPlaying = page == KioskPage.music ? ref.watch(musicStoreProvider.select((m) => m.queue?.playing == true ? m.queue?.current?.name : null)) : null;
    ref.watch(settingsLiveReloadProvider);
    // A retry after an error keeps showing the error (it retries on its own,
    // see EntitiesNotifier) rather than flashing the spinner each attempt.
    final load = ref.watch(entitiesProvider.select((a) => (loading: a.isLoading && !a.hasValue && !a.hasError, error: a.hasError ? a.error : null)));
    final settings = ref.watch(settingsHydrationProvider.select((a) => (loading: a.isLoading && !a.hasValue, error: a.hasError ? a.error : null)));
    final kiosk = ref.watch(kioskHydrationProvider.select((a) => a.isLoading && !a.hasValue));
    final loading = load.loading || settings.loading || kiosk;
    final error = load.error ?? settings.error;
    final underNav = page == KioskPage.house && !loading && error == null;

    Widget body;
    if (loading) {
      body = Center(
        child: SizedBox(width: 72, height: 72, child: CircularProgressIndicator(strokeWidth: 6, color: KColors.accentFg)),
      );
    } else if (error != null) {
      body = _ErrorView(message: error.toString(), onRetry: () => ref.invalidate(entitiesProvider));
    } else {
      body = _PageSwitcher(
        page: page,
        child: switch (page) {
          KioskPage.home => const HomePage(),
          KioskPage.calendar => const CalendarPage(),
          KioskPage.tasks => const TasksPage(),
          KioskPage.meals => const MealsPage(),
          KioskPage.lists => const ListsPage(),
          KioskPage.house => const HousePage(),
          KioskPage.music => const MusicPage(),
          KioskPage.settings => const SettingsPage(),
        },
      );
    }

    return ThemeAutoScheduler(
      child: Material(
        color: KColors.page,
        child: DefaultTextStyle(
          style: KText.s(20),
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(56, 56, 56, 0),
                    child: KioskHeader(
                      compact: page != KioskPage.home,
                      subtitle: switch (page) {
                        KioskPage.music => nowPlaying == null ? l10n.navMusic : '♪ $nowPlaying',
                        KioskPage.settings => l10n.shellScreenSettings,
                        _ => null,
                      },
                      onClockTap: () => _go(KioskPage.settings),
                    ),
                  ),
                  // Casa scrolls from right under the header (fading in over
                  // the gap) to the bottom of the screen, beneath the nav bar.
                  if (!underNav) const SizedBox(height: 32),
                  Expanded(
                    child: Padding(padding: EdgeInsets.fromLTRB(56, 0, 56, underNav ? 0 : 32 + 128), child: body),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: KioskNavBar(selected: page, onSelect: _go, onAssistant: () => showAssistant(context), blur: underNav),
              ),
              const BrowserLayer(),
              // Above the browser's bubble.
              const KitchenBubbleLayer(),
              const _DoorbellProblemBanner(),
              const _ToastLayer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A red banner across the top of every page while doorbell rings can't reach
/// this screen. Deliberately loud and not dismissable: a doorbell that
/// silently stopped working is the one intercom failure that must never go
/// unnoticed. It disappears on its own once the link is back.
class _DoorbellProblemBanner extends ConsumerWidget {
  const _DoorbellProblemBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problem = ref.watch(intercomControllerProvider).doorbellProblem;
    if (problem == null) return const SizedBox.shrink();
    return ValueListenableBuilder<String?>(
      valueListenable: problem,
      builder: (context, message, _) {
        if (message == null) return const SizedBox.shrink();
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: KColors.red,
            padding: const EdgeInsets.fromLTRB(56, 28, 56, 28),
            child: Row(
              children: [
                const KIcon(KIcons.bell, size: 48, color: KColors.onAccent, stroke: 2.2),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.shellDoorbellWontRing,
                        style: KText.s(30, weight: FontWeight.w700, color: KColors.onAccent),
                      ),
                      const SizedBox(height: 6),
                      Text(message, style: KText.s(21, color: KColors.onAccent.withValues(alpha: 0.95))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Swaps pages instantly: each page's sections run their own staggered
/// fade-up ([KFadeUp]) as they mount, so animating the page as a whole
/// here would double it up.
class _PageSwitcher extends StatelessWidget {
  const _PageSwitcher({required this.page, required this.child});

  final KioskPage page;
  final Widget child;

  // Its own layer, so the toast sliding over it and the header's clock
  // don't redraw the whole page.
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: KeyedSubtree(key: ValueKey(page), child: child),
  );
}

class _ToastLayer extends StatelessWidget {
  const _ToastLayer();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<KToastData?>(
      valueListenable: KToast.current,
      builder: (context, toast, _) => Positioned(
        left: 0,
        right: 0,
        bottom: 168,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            reverseDuration: const Duration(milliseconds: 220),
            switchInCurve: kEase,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            // Its own layer: the slide only moves the toast.
            child: toast == null
                ? const SizedBox.shrink()
                : RepaintBoundary(
                    key: ValueKey(toast),
                    child: _Toast(toast: toast),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.toast});

  final KToastData toast;

  // The design's dark pill on the light theme. On the dark one it can't
  // be darker than the page, so it floats as the lightest surface (`tile`
  // with the dark shadow-float outline) — never a light pill at night.
  static Color get _bg => KColors.isDark ? KColors.tile : KColors.dark;
  static Color get _fg => KColors.isDark ? KColors.ink : KColors.onAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      constraints: const BoxConstraints(maxWidth: 1300),
      padding: const EdgeInsets.fromLTRB(20, 0, 14, 0),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(46), boxShadow: KColors.shadowFloat),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: toast.error ? KColors.red : KColors.green, shape: BoxShape.circle),
            child: KIcon(toast.error ? KIcons.close : KIcons.check, size: 28, color: KColors.onAccent, stroke: 2.8),
          ),
          const SizedBox(width: 18),
          Flexible(
            child: Text(
              toast.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(22, weight: FontWeight.w500, color: _fg),
            ),
          ),
          const SizedBox(width: 18),
          KButton(
            label: toast.actionLabel,
            height: 64,
            fontSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 26),
            bg: KColors.onAccent.withValues(alpha: 0.16),
            fg: _fg,
            border: null,
            onTap: () {
              KToast.hide();
              toast.onAction?.call();
            },
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 880,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KIcon(KIcons.refresh, size: 64, color: KColors.red, stroke: 2),
            const SizedBox(height: 24),
            Text(l10n.shellNoHaConnection, style: KText.modalTitle),
            const SizedBox(height: 12),
            Text(
              l10n.shellRetryingAuto,
              textAlign: TextAlign.center,
              style: KText.s(22, color: KColors.ink2),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: KText.s(17, color: KColors.muted),
            ),
            const SizedBox(height: 32),
            KButton.primary(label: l10n.commonRetry, height: 72, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}
