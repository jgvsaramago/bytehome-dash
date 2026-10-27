import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// The app's texts in the current language: `l10n.save`, `l10n.mealFor(name)`.
///
/// A getter rather than `AppLocalizations.of(context)`, like `KColors`: data
/// and service code without a BuildContext needs the texts too, and a
/// language change rebuilds the whole app (see [LocaleController]).
AppLocalizations get l10n => LocaleController.instance.strings;

/// Which language the app shows.
///
/// By default the one Home Assistant is set to (its `get_config` language),
/// when the app has it; otherwise English. Definições › Ecrã e som can fix
/// one instead (`app_language`: `auto`, or a language code), kept on this
/// screen.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final instance = LocaleController._();

  static const _prefsKey = 'app_language';

  /// `auto` follows Home Assistant; otherwise a language code.
  String _choice = 'auto';
  String? _haLanguage;
  Locale _locale = const Locale('en');
  AppLocalizations _strings = lookupAppLocalizations(const Locale('en'));

  String get choice => _choice;
  Locale get locale => _locale;
  AppLocalizations get strings => _strings;

  /// The languages the app has translations for.
  static List<Locale> get supported => AppLocalizations.supportedLocales;

  /// Reads the saved choice and the date formats. Once, before runApp.
  Future<void> load() async {
    for (final l in supported) {
      await initializeDateFormatting(l.languageCode);
    }
    try {
      _choice = (await SharedPreferences.getInstance()).getString(_prefsKey) ?? 'auto';
    } catch (_) {}
    _apply();
  }

  /// Home Assistant's language ("pt", "pt-BR", "en-GB"…), once connected.
  void setHaLanguage(String? language) {
    if (language == null || language == _haLanguage) return;
    _haLanguage = language;
    _apply();
  }

  Future<void> choose(String choice) async {
    _choice = choice;
    _apply();
    try {
      await (await SharedPreferences.getInstance()).setString(_prefsKey, choice);
    } catch (_) {}
  }

  void _apply() {
    final wanted = _choice == 'auto' ? (_haLanguage ?? 'en') : _choice;
    final code = wanted.split(RegExp('[-_]')).first.toLowerCase();
    final next = supported.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('en'));
    if (next == _locale && _strings.localeName == next.languageCode) return;
    _locale = next;
    _strings = lookupAppLocalizations(next);
    Intl.defaultLocale = next.languageCode;
    debugPrint('[l10n] ${next.languageCode} (choice $_choice, Home Assistant ${_haLanguage ?? '-'})');
    notifyListeners();
    _rebuildAll();
  }

  /// Every element rebuilt in place, `const` ones included — the same way
  /// the theme switch does it (texts, like colours, are read on build).
  static void _rebuildAll() {
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(mark);
  }
}
