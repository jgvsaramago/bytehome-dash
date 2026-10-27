import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/ha_entity.dart';
import '../data/house_models.dart';
import '../data/dates.dart';
import '../theme/kiosk_icons.dart';
import '../theme/kiosk_tokens.dart';
import '../widgets/ac_widgets.dart';
import '../widgets/kiosk_widgets.dart';
import 'history_modal.dart';

Future<void> showRoomModal(BuildContext context, String areaId) => showKModal(context, (_) => RoomModal(areaId: areaId));

void _try(Future<void> f) => f.catchError(KToast.error);

/// "Aberta"/"Destrancada" as text: the warm dot in the light, warm `-fg`
/// in the dark.
Color get _openFg => KColors.isDark ? KColors.orangeInk : KColors.orange;

// Slider tracks: the design's tinted ones in the light, `track` in the dark.
Color get _brightTrack => KColors.isDark ? KColors.border : const Color(0xFFF1E3C2);
Color get _blindsTrack => KColors.isDark ? KColors.border : const Color(0xFFDCE6F0);

/// One room's controls (the design's "Modal de uma divisão"), opened from
/// its Divisões tile: lights and brightness, blinds, AC, ventilation, and
/// the window and extra line as plain readings.
class RoomModal extends ConsumerWidget {
  const RoomModal({super.key, required this.areaId});

  final String areaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = ref.watch(roomTilesProvider.select((rooms) => rooms.where((r) => r.areaId == areaId).firstOrNull));
    if (room == null) return const KModal(child: SizedBox(height: 120));
    // Each reading opens its history.
    final sub = Wrap(
      children: [
        KHistoryTap(
          target: room.temp == null || room.tempId == null
              ? null
              : HistoryTarget(entityId: room.tempId!, label: l10n.roomTemperatureHistory(room.name), unit: '°C', kind: HistoryKind.temp),
          child: Text(room.temp == null ? l10n.roomNoTemperatureSensor : l10n.acNowTemp(fmtDeg(room.temp))),
        ),
        if (room.humidity != null) ...[
          const Text(' · '),
          KHistoryTap(
            target: room.humidityId == null
                ? null
                : HistoryTarget(entityId: room.humidityId!, label: l10n.roomHumidityHistory(room.name), unit: '%', kind: HistoryKind.humidity),
            child: Text(l10n.roomHumidityValue(room.humidity!.round())),
          ),
        ],
      ],
    );
    final info = <(String, String, String, Color, HistoryTarget)>[
      if (room.window case final w?)
        (
          KIcons.window,
          l10n.roomWindow,
          room.windowOpen ? l10n.houseDoorOpen : l10n.houseDoorClosed,
          room.windowOpen ? _openFg : KColors.greenInk,
          HistoryTarget(
            entityId: w.entityId,
            label: l10n.roomWindowHistory(room.name),
            kind: HistoryKind.binary,
            states: [l10n.houseDoorClosed, l10n.houseDoorOpen],
          ),
        ),
      if (room.extra case final e?) _infoRow(e),
    ];
    final blocks = <Widget>[
      if (room.light != null) _LightBlock(room: room),
      if (room.cover != null) _BlindsBlock(room: room),
      if (room.ac != null) KRoomAcBlock(unit: room.ac!),
      if (room.vent != null) _VentBlock(room: room),
      if (info.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Column(
            children: [
              for (final (i, (icon, label, value, color, history)) in info.indexed)
                KHistoryTap(
                  target: history,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: KColors.divider, width: 1.5)),
                    ),
                    child: Row(
                      children: [
                        KIcon(icon, size: 26, color: color),
                        const SizedBox(width: 14),
                        Expanded(child: Text(label, style: KText.s(20))),
                        Text(
                          value,
                          style: KText.s(20, weight: FontWeight.w600, color: color),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
    ];
    return KModal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KModalHeader(title: room.name, subtitleChild: sub),
          for (final b in blocks) ...[const SizedBox(height: 24), b],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: KColors.divider, width: 1.5)),
            ),
            alignment: Alignment.centerRight,
            child: KButton.primary(
              label: l10n.commonDone,
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 44),
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, String, Color, HistoryTarget) _infoRow(HaEntity e) {
    final icon = switch (e.domain) {
      'lock' => KIcons.door,
      'cover' => KIcons.garage,
      'water_heater' => KIcons.thermo,
      'sensor' when e.deviceClass == 'temperature' => KIcons.thermo,
      'sensor' when e.deviceClass == 'power' => KIcons.plug,
      _ => KIcons.info,
    };
    final (value, color) = switch (e.domain) {
      'lock' => e.state == 'locked' ? (l10n.houseLockLocked, KColors.greenInk) : (l10n.houseLockUnlocked, _openFg),
      'cover' => e.state == 'closed' ? (l10n.houseGateClosed, KColors.greenInk) : (l10n.houseGateOpen, _openFg),
      _ => (e.displayState, KColors.muted),
    };
    final unit = e.attributes['unit_of_measurement'] as String? ?? '';
    final history = switch (e.domain) {
      'lock' => HistoryTarget(entityId: e.entityId, label: e.friendlyName, kind: HistoryKind.binary, states: [l10n.houseLockLocked, l10n.houseLockUnlocked]),
      'cover' || 'binary_sensor' => HistoryTarget(
        entityId: e.entityId,
        label: e.friendlyName,
        kind: HistoryKind.binary,
        states: [l10n.houseGateClosed, l10n.houseGateOpen],
      ),
      _ when double.tryParse(e.state) != null => HistoryTarget(
        entityId: e.entityId,
        label: e.friendlyName,
        unit: unit,
        kind: switch (e.deviceClass) {
          'temperature' => HistoryKind.temp,
          'humidity' => HistoryKind.humidity,
          'power' => HistoryKind.power,
          'energy' => HistoryKind.energy,
          _ => HistoryKind.number,
        },
      ),
      _ => HistoryTarget(entityId: e.entityId, label: e.friendlyName, kind: HistoryKind.states, stateLabel: (raw) => raw),
    };
    return (icon, e.friendlyName, value, color, history);
  }
}

/// The rounded grey (or lit) block each control sits in.
class _Block extends StatelessWidget {
  const _Block({required this.children, Color? bg}) : _bg = bg;

  final List<Widget> children;
  final Color? _bg;
  Color get bg => _bg ?? KColors.sub;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );
}

Widget _head({required String icon, required Color iconBg, required Color iconFg, required String title, required String sub, required Widget trailing}) => Row(
  children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
      child: Center(child: KIcon(icon, size: 28, color: iconFg)),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KText.s(24, weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(sub, style: KText.s(17, color: KColors.muted)),
        ],
      ),
    ),
    trailing,
  ],
);

class _LightBlock extends ConsumerStatefulWidget {
  const _LightBlock({required this.room});

  final RoomTile room;

  @override
  ConsumerState<_LightBlock> createState() => _LightBlockState();
}

class _LightBlockState extends ConsumerState<_LightBlock> {
  /// While dragging: the brightness under the finger.
  int? _drag;

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final on = r.lightOn;
    final id = r.light!.entityId;
    final bri = _drag ?? r.brightness ?? 100;
    return _Block(
      bg: on ? KColors.lightRoomBg : KColors.sub,
      children: [
        _head(
          icon: KIcons.bulb,
          iconBg: on ? KColors.lightIconBg : KColors.chipAlt,
          iconFg: on ? KColors.lightIconFg : KColors.muted,
          title: l10n.roomLights,
          sub: on ? l10n.houseLightsOn(r.lightsOn) : l10n.roomLightsOff,
          trailing: KPress(
            onTap: () => _try(toggleLight(ref, id, !on)),
            child: KSwitch(on: on),
          ),
        ),
        if (on && r.dimmable) ...[
          const SizedBox(height: 16),
          _SliderRow(
            label: l10n.roomBrightness,
            value: bri,
            track: _brightTrack,
            fill: KColors.lightIconBg,
            onChanged: (v) => setState(() => _drag = v.clamp(1, 100)),
            onDone: (v) {
              _try(setBrightness(ref, id, v.clamp(1, 100)).whenComplete(() => mounted ? setState(() => _drag = null) : null));
            },
          ),
        ],
      ],
    );
  }
}

class _BlindsBlock extends ConsumerStatefulWidget {
  const _BlindsBlock({required this.room});

  final RoomTile room;

  @override
  ConsumerState<_BlindsBlock> createState() => _BlindsBlockState();
}

class _BlindsBlockState extends ConsumerState<_BlindsBlock> {
  int? _drag;

  @override
  Widget build(BuildContext context) {
    final r = widget.room;
    final pos = _drag ?? r.coverPosition ?? 0;
    final moving = r.cover!.state == 'opening' || r.cover!.state == 'closing';
    final sub = moving
        ? (r.cover!.state == 'opening' ? l10n.roomBlindsOpening : l10n.roomBlindsClosing)
        : (pos == 0 ? l10n.roomBlindsClosed : (pos == 100 ? l10n.roomBlindsOpen : l10n.roomBlindsOpenAt(pos)));
    return _Block(
      children: [
        _head(
          icon: KIcons.blinds,
          iconBg: KColors.blueTint,
          iconFg: KColors.blue,
          title: l10n.roomBlinds,
          sub: sub,
          trailing: Row(
            children: [
              for (final (i, (label, value)) in [(l10n.commonOpen, 100), if (r.coverSettable) (l10n.roomBlindsHalf, 50), (l10n.commonClose, 0)].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                KButton(
                  label: label,
                  height: 56,
                  fontSize: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  border: null,
                  bg: pos == value && !moving ? KColors.blue : KColors.tile,
                  fg: pos == value && !moving ? KColors.onAccent : KColors.ink,
                  onTap: () => _try(setCover(ref, r, value)),
                ),
              ],
            ],
          ),
        ),
        if (r.coverSettable) ...[
          const SizedBox(height: 16),
          _SliderRow(
            label: l10n.roomBlindsAperture,
            value: pos,
            track: _blindsTrack,
            fill: KColors.blue,
            onChanged: (v) => setState(() => _drag = v),
            onDone: (v) {
              _try(setCover(ref, r, v).whenComplete(() => mounted ? setState(() => _drag = null) : null));
            },
          ),
        ],
      ],
    );
  }
}

class _VentBlock extends ConsumerWidget {
  const _VentBlock({required this.room});

  final RoomTile room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = room.ventOn;
    return _Block(
      children: [
        _head(
          icon: KIcons.fan,
          iconBg: KColors.greenTint,
          iconFg: KColors.greenInk,
          title: l10n.roomVentilation,
          sub: on ? l10n.roomVentOn : l10n.roomVentOff,
          trailing: KPress(
            onTap: () => _try(toggleEntity(ref, room.vent!, !on)),
            child: KSwitch(on: on),
          ),
        ),
      ],
    );
  }
}

/// "Brilho" / "Abertura": label, a 0-100 track with a white knob, and the
/// value. [onChanged] follows the finger; [onDone] fires once on release.
class _SliderRow extends StatelessWidget {
  const _SliderRow({required this.label, required this.value, required this.track, required this.fill, required this.onChanged, required this.onDone});

  final String label;
  final int value;
  final Color track;
  final Color fill;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onDone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: KText.s(17, weight: FontWeight.w600, color: KColors.muted),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              int at(double dx) => (dx / box.maxWidth * 100).clamp(0, 100).round();
              var last = value;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => onDone(at(d.localPosition.dx)),
                onHorizontalDragStart: (d) => onChanged(last = at(d.localPosition.dx)),
                onHorizontalDragUpdate: (d) => onChanged(last = at(d.localPosition.dx)),
                onHorizontalDragEnd: (_) => onDone(last),
                child: SizedBox(
                  height: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 18,
                        height: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: track, borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 18,
                        height: 16,
                        width: box.maxWidth * value / 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Positioned(
                        left: box.maxWidth * value / 100 - 18,
                        top: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          // The knob stays white, like a switch's.
                          decoration: const BoxDecoration(
                            color: KColors.onAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Color(0x4017191C), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 64,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            style: KText.s(22, weight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
