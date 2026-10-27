import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/theme_mode_controller.dart';
import '../../providers/temperature_entities_provider.dart';
import '../data/kiosk_entities.dart';

/// Repaints the app when the theme changes, with the design's 350 ms colour
/// cross-fade: a low-resolution snapshot of the old look is laid over the
/// new one and faded out. The layout never moves, so the blur of the
/// snapshot is never noticeable.
///
/// `KColors` are getters, so the switch is a matter of rebuilding every
/// element — done in place ([Element.markNeedsBuild] down the whole tree)
/// rather than by remounting, which keeps every page's state, open modal
/// and running call untouched.
class ThemeSwitch extends StatefulWidget {
  const ThemeSwitch({super.key, required this.child});

  final Widget child;

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  ui.Image? _snapshot;
  /// The theme on screen. Read at start-up, not lazily: a `late` field
  /// with an initialiser would first be read inside [_onMode], after the
  /// mode had already changed, so the very first switch looked like no
  /// change and only the Aspeto card (which redraws itself) followed it.
  late Brightness _shown;

  @override
  void initState() {
    super.initState();
    _shown = ThemeModeController.instance.mode.value;
    ThemeModeController.instance.mode.addListener(_onMode);
  }

  @override
  void dispose() {
    ThemeModeController.instance.mode.removeListener(_onMode);
    _fade.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  void _onMode() {
    final mode = ThemeModeController.instance.mode.value;
    if (mode == _shown) return;
    _shown = mode;
    ui.Image? image;
    try {
      final box = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (box != null && !box.debugNeedsPaint) image = box.toImageSync(pixelRatio: 0.35);
    } catch (_) {
      image = null;
    }
    _snapshot?.dispose();
    _snapshot = image;
    _rebuildAll();
    if (image != null) {
      _fade.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
        });
      });
    }
  }

  void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (snapshot != null)
          IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(_fade),
              child: RawImage(image: snapshot, fit: BoxFit.fill, filterQuality: FilterQuality.low),
            ),
          ),
      ],
    );
  }
}

/// Today's sunset and sunrise from the sun entity chosen in the
/// integration's Meteorologia, in minutes after midnight, local time — or
/// null without one.
final sunTimesProvider = Provider<({int sunset, int sunrise})?>((ref) {
  final id = ref.watch(temperatureEntityConfigProvider.select((c) => c.sunEntityId));
  final sun = ref.watch(kioskEntitiesProvider.select((m) => m[id ?? '']));
  int? minutes(Object? iso) {
    final t = iso is String ? DateTime.tryParse(iso)?.toLocal() : null;
    return t == null ? null : t.hour * 60 + t.minute;
  }

  final sunset = minutes(sun?.attributes['next_setting']);
  final sunrise = minutes(sun?.attributes['next_rising']);
  if (sunset == null || sunrise == null) return null;
  return (sunset: sunset, sunrise: sunrise);
});

/// The dark window automatic mode uses right now: the sun's, or the fixed
/// hours.
({int from, int to}) autoThemeWindow(ThemeSettings s, ({int sunset, int sunrise})? sun) =>
    s.bySun && sun != null ? (from: sun.sunset, to: sun.sunrise) : (from: s.darkAt, to: s.lightAt);

/// Applies automatic mode. Per the design, an automatic change waits for
/// 30 s without touches and never happens with a modal open (the intercom
/// and the assistant are modals too), so nobody sees the screen change
/// under their finger.
class ThemeAutoScheduler extends ConsumerStatefulWidget {
  const ThemeAutoScheduler({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ThemeAutoScheduler> createState() => _ThemeAutoSchedulerState();
}

class _ThemeAutoSchedulerState extends ConsumerState<ThemeAutoScheduler> {
  static const _quiet = Duration(seconds: 30);

  Timer? _tick;
  DateTime _lastTouch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 15), (_) => _check());
    ThemeModeController.instance.settings.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check(force: true));
  }

  @override
  void dispose() {
    _tick?.cancel();
    ThemeModeController.instance.settings.removeListener(_check);
    super.dispose();
  }

  void _check({bool force = false}) {
    if (!mounted) return;
    final c = ThemeModeController.instance;
    final s = c.settings.value;
    if (s.preference != ThemePreference.auto) return;
    final w = autoThemeWindow(s, ref.read(sunTimesProvider));
    final want = ThemeModeController.darkAt(DateTime.now(), w.from, w.to) ? Brightness.dark : Brightness.light;
    if (want == c.mode.value) return;
    if (!force) {
      if (DateTime.now().difference(_lastTouch) < _quiet) return;
      if (Navigator.of(context, rootNavigator: true).canPop()) return;
    }
    c.mode.value = want;
  }

  @override
  Widget build(BuildContext context) {
    // Sun times arriving from HA may move the window.
    ref.listen(sunTimesProvider, (_, _) => _check());
    return Listener(behavior: HitTestBehavior.translucent, onPointerDown: (_) => _lastTouch = DateTime.now(), child: widget.child);
  }
}
