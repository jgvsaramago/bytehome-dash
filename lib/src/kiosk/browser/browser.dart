import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../../services/browser_volume.dart';
import '../../services/web_view.dart';
import '../../widgets/on_screen_keyboard.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../data/dates.dart';
import '../data/family_data.dart';
import '../data/meals_data.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/bubble.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/music_widgets.dart';

/// The design's three ways to show the browser; the same window animates
/// between them.
enum BrowserMode { window, modal, full }

/// The browser's own start page (favourites and recent visits).
const kBrowserHome = 'inicio';

const _globeIcon = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z"/>';
const _minimizeIcon = '<path d="M6 12h12"/>';

/// Where the browser searches what's typed that isn't an address — chosen
/// in Definições › Navegador web, DuckDuckGo until then.
enum SearchEngine {
  duckduckgo('DuckDuckGo', 'https://duckduckgo.com/?q='),
  google('Google', 'https://www.google.com/search?q='),
  bing('Bing', 'https://www.bing.com/search?q='),
  ecosia('Ecosia', 'https://www.ecosia.org/search?q=');

  const SearchEngine(this.label, this.prefix);

  final String label;
  final String prefix;

  /// Under its name in Definições: the site, and what sets it apart.
  String get sub => switch (this) {
    duckduckgo => l10n.settingsBrowserEngineDuckSub,
    google => 'google.com',
    bing => 'bing.com',
    ecosia => l10n.settingsBrowserEngineEcosiaSub,
  };

  static ValueNotifier<SearchEngine> get current => BrowserPrefs.engine;
}

/// What the browser opens on: its own start page, Home Assistant, or an
/// address of the family's choosing.
enum BrowserHome { start, homeAssistant, custom }

/// The browser's settings (design: DefinicoesNavegador), kept on this
/// screen: the home page, the search engine and how it opens by default.
abstract final class BrowserPrefs {
  static final home = ValueNotifier<BrowserHome>(BrowserHome.start);

  /// The custom home page's address, as typed (`escola.exemplo.pt`).
  static final homeUrl = ValueNotifier<String>('');
  static final engine = ValueNotifier<SearchEngine>(SearchEngine.duckduckgo);
  static final mode = ValueNotifier<BrowserMode>(BrowserMode.window);

  static const _keyHome = 'browser_home';
  static const _keyHomeUrl = 'browser_home_url';
  static const _keyEngine = 'browser_search_engine';
  static const _keyMode = 'browser_mode';

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    home.value = BrowserHome.values.where((h) => h.name == p.getString(_keyHome)).firstOrNull ?? BrowserHome.start;
    homeUrl.value = p.getString(_keyHomeUrl) ?? '';
    engine.value = SearchEngine.values.where((e) => e.name == p.getString(_keyEngine)).firstOrNull ?? SearchEngine.duckduckgo;
    mode.value = BrowserMode.values.where((m) => m.name == p.getString(_keyMode)).firstOrNull ?? BrowserMode.window;
  }

  static Future<void> setHome(BrowserHome h, {String? url}) async {
    home.value = h;
    if (url != null) homeUrl.value = url;
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyHome, h.name);
    await p.setString(_keyHomeUrl, homeUrl.value);
  }

  static Future<void> setEngine(SearchEngine e) async {
    engine.value = e;
    await (await SharedPreferences.getInstance()).setString(_keyEngine, e.name);
  }

  static Future<void> setMode(BrowserMode m) async {
    mode.value = m;
    await (await SharedPreferences.getInstance()).setString(_keyMode, m.name);
  }

  /// Where the home page is, given Home Assistant's address ([haUrl]).
  static String homeAddress(String? haUrl) => switch (home.value) {
    BrowserHome.start => kBrowserHome,
    BrowserHome.homeAssistant => haUrl == null || haUrl.trim().isEmpty ? kBrowserHome : haUrl.trim(),
    BrowserHome.custom => homeUrl.value.trim().isEmpty ? kBrowserHome : browserAddressFor(homeUrl.value),
  };
}

/// A search on the web for [query], as an address.
String browserSearch(String query) => '${SearchEngine.current.value.prefix}${Uri.encodeQueryComponent(query)}';

/// What the address bar does with what was typed, as browsers do: a full
/// address opens as it is; something that looks like one — a domain
/// (`publico.pt/desporto`), an IP, `localhost`, a `.local` host or a host
/// with a port (`homeassistant:8123`) — opens with `https://` (`http://`
/// for local hosts and IPs); anything else is searched.
String browserAddressFor(String text) {
  final t = text.trim();
  if (t.isEmpty) return '';
  if (RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(t)) return t;
  if (RegExp(r'^(about|data):', caseSensitive: false).hasMatch(t)) return t;
  if (!t.contains(RegExp(r'\s'))) {
    final m = RegExp(r'^([^/?#:@]+)(:\d{1,5})?([/?#].*)?$').firstMatch(t);
    if (m != null) {
      final host = m.group(1)!.toLowerCase();
      final ip = RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
      final local = host == 'localhost' || RegExp(r'\.(local|lan|home|internal)$').hasMatch(host);
      final domain = RegExp(r'^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+(xn--[a-z0-9-]+|[a-z]{2,})$').hasMatch(host);
      final withPort = m.group(2) != null && RegExp(r'^[a-z0-9-]+$').hasMatch(host);
      if (ip || local || withPort) return 'http://$t';
      if (domain) return 'https://$t';
    }
  }
  return browserSearch(t);
}

/// The in-app browser (the design's "Navegador"): a WPE WebKit page in a
/// window over the app — floating (dragged and resized, the app still
/// usable around it), a modal over a dimmed app, or the whole screen.
///
/// It's drawn by [BrowserLayer] inside the kiosk shell, above the pages but
/// below every modal route: the Assistente, the door camera and any other
/// pop-up open on top of it. (It used to be an entry in the root overlay,
/// which the Navigator always keeps above its routes, so those opened
/// behind it.)
/// One at a time: opening it again navigates the open one.
abstract final class Browser {
  static final _shown = ValueNotifier<({String? url, BrowserMode mode})?>(null);
  static final _window = GlobalKey<_BrowserWindowState>();

  /// Opens [url], or the home page chosen in Definições; in [mode], or the
  /// default one from there ("Abrir por defeito") — an open browser keeps
  /// its own unless [mode] is given.
  static void open(BuildContext context, {String? url, BrowserMode? mode}) {
    final open = _window.currentState;
    if (_shown.value != null && open != null) {
      open.navigate(url ?? open._homeAddress, mode);
      return;
    }
    _shown.value = (url: url, mode: mode ?? BrowserPrefs.mode.value);
  }

  static void _remove() => _shown.value = null;
}

/// Where the browser window is drawn: a full-size layer in the kiosk
/// shell's stack, over the pages and nav bar.
class BrowserLayer extends StatelessWidget {
  const BrowserLayer({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Browser._shown,
    builder: (context, shown, _) => shown == null
        ? const SizedBox.shrink()
        : Positioned.fill(
            child: _BrowserWindow(key: Browser._window, url: shown.url, mode: shown.mode, onClosed: Browser._remove),
          ),
  );
}

class _Favorite {
  const _Favorite(this.name, this.url);

  final String name;
  final String url;

  Map<String, dynamic> toJson() => {'name': name, 'url': url};
}

class _Visit {
  const _Visit(this.title, this.url, this.at);

  final String title;
  final String url;
  final DateTime at;

  Map<String, dynamic> toJson() => {'title': title, 'url': url, 'at': at.millisecondsSinceEpoch};
}

String _host(String url) => Uri.tryParse(url)?.host ?? url;

class _BrowserWindow extends ConsumerStatefulWidget {
  const _BrowserWindow({super.key, required this.url, required this.mode, required this.onClosed});

  /// Null: the home page.
  final String? url;
  final BrowserMode mode;
  final VoidCallback onClosed;

  @override
  ConsumerState<_BrowserWindow> createState() => _BrowserWindowState();
}

class _BrowserWindowState extends ConsumerState<_BrowserWindow> with TickerProviderStateMixin {
  static const _scale = 1.25;
  static const _prefsWindow = 'browser_window';
  static const _prefsFavorites = 'browser_favorites';
  static const _prefsRecent = 'browser_recent';

  late BrowserMode _mode = widget.mode;

  // The floating window, kept across openings.
  double _fx = 560, _fy = 300, _fw = 820, _fh = 1240;
  bool _dragging = false;
  Offset? _dragFrom;
  Rect _dragRect = Rect.zero;

  WebViewController? _view;
  WebViewState _state = const WebViewState();
  bool _showStart = true;

  /// Minimised to a bubble (design: Navegador): the page and its sound go
  /// on; tapping the bubble brings the window back.
  bool _minimized = false;
  bool _editing = false;
  final _address = TextEditingController();
  Timer? _resize;

  /// What the keyboard types into while a page's text field has focus;
  /// every change to it goes to the page as key presses. [_sent] is the
  /// text the page has been sent so far.
  final _pageText = TextEditingController();
  String _sent = '';
  bool _lifted = false;

  List<_Favorite>? _favorites;
  List<_Visit> _recent = [];

  /// The browser-only volume popover, anchored under its bar button.
  final _volLink = LayerLink();
  final _volPopover = OverlayPortalController();
  Timer? _volDebounce;

  /// The ⋮ menu, anchored under its bar button like the volume.
  final _menuLink = LayerLink();
  final _menuPopover = OverlayPortalController();

  /// "Adicionar a uma refeição", while its sheet is open: the day (0 is
  /// today) and the meal; the dish is typed into [_dish].
  ({int day, MealType type})? _meal;
  final _dish = TextEditingController();
  bool _sending = false;

  late final _appear = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))..forward();
  late final _loadBar = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    OnScreenKeyboardController.instance.active.addListener(_onKeyboard);
    OnScreenKeyboardController.instance.floating.addListener(_onKeyboard);
    _pageText.addListener(_onPageText);
    BrowserVolume.instance.attach();
    _loadPrefs();
    final first = widget.url ?? _homeAddress;
    if (first != kBrowserHome) _go(first);
  }

  @override
  void dispose() {
    OnScreenKeyboardController.instance.active.removeListener(_onKeyboard);
    OnScreenKeyboardController.instance.floating.removeListener(_onKeyboard);
    OnScreenKeyboardController.instance.detach(_pageText);
    _view?.state.removeListener(_onState);
    _view?.field.removeListener(_onField);
    _view?.dispose();
    _resize?.cancel();
    _volDebounce?.cancel();
    BrowserVolume.instance.release();
    _appear.dispose();
    _loadBar.dispose();
    _address.dispose();
    _pageText.dispose();
    _dish.dispose();
    super.dispose();
  }

  // ─── Saved: window, favourites, recent visits ───────────────────────

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final w = p.getStringList(_prefsWindow);
    final fav = p.getString(_prefsFavorites);
    final rec = p.getString(_prefsRecent);
    if (!mounted) return;
    setState(() {
      if (w != null && w.length == 4) {
        _fx = double.tryParse(w[0]) ?? _fx;
        _fy = double.tryParse(w[1]) ?? _fy;
        _fw = double.tryParse(w[2]) ?? _fw;
        _fh = double.tryParse(w[3]) ?? _fh;
      }
      if (fav != null) {
        _favorites = [for (final m in (jsonDecode(fav) as List).whereType<Map>()) _Favorite(m['name'] as String? ?? '', m['url'] as String? ?? '')];
      }
      if (rec != null) {
        _recent = [
          for (final m in (jsonDecode(rec) as List).whereType<Map>())
            _Visit(m['title'] as String? ?? '', m['url'] as String? ?? '', DateTime.fromMillisecondsSinceEpoch((m['at'] as num? ?? 0).toInt())),
        ];
      }
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_prefsWindow, ['$_fx', '$_fy', '$_fw', '$_fh']);
    if (_favorites != null) await p.setString(_prefsFavorites, jsonEncode([for (final f in _favorites!) f.toJson()]));
    await p.setString(_prefsRecent, jsonEncode([for (final v in _recent) v.toJson()]));
  }

  /// Until some are starred: Home Assistant and a few everyday sites that work anywhere.
  List<_Favorite> get _favs {
    final saved = _favorites;
    if (saved != null) return saved;
    final ha = ref.read(connectionConfigProvider)?.baseUrl.trim();
    return [
      if (ha != null && ha.isNotEmpty) _Favorite('Home Assistant', ha),
      _Favorite(l10n.browserFavWeather, 'https://www.windy.com/'),
      _Favorite(l10n.browserFavNews, 'https://news.google.com/'),
      _Favorite('Wikipedia', 'https://www.wikipedia.org/'),
      _Favorite('YouTube', 'https://www.youtube.com/'),
    ];
  }

  /// The home page chosen in Definições › Navegador web.
  String get _homeAddress => BrowserPrefs.homeAddress(ref.read(connectionConfigProvider)?.baseUrl);

  void _goHome() => _go(_homeAddress);

  // ─── Navigation ─────────────────────────────────────────────────────

  /// Opens [url] (or the start page), in [mode] when given.
  void navigate(String url, [BrowserMode? mode]) {
    if (_minimized) setState(() => _minimized = false);
    if (mode != null) _setMode(mode);
    _go(url);
  }

  void _go(String text) {
    final t = text.trim();
    setState(() => _editing = false);
    OnScreenKeyboardController.instance.close();
    if (t.isEmpty) return;
    if (t == kBrowserHome) {
      setState(() => _showStart = true);
      return;
    }
    final url = browserAddressFor(t);
    setState(() => _showStart = false);
    final view = _view;
    if (view != null) {
      view.load(url);
      return;
    }
    WebViewController.create(url: url, size: _pageSize, scale: _scale).then(
      (c) {
        if (!mounted) {
          c.dispose();
          return;
        }
        c.state.addListener(_onState);
        c.field.addListener(_onField);
        setState(() => _view = c);
      },
      onError: (Object e) {
        if (mounted) KToast.show(l10n.browserUnavailable);
      },
    );
  }

  void _onState() {
    final s = _view!.state.value;

    if (s.loading && !_loadBar.isAnimating) _loadBar.repeat();
    if (!s.loading) _loadBar.stop();
    // A page that finished loading joins the recent visits.
    if (!s.loading && s.url.startsWith('http') && (s.url != _state.url || s.title != _state.title)) {
      _recent = [
        _Visit(s.title.isEmpty ? _host(s.url) : s.title, s.url, DateTime.now()),
        for (final v in _recent)
          if (v.url != s.url) v,
      ].take(12).toList();
      _save();
    }
    setState(() => _state = s);
  }

  void _onKeyboard() {
    final kb = OnScreenKeyboardController.instance;
    // The keyboard closed while typing the address: back to showing it.
    if (_editing && kb.active.value == null) setState(() => _editing = false);
    // Typing into the page with the keyboard docked: the browser's bottom
    // edge moves above it, so the field isn't hidden underneath.
    final lifted = kb.active.value == _pageText && !kb.floating.value;
    if (lifted != _lifted) {
      setState(() => _lifted = lifted);
      _reflowSoon();
    }
  }

  // ─── Typing into the page ───────────────────────────────────────────

  void _onField() {
    final f = _view?.field.value;
    final kb = OnScreenKeyboardController.instance;
    if (f == null) {
      kb.detach(_pageText);
      return;
    }
    if (_editing) setState(() => _editing = false);
    _sent = f.before;
    _pageText.value = TextEditingValue(
      text: f.before,
      selection: TextSelection.collapsed(offset: f.before.length),
    );
    // A multi-line box: the accent key just closes the keyboard. Anything
    // else sends Return, which submits.
    final submits = !f.multiline || f.hint.isNotEmpty;
    final search = f.search || f.hint == 'search';
    final plain = !search && !{'email', 'url', 'password'}.contains(f.type) && f.hint != 'go';
    kb.attach(
      _pageText,
      options: KeyboardOptions(
        doneLabel: !submits
            ? l10n.commonDone
            : switch (search ? 'search' : f.hint) {
                'search' => l10n.browserKeySearch,
                'send' => l10n.browserKeySend,
                'next' => l10n.commonNext,
                _ => l10n.browserKeyGo,
              },
        capitalize: plain,
        onDone: submits
            ? () {
                _view?.type(enter: true);
                kb.close();
              }
            : null,
      ),
    );
  }

  void _onPageText() {
    final now = _pageText.text.runes.toList();
    final was = _sent.runes.toList();
    _sent = _pageText.text;
    var same = 0;
    while (same < now.length && same < was.length && now[same] == was[same]) {
      same++;
    }
    final back = was.length - same;
    final add = String.fromCharCodes(now.sublist(same));
    if (back > 0 || add.isNotEmpty) _view?.type(back: back, text: add);
  }

  void _minimize() {
    OnScreenKeyboardController.instance.close();
    _volPopover.hide();
    _menuPopover.hide();
    setState(() => _minimized = true);
  }

  Widget _bubble() {
    final url = _showStart ? '' : (_view?.state.value.url ?? widget.url ?? '');
    final host = _host(url).replaceFirst(RegExp(r'^www\.'), '');
    final start = url.isEmpty || host.isEmpty;
    return Stack(
      children: [
        KBubble(
          slot: 1,
          face: Center(child: KIcon(_globeIcon, size: 48, stroke: 1.9)),
          corner: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: KColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Text(
              start ? l10n.browserTitle[0].toUpperCase() : host[0].toUpperCase(),
              style: KText.d(20, weight: FontWeight.w600, color: Colors.white),
            ),
          ),
          below: KBubbleLabel(start ? l10n.browserTitle : host),
          semantics: start ? l10n.browserReturnToStart : l10n.browserReturnTo(host),
          onTap: () => setState(() => _minimized = false),
        ),
      ],
    );
  }

  void _close() {
    OnScreenKeyboardController.instance.close();
    _volPopover.hide();
    _menuPopover.hide();
    _appear.reverse().whenComplete(widget.onClosed);
  }

  // ─── Geometry ───────────────────────────────────────────────────────

  bool get _win => _mode == BrowserMode.window;

  Rect get _rect {
    final r = switch (_mode) {
      BrowserMode.window => Rect.fromLTWH(_fx, _fy, _fw, _fh),
      BrowserMode.modal => const Rect.fromLTWH(140, 180, 1160, 2180),
      BrowserMode.full => const Rect.fromLTWH(0, 0, 1440, 2560),
    };
    if (!_lifted) return r;
    final limit = 2560 - kKeyboardHeight - (_mode == BrowserMode.full ? 0 : 16);
    if (r.bottom <= limit) return r;
    // A small window moves up whole when it can; otherwise it shortens.
    return Rect.fromLTRB(r.left, math.max(_mode == BrowserMode.full ? 0.0 : 16.0, math.min(r.top, limit - 900)), r.right, limit);
  }

  double get _btn => _win ? 52 : 60;

  EdgeInsets get _barPad => switch (_mode) {
    BrowserMode.window => const EdgeInsets.fromLTRB(14, 10, 14, 12),
    BrowserMode.modal => const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    BrowserMode.full => const EdgeInsets.fromLTRB(32, 64, 32, 16),
  };

  /// The page: the window less its grip, bar and load line.
  Size get _pageSize {
    final r = _rect;
    return Size(r.width, r.height - (_win ? 34 : 0) - (_btn + _barPad.vertical) - 4);
  }

  /// The page reflows once the window has settled into its new size.
  void _reflowSoon() {
    _resize?.cancel();
    _resize = Timer(const Duration(milliseconds: 450), () async {
      await _view?.resize(_pageSize, _scale);
      // Back into view: the field being typed in, if the page got shorter.
      if (_lifted) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await _view?.evaluate("document.activeElement && document.activeElement.scrollIntoView({block: 'nearest'})");
      }
    });
  }

  void _setMode(BrowserMode m) {
    if (m == _mode) return;
    setState(() => _mode = m);
    _reflowSoon();
  }

  Rect _clamp(Rect r) {
    final w = r.width.clamp(640.0, 1440 - 32.0);
    final h = r.height.clamp(800.0, 2560 - 32.0);
    return Rect.fromLTWH(r.left.clamp(16.0, 1440 - w - 16), r.top.clamp(16.0, 2560 - h - 16), w, h);
  }

  Offset _local(Offset global) => (context.findRenderObject() as RenderBox).globalToLocal(global);

  void _dragStart(DragStartDetails d) {
    _dragFrom = _local(d.globalPosition);
    _dragRect = _rect;
    setState(() => _dragging = true);
  }

  void _move(DragUpdateDetails d) {
    final delta = _local(d.globalPosition) - _dragFrom!;
    final r = _clamp(_dragRect.shift(delta));
    setState(() {
      _fx = r.left;
      _fy = r.top;
    });
  }

  void _size(DragUpdateDetails d) {
    final delta = _local(d.globalPosition) - _dragFrom!;
    final w = (_dragRect.width + delta.dx).clamp(640.0, 1440 - _fx - 16);
    final h = (_dragRect.height + delta.dy).clamp(800.0, 2560 - _fy - 16);
    setState(() {
      _fw = w.roundToDouble();
      _fh = h.roundToDouble();
    });
  }

  void _dragEnd({bool resized = false}) {
    setState(() => _dragging = false);
    _save();
    if (resized) _view?.resize(_pageSize, _scale);
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_minimized) return _bubble();
    final r = _rect;
    final modal = _mode == BrowserMode.modal;
    final full = _mode == BrowserMode.full;
    final duration = _dragging ? Duration.zero : const Duration(milliseconds: 420);
    final shadow = full
        ? const <BoxShadow>[]
        : _win
        ? [
            BoxShadow(
              color: KColors.dark.withValues(alpha: _dragging ? 0.35 : 0.28),
              blurRadius: _dragging ? 90 : 70,
              offset: Offset(0, _dragging ? 40 : 24),
            ),
          ]
        : KColors.shadowFloat;
    return AnimatedBuilder(
      animation: _appear,
      builder: (context, child) {
        final reversing = _appear.status == AnimationStatus.reverse;
        final t = reversing ? Curves.easeIn.transform(_appear.value) : kEase.transform(_appear.value);
        return Stack(
          children: [
            // Only the modal dims and blocks the app; a floating window
            // leaves it usable around it.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !modal,
                child: GestureDetector(
                  onTap: _close,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 350),
                    opacity: modal ? Curves.ease.transform(_appear.value) : 0,
                    child: ColoredBox(color: KColors.scrim),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: duration,
              curve: kEase,
              left: r.left,
              top: r.top,
              width: r.width,
              height: r.height,
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.translate(offset: Offset(0, (reversing ? 40 : 56) * (1 - t)), child: child),
              ),
            ),
          ],
        );
      },
      child: AnimatedContainer(
        duration: duration,
        curve: kEase,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(full ? 0 : (_win ? 28 : 36)), boxShadow: shadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_win)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _dragStart,
                onPanUpdate: _move,
                onPanEnd: (_) => _dragEnd(),
                child: Container(
                  height: 34,
                  color: KColors.sub,
                  alignment: Alignment.center,
                  child: Container(
                    width: 96,
                    height: 7,
                    decoration: BoxDecoration(color: KColors.ring, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            _bar(),
            _loadLine(),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.white,
                      child: _view == null ? const SizedBox() : WebViewSurface(controller: _view!, scale: _scale),
                    ),
                  ),
                  if (_showStart) Positioned.fill(child: _startPage()),
                  if (_meal != null) Positioned.fill(child: _mealSheet()),
                  if (_win)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      width: 64,
                      height: 64,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _dragStart,
                        onPanUpdate: _size,
                        onPanEnd: (_) => _dragEnd(resized: true),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: KIcon('<path d="M20 12v8h-8M20 20l-7-7"/>', size: 26, color: Color(0xFFA3A7AE), stroke: 2.2),
                          ),
                        ),
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

  Widget _round(String icon, VoidCallback? onTap, {double opacity = 1, Color? bg, Color? fg, double size = 26, bool filled = false}) => Opacity(
    opacity: opacity,
    child: KPress(
      onTap: onTap,
      child: Container(
        width: _btn,
        height: _btn,
        decoration: BoxDecoration(color: bg ?? Colors.transparent, shape: BoxShape.circle),
        child: Center(
          child: KIcon(icon, size: size, color: fg ?? KColors.ink, stroke: 2.1, solid: filled),
        ),
      ),
    ),
  );

  Widget _bar() {
    final s = _state;
    final view = _view;
    final canBack = _showStart ? view != null : true;
    final url = _showStart ? '' : s.url;
    final fav = !_showStart && _favs.any((f) => f.url == url);
    final gap = SizedBox(width: _win ? 4 : 8);
    return Container(
      color: KColors.sub,
      padding: _barPad,
      child: Row(
        children: [
          _round(KIcons.chevronLeft, canBack ? _back : null, opacity: canBack ? 1 : 0.35),
          if (!_win) ...[
            gap,
            _round(KIcons.chevronRight, s.canGoForward && !_showStart ? () => view?.forward() : null, opacity: s.canGoForward && !_showStart ? 1 : 0.35),
          ],
          gap,
          _round(s.loading ? KIcons.close : _reloadIcon, _showStart ? null : () => s.loading ? view?.stop() : view?.reload()),
          if (!_win) ...[gap, _round(KIcons.homeOutline, _goHome)],
          gap,
          Expanded(child: _addressField(url)),
          gap,
          _round(_star, _showStart || url.isEmpty ? null : () => _toggleFavorite(url), fg: fav ? const Color(0xFFC98A2A) : null, filled: fav),
          gap,
          _volumeButton(),
          gap,
          _menuButton(),
          Container(width: 1.5, height: 32, margin: const EdgeInsets.symmetric(horizontal: 2), color: KColors.border),
          gap,
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: KColors.chip, borderRadius: BorderRadius.circular(28)),
            child: Row(
              children: [
                for (final (m, icon) in const [(BrowserMode.window, _modeWindow), (BrowserMode.modal, _modeModal), (BrowserMode.full, _modeFull)]) ...[
                  if (m != BrowserMode.window) const SizedBox(width: 2),
                  KPress(
                    onTap: () => _setMode(m),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _win ? 44 : 50,
                      height: _win ? 44 : 50,
                      decoration: BoxDecoration(
                        color: _mode == m ? KColors.tile : Colors.transparent,
                        shape: BoxShape.circle,
                        boxShadow: _mode == m ? const [BoxShadow(color: Color(0x1F17191C), blurRadius: 6, offset: Offset(0, 2))] : null,
                      ),
                      child: Center(child: KIcon(icon, size: 22, stroke: 2)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          gap,
          _round(_minimizeIcon, _minimize, bg: KColors.chip, size: 24),
          gap,
          _round(KIcons.close, _close, bg: KColors.chip, size: 24),
        ],
      ),
    );
  }

  // ─── Volume (only the browser's) ────────────────────────────────────

  static const _spk = 'M4 9v6h4l5 4V5L8 9z';

  String _volIcon(int level) =>
      '<path d="$_spk${switch (level) {
        0 => 'M16 9l5 5M21 9l-5 5',
        < 34 => 'M16 10a3 3 0 0 1 0 4',
        < 67 => 'M16 9a4.5 4.5 0 0 1 0 6',
        _ => 'M16 9a4.5 4.5 0 0 1 0 6M18.5 6.5a8 8 0 0 1 0 11',
      }}"/>';

  Widget _volumeButton() {
    final v = BrowserVolume.instance;
    return CompositedTransformTarget(
      link: _volLink,
      child: OverlayPortal(
        controller: _volPopover,
        overlayChildBuilder: (_) => _volumePopover(),
        child: ListenableBuilder(
          listenable: Listenable.merge([v.percent, v.muted]),
          builder: (context, _) => _round(
            _volIcon(v.muted.value ? 0 : v.percent.value),
            () => setState(() {
              _menuPopover.hide();
              _volPopover.toggle();
            }),
            bg: _volPopover.isShowing ? KColors.tile : null,
          ),
        ),
      ),
    );
  }

  Widget _volumePopover() {
    final v = BrowserVolume.instance;
    return Stack(
      children: [
        // A tap anywhere else closes it, without reaching the page.
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(_volPopover.hide)),
        ),
        // Positioned without a size, so the follower is only as big as the
        // card: its top-right corner is then the card's, under the button.
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _volLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(8, 12),
            child: Container(
              width: 440,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: KColors.card,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [BoxShadow(color: Color(0x3317191C), blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: ListenableBuilder(
                listenable: Listenable.merge([v.percent, v.muted]),
                builder: (context, _) {
                  final muted = v.muted.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(l10n.browserVolume, style: KText.s(20, weight: FontWeight.w600)),
                          ),
                          Text(muted ? l10n.browserMuted : '${v.percent.value}%', style: KText.d(28)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          KPress(
                            onTap: () => v.setMuted(!muted),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(color: muted ? KColors.accent : KColors.sub, shape: BoxShape.circle),
                              child: Center(child: KIcon(_volIcon(muted ? 0 : 50), size: 24, color: muted ? Colors.white : KColors.ink, stroke: 2.1)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Opacity(
                              opacity: muted ? 0.45 : 1,
                              child: KSlider(
                                value: v.percent.value / 100,
                                height: 52,
                                trackHeight: 12,
                                knob: 36,
                                track: KColors.border,
                                fill: KColors.accent,
                                onChanged: (x) {
                                  // Shown at once; pactl only once the finger settles.
                                  v.percent.value = (x * 100).round();
                                  v.muted.value = false;
                                  _volDebounce?.cancel();
                                  _volDebounce = Timer(const Duration(milliseconds: 80), () => v.set(v.percent.value));
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(l10n.browserVolumeNote, style: KText.s(16, color: KColors.muted, height: 1.4)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── More options (⋮) ───────────────────────────────────────────────

  /// A site's page is open (not the start page): it can go to a meal or a phone.
  bool get _onSite => !_showStart && _state.url.startsWith('http');

  Widget _menuButton() => CompositedTransformTarget(
    link: _menuLink,
    child: OverlayPortal(
      controller: _menuPopover,
      overlayChildBuilder: (_) => _menu(),
      child: _round(
        _dots,
        () => setState(() {
          _volPopover.hide();
          _menuPopover.toggle();
        }),
        bg: _menuPopover.isShowing ? KColors.tile : null,
        filled: true,
      ),
    ),
  );

  Widget _menu() {
    final site = _onSite;
    final items = [
      (
        icon: _forkKnife,
        label: l10n.browserMenuAddToMeal,
        sub: site ? l10n.browserMenuAddToMealSub : l10n.browserMenuAddToMealNoSite,
        on: site,
        tap: _openMeal,
      ),
      (icon: _phone, label: l10n.browserMenuSendToPhone, sub: '', on: site, tap: _sendToPhone),
      (icon: _home, label: l10n.browserMenuHome, sub: '', on: true, tap: _goHome),
    ];
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => setState(_menuPopover.hide)),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _menuLink,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(8, 12),
            child: Container(
              width: 440,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: KColors.card,
                borderRadius: BorderRadius.circular(26),
                boxShadow: const [BoxShadow(color: Color(0x3317191C), blurRadius: 40, offset: Offset(0, 16))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, it) in items.indexed) ...[
                    if (i > 0) const SizedBox(height: 2),
                    Opacity(
                      opacity: it.on ? 1 : 0.45,
                      child: KPress(
                        onTap: it.on
                            ? () {
                                setState(_menuPopover.hide);
                                it.tap();
                              }
                            : null,
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 72),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(14)),
                                child: Center(child: KIcon(it.icon, size: 24, stroke: 2)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it.label, style: KText.s(20, weight: FontWeight.w600)),
                                    if (it.sub.isNotEmpty) ...[const SizedBox(height: 2), Text(it.sub, style: KText.s(15, color: KColors.muted))],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "Enviar para o telemóvel": the page to someone's phone, through the
  /// Home Assistant app (the integration's phones, as in the Assistente) —
  /// straight there when only one person has one, else they choose.
  Future<void> _sendToPhone() async {
    final url = _state.url;
    if (_sending || !url.startsWith('http')) return;
    final title = _state.title.isEmpty ? _host(url) : _state.title;
    final client = ref.read(haWebSocketClientProvider);
    final Map<String, String> phones;
    try {
      final r = await client.command('bytehomedash/phones');
      phones = {for (final p in (r as List? ?? const []).whereType<Map>()) '${p['name']}': '${p['device'] ?? ''}'};
    } catch (e) {
      KToast.error(e);
      return;
    }
    if (!mounted) return;
    final who = phones.length == 1
        ? phones.keys.first
        : await showKModal<String>(context, (_) => _PhoneChooser(phones: phones, page: '$title · ${_host(url)}'));
    if (who == null || !mounted) return;
    _sending = true;
    try {
      await client.command('bytehomedash/send_to_phone', {'name': who, 'url': url, 'title': title});
      KToast.show(l10n.assistantSentToPhone(who));
    } catch (e) {
      KToast.error(e);
    } finally {
      _sending = false;
    }
  }

  // ─── Adicionar a uma refeição ───────────────────────────────────────

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// The dish, from the page: its title without the site's name
  /// ("Bacalhau à Brás | Receitas" → "Bacalhau à Brás"), else the last part
  /// of the address ("/bacalhau-a-bras" → "Bacalhau a bras").
  String _pageDish() {
    final title = _state.title.trim().split(RegExp(r'\s+[|–—·-]\s+')).first.trim();
    if (title.isNotEmpty) return title;
    final segment = Uri.tryParse(_state.url)?.pathSegments.where((p) => p.isNotEmpty).lastOrNull ?? '';
    var words = segment;
    try {
      words = Uri.decodeComponent(segment);
    } catch (_) {}
    return KDates.cap(words.replaceAll(RegExp(r'\.[a-z0-9]+$'), '').replaceAll(RegExp(r'[-_+]+'), ' ').trim());
  }

  void _openMeal() {
    _dish.text = _pageDish();
    setState(() => _meal = (day: 0, type: MealType.jantar));
  }

  void _closeMeal() {
    final kb = OnScreenKeyboardController.instance;
    if (kb.active.value == _dish) kb.close();
    setState(() => _meal = null);
  }

  /// Planned at once, with the page's link (opened from Refeições, or in
  /// Modo cozinha); back as it was, with a warning, if HA doesn't save it.
  Future<void> _addMeal() async {
    final m = _meal;
    final dish = _dish.text.trim();
    if (m == null || dish.isEmpty) return;
    final day = addDays(_today, m.day);
    final existing = ref.read(mealPlanProvider)[mealKey(day, m.type)];
    final meal = m.type.label.toLowerCase();
    final done = switch (m.day) {
      0 => l10n.browserMealAddedToday(meal),
      1 => l10n.browserMealAddedTomorrow(meal),
      _ => l10n.browserMealAddedOn(meal, KDates.weekdays[day.weekday - 1]),
    };
    final url = _state.url;
    _closeMeal();
    try {
      await ref.read(mealPlanProvider.notifier).put(day, m.type, Meal(dish: dish, time: existing?.time ?? KDates.minutes(m.type.defaultMinutes), url: url));
      KToast.show(done);
    } catch (e) {
      KToast.error(e);
    }
  }

  Widget _mealSheet() {
    final m = _meal!;
    final plan = ref.watch(mealPlanProvider);
    final today = _today;
    final day = addDays(today, m.day);
    String? planned(MealType t) => plan[mealKey(day, t)]?.dish;
    final taken = planned(m.type);
    final kb = OnScreenKeyboardController.instance;
    final label = KText.label;
    return ListenableBuilder(
      listenable: Listenable.merge([kb.active, kb.floating]),
      builder: (context, _) {
        // Typing the dish with the keyboard docked: the sheet rises above it.
        final editing = kb.active.value == _dish;
        final lift = editing && !kb.floating.value ? math.max(0.0, _rect.bottom - (2560 - kKeyboardHeight)) : 0.0;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMeal,
                child: const ColoredBox(color: Color(0x6617191C)),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: kEase,
              left: 0,
              right: 0,
              bottom: lift,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 320),
                curve: kEase,
                builder: (context, v, child) => FractionalTranslation(translation: Offset(0, v), child: child),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(32, 30, 32, 32),
                  decoration: BoxDecoration(
                    color: KColors.card,
                    borderRadius: lift > 0 ? BorderRadius.circular(32) : const BorderRadius.vertical(top: Radius.circular(32)),
                    boxShadow: const [BoxShadow(color: Color(0x3317191C), blurRadius: 40, offset: Offset(0, -12))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(l10n.browserMenuAddToMeal, style: KText.d(36))),
                          KCircleButton(icon: KIcons.close, size: 56, iconSize: 24, stroke: 2.2, bg: KColors.page, border: null, onTap: _closeMeal),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.browserMealDish, style: label),
                      const SizedBox(height: 8),
                      KTextField(
                        controller: _dish,
                        height: 72,
                        fontSize: 24,
                        background: KColors.sub,
                        hint: l10n.browserMealDishHint,
                        options: KeyboardOptions(doneLabel: l10n.commonDone),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          KIcon(_globeLine, size: 18, color: KColors.muted, stroke: 2),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.browserMealKeepsLink(_host(_state.url)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: KText.s(16, color: KColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.browserMealDay, style: label),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var k = 0; k < 7; k++) ...[if (k > 0) const SizedBox(width: 8), _dayChip(k, addDays(today, k), k == m.day)],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.browserMealMeal, style: label),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(34)),
                        child: Row(
                          children: [
                            for (final (i, t) in MealType.values.indexed) ...[
                              if (i > 0) const SizedBox(width: 4),
                              Expanded(
                                child: KPress(
                                  onTap: () => setState(() => _meal = (day: m.day, type: t)),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 60,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: t == m.type ? KColors.tile : Colors.transparent,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: t == m.type ? const [BoxShadow(color: Color(0x1A17191C), blurRadius: 8, offset: Offset(0, 2))] : null,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          t.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KText.s(19, weight: FontWeight.w600),
                                        ),
                                        Text(
                                          planned(t) ?? l10n.browserMealSlotFree,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: KText.s(13, weight: FontWeight.w500, color: KColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (taken != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(color: KColors.orangeTint, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            children: [
                              KIcon(_warning, size: 24, color: KColors.orangeInk, stroke: 2.2),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.browserMealReplaces(taken, m.type.label.toLowerCase()),
                                  style: KText.s(18, weight: FontWeight.w600, color: KColors.orangeInk),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          KButton(label: l10n.commonCancel, height: 72, fontSize: 21, padding: const EdgeInsets.symmetric(horizontal: 32), onTap: _closeMeal),
                          const SizedBox(width: 12),
                          KButton.primary(
                            label: taken != null ? l10n.browserMealReplace : l10n.commonAdd,
                            height: 72,
                            fontSize: 21,
                            padding: const EdgeInsets.symmetric(horizontal: 36),
                            onTap: _addMeal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dayChip(int k, DateTime d, bool on) {
    final wd = d.weekday - 1;
    return KPress(
      onTap: () => setState(() => _meal = (day: k, type: _meal!.type)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minWidth: 96),
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: on ? KColors.accent : KColors.sub, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(switch (k) {
              0 => l10n.commonToday,
              1 => l10n.commonTomorrow,
              _ => KDates.weekdaysShort[wd],
            }, style: KText.s(18, weight: FontWeight.w700, color: on ? Colors.white : KColors.ink)),
            const SizedBox(height: 2),
            Opacity(
              opacity: 0.8,
              child: Text(k < 2 ? '${KDates.abbrLower[wd]} ${d.day}' : KDates.short(d), style: KText.s(14, color: on ? Colors.white : KColors.ink)),
            ),
          ],
        ),
      ),
    );
  }

  void _back() {
    final view = _view;
    if (_showStart) {
      if (view != null) setState(() => _showStart = false);
    } else if (_state.canGoBack) {
      view?.back();
    } else {
      setState(() => _showStart = true);
    }
  }

  void _toggleFavorite(String url) {
    final list = List.of(_favs);
    final i = list.indexWhere((f) => f.url == url);
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.add(_Favorite(_state.title.isEmpty ? _host(url) : _state.title, url));
    }
    setState(() => _favorites = list);
    _save();
  }

  Widget _addressField(String url) {
    final h = _win ? 56.0 : 64.0;
    final size = _win ? 19.0 : 21.0;
    if (_editing) {
      return KTextField(
        controller: _address,
        height: h,
        fontSize: size,
        autofocus: true,
        background: KColors.tile,
        hint: l10n.browserAddressHint(SearchEngine.current.value.label),
        leading: KIcon(KIcons.search, size: 22, color: KColors.muted, stroke: 2.1),
        options: KeyboardOptions(
          doneLabel: l10n.browserKeyGo,
          capitalize: false,
          suggestions: (t) {
            final q = t.toLowerCase();
            final hosts = [for (final f in _favs) _host(f.url)];
            return (q.isEmpty ? hosts : hosts.where((h) => h.toLowerCase().contains(q))).take(3).toList();
          },
          onSuggest: _go,
          onDone: () => _go(_address.text),
        ),
      );
    }
    final uri = Uri.tryParse(url);
    final secure = uri?.scheme == 'https';
    final host = _showStart ? l10n.browserStartPage : (uri?.host ?? url);
    final path = _showStart || uri == null ? '' : '${uri.path == '/' ? '' : uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
    return KPress(
      onTap: () => setState(() {
        _address.clear();
        _editing = true;
      }),
      child: Container(
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(h / 2)),
        child: Row(
          children: [
            if (!_showStart && url.isNotEmpty) ...[
              KIcon(secure ? KIcons.lock : _globeInfo, size: 20, color: secure ? KColors.muted : KColors.faint, stroke: 2.2),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: host,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: path,
                      style: TextStyle(color: KColors.faint),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KText.s(size),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadLine() => SizedBox(
    height: 4,
    child: ColoredBox(
      color: KColors.sub,
      child: !_state.loading || _showStart
          ? null
          : LayoutBuilder(
              builder: (context, box) => AnimatedBuilder(
                animation: _loadBar,
                builder: (context, _) {
                  final w = box.maxWidth * 0.4;
                  final x = -w + (box.maxWidth + w) * Curves.easeInOut.transform(_loadBar.value);
                  return Stack(
                    children: [
                      Positioned(
                        left: x,
                        top: 0,
                        bottom: 0,
                        width: w,
                        child: ColoredBox(color: KColors.accent),
                      ),
                    ],
                  );
                },
              ),
            ),
    ),
  );

  // ─── Start page ─────────────────────────────────────────────────────

  Widget _startPage() {
    final pad = switch (_mode) {
      BrowserMode.window => const EdgeInsets.fromLTRB(32, 28, 32, 60),
      BrowserMode.modal => const EdgeInsets.fromLTRB(48, 36, 48, 80),
      BrowserMode.full => const EdgeInsets.fromLTRB(64, 40, 64, 80),
    };
    const palette = [_Tone.blue, _Tone.purple, _Tone.orange, _Tone.green, _Tone.amber, _Tone.neutral, _Tone.red, _Tone.accent];
    return ColoredBox(
      color: KColors.card,
      child: SingleChildScrollView(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            Center(child: Text(l10n.browserStartTitle, style: KText.d(_win ? 40 : 48, spacing: -0.5))),
            const SizedBox(height: 22),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: KPress(
                  onTap: () => setState(() {
                    _address.clear();
                    _editing = true;
                  }),
                  child: Container(
                    height: 76,
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    decoration: BoxDecoration(color: KColors.chip, borderRadius: BorderRadius.circular(38)),
                    child: Row(
                      children: [
                        KIcon(KIcons.search, size: 26, color: KColors.muted, stroke: 2.1),
                        const SizedBox(width: 14),
                        Text(l10n.browserAddressHint(SearchEngine.current.value.label), style: KText.s(22, color: KColors.muted)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(l10n.browserFavorites, style: KText.label),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                for (final (i, f) in _favs.indexed)
                  KPress(
                    onTap: () => _go(f.url),
                    child: Column(
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(color: palette[i % palette.length].bg, borderRadius: BorderRadius.circular(26)),
                          alignment: Alignment.center,
                          child: Text(
                            f.name.isEmpty ? '?' : f.name.characters.first.toUpperCase(),
                            style: KText.d(36, weight: FontWeight.w600, color: palette[i % palette.length].fg),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          f.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(18, weight: FontWeight.w600),
                        ),
                        Text(
                          _host(f.url),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: KText.s(14, color: KColors.faint),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(l10n.browserRecentlyVisited, style: KText.label),
              ),
              for (final v in _recent.take(6))
                KPress(
                  onTap: () => _go(v.url),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 76),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: KColors.chip, borderRadius: BorderRadius.circular(14)),
                          child: Center(child: KIcon(_clock, size: 22, color: KColors.muted, stroke: 2)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: KText.s(20, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text('${_host(v.url)} · ${_when(v.at)}', style: KText.s(16, color: KColors.faint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  static String _when(DateTime at) {
    final now = DateTime.now();
    final d = now.difference(at);
    if (d.inMinutes < 1) return l10n.browserJustNow;
    if (d.inMinutes < 60) return l10n.browserMinutesAgo(d.inMinutes);
    if (d.inHours < 24 && now.day == at.day) return l10n.browserHoursAgo(d.inHours);
    if (d.inDays < 2) return l10n.browserYesterday;
    return d.inDays < 7 ? KDates.weekdays[at.weekday - 1] : KDates.short(at);
  }

  static const _dots = '<circle cx="12" cy="5" r="2"/><circle cx="12" cy="12" r="2"/><circle cx="12" cy="19" r="2"/>';
  static const _forkKnife = '<path d="M7 3v8a2 2 0 0 0 2 2v8M11 3v8a2 2 0 0 1-2 2M9 3v6M17 21V3c-2 1.5-3 4-3 7v4h3"/>';
  static const _phone = '<path d="M8 2h8a2 2 0 0 1 2 2v16a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zM11 18h2"/>';
  static const _home = '<path d="M3 11l9-7 9 7M5 10v10h14V10"/>';
  static const _globeLine = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18"/>';
  static const _warning = '<path d="M12 3l9.5 17h-19zM12 10v4M12 17.5h.01"/>';
  static const _reloadIcon = '<path d="M20 12a8 8 0 1 1-2.3-5.7M20 4v5h-5"/>';
  static const _star = '<path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8-4.3-4.1 5.9-.9z"/>';
  static const _globeInfo = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 8h.01"/>';
  static const _clock = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2"/>';
  static const _modeWindow = '<path d="M4 8h11v11H4zM9 4h11v11"/>';
  static const _modeModal = '<path d="M3 5h18v14H3zM7 9h10v6H7z"/>';
  static const _modeFull = '<path d="M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5"/>';
}

/// A favourite's tile colours (the design's, following the theme).
enum _Tone {
  blue,
  purple,
  orange,
  green,
  amber,
  neutral,
  red,
  accent;

  Color get bg => switch (this) {
    blue => KColors.blueTint,
    purple => KColors.purpleTint,
    orange => KColors.orangeTint,
    green => KColors.greenTint,
    amber => KColors.amberTint,
    neutral => KColors.chipAlt,
    red => KColors.redTint,
    accent => KColors.accentSoft,
  };

  Color get fg => switch (this) {
    blue => KColors.blue,
    purple => KColors.purple,
    orange => KColors.orangeInk,
    green => KColors.greenInk,
    amber => KColors.amberInk,
    neutral => KColors.ink2,
    red => KColors.red,
    accent => KColors.accentFg,
  };
}

/// Who gets the page on their phone, when more than one person can.
class _PhoneChooser extends ConsumerWidget {
  const _PhoneChooser({required this.phones, required this.page});

  /// Person → their phone's name.
  final Map<String, String> phones;

  /// The page's title and site.
  final String page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(familyMembersProvider);
    return KModal(
      width: 640,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Text(l10n.assistantChooserWho, style: KText.d(34)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              page,
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
              child: KButton.primary(label: l10n.assistantGotIt, height: 64, fontSize: 20, onTap: () => Navigator.of(context).pop()),
            ),
          ],
          for (final p in phones.entries) ...[
            const SizedBox(height: 10),
            KPress(
              onTap: () => Navigator.of(context).pop(p.key),
              child: Container(
                constraints: const BoxConstraints(minHeight: 84),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(24)),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: members.where((m) => m.name == p.key).firstOrNull?.color.color ?? KColors.muted, shape: BoxShape.circle),
                      child: Text(
                        p.key.isEmpty ? '?' : p.key.characters.first.toUpperCase(),
                        style: KText.s(22, weight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.key, style: KText.s(21, weight: FontWeight.w600)),
                          if (p.value.isNotEmpty) Text(p.value, style: KText.s(16, color: KColors.muted)),
                        ],
                      ),
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
}
