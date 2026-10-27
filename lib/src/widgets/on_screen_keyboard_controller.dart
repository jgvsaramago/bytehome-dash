import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Per-field extras for the on-screen keyboard: a suggestion row computed
/// from what's typed so far, and what the accent "done" key says and does.
/// Fields that pass none (every settings screen) get the plain keyboard:
/// no suggestions, a "Concluído" key that just closes it.
class KeyboardOptions {
  const KeyboardOptions({this.suggestions, String? doneLabel, this.onDone, this.onSuggest, this.capitalize = true}) : _doneLabel = doneLabel;

  /// Given the field's current text, the chips to offer above the keys.
  final List<String> Function(String text)? suggestions;
  final String? _doneLabel;
  String get doneLabel => _doneLabel ?? l10n.commonDone;

  /// Runs instead of closing the keyboard — e.g. moving focus to the next
  /// field of a form. Null closes the keyboard.
  final VoidCallback? onDone;

  /// What tapping a suggestion does. Null replaces the field's text with it.
  final ValueChanged<String>? onSuggest;

  /// Auto-shift at the start of the field and after sentence punctuation.
  final bool capitalize;
}

/// App-wide handle for which `TextEditingController` should currently be
/// receiving on-screen-keyboard input. flutter-pi (this app's real target)
/// has no native IME — focusing a text field there shows nothing at all,
/// unlike Android/iOS/desktop/web, which all pop a real keyboard on their
/// own. Any text-entry widget attaches itself here on focus and detaches on
/// blur; `OnScreenKeyboardHost` (mounted once at the app root) reacts to
/// that to show/hide the keyboard panel and know where typed keys go.
class OnScreenKeyboardController {
  OnScreenKeyboardController._();

  static final instance = OnScreenKeyboardController._();

  final ValueNotifier<TextEditingController?> active = ValueNotifier(null);

  /// The design's "Flutuar": a smaller panel dragged anywhere on screen,
  /// which leaves what's behind it where it is instead of pushing it up.
  final ValueNotifier<bool> floating = ValueNotifier(false);

  /// Where the floating panel sits: its left and bottom edges, in design px.
  Offset floatAt = const Offset(390, 150);

  static const _prefsKey = 'keyboard_float';

  /// Floating or not, and where, carry over to the next time it opens —
  /// across restarts too.
  Future<void> loadPrefs() async {
    final raw = (await SharedPreferences.getInstance()).getStringList(_prefsKey);
    if (raw == null || raw.length != 3) return;
    floatAt = Offset(double.tryParse(raw[1]) ?? floatAt.dx, double.tryParse(raw[2]) ?? floatAt.dy);
    floating.value = raw[0] == '1';
  }

  Future<void> savePrefs() async {
    (await SharedPreferences.getInstance()).setStringList(_prefsKey, [floating.value ? '1' : '0', '${floatAt.dx}', '${floatAt.dy}']);
  }

  void setFloating(bool on) {
    floating.value = on;
    savePrefs();
  }

  /// Options for whichever field is [active]. Set together with it.
  KeyboardOptions options = const KeyboardOptions();

  void attach(TextEditingController controller, {KeyboardOptions options = const KeyboardOptions()}) {
    this.options = options;
    active.value = controller;
  }

  /// No-ops if [controller] isn't the currently-attached one — guards
  /// against a stale blur from a field that's already lost the "race" to a
  /// newly-focused one.
  void detach(TextEditingController controller) {
    if (active.value == controller) active.value = null;
  }

  /// Closes the keyboard and drops focus from whichever field had it, so
  /// the field's own focus listener and this stay in step.
  void close() {
    active.value = null;
    FocusManager.instance.primaryFocus?.unfocus();
  }
}
