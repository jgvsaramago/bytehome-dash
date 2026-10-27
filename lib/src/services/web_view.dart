import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// What a page reports while it loads and navigates.
class WebViewState {
  const WebViewState({this.url = '', this.title = '', this.progress = 0, this.loading = false, this.canGoBack = false, this.canGoForward = false});

  final String url;
  final String title;
  final double progress;
  final bool loading;
  final bool canGoBack;
  final bool canGoForward;
}

/// A text field the user tapped in a page.
class WebField {
  const WebField({this.before = '', this.multiline = false, this.search = false, this.type = 'text', this.hint = ''});

  /// The field's text before its caret when it was tapped.
  final String before;
  final bool multiline;

  /// Looks like a search box (its type, role, name or label say so).
  final bool search;

  /// The input's `type` (text, search, email, url, password…) and
  /// `enterkeyhint` (search, go, send, next…).
  final String type;
  final String hint;
}

/// A WPE WebKit page rendered by the patched flutter-pi's `wpe_webview`
/// plugin (see `device/flutter-pi/wpe_webview.c`): WebKit draws off-screen and
/// each frame reaches Flutter as a GPU texture. Only the kiosk build has
/// the plugin; anywhere else [create] fails and the page shows as
/// unavailable.
class WebViewController {
  WebViewController._(this.id, this.size);

  static const _channel = MethodChannel('bytehomedash/webview', JSONMethodCodec());
  static final _views = <int, WebViewController>{};
  static bool _listening = false;

  /// The Flutter texture the page draws into, and the view's handle.
  final int id;
  final ValueNotifier<WebViewState> state = ValueNotifier(const WebViewState());

  /// The page's size in device pixels (its texture's), as last asked for —
  /// what touches are measured against, even while the widget showing it
  /// is mid-animation to another size.
  Size size;

  /// The page's text field the user last tapped, while it has focus.
  final ValueNotifier<WebField?> field = ValueNotifier(null);
  bool _disposed = false;

  /// A page [width]×[height] logical pixels on screen, laid out at [scale]
  /// device pixels per CSS pixel.
  static Future<WebViewController> create({required String url, required Size size, double scale = 1}) async {
    if (!_listening) {
      _listening = true;
      _channel.setMethodCallHandler(_onCall);
    }
    final res = await _channel.invokeMethod<Map<String, dynamic>>('create', {
      'url': url,
      'width': (size.width / scale).round(),
      'height': (size.height / scale).round(),
      'scale': scale,
    });
    final c = WebViewController._((res!['id'] as num).toInt(), size);
    _views[c.id] = c;
    return c;
  }

  static Future<dynamic> _onCall(MethodCall call) async {
    final a = (call.arguments as Map).cast<String, dynamic>();
    final c = _views[(a['id'] as num).toInt()];
    if (call.method == 'field') {
      final f = jsonDecode(a['data'] as String? ?? '{}') as Map<String, dynamic>;
      c?.field.value = f['editable'] == true
          ? WebField(
              before: f['before'] as String? ?? '',
              multiline: f['multiline'] == true,
              search: f['search'] == true,
              type: f['type'] as String? ?? 'text',
              hint: f['hint'] as String? ?? '',
            )
          : null;
      return null;
    }
    if (call.method != 'state') return null;
    c?.state.value = WebViewState(
      url: a['url'] as String? ?? '',
      title: a['title'] as String? ?? '',
      progress: (a['progress'] as num?)?.toDouble() ?? 0,
      loading: a['loading'] == true,
      canGoBack: a['canGoBack'] == true,
      canGoForward: a['canGoForward'] == true,
    );
    return null;
  }

  Future<void> _call(String method, [Map<String, dynamic> args = const {}]) async {
    if (_disposed) return;
    await _channel.invokeMethod<void>(method, {'id': id, ...args});
  }

  Future<void> load(String url) => _call('load', {'url': url});
  Future<void> back() => _call('back');
  Future<void> forward() => _call('forward');
  Future<void> reload() => _call('reload');
  Future<void> stop() => _call('stop');
  Future<void> evaluate(String js) => _call('eval', {'js': js});

  /// Key presses into the focused field: [back] backspaces, then [text],
  /// then Return if [enter].
  Future<void> type({int back = 0, String text = '', bool enter = false}) => _call('type', {'back': back, 'text': text, 'enter': enter});

  /// The page's new size on screen (it reflows), at the scale it was
  /// created with.
  Future<void> resize(Size size, double scale) {
    this.size = size;
    return _call('resize', {'width': (size.width / scale).round(), 'height': (size.height / scale).round()});
  }

  // Positions and distances below are in device pixels: WebKit divides them
  // by the page's scale itself (measured: a click sent at 400,300 at 1.25×
  // arrived at CSS 320,240).

  /// [type]: 0 down, 1 move, 2 up, 3 cancel.
  Future<void> touch(int type, Offset at) => _call('touch', {'type': type, 'x': at.dx, 'y': at.dy});

  /// A left click at [at].
  Future<void> click(Offset at) => _call('click', {'x': at.dx, 'y': at.dy});

  /// Scrolls as if the finger at [at] moved by [by].
  Future<void> scroll(Offset at, Offset by) => _call('scroll', {'x': at.dx, 'y': at.dy, 'dx': by.dx, 'dy': by.dy});

  Future<void> dispose() async {
    if (_disposed) return;
    await _call('dispose');
    _disposed = true;
    _views.remove(id);
    state.dispose();
    field.dispose();
  }
}

/// The page itself: its texture, with the finger turned into what every
/// page understands — a tap is a mouse click where it landed, a drag
/// scrolls (and keeps going for a moment after a flick, slowing down) —
/// and a soft circle where the finger is. Raw touch events reached WebKit
/// too, but plenty of pages (cookie and consent dialogs, buttons with their
/// own scripts) never took them as clicks.
///
/// Touches are measured against the page's own size, not the widget's, so
/// they still land right while the window animates to another mode or is
/// being resized (the texture is stretched until the page reflows).
class WebViewSurface extends StatefulWidget {
  const WebViewSurface({super.key, required this.controller, required this.scale});

  final WebViewController controller;

  /// The page's device pixels per CSS pixel (kept for callers; touches go
  /// in device pixels).
  final double scale;

  @override
  State<WebViewSurface> createState() => _WebViewSurfaceState();
}

class _WebViewSurfaceState extends State<WebViewSurface> with TickerProviderStateMixin {
  /// Past this, a touch is a drag, not a tap.
  static const _slop = 12.0;

  late final Ticker _fling = createTicker(_onFling);
  late final _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), reverseDuration: const Duration(milliseconds: 260));
  VelocityTracker? _tracker;
  Offset? _down;
  Offset _last = Offset.zero;
  Offset _touchAt = Offset.zero;
  bool _dragging = false;
  Offset _velocity = Offset.zero;
  Duration _lastTick = Duration.zero;
  Size _box = Size.zero;

  /// From the widget's pixels to the page's.
  Offset _page(Offset p) {
    final s = widget.controller.size;
    if (_box.isEmpty) return p;
    return Offset(p.dx * s.width / _box.width, p.dy * s.height / _box.height);
  }

  @override
  void dispose() {
    _fling.dispose();
    _ring.dispose();
    super.dispose();
  }

  void _onDown(PointerDownEvent e) {
    _fling.stop();
    _down = e.localPosition;
    _last = e.localPosition;
    _dragging = false;
    _tracker = VelocityTracker.withKind(e.kind)..addPosition(e.timeStamp, e.localPosition);
    setState(() => _touchAt = e.localPosition);
    _ring.forward(from: 0);
  }

  void _onMove(PointerMoveEvent e) {
    final down = _down;
    if (down == null) return;
    _tracker?.addPosition(e.timeStamp, e.localPosition);
    setState(() => _touchAt = e.localPosition);
    if (!_dragging && (e.localPosition - down).distance > _slop) {
      _dragging = true;
      _last = down;
    }
    if (_dragging) {
      widget.controller.scroll(_page(e.localPosition), _page(e.localPosition) - _page(_last));
      _last = e.localPosition;
    }
  }

  void _onUp(PointerUpEvent e) {
    final down = _down;
    _down = null;
    _ring.reverse();
    if (down == null) return;
    if (!_dragging) {
      widget.controller.click(_page(e.localPosition));
      return;
    }
    final v = _tracker?.getVelocity().pixelsPerSecond ?? Offset.zero;
    if (v.distance > 200) {
      _velocity = v;
      _lastTick = Duration.zero;
      _fling.start();
    }
  }

  void _onFling(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (dt <= 0) return;
    widget.controller.scroll(_page(_last), _page(_velocity * dt));
    // Friction: about a second to come to rest from a brisk flick.
    _velocity *= math.pow(0.04, dt).toDouble();
    if (_velocity.distance < 30) _fling.stop();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _box = box.biggest;
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: (_) {
          _down = null;
          _ring.reverse();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Texture(textureId: widget.controller.id, filterQuality: FilterQuality.medium),
            // Where the finger is: a soft circle that grows in on touch
            // and fades as it lifts. Its own layer, so it never repaints
            // the page.
            IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ring,
                  builder: (context, _) {
                    final t = Curves.easeOut.transform(_ring.value);
                    if (t == 0) return const SizedBox.shrink();
                    final d = 44 + 20 * t;
                    return Stack(
                      children: [
                        Positioned(
                          left: _touchAt.dx - d / 2,
                          top: _touchAt.dy - d / 2,
                          width: d,
                          height: d,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1F4D45).withValues(alpha: 0.22 * t),
                              border: Border.all(color: const Color(0xFF1F4D45).withValues(alpha: 0.55 * t), width: 2.5),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
