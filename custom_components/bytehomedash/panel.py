"""Registers the settings-editor sidebar panel.

Serves `frontend/bytehomedash-panel.js` as a static asset and registers
it as a `panel_custom` panel. The panel is just another client of the
`get_settings`/`set_settings` websocket commands defined in `__init__.py` -
it needs no backend support of its own beyond being served to the browser.
"""
from __future__ import annotations

import hashlib
from pathlib import Path

from homeassistant.components import frontend, panel_custom
from homeassistant.components.http import StaticPathConfig
from homeassistant.core import HomeAssistant

from .const import DOMAIN

FRONTEND_SCRIPT_URL = f"/{DOMAIN}_panel/bytehomedash-panel.js"
_FRONTEND_DIR = Path(__file__).parent / "frontend"


async def async_register_panel(hass: HomeAssistant) -> None:
    await hass.http.async_register_static_paths(
        [StaticPathConfig(f"/{DOMAIN}_panel", str(_FRONTEND_DIR), cache_headers=False)]
    )

    await panel_custom.async_register_panel(
        hass,
        webcomponent_name="bytehomedash-panel",
        frontend_url_path=DOMAIN,
        # The file's own fingerprint in the URL: the browser caches the
        # module by URL, so after an update it kept running the old panel.
        module_url=f"{FRONTEND_SCRIPT_URL}?v={await hass.async_add_executor_job(_fingerprint)}",
        sidebar_title="ByteHomeDash",
        sidebar_icon="mdi:tablet-dashboard",
        require_admin=True,
        config={},
    )


def _fingerprint() -> str:
    """The panel and its translations: the panel fetches them with the same
    `?v=`, so a changed translation is fetched again too."""
    digest = hashlib.sha1((_FRONTEND_DIR / "bytehomedash-panel.js").read_bytes())
    for f in sorted((_FRONTEND_DIR / "i18n").glob("*.json")):
        digest.update(f.read_bytes())
    return digest.hexdigest()[:10]


def async_remove_panel(hass: HomeAssistant) -> None:
    frontend.async_remove_panel(hass, DOMAIN)
