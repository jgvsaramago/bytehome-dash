import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../services/doorbell_history.dart';
import '../../services/doorbell_ringer.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';
import 'intercom_history.dart';

enum IntercomMode { view, ringing, inCall }

/// What the camera area is currently showing, for the header badge: the live
/// stream still connecting, playing, or fallen back to still snapshots.
enum IntercomVideoStatus { connecting, live, snapshots }

/// What the intercom screen needs from the door station. The kiosk is meant
/// to act as a Hikvision indoor station on its own (no Home Assistant in
/// the path); until that link exists, [NotConnectedIntercom] stands in and
/// the screen says so instead of pretending to show video.
abstract class IntercomController {
  bool get connected;

  /// A live view of the door camera, or null when there's none.
  Widget? videoView();

  /// The state of [videoView]'s stream, driving the header badge. Null when
  /// the view has no notion of it (the badge then just says "Ao vivo").
  ValueListenable<IntercomVideoStatus>? get videoStatus => null;

  /// One still JPEG from the door camera, for the camera card's preview; null
  /// when there's no camera or the fetch failed.
  Future<Uint8List?> snapshot() async => null;

  /// Why a doorbell ring would currently NOT reach this screen (shown as a
  /// loud banner by the shell), or null while it would. Null for a
  /// controller that never had ring detection.
  ValueListenable<String?>? get doorbellProblem => null;

  /// The doorbell calls this screen recorded, or null without ring detection.
  DoorbellHistory? get history => null;

  Future<void> answer();
  Future<void> hangUp();
  Future<void> setMuted(bool muted);
  Future<void> unlock();

  /// How long the lock stays open after [unlock].
  Duration get unlockHold => const Duration(seconds: 5);

  /// Emits whenever the door station's call state changes — [IntercomMode.ringing]
  /// when someone presses the bell, [IntercomMode.view] when the call ends — so
  /// the shell can auto-open this screen on a ring and close it when it's over.
  /// Null when ring detection isn't available (e.g. not connected).
  Stream<IntercomMode>? get callEvents => null;

  /// Emits when a call this screen answered was ended from the other side
  /// (the door or the indoor station hung up), so the screen leaves talking
  /// mode. Null when calls are only local.
  Stream<void>? get callEnded => null;
}

class NotConnectedIntercom implements IntercomController {
  const NotConnectedIntercom();

  @override
  bool get connected => false;

  @override
  Widget? videoView() => null;

  @override
  ValueListenable<IntercomVideoStatus>? get videoStatus => null;

  @override
  Future<Uint8List?> snapshot() async => null;

  @override
  ValueListenable<String?>? get doorbellProblem => null;

  @override
  DoorbellHistory? get history => null;

  @override
  Future<void> answer() async {}

  @override
  Future<void> hangUp() async {}

  @override
  Future<void> setMuted(bool muted) async {}

  @override
  Future<void> unlock() async {}

  @override
  Duration get unlockHold => const Duration(seconds: 5);

  @override
  Stream<IntercomMode>? get callEvents => null;

  @override
  Stream<void>? get callEnded => null;
}

/// Stands in for [IntercomController.videoStatus] when a controller has none.
class _NoVideoStatus implements ValueListenable<IntercomVideoStatus?> {
  const _NoVideoStatus();

  @override
  IntercomVideoStatus? get value => null;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

final intercomControllerProvider = Provider<IntercomController>((ref) => const NotConnectedIntercom());

/// Whether this screen has an intercom (a door station in its settings).
/// It's optional: without one, Início shows the first camera in its place,
/// Casa only the cameras and Definições says how to set it up.
final hasIntercomProvider = Provider<bool>((ref) => ref.watch(intercomControllerProvider) is! NotConnectedIntercom);

/// [history]: open on the call history instead of the live door.
Future<void> showIntercom(BuildContext context, {IntercomMode mode = IntercomMode.view, bool history = false}) =>
    showKModal(context, (_) => IntercomModal(initialMode: mode, showHistory: history));

/// The design's "Intercomunicador": the gate camera with talk, door-open
/// and hang-up controls, in three modes — just looking, someone ringing,
/// and in a call.
class IntercomModal extends ConsumerStatefulWidget {
  const IntercomModal({super.key, this.initialMode = IntercomMode.view, this.showHistory = false});

  final IntercomMode initialMode;
  final bool showHistory;

  static int _open = 0;

  /// Whether the intercom screen is currently showing — a ring then switches
  /// it to "A tocar…" itself instead of the shell opening a second one.
  static bool get isOpen => _open > 0;

  @override
  ConsumerState<IntercomModal> createState() => _IntercomModalState();
}

/// What fills the camera slot: the live door, the call history, or one
/// call's picture from it.
enum _Slot { live, list, detail }

class _IntercomModalState extends ConsumerState<IntercomModal> {
  late IntercomMode _mode = widget.initialMode;
  late final bool _openedByRing = widget.initialMode == IntercomMode.ringing;
  bool _muted = false;
  int _callSecs = 0;
  int _doorLeft = 0;
  Timer? _tick;
  StreamSubscription<IntercomMode>? _calls;
  StreamSubscription<void>? _ended;
  IntercomController? _ic;

  _Slot _slot = _Slot.live;

  /// The call whose picture is open (by id, so a new ring that shifts the
  /// list doesn't change which one is shown).
  String? _pickedId;

  /// Missed calls that were new when the history was opened: tagged «NOVA»
  /// for this visit only.
  Set<String> _newIds = const {};

  /// The list keeps its scroll position while a picture is open.
  ScrollController _listScroll = ScrollController();
  double _listOffset = 0;

  /// Bumped on every slot change so the switcher animates it.
  int _view = 0;
  final _pictures = <String, Future<Uint8List?>>{};

  /// A call's still, loaded once per modal (and again once it has one).
  Future<Uint8List?> _picture(DoorbellHistory history, DoorbellCall call) =>
      _pictures.putIfAbsent('${call.id}:${call.hasPicture}', () => history.picture(call));

  @override
  void initState() {
    super.initState();
    IntercomModal._open++;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_mode == IntercomMode.inCall) _callSecs++;
        if (_doorLeft > 0) _doorLeft--;
      });
    });
    _ic = ref.read(intercomControllerProvider);
    _calls = _ic!.callEvents?.listen(_onCallEvent);
    _ended = _ic!.callEnded?.listen((_) {
      if (mounted && _mode == IntercomMode.inCall) _endTalking();
    });
    if (widget.showHistory && _ic!.history != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showSlot(_Slot.list));
      });
    }
  }

  /// Leaving talking mode, however it happens: the call is hung up (no more
  /// door sound, and nothing more from our microphone) and mute resets.
  void _endTalking() {
    _ic?.hangUp();
    setState(() {
      _mode = IntercomMode.view;
      _muted = false;
    });
  }

  /// The doorbell, while this screen is open: a ring turns "just looking" —
  /// or the history — into "A tocar…" on the live view; when the ringing
  /// stops without being answered here (answered on the indoor station, or
  /// the visitor gave up), a screen the ring opened closes again and one
  /// opened by hand goes back to the view.
  void _onCallEvent(IntercomMode event) {
    if (!mounted) return;
    if (event == IntercomMode.ringing && _mode == IntercomMode.view) {
      setState(() {
        _mode = IntercomMode.ringing;
        _showSlot(_Slot.live);
      });
    } else if (event == IntercomMode.view && _mode == IntercomMode.ringing) {
      if (_openedByRing) {
        Navigator.of(context).maybePop();
      } else {
        setState(() => _mode = IntercomMode.view);
      }
    }
  }

  void _showSlot(_Slot slot, {String? picked}) {
    if (_slot == _Slot.list && slot != _Slot.list && _listScroll.hasClients) _listOffset = _listScroll.offset;
    if (slot == _Slot.list && _slot != _Slot.list) {
      // Back from a picture: same place in the list; from the camera: the top.
      final old = _listScroll;
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
      _listScroll = ScrollController(initialScrollOffset: _slot == _Slot.detail ? _listOffset : 0);
    }
    _slot = slot;
    _pickedId = picked;
    _view++;
  }

  @override
  void dispose() {
    // Closing the screen silences the bell, like declining on an indoor
    // station.
    DoorbellRinger.instance.stop();
    // Closing the screen mid-call (backdrop, remote close, a timer) hangs up:
    // the call must never outlive the screen showing it.
    if (_mode == IntercomMode.inCall) _ic?.hangUp();
    IntercomModal._open--;
    _tick?.cancel();
    _calls?.cancel();
    _ended?.cancel();
    _listScroll.dispose();
    super.dispose();
  }

  Future<void> _do(Future<void> Function() f, VoidCallback onOk) async {
    try {
      await f();
      if (mounted) setState(onOk);
    } catch (e) {
      KToast.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ic = ref.watch(intercomControllerProvider);
    final ringing = _mode == IntercomMode.ringing, inCall = _mode == IntercomMode.inCall, view = _mode == IntercomMode.view;
    final doorOpen = _doorLeft > 0;
    final history = ic.history;
    final slot = history == null ? _Slot.live : _slot;
    final log = slot != _Slot.live;
    (String, Color) status(IntercomVideoStatus? video) => !ic.connected
        ? (l10n.settingsStatusDisconnected, _IcColors.grey)
        : ringing
        ? (l10n.intercomRinging, _IcColors.orange)
        : inCall
        ? ('${KDates.two(_callSecs ~/ 60)}:${KDates.two(_callSecs % 60)}', _IcColors.green)
        : switch (video) {
            IntercomVideoStatus.connecting => (l10n.intercomConnecting, _IcColors.grey),
            IntercomVideoStatus.snapshots => (l10n.intercomSnapshots, _IcColors.orange),
            IntercomVideoStatus.live || null => (l10n.intercomLive, _IcColors.red),
          };

    Widget control(String label, String icon, Color bg, VoidCallback? onTap, {Color fg = KColors.onAccent, bool pulse = false}) {
      return Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: KPress(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pulse(
                enabled: pulse,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Center(child: KIcon(icon, size: 44, color: fg, stroke: 1.9)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: KText.s(20, weight: FontWeight.w600, color: KColors.onAccent),
              ),
            ],
          ),
        ),
      );
    }

    void close() => Navigator.of(context).maybePop();
    final controls = <Widget>[
      if (log) ...[
        control(l10n.commonBack, KIcons.arrowLeft, const Color(0x1FFFFFFF), () => setState(() => _showSlot(slot == _Slot.detail ? _Slot.list : _Slot.live))),
        control(l10n.commonClose, KIcons.close, const Color(0x1FFFFFFF), close),
      ] else ...[
        if (view)
          control(
            l10n.intercomTalk,
            KIcons.phone,
            _IcColors.green,
            ic.connected
                ? () => _do(ic.answer, () {
                    _mode = IntercomMode.inCall;
                    _callSecs = 0;
                  })
                : null,
          ),
        // Only closes this screen: the indoor station keeps ringing and can
        // still answer.
        // Ignoring a ring leaves it unanswered: it counts as missed at once.
        if (ringing)
          control(l10n.intercomIgnore, KIcons.bellOff, const Color(0x1FFFFFFF), () {
            history?.ignoredHere();
            _do(ic.hangUp, () {}).then((_) => close());
          }),
        if (inCall)
          control(
            _muted ? l10n.intercomMicOff : l10n.intercomMute,
            KIcons.micOff,
            _muted ? KColors.onAccent : const Color(0x1FFFFFFF),
            () => _do(() => ic.setMuted(!_muted), () => _muted = !_muted),
            fg: _muted ? KColors.dark : KColors.onAccent,
          ),
        control(
          doorOpen ? l10n.intercomDoorOpened : l10n.intercomOpenDoor,
          doorOpen ? KIcons.check : KIcons.lockOpen,
          doorOpen ? _IcColors.green : const Color(0x1FFFFFFF),
          ic.connected && !doorOpen ? () => _do(ic.unlock, () => _doorLeft = ic.unlockHold.inSeconds) : null,
        ),
        if (ringing)
          control(l10n.intercomAnswer, KIcons.phone, _IcColors.green, () {
            DoorbellRinger.instance.stop();
            _do(ic.answer, () {
              _mode = IntercomMode.inCall;
              _callSecs = 0;
            });
          }, pulse: true),
        if (inCall) control(l10n.intercomHangUp, KIcons.phoneDown, _IcColors.red, _endTalking),
        if (view) control(l10n.commonClose, KIcons.close, const Color(0x1FFFFFFF), close),
      ],
    ];

    final Widget slotView = switch (slot) {
      _Slot.list => IntercomHistoryList(
        history: history!,
        newIds: _newIds,
        pictures: (c) => _picture(history, c),
        controller: _listScroll,
        onPick: (i) => setState(() => _showSlot(_Slot.detail, picked: history.calls.value[i].id)),
        onRinging: () => setState(() {
          _mode = IntercomMode.ringing;
          _showSlot(_Slot.live);
        }),
      ),
      _Slot.detail => ValueListenableBuilder<List<DoorbellCall>>(
        valueListenable: history!.calls,
        builder: (context, calls, _) {
          final i = calls.indexWhere((c) => c.id == _pickedId);
          if (i < 0) return const SizedBox.shrink();
          return IntercomHistoryDetail(
            calls: calls,
            index: i,
            picture: (c) => _picture(history, c),
            onIndex: (to) => setState(() => _showSlot(_Slot.detail, picked: calls[to].id)),
          );
        },
      ),
      _Slot.live => Stack(
        children: [
          Positioned.fill(
            child:
                ic.videoView() ??
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const KIcon(KIcons.video, size: 64, color: Color(0xFF9AA0A6), stroke: 1.5),
                    const SizedBox(height: 14),
                    Text(ic.connected ? l10n.intercomVideoUnavailable : l10n.intercomNotConnected, style: KText.s(22, color: const Color(0xFF9AA0A6))),
                  ],
                ),
          ),
          if (ringing)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(color: const Color(0xC717191C), borderRadius: BorderRadius.circular(28)),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.intercomSomeoneRang,
                    style: KText.s(22, weight: FontWeight.w600, color: KColors.onAccent),
                  ),
                ),
              ),
            ),
          if (doorOpen)
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 28),
                decoration: BoxDecoration(color: _IcColors.doorBanner, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    const KIcon(KIcons.lockOpen, size: 32, color: KColors.onAccent, stroke: 2),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.intercomDoorUnlocked,
                        style: KText.s(24, weight: FontWeight.w600, color: KColors.onAccent),
                      ),
                    ),
                    Text(
                      l10n.intercomRelocksIn(_doorLeft),
                      style: KText.s(20, weight: FontWeight.w500, color: const Color(0xFFD3F0DA)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    };

    // The video and everything over it look the same in both themes (the
    // colours below are that fixed dark surface's, not theme tokens); only
    // the card around it follows the theme, lifting to `surface` — with
    // KModal's dark outline — so it doesn't sink into the dark page.
    return KModal(
      width: 1040,
      background: KColors.isDark ? KColors.card : KColors.dark,
      scrim: const Color(0xB80A0C0E),
      dismissible: !ringing,
      shadow: const BoxShadow(color: Color(0x73000000), blurRadius: 100, offset: Offset(0, 40)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(color: Color(0x1AFFFFFF), shape: BoxShape.circle),
                child: Center(
                  child: KIcon(
                    ringing
                        ? KIcons.bell
                        : log
                        ? KIcons.history
                        : KIcons.gateHouse,
                    size: log ? 32 : 34,
                    color: KColors.onAccent,
                    stroke: 2,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log ? l10n.intercomDoorCalls : (ringing ? l10n.intercomCallAtBuildingDoor : (inCall ? l10n.intercomInCall : l10n.intercomBuildingDoor)),
                      style: KText.modalTitle.copyWith(color: KColors.onAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(log ? l10n.intercomLoggedHere : l10n.intercomSubBuildingDoor, style: KText.s(21, color: const Color(0xFFB9BEC4))),
                  ],
                ),
              ),
              if (!log)
                ValueListenableBuilder<IntercomVideoStatus?>(
                  valueListenable: ic.videoStatus ?? const _NoVideoStatus(),
                  builder: (context, video, _) {
                    final (label, bg) = status(video);
                    return Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(26)),
                      child: Row(
                        children: [
                          KBlink(
                            enabled: ic.connected,
                            period: const Duration(milliseconds: 1200),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(color: KColors.onAccent, shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            label,
                            style: KText.s(20, weight: FontWeight.w700, color: KColors.onAccent),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              // The history sits in the header, not the call controls: it
              // isn't part of answering, and it goes away while ringing or
              // in a call.
              if (view && !log && history != null) ...[
                const SizedBox(width: 16),
                ValueListenableBuilder<int>(
                  valueListenable: history.unseenMissed,
                  builder: (context, missed, _) => _HistoryButton(
                    missed: missed,
                    onTap: () => setState(() {
                      _newIds = history.markSeen();
                      _showSlot(_Slot.list);
                    }),
                  ),
                ),
              ],
              if (!ringing) ...[
                const SizedBox(width: 16),
                KCircleButton(
                  icon: KIcons.close,
                  size: 64,
                  iconSize: 26,
                  stroke: 2.2,
                  bg: const Color(0x1AFFFFFF),
                  fg: KColors.onAccent,
                  border: null,
                  onTap: close,
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: const Cubic(0.2, 0.8, 0.2, 1),
              height: log ? 880 : 544,
              color: log ? const Color(0xFF1C1F23) : KColors.camera,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: const Cubic(0.2, 0.8, 0.2, 1),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 16 / 880), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
                child: KeyedSubtree(key: ValueKey(_view), child: slotView),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (i, c) in controls.indexed) ...[if (i > 0) const SizedBox(width: 56), c],
            ],
          ),
          if (ringing) ...[
            const SizedBox(height: 20),
            Text(
              l10n.intercomIgnoreHint,
              textAlign: TextAlign.center,
              style: KText.s(18, color: const Color(0xFF9AA0A6)),
            ),
          ],
        ],
      ),
    );
  }
}

/// The header's "Histórico" pill, with the count of missed calls nobody
/// has looked at yet.
class _HistoryButton extends StatelessWidget {
  const _HistoryButton({required this.missed, required this.onTap});

  final int missed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: Container(
        height: 64,
        padding: EdgeInsets.fromLTRB(20, 0, missed > 0 ? 16 : 26, 0),
        decoration: BoxDecoration(color: const Color(0x1AFFFFFF), borderRadius: BorderRadius.circular(32)),
        child: Row(
          children: [
            const KIcon(KIcons.history, size: 28, color: KColors.onAccent, stroke: 2),
            const SizedBox(width: 12),
            Text(
              l10n.intercomHistory,
              style: KText.s(20, weight: FontWeight.w600, color: KColors.onAccent),
            ),
            if (missed > 0) ...[
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(color: const Color(0xFFE5484D), borderRadius: BorderRadius.circular(18)),
                alignment: Alignment.center,
                child: Text(
                  '$missed',
                  style: KText.s(19, weight: FontWeight.w700, color: KColors.onAccent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The design's `dcPulse` ring around the "Atender" button.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  // Created up front: a lazy one would first be built in dispose() for a
  // button that never pulsed, while the tree is already being torn down.
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    if (widget.enabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    // Its own layer, so the ring doesn't repaint the modal every frame.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final t = (_c.value / 0.75).clamp(0.0, 1.0);
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _IcColors.green.withValues(alpha: 0.6 * (1 - t)),
                  spreadRadius: 40 * t,
                ),
              ],
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// The intercom's own colours: the video and the controls over it are the
/// same in both themes (the design's "Regras do modo escuro"), so these are
/// the light theme's state colours, fixed.
abstract final class _IcColors {
  static const green = Color(0xFF2B8A3E);
  static const red = Color(0xFFB42318);
  static const orange = Color(0xFFC2410C);
  static const doorBanner = Color(0xFF1E5E2B);
  static const grey = Color(0xFF5F646B);
}
