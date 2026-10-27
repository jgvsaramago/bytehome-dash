#!/usr/bin/env python3
"""Checks that every language has the same texts as English, with the same
placeholders, in the three places ByteHomeDash keeps translations:

- the app: lib/l10n/app_<lang>.arb (English, app_en.arb, is the template);
- the integration's panel: custom_components/bytehomedash/frontend/i18n/<lang>.json;
- the integration's texts for screens and phones: custom_components/bytehomedash/i18n/<lang>.json.

Missing texts are reported but allowed (they fall back to English); extra
keys or placeholders that differ from English are errors. Exit code 1 on
errors.

    python3 tool/check_translations.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
# "{name}" or "{count, plural, …}" — not the text inside plural arms.
PLACEHOLDER = re.compile(r"\{(\w+)\s*[,}]")


def flat(node: object, prefix: str = "") -> dict[str, str]:
    if isinstance(node, dict):
        out: dict[str, str] = {}
        for k, v in node.items():
            out.update(flat(v, f"{prefix}{k}."))
        return out
    return {prefix.rstrip("."): node} if isinstance(node, str) else {}


def placeholders(text: str, arb: bool) -> set[str]:
    names = set(PLACEHOLDER.findall(text))
    if arb:
        # ICU: plural/select arms and keywords aren't placeholders.
        names -= {"plural", "select", "other", "one", "zero", "two", "few", "many"}
    return names


def check(name: str, files: dict[str, dict[str, str]], arb: bool) -> int:
    errors = 0
    english = files.pop("en", None)
    if english is None:
        print(f"{name}: no English file")
        return 1
    for lang, texts in sorted(files.items()):
        missing = sorted(set(english) - set(texts))
        extra = sorted(set(texts) - set(english))
        wrong = sorted(k for k in english.keys() & texts.keys() if placeholders(english[k], arb) != placeholders(texts[k], arb))
        status = "ok" if not (missing or extra or wrong) else ""
        print(f"{name} [{lang}]: {len(texts)}/{len(english)} texts {status}")
        for k in missing:
            print(f"  missing (shows English): {k}")
        for k in extra:
            print(f"  ERROR not in English: {k}")
        for k in wrong:
            print(f"  ERROR placeholders differ from English: {k}")
        errors += len(extra) + len(wrong)
    return errors


def main() -> int:
    errors = 0
    arbs = {}
    for f in sorted((ROOT / "lib/l10n").glob("app_*.arb")):
        data = json.loads(f.read_text(encoding="utf-8"))
        arbs[f.stem.removeprefix("app_")] = {k: v for k, v in data.items() if not k.startswith("@") and isinstance(v, str)}
    errors += check("app", arbs, arb=True)
    for name, folder in (("panel", "custom_components/bytehomedash/frontend/i18n"), ("integration", "custom_components/bytehomedash/i18n")):
        files = {f.stem: flat(json.loads(f.read_text(encoding="utf-8"))) for f in sorted((ROOT / folder).glob("*.json"))}
        errors += check(name, files, arb=False)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
