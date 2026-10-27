/// Web build of [BrowserAudioStreams] — no PipeWire to talk to.
class BrowserAudioStreams {
  BrowserAudioStreams(void Function() onNewStream);

  Future<void> apply({required int percent, required bool muted}) async {}

  void watch() {}

  void unwatch() {}
}
