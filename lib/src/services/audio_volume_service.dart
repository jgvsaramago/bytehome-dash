// Reads/writes the device's master volume — the default PipeWire output
// (the reSpeaker's speaker on the kiosk). A no-op stub swaps in on web, where
// `dart:io` doesn't exist.
export 'audio_volume_service_stub.dart' if (dart.library.io) 'audio_volume_service_io.dart';
