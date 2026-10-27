import 'mqtt_config.dart';

/// Web build — nothing to connect to.
class DeviceTelemetryPublisher {
  DeviceTelemetryPublisher();

  Future<void> start(MqttConfig config) async {}

  Future<void> stop() async {}
}
