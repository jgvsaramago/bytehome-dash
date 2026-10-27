// Sets the volume of the in-app browser's own audio streams (the WPE web
// process's PipeWire streams), leaving the master volume alone. A no-op stub
// swaps in on web, where `dart:io` doesn't exist.
export 'browser_audio_streams_stub.dart' if (dart.library.io) 'browser_audio_streams_io.dart';
