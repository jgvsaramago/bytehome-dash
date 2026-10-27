import 'dart:io';

import 'package:flutter/foundation.dart';

/// This screen's name: `SCREEN_NAME` from the launch environment, else the
/// machine's hostname. It lists the screen in the sidebar panel and names its
/// MQTT device, so every screen in the house shows up as itself — set the
/// hostname (or `SCREEN_NAME`) per device, e.g. `dashboard-living-room`.
String screenName() {
  if (kIsWeb) return 'Navegador';
  final env = Platform.environment['SCREEN_NAME']?.trim();
  return env == null || env.isEmpty ? Platform.localHostname : env;
}

/// The board the app runs on, from the device tree ("Raspberry Pi 5 Model B
/// Rev 1.0", "Radxa ROCK 5B"). Null off-device.
String? boardModel() {
  if (kIsWeb) return null;
  try {
    final model = File('/sys/firmware/devicetree/base/model').readAsStringSync().replaceAll('\x00', '').trim();
    return model.isEmpty ? null : model;
  } catch (_) {
    return null;
  }
}
