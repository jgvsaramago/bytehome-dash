# Contributing to ByteHomeDash

Thanks for helping. Issues and pull requests are welcome: bug reports, fixes, support for more hardware, new features and translations.

- **Before a bigger change**, open an issue to talk it through.
- **Keep personal data out:** names, addresses, IPs, tokens, real entity ids. Machine-specific values go in `/etc/bytehomedash.env` (see `device/bytehomedash.env.example`).
- **App code:** format with `dart format -l 160`. On the boards' release compiler, null-aware collection elements (`?x` in a list or map literal) crash. Use `if (x case final v?) v`.
- **Licence:** contributions are under the project's [GPL-3.0](LICENSE) licence.
- **More detail:** see the [wiki](https://github.com/jgvsaramago/bytehomedash/wiki), especially *Development*.

## Translations

English is the source language. Portuguese (pt-PT) is the other complete translation. A missing text shows in English, so a partial translation is fine.

Texts live in three places, all in formats that tools like [Weblate](https://weblate.org) and Crowdin read directly:

| What | Files | Format |
|---|---|---|
| The app on the screen | `lib/l10n/app_<lang>.arb` | ARB (Flutter gen-l10n), ICU messages |
| The integration's sidebar panel | `custom_components/bytehomedash/frontend/i18n/<lang>.json` | nested JSON, `{placeholder}` |
| The integration's texts for screens and phones | `custom_components/bytehomedash/i18n/<lang>.json` | nested JSON, `{placeholder}` |
| Home Assistant's setup dialog | `custom_components/bytehomedash/translations/<lang>.json` | Home Assistant's own format |

`<lang>` is the language code (`pt`, `es`, `de`…).

### Adding a language

1. **App:** copy `lib/l10n/app_en.arb` to `app_<lang>.arb`, set `"@@locale": "<lang>"`, translate the values and delete the `@…` metadata entries. They describe the English text and only need to be in the template.
2. **Integration:** copy `frontend/i18n/en.json`, `i18n/en.json` and `translations/en.json` to `<lang>.json` in the same folders, and translate the values.
3. Run `python3 tool/check_translations.py`. It lists missing texts and flags placeholders that differ from English. The same check runs on every pull request.
4. Open a pull request.

Building the app picks up the new language by itself (`flutter gen-l10n`). It then shows up in *Settings › Screen and sound › Language*.

### How the language is chosen

- **The app** follows Home Assistant's language by default. *Settings › Screen and sound › Language* fixes one instead; that choice is kept per screen.
- **The panel** follows the Home Assistant user's language.
- **Texts the integration sends** (rows under the assistant's answers, phone notifications) use Home Assistant's language.

### Writing a translation

- **Placeholders** such as `{name}` and `{count}` stay as they are. Move them anywhere in the sentence that fits the language.
- **Plurals in the app** use ICU: `{count, plural, =1{1 sample} other{{count} samples}}`. Add the plural categories your language needs (`one`, `few`, `many`…).
- **Plurals in the integration** use separate keys: `name_one` and `name_other`.
- **Weekday and month lists** (`datesWeekdaysTitle`, `day.weekdays`…) are comma-separated, Monday first, with no spaces.
- **Example voice commands** on screen ("Ok Nabu, next step") should be what a speaker of your language would say to the assistant.
- **Brand names** stay as they are: Home Assistant, Music Assistant, Nabu.

### Adding texts to the code

- **App:** add the English text to `app_en.arb`, with a `@key` entry for placeholders and context, and the Portuguese to `app_pt.arb`. Use it as `l10n.yourKey` (`import '…/l10n/l10n.dart'`). Never concatenate translated pieces into a sentence; use one message with placeholders.
- **Integration:** add the text to `i18n/en.json` and `i18n/pt.json` and use `tr(hass, "section.key", name=…)` (`i18n.py`). The panel uses `t("section.key", {…})`.
