import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../providers/ha_providers.dart';
import '../../widgets/on_screen_keyboard_controller.dart';
import '../browser/browser.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/kiosk_widgets.dart';

const _globe = '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9z"/>';
const _house = '<path d="M3 11l9-7 9 7M5 10v10h14V10"/>';
const _search = '<path d="M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4"/>';
const _windows = '<path d="M4 7h12v12H4zM8 3h12v12"/>';

/// Definições › Navegador web (design: DefinicoesNavegador): the browser's
/// home page, search engine and how it opens by default, kept on this
/// screen ([BrowserPrefs]).
class SettingsBrowserView extends ConsumerStatefulWidget {
  const SettingsBrowserView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  ConsumerState<SettingsBrowserView> createState() => _SettingsBrowserViewState();
}

class _SettingsBrowserViewState extends ConsumerState<SettingsBrowserView> {
  final _url = TextEditingController(text: BrowserPrefs.homeUrl.value);
  Timer? _saveUrl;

  @override
  void initState() {
    super.initState();
    // The on-screen keyboard's typing doesn't always reach onChanged; the
    // controller always hears it.
    _url.addListener(_onUrl);
  }

  @override
  void dispose() {
    _saveUrl?.cancel();
    _url.removeListener(_onUrl);
    _url.dispose();
    super.dispose();
  }

  void _onUrl() {
    if (_url.text == BrowserPrefs.homeUrl.value) return;
    _saveUrl?.cancel();
    _saveUrl = Timer(const Duration(milliseconds: 400), () => BrowserPrefs.setHome(BrowserHome.custom, url: _url.text.trim()));
  }

  /// Done typing: an empty address goes back to the browser's start page.
  void _doneUrl() {
    _saveUrl?.cancel();
    final url = _url.text.trim();
    BrowserPrefs.setHome(url.isEmpty ? BrowserHome.start : BrowserHome.custom, url: url);
    OnScreenKeyboardController.instance.close();
  }

  @override
  Widget build(BuildContext context) {
    final haUri = Uri.tryParse(ref.watch(connectionConfigProvider)?.baseUrl.trim() ?? '');
    final haHost = haUri == null || haUri.host.isEmpty ? '' : (haUri.hasPort ? '${haUri.host}:${haUri.port}' : haUri.host);
    return Container(
      decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(36, 36, 36, 180),
        child: ListenableBuilder(
          listenable: Listenable.merge([BrowserPrefs.home, BrowserPrefs.homeUrl, BrowserPrefs.engine, BrowserPrefs.mode]),
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  KCircleButton(icon: KIcons.chevronLeft, size: 72, iconSize: 32, stroke: 2.2, bg: KColors.page, border: null, onTap: widget.onBack),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.settingsBrowserTitle, style: KText.d(46, spacing: -0.5)),
                        const SizedBox(height: 4),
                        Text(l10n.settingsBrowserSubtitle, style: KText.s(20, color: KColors.muted, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  KButton.primary(
                    label: l10n.settingsBrowserOpen,
                    icon: _globe,
                    iconSize: 28,
                    gap: 12,
                    height: 72,
                    padding: const EdgeInsets.fromLTRB(24, 0, 32, 0),
                    onTap: () => Browser.open(context),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _homeCard(haHost)),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _Card(
                      icon: _search,
                      title: l10n.settingsBrowserEngine,
                      sub: l10n.settingsBrowserEngineSub,
                      children: [
                        for (final e in SearchEngine.values)
                          _Option(label: e.label, sub: e.sub, on: BrowserPrefs.engine.value == e, onTap: () => BrowserPrefs.setEngine(e)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _Card(
                icon: _windows,
                title: l10n.settingsBrowserMode,
                sub: l10n.settingsBrowserModeSub,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, m) in BrowserMode.values.indexed) ...[
                        if (i > 0) const SizedBox(width: 20),
                        Expanded(
                          child: _ModeTile(mode: m, on: BrowserPrefs.mode.value == m, onTap: () => BrowserPrefs.setMode(m)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _homeCard(String haHost) {
    final home = BrowserPrefs.home.value;
    final custom = BrowserPrefs.homeUrl.value.trim();
    return _Card(
      icon: _house,
      title: l10n.settingsBrowserHome,
      sub: l10n.settingsBrowserHomeSub,
      children: [
        _Option(
          label: l10n.settingsBrowserHomeStart,
          sub: l10n.settingsBrowserHomeStartSub,
          on: home == BrowserHome.start,
          onTap: () => BrowserPrefs.setHome(BrowserHome.start),
        ),
        _Option(
          label: 'Home Assistant',
          sub: haHost.isEmpty ? l10n.settingsBrowserHomeHaMissing : haHost,
          on: home == BrowserHome.homeAssistant,
          onTap: () => BrowserPrefs.setHome(BrowserHome.homeAssistant),
        ),
        _Option(
          label: l10n.settingsBrowserHomeOther,
          sub: custom.isEmpty ? l10n.settingsBrowserHomeOtherSub : custom,
          on: home == BrowserHome.custom,
          onTap: () => BrowserPrefs.setHome(BrowserHome.custom),
        ),
        if (home == BrowserHome.custom) ...[
          const SizedBox(height: 2),
          KTextField(
            controller: _url,
            height: 76,
            fontSize: 22,
            background: KColors.tile,
            autofocus: custom.isEmpty,
            hint: l10n.settingsBrowserHomeUrlHint,
            leading: KIcon(_globe, size: 24, color: KColors.faint, stroke: 2),
            options: KeyboardOptions(
              doneLabel: l10n.commonSave,
              capitalize: false,
              suggestions: (t) => [if (haHost.isNotEmpty && haHost.contains(t.trim().toLowerCase())) haHost],
              onDone: _doneUrl,
            ),
          ),
        ],
      ],
    );
  }
}

/// One of the page's cards: icon, title and what it's for, then its options.
class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.sub, required this.children});

  final String icon;
  final String title;
  final String sub;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: KColors.tile, shape: BoxShape.circle),
              child: KIcon(icon, size: 32, color: KColors.accentFg, stroke: 1.9),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KText.d(34)),
                  const SizedBox(height: 2),
                  Text(sub, style: KText.s(17, color: KColors.muted, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 8), c],
      ],
    ),
  );
}

/// A radio choice: the chosen one on a tile, ringed in the accent.
class _Option extends StatelessWidget {
  const _Option({required this.label, required this.sub, required this.on, required this.onTap});

  final String label;
  final String sub;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    inMutuallyExclusiveGroup: true,
    checked: on,
    child: KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: on ? KColors.tile : KColors.tile.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? KColors.accent : KColors.accent.withValues(alpha: 0), width: 3),
        ),
        child: Row(
          children: [
            _Radio(on: on, size: 40, dot: 14, ring: 3),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: KText.s(22, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: KText.s(17, color: KColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Radio extends StatelessWidget {
  const _Radio({required this.on, required this.size, required this.dot, required this.ring});

  final bool on;
  final double size;
  final double dot;
  final double ring;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? KColors.accent : KColors.accent.withValues(alpha: 0),
      border: on ? null : Border.all(color: KColors.border, width: ring),
    ),
    child: on
        ? Container(
            width: dot,
            height: dot,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          )
        : null,
  );
}

/// "Abrir por defeito": a picture of the screen with the browser in that
/// form, and its name.
class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.on, required this.onTap});

  final BrowserMode mode;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, sub) = switch (mode) {
      BrowserMode.window => (l10n.settingsBrowserModeWindow, l10n.settingsBrowserModeWindowSub),
      BrowserMode.modal => (l10n.settingsBrowserModeModal, l10n.settingsBrowserModeModalSub),
      BrowserMode.full => (l10n.settingsBrowserModeFull, l10n.settingsBrowserModeFullSub),
    };
    // The window's place on the screen, as fractions, and its corners.
    final (l, t, w, h, r) = switch (mode) {
      BrowserMode.window => (0.50, 0.16, 0.46, 0.64, 10.0),
      BrowserMode.modal => (0.09, 0.10, 0.82, 0.78, 12.0),
      BrowserMode.full => (0.0, 0.0, 1.0, 1.0, 0.0),
    };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: on,
      label: label,
      child: KPress(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          decoration: BoxDecoration(
            color: KColors.tile,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: on ? KColors.accent : KColors.accent.withValues(alpha: 0), width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 220,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: KColors.page,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: KColors.divider, width: 1.5),
                ),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final bw = box.maxWidth, bh = box.maxHeight;
                    return Stack(
                      children: [
                        Positioned(
                          left: 14,
                          right: 14,
                          top: 14,
                          height: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(7)),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: bw * 0.5,
                          top: 40,
                          bottom: 34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Positioned(
                          left: bw * 0.54,
                          right: 14,
                          top: 40,
                          bottom: 34,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        Positioned(left: 0, right: 0, bottom: 0, height: 24, child: ColoredBox(color: KColors.card)),
                        if (mode == BrowserMode.modal) const Positioned.fill(child: ColoredBox(color: Color(0x5917191C))),
                        Positioned(
                          left: bw * l,
                          top: bh * t,
                          width: bw * w,
                          height: bh * h,
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: KColors.card,
                              borderRadius: BorderRadius.circular(r),
                              boxShadow: const [BoxShadow(color: Color(0x4017191C), blurRadius: 18, offset: Offset(0, 6))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(height: 18, color: KColors.sub),
                                Container(
                                  height: 8,
                                  margin: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(4)),
                                ),
                                FractionallySizedBox(
                                  widthFactor: 0.6,
                                  child: Container(
                                    height: 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(color: KColors.border, borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  children: [
                    _Radio(on: on, size: 28, dot: 10, ring: 2),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: KText.s(22, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(sub, style: KText.s(16, color: KColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
