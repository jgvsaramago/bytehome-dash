import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../music/ma_client.dart';
import '../../music/ma_models.dart';
import '../../music/music_store.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import 'kiosk_widgets.dart';

/// Paper/sand tones the Música design uses on top of the kiosk palette.
abstract final class KMusic {
  static Color get paper => KColors.sub;
  static Color get sand => KColors.chip;
  static Color get line => KColors.border;
  static Color get rule => KColors.divider;
  // Light: two paler steps of accent-soft from the Música board; dark:
  // accent-soft itself.
  static Color get playingRow => KColors.isDark ? KColors.accentSoft : const Color(0xFFEEF4F2);
  static Color get groupOn => KColors.isDark ? KColors.accentSoft : const Color(0xFFE4EEEB);
  static Color get faint => KColors.disabledFg;

  /// Gradient pairs for artwork that has no image (and the genre tiles).
  /// Artwork: the same in both themes.
  static const gradients = [
    (Color(0xFF1F4D45), Color(0xFFE0A96D)),
    (Color(0xFF7A1F2B), Color(0xFFD9734E)),
    (Color(0xFF3B2A5C), Color(0xFFA06CD5)),
    (Color(0xFF1B3A4B), Color(0xFF2EC4B6)),
    (Color(0xFFD16B86), Color(0xFFF2B49B)),
    (Color(0xFF0B6E4F), Color(0xFFE0A82E)),
    (Color(0xFF2C3E73), Color(0xFF8EA6F0)),
    (Color(0xFF0F4C81), Color(0xFFE5B80B)),
    (Color(0xFF5E3023), Color(0xFFC08552)),
    (Color(0xFF3A0CA3), Color(0xFFF72585)),
    (Color(0xFF2F3E46), Color(0xFF8FA89B)),
    (Color(0xFFC1121F), Color(0xFFFF8A00)),
  ];

  static LinearGradient gradientFor(String key) {
    final pair = gradients[key.hashCode.abs() % gradients.length];
    return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [pair.$1, pair.$2]);
  }

  /// The coloured dot and name for where an item streams from — each
  /// service's brand colour, the same in both themes (Tidal's black dot
  /// follows `ink` so it doesn't vanish in the dark).
  static (Color, String) source(String domain) => switch (domain) {
    'spotify' => (const Color(0xFF1DB954), 'Spotify'),
    'apple_music' => (const Color(0xFFFA2D48), 'Apple Music'),
    'tunein' => (const Color(0xFF14A8A0), 'TuneIn'),
    'radiobrowser' => (const Color(0xFF14A8A0), l10n.musicRadio),
    'youtube_music' || 'ytmusic' => (const Color(0xFFFF0000), 'YouTube Music'),
    'tidal' => (KColors.ink, 'Tidal'),
    'deezer' => (const Color(0xFFA238FF), 'Deezer'),
    'filesystem_local' || 'filesystem_smb' || 'plex' || 'jellyfin' || 'subsonic' => (const Color(0xFF8A8F98), l10n.musicLocalLibrary),
    _ => (const Color(0xFF18BCF2), 'Music Assistant'),
  };
}

String fmtDuration(num? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final s = seconds.round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}' : '$m:${r.toString().padLeft(2, '0')}';
}

String totalDuration(List<MaItem> items) {
  final m = (items.fold<int>(0, (a, i) => a + (i.duration ?? 0)) / 60).round();
  return m >= 60 ? l10n.musicDurationHoursMinutes(m ~/ 60, m % 60) : l10n.musicDurationMinutes(m);
}

String initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty && w[0].toUpperCase() == w[0] && RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(w[0]))
    .take(2)
    .map((w) => w[0])
    .join();

/// The decoded-at-size image [MaArt] draws; the same key [precacheMaArt]
/// warms, so a pre-loaded cover shows without a decode.
ImageProvider maArtImage(MaClient client, String url, double px) => ResizeImage(
  NetworkImage(url, headers: client.imageHeaders),
  width: px.round(),
  policy: ResizeImagePolicy.fit,
);

/// Decodes [image] at [size] ahead of time — the big "A tocar" cover, so
/// opening it doesn't stall its slide-in on a decode and texture upload.
void precacheMaArt(BuildContext context, WidgetRef ref, MaImage? image, double size) {
  final client = ref.read(maClientProvider);
  final url = client?.imageUrl(image);
  if (client == null || url == null) return;
  precacheImage(maArtImage(client, url, size * MediaQuery.devicePixelRatioOf(context)), context, onError: (_, _) {});
}

/// An item's artwork: its MA image when it has one, otherwise the design's
/// gradient tile with the name on it.
class MaArt extends ConsumerWidget {
  const MaArt({
    super.key,
    required this.size,
    this.item,
    this.image,
    this.label,
    this.radius = 22,
    this.circle = false,
    this.labelSize,
    this.shadow = false,
    this.width,
  });

  final double size;
  final double? width;
  final MaItem? item;
  final MaImage? image;
  final String? label;
  final double radius;
  final bool circle;
  final double? labelSize;
  final bool shadow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(maClientProvider);
    final img = image ?? item?.image;
    final url = client?.imageUrl(img);
    final key = item?.uri ?? label ?? '';
    final w = width ?? size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final shape = circle ? const CircleBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    final text = label ?? item?.name ?? '';
    final fallback = Stack(
      children: [
        Positioned(
          right: -w * 0.19,
          bottom: -w * 0.19,
          child: Container(
            width: w * 0.73,
            height: w * 0.73,
            decoration: BoxDecoration(color: KColors.onAccent.withValues(alpha: 0.14), shape: BoxShape.circle),
          ),
        ),
        if (labelSize != null && text.isNotEmpty)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(size * 0.08),
              child: Align(
                alignment: circle ? Alignment.center : Alignment.bottomLeft,
                child: Text(
                  circle ? initials(text) : text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: circle ? TextAlign.center : TextAlign.left,
                  style: KText.d(labelSize!, color: KColors.onAccent, height: 1.08),
                ),
              ),
            ),
          ),
      ],
    );
    return Container(
      width: w,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: KMusic.gradientFor(key),
        shadows: shadow ? [BoxShadow(color: KColors.dark.withValues(alpha: 0.12), blurRadius: 18, offset: const Offset(0, 6))] : null,
      ),
      child: url == null
          ? fallback
          : Image(image: maArtImage(client!, url, w * dpr), fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => fallback),
    );
  }
}

/// The design's "a tocar" bars (`dcWave`): three bars bouncing from the
/// bottom while [playing].
class PlayingBars extends StatefulWidget {
  const PlayingBars({super.key, this.playing = true, Color? color, this.height = 22, this.barWidth = 4, this.gap = 3}) : _color = color;

  final bool playing;
  final Color? _color;
  Color get color => _color ?? KColors.accentFg;
  final double height;
  final double barWidth;
  final double gap;

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(PlayingBars old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) _c.repeat();
    if (!widget.playing && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Its own layer, so the bars don't repaint the whole page around them
    // every frame (which also kept the Pi from caching that page).
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: widget.gap),
                Container(
                  width: widget.barWidth,
                  height: widget.height * (widget.playing ? 0.25 + 0.75 * (1 - math.cos(2 * math.pi * ((_c.value - i * 0.25) % 1))) / 2 : 0.35),
                  decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(widget.barWidth / 2)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Track + fill + knob slider the Música design uses for position and
/// volume. Reports 0..1; [onEnd] fires when the finger lifts.
class KSlider extends StatefulWidget {
  const KSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onEnd,
    this.height = 44,
    this.trackHeight = 10,
    this.knob = 30,
    Color? track,
    Color? fill,
    this.knobColor = KColors.onAccent,
    this.knobShadow = true,
    this.enabled = true,
  }) : _track = track,
       _fill = fill;

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onEnd;
  final double height;
  final double trackHeight;
  final double knob;
  final Color? _track;
  final Color? _fill;
  Color get track => _track ?? (KColors.isDark ? KColors.onAccent.withValues(alpha: 0.14) : KColors.dark.withValues(alpha: 0.12));
  Color get fill => _fill ?? KColors.ink;
  final Color knobColor;
  final bool knobShadow;
  final bool enabled;

  @override
  State<KSlider> createState() => _KSliderState();
}

class _KSliderState extends State<KSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final v = (_drag ?? widget.value).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        double at(Offset p) => (p.dx / w).clamp(0.0, 1.0);
        void move(Offset p) {
          setState(() => _drag = at(p));
          widget.onChanged(at(p));
        }

        void end() {
          final d = _drag;
          setState(() => _drag = null);
          if (d != null) widget.onEnd?.call(d);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? (d) => move(d.localPosition) : null,
          onTapUp: widget.enabled ? (_) => end() : null,
          onHorizontalDragUpdate: widget.enabled ? (d) => move(d.localPosition) : null,
          onHorizontalDragEnd: widget.enabled ? (_) => end() : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: SizedBox(
              height: widget.height,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: widget.trackHeight,
                    decoration: BoxDecoration(color: widget.track, borderRadius: BorderRadius.circular(widget.trackHeight / 2)),
                  ),
                  Container(
                    width: w * v,
                    height: widget.trackHeight,
                    decoration: BoxDecoration(color: widget.fill, borderRadius: BorderRadius.circular(widget.trackHeight / 2)),
                  ),
                  Positioned(
                    left: w * v - widget.knob / 2,
                    child: Container(
                      width: widget.knob,
                      height: widget.knob,
                      decoration: BoxDecoration(
                        color: widget.knobColor,
                        shape: BoxShape.circle,
                        boxShadow: widget.knobShadow
                            ? [BoxShadow(color: KColors.dark.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The "EM DIRETO" dot over radio artwork: on the image, so fixed.
const _liveDot = Color(0xFFFF5A4E);

/// A 232 px square card with title and subtitle under it — the rails on
/// "Ouvir agora", search results and an artist's discography.
class MusicCard extends StatelessWidget {
  const MusicCard({super.key, required this.item, required this.onTap, this.sub, this.playing = false});

  final MaItem item;
  final VoidCallback onTap;
  final String? sub;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final artist = item.mediaType == 'artist';
    final radio = item.mediaType == 'radio';
    return KPress(
      onTap: onTap,
      child: SizedBox(
        width: 232,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                MaArt(item: item, size: 232, circle: artist, shadow: true, labelSize: artist ? 72 : (radio ? 34 : 26)),
                if (radio && !playing)
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: KColors.dark.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          KBlink(
                            period: const Duration(milliseconds: 1400),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: _liveDot, shape: BoxShape.circle),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.musicLive,
                            style: KText.s(14, weight: FontWeight.w700, color: KColors.onAccent, spacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (playing)
                  Positioned(
                    right: 14,
                    top: 14,
                    child: Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.only(bottom: 14),
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(color: KColors.accent, shape: BoxShape.circle),
                      child: const PlayingBars(color: KColors.onAccent, height: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: KText.s(22, weight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              sub ?? describe(item),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: KText.s(17, color: KColors.muted, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Playlist · Ana", "2020 · Mariza", "Artista"… for a card or row.
String describe(MaItem item) => switch (item.mediaType) {
  'playlist' => item.owner == null || item.owner!.isEmpty ? l10n.musicPlaylist : l10n.musicPlaylistBy(item.owner!),
  'album' => [if (item.year != null) '${item.year}', if (item.artistNames.isNotEmpty) item.artistNames].join(' · '),
  'artist' => l10n.musicArtist,
  'radio' => l10n.musicRadio,
  'podcast' => item.owner == null || item.owner!.isEmpty ? l10n.musicPodcast : l10n.musicPodcastBy(item.owner!),
  'track' => item.artistNames,
  _ => '',
};

/// A titled horizontal row of [MusicCard]s.
class MusicRail extends StatelessWidget {
  const MusicRail({super.key, required this.title, required this.children, this.note, this.wrap = false});

  final String title;
  final String? note;
  final List<Widget> children;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(title, style: KText.d(34))),
            if (note != null) Text(note!, style: KText.s(17, color: KColors.muted)),
          ],
        ),
        const SizedBox(height: 20),
        if (wrap)
          Wrap(spacing: 24, runSpacing: 28, children: children)
        else
          // Unclipped, so cards scroll out to the card's own edge as in the
          // design (the section card clips them there).
          SizedBox(
            height: 232 + 12 + 30 + 4 + 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 24),
              itemBuilder: (_, i) => Align(alignment: Alignment.topLeft, child: children[i]),
            ),
          ),
      ],
    );
  }
}

/// A pill chip (filters, recent searches, presets).
class MusicChip extends StatelessWidget {
  const MusicChip({super.key, required this.label, required this.onTap, this.on = false, this.icon, this.count, this.height = 56});

  final String label;
  final VoidCallback onTap;
  final bool on;
  final String? icon;
  final String? count;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = on ? KColors.onAccent : KColors.ink;
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        padding: EdgeInsets.fromLTRB(icon == null ? 26 : 18, 0, icon == null ? 26 : 24, 0),
        decoration: BoxDecoration(color: on ? KColors.accent : KMusic.sand, borderRadius: BorderRadius.circular(height / 2)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[KIcon(icon!, size: 22, color: on ? KColors.onAccent : KColors.muted, stroke: 2), const SizedBox(width: 10)],
            Text(
              label,
              style: KText.s(20, weight: FontWeight.w600, color: fg),
            ),
            if (count != null) ...[
              const SizedBox(width: 10),
              Opacity(
                opacity: .7,
                child: Text(
                  count!,
                  style: KText.s(17, weight: FontWeight.w600, color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A round button on the sand background (shuffle, heart, add to queue…).
class MusicRoundButton extends StatelessWidget {
  const MusicRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 72,
    this.iconSize = 30,
    Color? bg,
    Color? fg,
    this.filled = false,
    this.stroke = 2,
  }) : _bg = bg,
       _fg = fg;

  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? _bg;
  final Color? _fg;
  Color get bg => _bg ?? KMusic.sand;
  Color get fg => _fg ?? KColors.ink;
  final bool filled;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: KIcon(icon, size: iconSize, color: fg, stroke: stroke, filled: filled),
      ),
    );
  }
}

/// The big accent play/pause button.
class MusicPlayButton extends StatelessWidget {
  const MusicPlayButton({super.key, required this.playing, required this.onTap, this.size = 96});

  final bool playing;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return KPress(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: KColors.accent,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: KColors.accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        alignment: Alignment.center,
        child: KIcon(playing ? KIcons.pauseFilled : KIcons.playFilled, size: size * 0.42, color: KColors.onAccent, filled: true),
      ),
    );
  }
}
