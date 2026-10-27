"""Texts the integration writes for people — the screens' result rows,
phone notifications, errors shown on a screen — in Home Assistant's
language (`hass.config.language`), English when there's no translation.

The texts are in `i18n/<language>.json` (nested, `{placeholder}`), English
being the source: see CONTRIBUTING.md, "Translations". The panel's own texts
are in `frontend/i18n/`.
"""
from __future__ import annotations

from functools import cache
import json
from pathlib import Path
from typing import Any

from homeassistant.core import HomeAssistant

_DIR = Path(__file__).parent / "i18n"


@cache
def _load(language: str) -> dict[str, Any]:
    try:
        return json.loads((_DIR / f"{language}.json").read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {}


def _lookup(texts: dict[str, Any], key: str) -> str | None:
    node: Any = texts
    for part in key.split("."):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node if isinstance(node, str) else None


def language(hass: HomeAssistant) -> str:
    return (hass.config.language or "en").split("-")[0].lower()


def tr(hass: HomeAssistant, key: str, count: int | None = None, **params: Any) -> str:
    """The text for `key` ("calls.door"); with `count`, `key_one` when it's 1
    and `key_other` otherwise, and `{count}` filled in."""
    if count is not None:
        key = f"{key}_{'one' if count == 1 else 'other'}"
        params.setdefault("count", count)
    text = _lookup(_load(language(hass)), key) or _lookup(_load("en"), key) or key
    try:
        return text.format(**params)
    except (KeyError, IndexError, ValueError):
        return text


def tr_list(hass: HomeAssistant, key: str) -> list[str]:
    """A comma-separated text as a list ("day.weekdays")."""
    return tr(hass, key).split(",")
