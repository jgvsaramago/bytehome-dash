import 'dart:async';

import 'package:flutter/foundation.dart';

import '../l10n/l10n.dart';
import 'doorbell_watcher.dart';
import 'sip_extension.dart';

/// Web/no-io stand-in: never registers, never rings, and says so — same shape
/// as [MissingDoorbellWatcher] so the shell can warn.
SipExtension startSipExtension(SipExtensionConfig config) => _StubSipExtension();

class _StubSipExtension implements SipExtension {
  late final _problem = ValueNotifier<String?>(l10n.doorSipDeviceOnly);

  @override
  Stream<IndoorCallStatus> get calls => const Stream.empty();

  @override
  ValueListenable<String?> get problem => _problem;

  @override
  SipCallMedia? get activeMedia => null;

  @override
  void answer() {}

  @override
  void setMicMuted(bool muted) {}

  @override
  void hangup() {}

  @override
  Future<bool> unlockViaInfo() async => false;

  @override
  void dispose() => _problem.dispose();
}
