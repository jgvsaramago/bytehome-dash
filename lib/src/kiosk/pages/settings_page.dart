import 'dart:async';
import 'dart:io' show Directory, File, NetworkInterface, InternetAddressType, Process, exit;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../build_info.dart';
import '../../ha_client/ha_websocket_client.dart';
import '../../music/ma_client.dart';
import '../../music/music_store.dart';
import '../../providers/ha_providers.dart';
import '../../services/device_identity.dart';
import '../../services/doorbell_ringer.dart';
import '../../services/master_volume.dart';
import '../../services/screen_brightness_service.dart';
import '../../services/screen_power_controller.dart';
import '../../services/system_control_service.dart';
import '../../services/voice_satellite.dart';
import '../../theme/theme_mode_controller.dart';
import '../browser/browser.dart';
import '../modals/intercom_modal.dart';
import '../data/assistant_config.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../theme/theme_switch.dart';
import '../widgets/kiosk_widgets.dart';
import '../widgets/music_widgets.dart';
import 'settings_browser_page.dart';
import 'settings_intercom_page.dart';
import 'settings_voices_page.dart';

final _haLanguageProvider = FutureProvider<String?>((ref) async {
  await haReady(ref);
  final config = await ref.read(haWebSocketClientProvider).getConfig();
  return config['language'] as String?;
});

/// One network link's row under Ligações.
typedef _NetLink = ({String label, String sub, bool up});

/// The screen's network links: every wired port, then Wi-Fi when the board
/// has it. Found by what they are in sysfs, not by name (`eth0`, `end0`,
/// `enP4p65s0`…, depending on the board); a port with no cable still shows.
/// The one carrying the default route (the home network) comes first — on
/// a kiosk with an intercom NIC the other port is the intercom network.
/// Re-read each time the page opens.
final _networkProvider = FutureProvider.autoDispose<List<_NetLink>>((ref) async {
  if (kIsWeb) return const [];
  final addresses = {
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
      if (i.addresses.isNotEmpty) i.name: i.addresses.first.address,
  };
  String? defaultRoute;
  try {
    for (final line in File('/proc/net/route').readAsLinesSync().skip(1)) {
      final f = line.split(RegExp(r'\s+'));
      if (f.length > 2 && f[1] == '00000000') {
        defaultRoute = f[0];
        break;
      }
    }
  } catch (_) {}

  final wired = <String>[], wireless = <String>[];
  try {
    for (final dir in Directory('/sys/class/net').listSync()) {
      final name = dir.path.split('/').last;
      // Only real hardware: lo, bridges, VLANs and VPNs have no device.
      if (!Directory('${dir.path}/device').existsSync()) continue;
      (Directory('${dir.path}/wireless').existsSync() || Directory('${dir.path}/phy80211').existsSync() ? wireless : wired).add(name);
    }
  } catch (_) {}
  int order(String a, String b) => a == defaultRoute ? -1 : (b == defaultRoute ? 1 : a.compareTo(b));
  wired.sort(order);
  wireless.sort(order);

  final wifi = wireless.isEmpty ? null : addresses[wireless.first];
  // SSID and signal from NetworkManager; just the address without it.
  String? ssid;
  int? signal;
  if (wifi != null) {
    try {
      final r = await Process.run('nmcli', ['-t', '-f', 'active,ssid,signal', 'dev', 'wifi', 'list', '--rescan', 'no']).timeout(const Duration(seconds: 3));
      for (final line in '${r.stdout}'.split('\n')) {
        final parts = line.split(':');
        if (parts.length >= 3 && parts.first == 'yes') {
          ssid = parts.sublist(1, parts.length - 1).join(':').replaceAll(r'\:', ':');
          signal = int.tryParse(parts.last);
          break;
        }
      }
    } catch (_) {}
  }
  return [
    for (final (i, name) in wired.indexed)
      (label: i == 0 ? 'Ethernet' : 'Ethernet ${i + 1}', sub: addresses[name] ?? l10n.settingsNetNoCable, up: addresses[name] != null),
    if (wireless.isNotEmpty)
      (
        label: 'Wi-Fi',
        sub: wifi == null ? l10n.commonOff : [if (ssid != null && ssid.isNotEmpty) ssid, if (signal != null) l10n.settingsNetSignal(signal), wifi].join(' · '),
        up: wifi != null,
      ),
  ];
});

String _hm(int minutes) {
  final m = ((minutes % 1440) + 1440) % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// Definições (design "Definições"): what belongs to this screen itself.
/// Opened by tapping the header's clock; everything that maps the screen
/// onto HA entities lives in HA's "ByteHomeDash" panel instead.
///
/// The intercom's tones are a sub-page (design "DefinicoesIntercom"), shown
/// in place of the list with its own back button, so the shell's pages
/// don't need to know about it.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _intercom = false;
  bool _voices = false;
  bool _browser = false;

  @override
  Widget build(BuildContext context) {
    if (_browser) {
      return KFadeUp(
        key: const ValueKey('browser'),
        child: SettingsBrowserView(onBack: () => setState(() => _browser = false)),
      );
    }
    if (_voices) {
      return KFadeUp(
        key: const ValueKey('voices'),
        child: SettingsVoicesView(onBack: () => setState(() => _voices = false)),
      );
    }
    if (_intercom) {
      return KFadeUp(
        key: const ValueKey('intercom'),
        child: SettingsIntercomView(onBack: () => setState(() => _intercom = false)),
      );
    }
    return KFadeUp(
      key: const ValueKey('main'),
      child: Container(
        decoration: BoxDecoration(color: KColors.card, borderRadius: BorderRadius.circular(36)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(l10n.settingsTitle, style: KText.d(46, spacing: -0.5)),
                  const Spacer(),
                  Text(l10n.settingsTapClockHint, style: KText.s(20, color: KColors.muted)),
                ],
              ),
              const SizedBox(height: 28),
              const _AppearanceGroup(),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: _ScreenGroup()),
                  const SizedBox(width: 28),
                  Expanded(child: _VoiceGroup(onVoices: () => setState(() => _voices = true))),
                ],
              ),
              const SizedBox(height: 28),
              const _ConnectionsGroup(),
              const SizedBox(height: 28),
              _IntercomGroup(onOpen: () => setState(() => _intercom = true)),
              const SizedBox(height: 28),
              _SystemGroup(onBrowserSettings: () => setState(() => _browser = true)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A group's card: round icon tile and title, then rows split by hairlines.
class _Group extends StatelessWidget {
  const _Group({required this.icon, required this.title, required this.rows});

  final String icon;
  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _GroupTitle(
              icon: KIcon(icon, size: 28, color: KColors.accentFg, stroke: 1.9),
              title: title,
            ),
          ),
          for (final (i, r) in rows.indexed)
            Container(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
              ),
              child: r,
            ),
        ],
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.icon, required this.title, this.trailing});

  final Widget icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: KColors.tile, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: icon,
      ),
      const SizedBox(width: 16),
      Expanded(child: Text(title, style: KText.d(34))),
      ?trailing,
    ],
  );
}

/// Label (+ optional sub) on the left, [trailing] on the right.
class _Row extends StatelessWidget {
  const _Row({required this.label, this.sub, this.trailing, this.dot, this.below});

  final String label;
  final String? sub;
  final Widget? trailing;

  /// A status dot: (dot, its soft ring).
  final (Color, Color)? dot;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                if (dot case (final color, final ring)) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: KText.s(22, weight: FontWeight.w600)),
                      if (sub != null && sub!.isNotEmpty) ...[const SizedBox(height: 4), Text(sub!, style: KText.s(17, color: KColors.muted, height: 1.4))],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 20), trailing!],
              ],
            ),
          ),
          if (below != null) ...[const SizedBox(height: 14), below!],
        ],
      ),
    );
  }
}

/// A row that opens a sub-page: the whole row is the target, with the
/// design's pressed tint.
class _LinkRow extends StatefulWidget {
  const _LinkRow({required this.label, required this.sub, required this.value, required this.onTap});

  final String label;
  final String sub;
  final String value;
  final VoidCallback onTap;

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => _set(true),
    onTapUp: (_) => _set(false),
    onTapCancel: () => _set(false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(color: _down ? KColors.pressed : KColors.pressed.withValues(alpha: 0), borderRadius: BorderRadius.circular(22)),
        child: _Row(
          label: widget.label,
          sub: widget.sub,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.value,
                style: KText.s(20, weight: FontWeight.w600, color: KColors.muted),
              ),
              const SizedBox(width: 10),
              KIcon(KIcons.chevronRight, size: 30, color: KColors.faint, stroke: 2.2),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.label, required this.sub, required this.state});

  final String label;
  final String sub;

  /// `ok`, `wait`, `off`.
  final String state;

  @override
  Widget build(BuildContext context) {
    final (dot, ring, fg, text) = switch (state) {
      'ok' => (KColors.green, KColors.greenTint, KColors.greenInk, l10n.settingsStatusConnected),
      'wait' => (KColors.amber, KColors.amberTint, KColors.amberInk, l10n.settingsStatusConnecting),
      _ => (KColors.orange, KColors.orangeTint, KColors.orangeInk, l10n.settingsStatusDisconnected),
    };
    return _Row(
      label: label,
      sub: sub,
      dot: (dot, ring),
      trailing: Text(
        text,
        style: KText.s(22, weight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => KButton(label: label, height: 64, fontSize: 20, onTap: onTap);
}

// ----------------------------------------------------------------------- Aspeto

/// Claro, Escuro or Automático, and when Automático switches.
class _AppearanceGroup extends ConsumerWidget {
  const _AppearanceGroup();

  static const _contrast = '<circle cx="12" cy="12" r="8.5"/>';
  static const _sunset = '<path d="M3 18h18M7 18a5 5 0 0 1 10 0M12 9V4M9.5 6.5L12 9l2.5-2.5"/>';
  static const _sunrise = '<path d="M3 18h18M7 18a5 5 0 0 1 10 0M12 4v5M9.5 6.5L12 4l2.5 2.5"/>';

  static String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sun = ref.watch(sunTimesProvider);
    final c = ThemeModeController.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([c.settings, c.mode]),
      builder: (context, _) {
        final s = c.settings.value;
        final dark = c.mode.value == Brightness.dark;
        final w = autoThemeWindow(s, sun);
        final status = switch (s.preference) {
          ThemePreference.auto => dark ? l10n.settingsThemeNowDark(_hm(w.to)) : l10n.settingsThemeNowLight(_hm(w.from)),
          ThemePreference.dark => l10n.settingsThemeAlwaysDark,
          ThemePreference.light => l10n.settingsThemeAlwaysLight,
        };

        void pick(ThemePreference p) {
          if (p == s.preference) return;
          if (p != ThemePreference.auto) {
            c.setPreference(p);
            return;
          }
          // The first switch into automatic applies at once, by the window
          // it will follow (the sun's when HA has it).
          final next = s.copyWith(preference: ThemePreference.auto);
          final win = autoThemeWindow(next, sun);
          c.update(next, autoNow: ThemeModeController.darkAt(DateTime.now(), win.from, win.to) ? Brightness.dark : Brightness.light);
        }

        // Later changes to when it switches are left to the shell's
        // scheduler, which waits for nobody to be touching the screen.
        void set(ThemeSettings next) => c.update(next);

        final accentHex = _hex(KColors.accentFg);
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: KColors.sub, borderRadius: BorderRadius.circular(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GroupTitle(
                icon: KIcon('$_contrast<path d="M12 3.5v17a8.5 8.5 0 0 0 0-17z" fill="$accentHex"/>', size: 28, color: KColors.accentFg, stroke: 1.9),
                title: l10n.settingsAppearance,
                trailing: Text(
                  status,
                  textAlign: TextAlign.right,
                  style: KText.s(18, color: KColors.muted),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  for (final (i, p) in ThemePreference.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 20),
                    Expanded(
                      child: _ThemeCard(
                        preference: p,
                        on: s.preference == p,
                        sub: switch (p) {
                          ThemePreference.light => l10n.settingsThemeAlwaysLight,
                          ThemePreference.dark => l10n.settingsThemeAlwaysDark,
                          ThemePreference.auto => s.bySun ? l10n.settingsThemeBySun : l10n.settingsThemeFixedTimes,
                        },
                        onTap: () => pick(p),
                      ),
                    ),
                  ],
                ],
              ),
              if (s.preference == ThemePreference.auto) ...[
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.only(top: 18),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(l10n.settingsThemeWhen, style: KText.s(22, weight: FontWeight.w600)),
                          ),
                          KChip(
                            label: l10n.settingsThemeAtSunsetSunrise,
                            on: s.bySun,
                            fontSize: 20,
                            padX: 24,
                            offBg: KColors.tile,
                            onTap: () => set(s.copyWith(bySun: true)),
                          ),
                          const SizedBox(width: 10),
                          KChip(
                            label: l10n.settingsThemeFixedTimes,
                            on: !s.bySun,
                            fontSize: 20,
                            padX: 24,
                            offBg: KColors.tile,
                            onTap: () => set(s.copyWith(bySun: false)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (s.bySun) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _TimeTile(icon: _sunset, label: l10n.settingsThemeDarkAtSunset, value: sun == null ? '--:--' : _hm(sun.sunset)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _TimeTile(icon: _sunrise, label: l10n.settingsThemeLightAtSunrise, value: sun == null ? '--:--' : _hm(sun.sunrise)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          sun == null ? l10n.settingsThemeWaitingForSun(_hm(s.darkAt), _hm(s.lightAt)) : l10n.settingsThemeSunToday,
                          style: KText.s(17, color: KColors.muted),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: _Stepper(
                                label: l10n.settingsThemeDarkFrom,
                                minutes: s.darkAt,
                                onStep: (d) => set(s.copyWith(darkAt: ((s.darkAt + d) % 1440 + 1440) % 1440)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _Stepper(
                                label: l10n.settingsThemeLightFrom,
                                minutes: s.lightAt,
                                onStep: (d) => set(s.copyWith(lightAt: ((s.lightAt + d) % 1440 + 1440) % 1440)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: KIcon(KIcons.wave, size: 26, color: KColors.muted, stroke: 1.9),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: KText.s(17, color: KColors.muted, height: 1.45),
                          // The two bold parts go where the language puts them.
                          children: _spansAround(l10n.settingsThemeTip('\u0001', '\u0002'), {
                            '\u0001': TextSpan(
                              text: l10n.settingsThemeVoiceCommand(ref.watch(assistantConfigProvider).wakePhrase),
                              style: TextStyle(color: KColors.ink, fontWeight: FontWeight.w600),
                            ),
                            '\u0002': TextSpan(
                              // The screen's MQTT device and its theme select, by name.
                              text: '${screenName()} › ${l10n.themeMqttSelectName}',
                              style: TextStyle(color: KColors.ink, fontWeight: FontWeight.w600),
                            ),
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// [text] split into spans, with each marker character in [marks] replaced
/// by its span.
List<InlineSpan> _spansAround(String text, Map<String, InlineSpan> marks) {
  final out = <InlineSpan>[];
  var start = 0;
  for (final m in RegExp('[${marks.keys.join()}]').allMatches(text)) {
    if (m.start > start) out.add(TextSpan(text: text.substring(start, m.start)));
    out.add(marks[m[0]]!);
    start = m.end;
  }
  if (start < text.length) out.add(TextSpan(text: text.substring(start)));
  return out;
}

/// One of Claro / Escuro / Automático: a miniature of the screen in that
/// theme, and a radio.
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.preference, required this.on, required this.sub, required this.onTap});

  final ThemePreference preference;
  final bool on;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = switch (preference) {
      ThemePreference.light => _MiniScreen(_MiniPalette.light),
      ThemePreference.dark => _MiniScreen(_MiniPalette.dark),
      ThemePreference.auto => Stack(
        fit: StackFit.expand,
        children: [
          _MiniScreen(_MiniPalette.light),
          ClipPath(clipper: _DiagonalClipper(), child: _MiniScreen(_MiniPalette.dark)),
        ],
      ),
    };
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
        decoration: BoxDecoration(
          color: KColors.tile,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: on ? KColors.accent : KColors.accent.withValues(alpha: 0), width: 3, strokeAlign: BorderSide.strokeAlignInside),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 196,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: KColors.divider, width: 1.5, strokeAlign: BorderSide.strokeAlignOutside),
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(18), child: preview),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? KColors.accent : KColors.accent.withValues(alpha: 0),
                      border: on ? null : Border.all(color: KColors.border, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: on
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: KColors.onAccent, shape: BoxShape.circle),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(switch (preference) {
                          ThemePreference.light => l10n.settingsThemeLight,
                          ThemePreference.dark => l10n.settingsThemeDark,
                          ThemePreference.auto => l10n.commonAuto,
                        }, style: KText.s(22, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
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
          ],
        ),
      ),
    );
  }
}

/// The fixed colours of each theme, for the miniatures — they always show
/// both, whatever the screen is in now.
class _MiniPalette {
  const _MiniPalette({
    required this.bg,
    required this.surface,
    required this.card,
    required this.ink,
    required this.ink3,
    required this.icon,
    required this.track,
    required this.accent,
    required this.warm,
  });

  final Color bg, surface, card, ink, ink3, icon, track, accent, warm;

  static const light = _MiniPalette(
    bg: Color(0xFFF3F1EC),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFF7F5F1),
    ink: Color(0xFF17191C),
    ink3: Color(0xFF696E75),
    icon: Color(0xFF3B4046),
    track: Color(0xFFE3DFD6),
    accent: Color(0xFF1F4D45),
    warm: Color(0xFFFDEBDD),
  );

  static const dark = _MiniPalette(
    bg: Color(0xFF111214),
    surface: Color(0xFF1B1D21),
    card: Color(0xFF202328),
    ink: Color(0xFFECECEF),
    ink3: Color(0xFF979CA3),
    icon: Color(0xFFC9CCD1),
    track: Color(0xFF34373D),
    accent: Color(0xFF2E7A6D),
    warm: Color(0xFF3A2518),
  );
}

/// A sketch of a page: title, four cards, the nav bar.
class _MiniScreen extends StatelessWidget {
  const _MiniScreen(this.p);

  final _MiniPalette p;

  Widget _bar(double factor, double h, Color color) => FractionallySizedBox(
    widthFactor: factor,
    alignment: Alignment.centerLeft,
    child: Container(
      height: h,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
    ),
  );

  Widget _box(double w, double h, double r, Color color) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
  );

  Widget _card(List<Widget> children) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(12)),
      // The sketch's contents may be a touch taller than a card; clip
      // rather than overflow.
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(height: 6), c],
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: p.bg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, c) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_box(c.maxWidth * 0.38, 16, 4, p.ink), _box(c.maxWidth * 0.22, 10, 4, p.ink3)],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card([_bar(0.6, 8, p.ink), _bar(0.4, 6, p.ink3), _box(34, 12, 6, p.warm)]),
                      const SizedBox(width: 8),
                      _card([_bar(0.5, 8, p.ink), _box(22, 22, 7, p.accent)]),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _card([_bar(0.7, 8, p.ink), _bar(0.45, 6, p.ink3), _bar(0.55, 6, p.ink3)]),
                      const SizedBox(width: 8),
                      _card([_bar(0.4, 8, p.ink), _bar(1, 8, p.track)]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 22,
            decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_box(18, 6, 4, p.icon), const SizedBox(width: 14), _box(18, 6, 4, p.icon), const SizedBox(width: 14), _box(18, 6, 4, p.accent)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Automático's miniature: dark on a diagonal band to the right.
class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * 0.62, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(size.width * 0.38, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.icon, required this.label, required this.value});

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(22)),
    child: Row(
      children: [
        KIcon(icon, size: 32, color: KColors.solar, stroke: 1.8),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: KText.s(17, color: KColors.muted)),
            const SizedBox(height: 2),
            Text(value, style: KText.d(34)),
          ],
        ),
      ],
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.minutes, required this.onStep});

  final String label;
  final int minutes;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
    decoration: BoxDecoration(color: KColors.tile, borderRadius: BorderRadius.circular(22)),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: KText.s(17, color: KColors.muted)),
              const SizedBox(height: 2),
              Text(_hm(minutes), style: KText.d(34)),
            ],
          ),
        ),
        KCircleButton(icon: KIcons.minus, size: 60, iconSize: 26, stroke: 2.2, bg: KColors.tile, onTap: () => onStep(-30)),
        const SizedBox(width: 12),
        KCircleButton(icon: KIcons.plus, size: 60, iconSize: 26, stroke: 2.2, bg: KColors.tile, onTap: () => onStep(30)),
      ],
    ),
  );
}

// ------------------------------------------------------------------------ Ecrã

class _ScreenGroup extends StatefulWidget {
  const _ScreenGroup();

  @override
  State<_ScreenGroup> createState() => _ScreenGroupState();
}

class _ScreenGroupState extends State<_ScreenGroup> {
  static const _service = ScreenBrightnessService();
  double? _percent;
  double? _volumePercent;
  Timer? _debounce;
  Timer? _volumeDebounce;

  @override
  void initState() {
    super.initState();
    if (_service.isSupported) {
      _service.readPercent().then((v) {
        if (mounted) setState(() => _percent = (v ?? 100).toDouble());
      });
    }
    _volumePercent = MasterVolume.instance.percent.value?.toDouble();
    MasterVolume.instance.percent.addListener(_volumeFromSystem);
    if (MasterVolume.instance.isSupported) MasterVolume.instance.refresh();
  }

  /// Changes from HA (MQTT) or a refresh; ignored mid-drag so a write that
  /// lands late doesn't pull the knob back.
  void _volumeFromSystem() {
    final v = MasterVolume.instance.percent.value;
    if (v != null && _volumeDebounce?.isActive != true) setState(() => _volumePercent = v.toDouble());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _volumeDebounce?.cancel();
    MasterVolume.instance.percent.removeListener(_volumeFromSystem);
    super.dispose();
  }

  void _changed(double v) {
    setState(() => _percent = v);
    // Each DDC/CI write takes ~100 ms on the monitor's I²C bus; only send
    // once the slider settles (the service also collapses bursts).
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () async {
      if (!await _service.setPercent(v.round())) KToast.show(l10n.settingsBrightnessFailed, error: true);
    });
  }

  void _volumeChanged(double v) {
    setState(() => _volumePercent = v);
    // One pactl process per write; don't spawn one for every drag frame.
    _volumeDebounce?.cancel();
    _volumeDebounce = Timer(const Duration(milliseconds: 80), () async {
      if (!await MasterVolume.instance.set(v.round())) KToast.show(l10n.settingsVolumeFailed, error: true);
    });
  }

  Widget _slider(String icon, double? p, ValueChanged<double> onChanged) => Row(
    children: [
      KIcon(icon, size: 26, color: KColors.muted, stroke: 2),
      const SizedBox(width: 18),
      Expanded(
        child: KSlider(
          value: (p ?? 0) / 100,
          enabled: p != null,
          height: 52,
          trackHeight: 12,
          knob: 36,
          track: KColors.border,
          fill: KColors.accent,
          onChanged: (v) => onChanged((v * 100).roundToDouble()),
        ),
      ),
      SizedBox(
        width: 72,
        child: Text(
          p == null ? '--' : '${p.round()}%',
          textAlign: TextAlign.right,
          style: KText.s(22, weight: FontWeight.w600),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final vol = _volumePercent;
    return _Group(
      icon: KIcons.screen,
      title: l10n.settingsScreenAndSound,
      rows: [
        _Row(
          label: l10n.settingsBrightness,
          sub: _service.isSupported ? l10n.settingsBrightnessSub : l10n.settingsUnavailableOnScreen,
          below: _slider(KIcons.sun, _percent, _changed),
        ),
        _Row(
          label: l10n.settingsVolume,
          sub: vol != null ? l10n.settingsVolumeSub : l10n.settingsUnavailableOnScreen,
          below: _slider(vol == null || vol == 0 ? KIcons.volLow : (vol < 50 ? KIcons.volMid : KIcons.volHigh), vol, _volumeChanged),
        ),
        _Row(
          label: l10n.settingsLanguage,
          sub: l10n.settingsLanguageSub,
          below: ListenableBuilder(
            listenable: LocaleController.instance,
            builder: (context, _) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (code, label) in [
                  ('auto', l10n.settingsLanguageAuto),
                  for (final l in LocaleController.supported) (l.languageCode, lookupAppLocalizations(l).languageName),
                ])
                  KChip(
                    label: label,
                    on: LocaleController.instance.choice == code,
                    fontSize: 20,
                    padX: 24,
                    offBg: KColors.tile,
                    onTap: () => LocaleController.instance.choose(code),
                  ),
              ],
            ),
          ),
        ),
        _Row(
          label: l10n.settingsScreenOff,
          sub: l10n.settingsScreenOffSub,
          trailing: _OutlineButton(label: l10n.settingsScreenOffButton, onTap: () => ScreenPowerController.instance.setPowered(false)),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ Assistente de voz

class _VoiceGroup extends ConsumerWidget {
  const _VoiceGroup({required this.onVoices});

  final VoidCallback onVoices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(_haLanguageProvider).valueOrNull;
    final sat = VoiceSatellite.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([sat.available, sat.muted]),
      builder: (context, _) {
        final available = sat.available.value;
        final on = available && !sat.muted.value;
        return _Group(
          icon: KIcons.micStand,
          title: l10n.settingsVoiceAssistant,
          rows: [
            _Row(
              label: l10n.settingsWakeWord,
              sub: available ? l10n.settingsWakeWordSub(ref.watch(assistantConfigProvider).wakePhrase) : l10n.settingsMicNotConnected,
              trailing: Opacity(
                opacity: available ? 1 : 0.45,
                child: KPress(
                  onTap: available ? () => sat.setMuted(on) : null,
                  child: KSwitch(on: on),
                ),
              ),
            ),
            _LinkRow(label: l10n.settingsRecognizedVoices, sub: l10n.settingsRecognizedVoicesSub, value: l10n.settingsManage, onTap: onVoices),
            _Row(
              label: l10n.settingsAssistantLanguage,
              sub: l10n.settingsSetInHa,
              trailing: Text(_languageName(language), style: KText.s(22, weight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  static String _languageName(String? code) => switch (code) {
    null => '--',
    'pt' || 'pt-PT' => 'Português (Portugal)',
    'pt-BR' => 'Português (Brasil)',
    'en' || 'en-GB' || 'en-US' => 'English',
    'es' => 'Español',
    'fr' => 'Français',
    _ => code,
  };
}

// --------------------------------------------------------------------- Ligações

class _ConnectionsGroup extends ConsumerWidget {
  const _ConnectionsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ha = ref.watch(haConnectionStateProvider).valueOrNull ?? HaConnectionState.disconnected;
    final url = ref.watch(connectionConfigProvider)?.baseUrl ?? '--';
    final host = Uri.tryParse(url)?.host ?? url;
    final count = ref.watch(entitiesProvider.select((a) => a.valueOrNull?.length ?? 0));
    final music = ref.watch(musicStoreProvider.select((m) => (conn: m.connection, speakers: m.speakers.where((p) => p.available).length)));
    final net = ref.watch(_networkProvider).valueOrNull;
    final haState = switch (ha) {
      HaConnectionState.connected => 'ok',
      HaConnectionState.connecting || HaConnectionState.authenticating => 'wait',
      _ => 'off',
    };
    final maState = switch (music.conn) {
      MaConnectionState.connected => 'ok',
      MaConnectionState.connecting => 'wait',
      _ => 'off',
    };
    return _Group(
      icon: KIcons.wifi,
      title: l10n.settingsConnections,
      rows: [
        _Status(label: 'Home Assistant', sub: l10n.settingsHaSub(host, count), state: haState),
        _Status(
          label: 'Music Assistant',
          sub: music.conn == MaConnectionState.connected
              ? l10n.settingsMaSpeakersFound(music.speakers)
              : (music.conn == MaConnectionState.unavailable ? l10n.settingsMaAddonMissing : l10n.settingsMaViaHa),
          state: maState,
        ),
        for (final l in net ?? const <_NetLink>[]) _Status(label: l.label, sub: l.sub, state: l.up ? 'ok' : 'off'),
      ],
    );
  }
}

// ------------------------------------------------------------- Intercomunicador

class _IntercomGroup extends ConsumerWidget {
  const _IntercomGroup({required this.onOpen});

  final VoidCallback onOpen;

  static const _building = '<path d="M4 21V6l8-3 8 3v15M2 21h20M8 9h2M14 9h2M8 13h2M14 13h2M10 21v-4h4v4"/>';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Optional: without one, the section says where it's set up (design
    // "SemIntercomDefinicoes").
    if (!ref.watch(hasIntercomProvider)) {
      return _Group(
        icon: _building,
        title: l10n.settingsIntercom,
        rows: [
          _Row(
            label: l10n.settingsIntercomOff,
            sub: l10n.settingsIntercomOffSub,
            trailing: Text(
              l10n.settingsIntercomOffValue,
              style: KText.s(20, weight: FontWeight.w600, color: KColors.faint),
            ),
          ),
        ],
      );
    }
    final ringer = DoorbellRinger.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([ringer.settings, ringer.customTones]),
      builder: (context, _) {
        final s = ringer.settings.value;
        final tone = ringer.all.where((r) => r.id == s.ringtone).firstOrNull;
        return _Group(
          icon: _building,
          title: l10n.settingsIntercom,
          rows: [
            _LinkRow(
              label: l10n.settingsIntercomTones,
              sub: l10n.settingsIntercomToneSub(tone?.name ?? '--'),
              value: l10n.settingsVolumePercent(s.volume),
              onTap: onOpen,
            ),
            const _IntercomStatus(),
          ],
        );
      },
    );
  }
}

/// The intercom's row: healthy while a ring would reach this screen — the
/// same signal as the shell's loud doorbell banner.
class _IntercomStatus extends ConsumerWidget {
  const _IntercomStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intercom = ref.watch(intercomControllerProvider);
    if (!intercom.connected) return _Status(label: l10n.settingsIntercomConnection, sub: l10n.settingsIntercomNotConfigured, state: 'off');
    final problem = intercom.doorbellProblem;
    if (problem == null) return _Status(label: l10n.settingsIntercomConnection, sub: l10n.settingsIntercomDoorCamera, state: 'ok');
    return ValueListenableBuilder<String?>(
      valueListenable: problem,
      builder: (context, why, _) =>
          _Status(label: l10n.settingsIntercomConnection, sub: why ?? l10n.settingsIntercomBuildingDoor, state: why == null ? 'ok' : 'off'),
    );
  }
}

// ---------------------------------------------------------------------- Sistema

class _SystemGroup extends StatelessWidget {
  const _SystemGroup({required this.onBrowserSettings});

  final VoidCallback onBrowserSettings;

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String text,
    required String cta,
    required String toast,
    required Future<void> Function() action,
  }) async {
    final ok = await showKModal<bool>(
      context,
      (ctx) => KModal(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: KText.modalTitle),
            const SizedBox(height: 20),
            Text(text, style: KText.s(22, color: KColors.muted, height: 1.45)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                KButton(label: l10n.commonCancel, height: 72, padding: const EdgeInsets.symmetric(horizontal: 40), onTap: () => Navigator.of(ctx).pop(false)),
                const SizedBox(width: 14),
                KButton.primary(label: cta, height: 72, padding: const EdgeInsets.symmetric(horizontal: 44), onTap: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    KToast.show(toast);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await action();
  }

  @override
  Widget build(BuildContext context) {
    final system = SystemControlService();
    return _Group(
      icon: KIcons.gear,
      title: l10n.settingsSystem,
      rows: [
        _Row(
          label: l10n.settingsVersion,
          sub: l10n.settingsVersionSub,
          trailing: Text('$kBuildRevision · flutter-pi', style: KText.s(22, weight: FontWeight.w600)),
        ),
        _Row(label: l10n.settingsConfigureEntities, sub: l10n.settingsConfigureEntitiesSub),
        if (!kIsWeb)
          _Row(
            label: l10n.settingsRestartApp,
            sub: l10n.settingsRestartAppSub,
            trailing: _OutlineButton(
              label: l10n.settingsRestartApp,
              onTap: () => _confirm(
                context,
                title: l10n.settingsRestartAppTitle,
                text: l10n.settingsRestartAppText,
                cta: l10n.settingsRestart,
                toast: l10n.settingsRestartingApp,
                // The systemd service restarts the app whenever it exits.
                action: () async => exit(0),
              ),
            ),
          ),
        if (system.isSupported)
          _Row(
            label: l10n.settingsRebootScreen,
            sub: l10n.settingsRebootScreenSub,
            trailing: _OutlineButton(
              label: l10n.settingsRebootScreen,
              onTap: () => _confirm(
                context,
                title: l10n.settingsRebootScreenTitle,
                text: l10n.settingsRebootScreenText,
                cta: l10n.settingsRebootScreen,
                toast: l10n.settingsRebootingScreen,
                action: () async {
                  if (!await system.reboot()) KToast.show(l10n.settingsRebootFailed, error: true);
                },
              ),
            ),
          ),
        if (!kIsWeb) ...[
          // Opened from here, as the other rows' buttons; its settings on a page of their own.
          _Row(
            label: l10n.settingsWebBrowser,
            sub: l10n.settingsBrowserOpenSub,
            trailing: _OutlineButton(label: l10n.commonOpen, onTap: () => Browser.open(context)),
          ),
          _LinkRow(label: l10n.settingsBrowserSettings, sub: l10n.settingsBrowserSettingsSub, value: l10n.settingsBrowserManage, onTap: onBrowserSettings),
        ],
      ],
    );
  }
}
