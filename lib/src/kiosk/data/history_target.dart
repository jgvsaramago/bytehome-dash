/// What a value on screen measures — picks the chart's colour, icon and
/// number format (the design's `kind`).
enum HistoryKind { temp, humidity, power, energy, battery, percent, wind, pressure, uv, rain, radiation, number, binary, states }

/// An entity whose history a tap on its value opens.
class HistoryTarget {
  const HistoryTarget({required this.entityId, required this.label, this.unit = '', this.kind = HistoryKind.number, this.states, this.stateLabel});

  final String entityId;
  final String label;
  final String unit;
  final HistoryKind kind;

  /// [HistoryKind.binary]: how to say "closed/off" and "open/on", in that
  /// order (`Fechada|Aberta`).
  final List<String>? states;

  /// [HistoryKind.states]: a raw state as the screen says it.
  final String Function(String raw)? stateLabel;

  bool get timeline => kind == HistoryKind.binary || kind == HistoryKind.states;
}
