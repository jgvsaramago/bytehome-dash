"""ByteHomeDash integration.

Centralizes the kiosk app's settings in Home Assistant's own storage, so
every screen running the app reads and writes the same ones instead of each
keeping its own local copy. Two kinds live here: the entity mappings edited
in the "ByteHomeDash" sidebar panel (family, calendars, weather, rooms,
the Casa page, energy, EV cars, to-do lists), and the household data the screens edit
themselves (`meal_plan`, `chores`, `todo_list_icons`).

The Flutter app never looks for entities on its own: every entity it uses
is one of these settings. Settings nobody has chosen yet are filled with a
best guess when Home Assistant starts (suggest.py), and can be changed in
the panel.

Settings are stored as opaque JSON keyed by a domain-chosen string (e.g.
"rooms"). This integration doesn't know or care about the shape of any
individual setting - it's just a shared key/value store with two websocket
commands, `bytehomedash/get_settings` and
`bytehomedash/set_settings`.

Screens announce themselves (`bytehomedash/register_screen`) for as
long as their websocket stays open, so the sidebar panel can say whether a
screen is connected (`bytehomedash/list_screens`); they also
subscribe to saved changes (`bytehomedash/subscribe_settings`) and
apply them live.

Registers the "ByteHomeDash" LLM API (llm_api.py): tools a conversation
agent uses to show web pages as cards on the screen it's talking to, sent
over `bytehomedash/subscribe_assistant`, and who is speaking (speakers.py,
reported by the voice satellite) with that person's calendar and to-do
list, for that turn only. Screens can send a card to a person's phone
(phones.py, `bytehomedash/phones` and `bytehomedash/send_to_phone`).

Also proxies calendar event lookups (`bytehomedash/get_calendar_events`)
over this same authenticated websocket connection, so the app's web build
never has to hit HA's REST `/api/calendars/<entity_id>` endpoint directly —
that endpoint is subject to browser CORS restrictions the websocket isn't.
"""
from __future__ import annotations

import copy
from typing import Any

import voluptuous as vol

from homeassistant.components import websocket_api
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import EVENT_HOMEASSISTANT_STARTED
from homeassistant.core import CoreState, Event, HomeAssistant, callback
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers import config_validation as cv, llm
from homeassistant.helpers.storage import Store
from homeassistant.helpers.typing import ConfigType
from homeassistant.util import dt as dt_util

from .const import (
    DOMAIN,
    EVENT_ASSISTANT,
    EVENT_SETTINGS_UPDATED,
    LEGACY_STORAGE_KEY,
    OBSOLETE_KEYS,
    STORAGE_KEY,
    STORAGE_VERSION,
)
from .household_tools import websocket_leave_message
from .llm_api import ByteHomeDashAPI, websocket_confirm_meals, websocket_get_recipe, websocket_undo
from .speakers import async_setup_speakers
from .panel import async_register_panel, async_remove_panel
from .phones import websocket_phones, websocket_send_to_phone
from .suggest import AUTO_KEY, suggest

CONFIG_SCHEMA = cv.empty_config_schema(DOMAIN)

# Any JSON-serializable value: the individual settings stores on the Dart
# side each choose their own shape (list, dict, scalar) and this integration
# just stores whatever it's given.
_SETTINGS_VALUE = vol.Any(dict, list, str, int, float, bool, None)


async def async_setup(hass: HomeAssistant, config: ConfigType) -> bool:
    """Register the websocket commands once, regardless of config entries."""
    hass.data.setdefault(DOMAIN, {})
    websocket_api.async_register_command(hass, websocket_get_settings)
    websocket_api.async_register_command(hass, websocket_set_settings)
    websocket_api.async_register_command(hass, websocket_get_calendar_events)
    websocket_api.async_register_command(hass, websocket_register_screen)
    websocket_api.async_register_command(hass, websocket_list_screens)
    websocket_api.async_register_command(hass, websocket_subscribe_settings)
    websocket_api.async_register_command(hass, websocket_fill_suggestions)
    websocket_api.async_register_command(hass, websocket_auto_paths)
    websocket_api.async_register_command(hass, websocket_reset_auto)
    websocket_api.async_register_command(hass, websocket_subscribe_assistant)
    websocket_api.async_register_command(hass, websocket_phones)
    websocket_api.async_register_command(hass, websocket_send_to_phone)
    websocket_api.async_register_command(hass, websocket_undo)
    websocket_api.async_register_command(hass, websocket_confirm_meals)
    websocket_api.async_register_command(hass, websocket_get_recipe)
    websocket_api.async_register_command(hass, websocket_leave_message)
    llm.async_register_api(hass, ByteHomeDashAPI(hass))
    async_setup_speakers(hass)
    return True


async def _async_fill_suggestions(hass: HomeAssistant) -> None:
    """Apply the integration's own entity choices (see suggest.py)."""
    domain_data = hass.data.get(DOMAIN, {})
    store: Store | None = domain_data.get("store")
    data = domain_data.get("data")
    if store is None or data is None:
        return
    changes = suggest(hass, data)
    if not changes:
        return
    data.update(changes)
    await store.async_save(data)
    for key in changes:
        hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": key})


def _value_at(value: Any, path: str) -> Any:
    """The part of a setting an `auto_choices` path names."""
    if path == "":
        return value
    if "/" in path:  # rooms: "<area id>/<field>"
        area_id, field = path.split("/", 1)
        for row in value if isinstance(value, list) else []:
            if isinstance(row, dict) and row.get("areaId") == area_id:
                return row.get(field)
        return None
    return value.get(path) if isinstance(value, dict) else None


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    store = Store(hass, STORAGE_VERSION, STORAGE_KEY)
    hass.data[DOMAIN]["store"] = store
    data = await store.async_load()
    if data is None:
        legacy = Store(hass, STORAGE_VERSION, LEGACY_STORAGE_KEY)
        data = await legacy.async_load() or {}
        if data:
            await store.async_save(data)
            await legacy.async_remove()
    if any(key in data for key in OBSOLETE_KEYS):
        for key in OBSOLETE_KEYS:
            data.pop(key, None)
        await store.async_save(data)
    hass.data[DOMAIN]["data"] = data

    await async_register_panel(hass)

    # Fill settings nobody has chosen yet with the integration's own
    # choices (see suggest.py) — once every entity is loaded, so it can see
    # them all. The panel asks again whenever it opens.
    async def _fill(_event: Event | None = None) -> None:
        await _async_fill_suggestions(hass)

    if hass.state is CoreState.running:
        await _fill()
    else:
        entry.async_on_unload(hass.bus.async_listen_once(EVENT_HOMEASSISTANT_STARTED, _fill))

    return True


async def async_unload_entry(hass: HomeAssistant, entry: ConfigEntry) -> bool:
    async_remove_panel(hass)

    hass.data[DOMAIN].pop("store", None)
    hass.data[DOMAIN].pop("data", None)
    return True


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/get_settings",
        vol.Optional("key"): cv.string,
    }
)
@websocket_api.async_response
async def websocket_get_settings(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Return the stored settings, or a single key if `key` is given."""
    data = hass.data.get(DOMAIN, {}).get("data")
    if data is None:
        connection.send_error(msg["id"], "not_setup", "Integration is not set up")
        return

    key = msg.get("key")
    connection.send_result(msg["id"], {"value": data.get(key) if key is not None else data})


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/set_settings",
        vol.Required("key"): cv.string,
        vol.Required("value"): _SETTINGS_VALUE,
    }
)
@websocket_api.async_response
async def websocket_set_settings(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Persist one settings key and notify listeners it changed."""
    domain_data = hass.data.get(DOMAIN, {})
    store: Store | None = domain_data.get("store")
    if store is None:
        connection.send_error(msg["id"], "not_setup", "Integration is not set up")
        return

    data = domain_data["data"]
    key = msg["key"]
    # A choice the integration made and the user has now changed becomes
    # the user's: it loses its "Automático" mark and is never re-guessed.
    marks = (data.get(AUTO_KEY) or {}).get(key) or {}
    kept = {path: True for path in marks if _value_at(data.get(key), path) == _value_at(msg["value"], path)}
    data[key] = msg["value"]
    if kept != marks:
        data[AUTO_KEY] = {**(data.get(AUTO_KEY) or {}), key: kept}
    await store.async_save(data)

    hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": key})
    # Settings that others derive from (a robot's entities) follow at once.
    await _async_fill_suggestions(hass)

    connection.send_result(msg["id"], {"auto": kept})


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/fill_suggestions"})
@websocket_api.async_response
async def websocket_fill_suggestions(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Re-run the integration's own choices (new areas, devices, lists)."""
    await _async_fill_suggestions(hass)
    connection.send_result(msg["id"])


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/auto_paths"})
@callback
def websocket_auto_paths(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """What the integration can choose on its own, as `auto_choices` paths
    per settings key — so the panel can offer "Repor automático" there."""
    connection.send_result(msg["id"], {"auto": suggest(hass, {}).get(AUTO_KEY, {})})


def _without(value: Any, path: str) -> Any:
    """`value` with the part an `auto_choices` path names removed."""
    if "/" in path:  # rooms: "<area id>/<field>"
        if not isinstance(value, list):
            return value
        area_id, field = path.split("/", 1)
        return [
            {k: v for k, v in row.items() if k != field} if isinstance(row, dict) and row.get("areaId") == area_id else row
            for row in value
        ]
    return {k: v for k, v in value.items() if k != path} if isinstance(value, dict) else value


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/reset_auto",
        vol.Required("key"): cv.string,
        vol.Required("path"): str,
    }
)
@websocket_api.async_response
async def websocket_reset_auto(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Give a choice the user took over back to the integration: forget the
    user's value (a whole list for path "") and guess it again."""
    domain_data = hass.data.get(DOMAIN, {})
    store: Store | None = domain_data.get("store")
    data = domain_data.get("data")
    if store is None or data is None:
        connection.send_error(msg["id"], "not_setup", "Integration is not set up")
        return

    key, path = msg["key"], msg["path"]
    trial = copy.deepcopy(data)
    if path == "":
        trial.pop(key, None)
    elif key in trial:
        trial[key] = _without(trial[key], path)
    trial.update(suggest(hass, trial))
    if not ((trial.get(AUTO_KEY) or {}).get(key) or {}).get(path):
        connection.send_error(msg["id"], "not_automatic", "The integration doesn't choose this")
        return

    changed = [k for k in trial if trial[k] != data.get(k)]
    data.clear()
    data.update(trial)
    await store.async_save(data)
    for k in changed:
        hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": k})

    connection.send_result(msg["id"], {"value": data.get(key), "auto": data[AUTO_KEY].get(key, {})})


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/register_screen",
        vol.Required("name"): cv.string,
    }
)
@callback
def websocket_register_screen(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Track a screen for as long as this connection stays open.

    Registered like a subscription, so HA calls the cleanup itself when the
    connection closes — a screen that loses power or network drops off the
    list without having to say goodbye.
    """
    screens: dict[int, dict] = hass.data[DOMAIN].setdefault("screens", {})
    key = id(connection)
    screens[key] = {"name": msg["name"], "since": dt_util.utcnow().isoformat()}

    @callback
    def _gone() -> None:
        screens.pop(key, None)

    connection.subscriptions[msg["id"]] = _gone
    connection.send_result(msg["id"])


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/subscribe_settings"})
@callback
def websocket_subscribe_settings(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Send `{"key": ...}` on this subscription whenever a setting is saved.

    Its own command rather than `subscribe_events`, which only lets admin
    users subscribe to a custom event type — a screen's token needn't be one.
    """

    @callback
    def _forward(event: Event) -> None:
        connection.send_message(websocket_api.event_message(msg["id"], {"key": event.data.get("key")}))

    connection.subscriptions[msg["id"]] = hass.bus.async_listen(EVENT_SETTINGS_UPDATED, _forward)
    connection.send_result(msg["id"])


def _same_screen(a: str, b: str) -> bool:
    """Screen and satellite names compared loosely ("dashboard-kitchen" is
    the satellite "Dashboard Kitchen")."""
    norm = lambda s: "".join(ch for ch in s.lower() if ch.isalnum())  # noqa: E731
    return norm(a) == norm(b)


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/subscribe_assistant",
        vol.Required("name"): cv.string,
    }
)
@callback
def websocket_subscribe_assistant(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Forward the conversation agent's cards / open requests (llm_api.py)
    meant for this screen: from its own voice satellite, or a typed request
    (no device), which a screen only shows while its Assistente is open."""

    @callback
    def _forward(event: Event) -> None:
        screen = event.data.get("screen")
        if screen is None or _same_screen(screen, msg["name"]):
            connection.send_message(websocket_api.event_message(msg["id"], dict(event.data)))

    connection.subscriptions[msg["id"]] = hass.bus.async_listen(EVENT_ASSISTANT, _forward)
    connection.send_result(msg["id"])


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/list_screens"})
@callback
def websocket_list_screens(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """The screens connected right now."""
    screens = hass.data.get(DOMAIN, {}).get("screens", {})
    connection.send_result(msg["id"], {"screens": list(screens.values())})


def _wrap_event_datetime(value: str) -> dict[str, str]:
    """Match the REST `/api/calendars/<entity_id>` endpoint's nested
    `{"date": ...}` / `{"dateTime": ...}` shape (see `_api_event_dict_factory`
    in Home Assistant core's `calendar` component) from the flat ISO string
    the `calendar.get_events` service returns, so the Dart side's
    `HaCalendarEvent.fromJson` only ever has to understand one shape. An
    all-day event's value has no time component, so it round-trips as a
    bare date string (e.g. "2026-08-15") with no "T"; a timed event's always
    has one.
    """
    return {"date": value} if "T" not in value else {"dateTime": value}


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/get_calendar_events",
        vol.Required("entity_id"): cv.entity_id,
        vol.Required("start"): cv.string,
        vol.Required("end"): cv.string,
    }
)
@websocket_api.async_response
async def websocket_get_calendar_events(
    hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict
) -> None:
    """Return one calendar's events between `start` and `end`.

    Sourced via the `calendar.get_events` service — the same one behind the
    "Calendar: Get events" action — over this integration's own
    authenticated websocket connection, rather than the REST
    `/api/calendars/<entity_id>` endpoint. The web build can't reach that
    REST endpoint cross-origin unless the household has explicitly opened
    up HA's CORS settings for it, which broke every calendar's events as
    soon as one was configured; the websocket connection this command rides
    on is already established and authenticated by the time the app can
    even ask for a calendar's events, so it isn't subject to that at all.
    """
    start_date = dt_util.parse_datetime(msg["start"])
    end_date = dt_util.parse_datetime(msg["end"])
    if start_date is None or end_date is None:
        connection.send_error(msg["id"], "invalid_format", "start/end must be ISO 8601 datetimes")
        return

    try:
        response = await hass.services.async_call(
            "calendar",
            "get_events",
            {
                "entity_id": msg["entity_id"],
                "start_date_time": dt_util.as_local(start_date),
                "end_date_time": dt_util.as_local(end_date),
            },
            blocking=True,
            return_response=True,
        )
    except HomeAssistantError as err:
        connection.send_error(msg["id"], "read_failed", str(err))
        return

    raw_events = (response or {}).get(msg["entity_id"], {}).get("events", [])
    connection.send_result(
        msg["id"],
        {
            "events": [
                {
                    "start": _wrap_event_datetime(event["start"]),
                    "end": _wrap_event_datetime(event["end"]),
                    "summary": event.get("summary", ""),
                }
                for event in raw_events
            ]
        },
    )
