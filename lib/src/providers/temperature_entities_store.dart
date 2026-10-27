import '../ha_client/ha_websocket_client.dart';

/// The panel's Meteorologia: the header's temperature sensor (preferred
/// for the big number) and `weather.*` entity (condition and forecast),
/// `sun.*` (sunrise/sunset, automatic dark mode) and the forecast modal's
/// warning, fire risk and UV sensors. All chosen in the HA integration —
/// which pre-fills them with its own guess — never looked up here. Saved
/// under the old `temperature_entities` key; its older fields (indoor air
/// quality, wind, rain…) are no longer read.
class TemperatureEntityConfig {
  const TemperatureEntityConfig({
    this.exteriorTempEntityId,
    this.weatherStateEntityId,
    this.sunEntityId,
    this.warningEntityId,
    this.fireRiskEntityId,
    this.uvEntityId,
  });

  final String? exteriorTempEntityId;
  final String? weatherStateEntityId;
  final String? sunEntityId;
  final String? warningEntityId;
  final String? fireRiskEntityId;
  final String? uvEntityId;

  factory TemperatureEntityConfig.fromJson(Map<String, dynamic> json) {
    String? id(String k) => switch (json[k]) {
      final String s when s.trim().isNotEmpty => s.trim(),
      _ => null,
    };
    return TemperatureEntityConfig(
      exteriorTempEntityId: id('exteriorTempEntityId'),
      weatherStateEntityId: id('weatherStateEntityId'),
      sunEntityId: id('sunEntityId'),
      warningEntityId: id('warningEntityId'),
      fireRiskEntityId: id('fireRiskEntityId'),
      uvEntityId: id('uvEntityId'),
    );
  }
}

/// Reads [TemperatureEntityConfig] as saved by the HA sidebar panel.
class TemperatureEntitiesStore {
  TemperatureEntitiesStore(this._client);

  final HaWebSocketClient _client;

  static const _key = 'temperature_entities';

  Future<TemperatureEntityConfig> read() async {
    final raw = await _client.getSettings(_key);
    if (raw is! Map) return const TemperatureEntityConfig();
    return TemperatureEntityConfig.fromJson(raw.cast<String, dynamic>());
  }
}
