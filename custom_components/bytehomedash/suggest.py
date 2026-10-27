"""The integration's own entity choices, for settings nobody has made.

The kiosk app never looks for entities itself: everything it reads is a
setting stored here. So that a fresh install — or a new setting, area or
device — works without first visiting the sidebar panel, the integration
picks entities on its own:

* a field that has never been set is filled with the best guess;
* a field it filled before is marked in `auto_choices`, so the panel can
  show it as "Automático", and is guessed again when it is empty or its
  entity is gone (a new device in an area, a replaced sensor); a whole
  list it chose (people, to-do lists, locks) follows HA as it changes;
* a field the user set in the panel (the panel drops its mark on save) is
  never touched again, even if it was saved empty.

`auto_choices` is `{store key: {path: True}}`; a path is a field name in a
dict setting, "<area id>/<field>" in `rooms`, and "" for a whole list.
"""
from __future__ import annotations

import copy
import re
from typing import Any

from homeassistant.core import HomeAssistant, State
from homeassistant.helpers import area_registry as ar
from homeassistant.helpers import device_registry as dr
from homeassistant.helpers import entity_registry as er

AUTO_KEY = "auto_choices"

_TARIFF = re.compile(r"^(vazio|cheias|ponta|super ?vazio)$", re.IGNORECASE)
_WATER = re.compile(r"aqs|água quente|agua quente|water heater|boiler", re.IGNORECASE)

# The kiosk's person palette (KPersonColor keys), in the order the panel
# hands them out.
_COLORS = ("blue", "amber", "green", "accent", "pink")

# Roles of the exterior weather station's sensors, as the Exterior card on
# the screen's Casa page shows them (StationRole on the app side).
STATION_ROLES = (
    "feels", "dewPoint", "humidity", "wind", "gust", "gustMax", "windDir",
    "rain", "rainRate", "pressure", "uv", "irradiance",
)

# What a room (an HA area) maps, as the panel's Divisões edits it.
ROOM_FIELDS = (
    "lightEntityId", "climateEntityId", "windowEntityId", "coverEntityId",
)


def _available(state: State | None) -> bool:
    return state is not None and state.state not in ("unavailable", "unknown")


def _ids(hass: HomeAssistant, domain: str) -> list[str]:
    return sorted(s.entity_id for s in hass.states.async_all(domain) if _available(s))


def _name(state: State) -> str:
    return str(state.attributes.get("friendly_name") or state.entity_id)


class _Choices:
    """Applies guesses to a copy of the settings, keeping `auto_choices` in
    step, and records which settings keys changed."""

    def __init__(self, hass: HomeAssistant, data: dict) -> None:
        self.hass = hass
        self.data = data
        self.auto: dict[str, dict[str, bool]] = copy.deepcopy(data.get(AUTO_KEY) or {})
        self.changed: dict[str, Any] = {}

    def _is_auto(self, store: str, path: str) -> bool:
        return bool(self.auto.get(store, {}).get(path))

    def _mark(self, store: str, path: str) -> None:
        if not self._is_auto(store, path):
            self.auto.setdefault(store, {})[path] = True
            self.changed[AUTO_KEY] = self.auto

    def _keeps(self, store: str, path: str, value: Any) -> bool:
        """An earlier automatic choice stays while its entity exists, so a
        new device doesn't swap it; only an empty or vanished one is
        guessed again."""
        return self._is_auto(store, path) and isinstance(value, str) and self.hass.states.get(value) is not None

    def current(self, store: str) -> Any:
        return self.changed.get(store, self.data.get(store))

    def field(self, store: str, key: str, guess) -> None:
        """One field of a dict setting. `guess` is called only when needed."""
        value = self.current(store)
        value = dict(value) if isinstance(value, dict) else {}
        if key in value and (not self._is_auto(store, key) or self._keeps(store, key, value[key])):
            return
        new = guess()
        self._mark(store, key)
        if key not in value or value[key] != new:
            value[key] = new
            self.changed[store] = value

    def whole(self, store: str, guess) -> None:
        """A list setting, chosen as a whole."""
        if store in self.data and not self._is_auto(store, ""):
            return
        new = guess()
        self._mark(store, "")
        if self.current(store) != new:
            self.changed[store] = new

    def rooms(self, guesses: dict[str, dict[str, str | None]]) -> None:
        """`rooms`: one row per area, each field on its own."""
        rows = [dict(r) for r in (self.current("rooms") or []) if isinstance(r, dict)]
        by_area = {r.get("areaId"): r for r in rows if r.get("areaId")}
        dirty = False
        for area_id, fields in guesses.items():
            row = by_area.get(area_id)
            if row is None:
                row = {"areaId": area_id}
                rows.append(row)
                by_area[area_id] = row
                dirty = True
            for key, new in fields.items():
                path = f"{area_id}/{key}"
                if key in row and (not self._is_auto("rooms", path) or self._keeps("rooms", path, row[key])):
                    continue
                self._mark("rooms", path)
                if key not in row or row[key] != new:
                    row[key] = new
                    dirty = True
        if dirty:
            self.changed["rooms"] = rows


# ---------- Guesses ----------

def _station_role(state: State) -> str | None:
    """What a sensor on the station's device measures, by class and name
    (Ecowitt, Netatmo and the like put every reading on one device)."""
    if state.domain != "sensor":
        return None
    dc = state.attributes.get("device_class")
    unit = state.attributes.get("unit_of_measurement")
    n = f"{state.entity_id} {_name(state)}".lower()

    def has(pattern: str) -> bool:
        return re.search(pattern, n) is not None

    if dc == "temperature":
        if has("feel|sensa|apparent"):
            return "feels"
        if has("dew|orvalho"):
            return "dewPoint"
        return None
    if dc == "humidity":
        return None if has("indoor|interior|inside") else "humidity"
    if dc == "wind_speed" or (has("wind|vento") and unit == "km/h"):
        if has("max|máx"):
            return "gustMax"
        if has("gust|rajada"):
            return "gust"
        return "wind"
    if dc == "wind_direction" or (has("wind|vento") and has("direc")):
        return None if has("avg|média|media") else "windDir"
    if dc == "precipitation_intensity" or has("rain_rate|rain rate"):
        return "rainRate"
    if dc == "precipitation" and has("daily|diári|diari|today|hoje"):
        return "rain"
    if dc == "atmospheric_pressure" or (dc == "pressure" and unit == "hPa"):
        return None if has("absolute|absoluta") else "pressure"
    if has(r"\buv|uv_index|uv index|índice uv"):
        return "uv"
    if dc == "irradiance" or has("radia|irradi"):
        return "irradiance"
    return None


def _weather_entity(hass: HomeAssistant, reg: er.EntityRegistry) -> str | None:
    weathers = _ids(hass, "weather")
    # IPMA is the Portuguese met office: prefer it when there is one.
    ipma = [w for w in weathers if (e := reg.async_get(w)) and e.platform == "ipma"]
    return (ipma or weathers or [None])[0]


def _exterior_temp(hass: HomeAssistant) -> str | None:
    outdoor = sorted(
        s.entity_id
        for s in hass.states.async_all("sensor")
        if _available(s)
        and s.attributes.get("device_class") == "temperature"
        and re.search(r"outdoor|outside|exterior", f"{s.entity_id} {_name(s)}".lower())
    )
    return outdoor[0] if outdoor else None


def _ipma(reg: er.EntityRegistry, weather_id: str | None, translation: str) -> str | None:
    entry = reg.async_get(weather_id) if weather_id else None
    found = [e for e in reg.entities.values() if e.platform == "ipma" and not e.disabled_by and e.translation_key == translation]
    # The IPMA location that shares the weather entity's config entry.
    found.sort(key=lambda e: (entry is None or e.config_entry_id != entry.config_entry_id, e.entity_id))
    return found[0].entity_id if found else None


def _station(hass: HomeAssistant, reg: er.EntityRegistry, exterior_id: str | None) -> dict[str, str | None]:
    """The station's other sensors: the device of the exterior temperature."""
    out: dict[str, str | None] = {role: None for role in STATION_ROLES}
    entry = reg.async_get(exterior_id) if exterior_id else None
    if entry is None or entry.device_id is None:
        return out
    for e in sorted(er.async_entries_for_device(reg, entry.device_id), key=lambda e: e.entity_id):
        if e.entity_id == exterior_id:
            continue
        state = hass.states.get(e.entity_id)
        role = _station_role(state) if state else None
        if role and out[role] is None:
            out[role] = e.entity_id
    return out


def _water_heater(hass: HomeAssistant) -> str | None:
    heaters = _ids(hass, "water_heater")
    if heaters:
        return heaters[0]
    for s in sorted(hass.states.async_all("climate"), key=lambda s: s.entity_id):
        if _available(s) and _WATER.search(_name(s)):
            return s.entity_id
    return None


def _tariff(hass: HomeAssistant) -> str | None:
    for s in sorted(hass.states.async_all(("sensor", "select")), key=lambda s: s.entity_id):
        if "tarif" in s.entity_id and _TARIFF.match(s.state):
            return s.entity_id
    return None


def _locks(hass: HomeAssistant) -> list[dict[str, str]]:
    """Every lock, plus garage doors and gates (covers)."""
    ids = _ids(hass, "lock") + [
        s.entity_id
        for s in sorted(hass.states.async_all("cover"), key=lambda s: s.entity_id)
        if _available(s) and s.attributes.get("device_class") in ("garage", "gate")
    ]
    return [{"name": "", "entityId": i} for i in ids]


def _vacuums(hass: HomeAssistant) -> list[dict[str, str]]:
    """Every robot vacuum, with the area it lives in as "where"."""
    ent_reg = er.async_get(hass)
    dev_reg = dr.async_get(hass)
    area_reg = ar.async_get(hass)
    out = []
    for entity_id in _ids(hass, "vacuum"):
        entry = ent_reg.async_get(entity_id)
        area_id = entry.area_id if entry else None
        if area_id is None and entry and entry.device_id and (device := dev_reg.async_get(entry.device_id)):
            area_id = device.area_id
        area = area_reg.async_get_area(area_id) if area_id else None
        out.append({"name": "", "entityId": entity_id, "where": area.name if area else ""})
    return out


# What the screen's vacuum modal reads and drives on a robot's own device,
# by domain and key (a Dreame entity's translation key; any other
# integration's entity id ending in it).
VACUUM_ROLES: dict[str, tuple[str, ...]] = {
    "sensor": (
        "battery_level", "cleaned_area", "cleaning_time", "cleaning_progress", "cleaning_count", "current_room", "error",
        "self_wash_base_status", "auto_empty_status", "clean_water_tank_status", "dirty_water_tank_status",
        "dust_bag_status", "detergent_status", "low_water_warning", "drying_progress", "drying_left",
        "main_brush_left", "main_brush_time_left", "side_brush_left", "side_brush_time_left", "filter_left",
        "filter_time_left", "sensor_dirty_left", "sensor_dirty_time_left", "wheel_dirty_left", "wheel_dirty_time_left",
        "scale_inhibitor_left", "scale_inhibitor_time_left", "total_cleaned_area", "total_cleaning_time", "cleaning_history",
    ),
    "select": ("cleaning_mode", "suction_level", "mop_pad_humidity", "cleaning_route", "cleangenius"),
    "number": ("wetness_level", "volume"),
    "switch": ("dnd", "child_lock"),
    "time": ("dnd_start", "dnd_end"),
    "button": (
        "start_auto_empty", "self_clean", "manual_drying", "base_station_cleaning", "reset_main_brush",
        "reset_side_brush", "reset_filter", "reset_sensor", "reset_wheel", "reset_scale_inhibitor",
    ),
    "camera": ("map",),
}


def vacuum_entities(hass: HomeAssistant, vacuums: list[Any]) -> dict[str, dict[str, str]]:
    """For each configured robot, its device's entities by role
    ("select.suction_level" → entity id). Derived, never edited: per-room
    variants (Dreame's `room_<n>_…`) are left out."""
    reg = er.async_get(hass)
    out: dict[str, dict[str, str]] = {}
    for v in vacuums:
        entity_id = v.get("entityId") if isinstance(v, dict) else None
        entry = reg.async_get(entity_id) if entity_id else None
        if not entry or not entry.device_id:
            continue
        entries = [
            e for e in er.async_entries_for_device(reg, entry.device_id)
            if not e.disabled_by and "_room_" not in f"{e.unique_id} {e.entity_id}"
        ]
        found: dict[str, str] = {}
        # A translation key names the role exactly; an entity id's ending
        # is the fallback, for entities without one.
        for e in sorted(entries, key=lambda e: e.translation_key is None):
            keys = VACUUM_ROLES.get(e.domain, ())
            if e.translation_key is not None:
                key = e.translation_key if e.translation_key in keys else None
            else:
                key = next((k for k in keys if e.entity_id.endswith(f"_{k}")), None)
            if key:
                found.setdefault(f"{e.domain}.{key}", e.entity_id)
        out[entity_id] = found
    return out


def _areas(hass: HomeAssistant) -> dict[str, dict[str, str | None]]:
    """Each area's light, AC, window and blinds (its temperature and
    humidity are the area's own, set in HA)."""
    ent_reg = er.async_get(hass)
    dev_reg = dr.async_get(hass)
    area_reg = ar.async_get(hass)

    by_area: dict[str, list[State]] = {}
    for e in ent_reg.entities.values():
        if e.disabled_by or e.hidden_by or e.entity_category:
            continue
        area_id = e.area_id
        if area_id is None and e.device_id and (device := dev_reg.async_get(e.device_id)):
            area_id = device.area_id
        state = hass.states.get(e.entity_id)
        if area_id and state is not None:
            by_area.setdefault(area_id, []).append(state)

    def first(states: list[State]) -> str | None:
        ids = sorted(s.entity_id for s in states)
        return ids[0] if ids else None

    out: dict[str, dict[str, str | None]] = {}
    for area in area_reg.async_list_areas():
        states = by_area.get(area.id, [])

        def of(domain: str, *classes: str | None) -> list[State]:
            return [s for s in states if s.domain == domain and (not classes or s.attributes.get("device_class") in classes)]

        lights = of("light")
        # One toggle per room: a light group covering the room wins.
        groups = [s for s in lights if isinstance(s.attributes.get("entity_id"), list)]
        climates = [s for s in of("climate") if not _WATER.search(_name(s))]

        out[area.id] = {
            "lightEntityId": first(groups) or first(lights),
            "climateEntityId": first(climates),
            "windowEntityId": first(of("binary_sensor", "window")),
            "coverEntityId": first(of("cover", None, "blind", "shutter", "curtain", "shade", "awning")),
        }
    return out


_GREETING = re.compile(r"^(ok(ay)?|hey|hei|olá|ola|ei)[\s,]+", re.IGNORECASE)


def _wake_phrase(hass: HomeAssistant, reg: er.EntityRegistry) -> str:
    """The voice satellite's wake word ("Okay Nabu"), from its wake word
    select in HA (ESPHome / Linux Voice Assistant), else HA's default."""
    for e in sorted(reg.entities.values(), key=lambda e: e.entity_id):
        if e.domain != "select" or e.disabled_by:
            continue
        if e.translation_key != "wake_word" and "wake_word" not in e.entity_id:
            continue
        state = hass.states.get(e.entity_id)
        if _available(state):
            return state.state.replace("_", " ").strip().title()
    return "Ok Nabu"


def suggest(hass: HomeAssistant, data: dict) -> dict[str, Any]:
    """The settings keys to change, each with its whole new value."""
    reg = er.async_get(hass)
    c = _Choices(hass, data)

    weather = "temperature_entities"
    c.field(weather, "weatherStateEntityId", lambda: _weather_entity(hass, reg))
    c.field(weather, "exteriorTempEntityId", lambda: _exterior_temp(hass))
    c.field(weather, "sunEntityId", lambda: "sun.sun" if hass.states.get("sun.sun") else None)
    weather_id = (c.current(weather) or {}).get("weatherStateEntityId")
    c.field(weather, "warningEntityId", lambda: _ipma(reg, weather_id, "weather_alert"))
    c.field(weather, "fireRiskEntityId", lambda: _ipma(reg, weather_id, "fire_risk"))
    c.field(weather, "uvEntityId", lambda: _ipma(reg, weather_id, "uv_index"))

    station = _station(hass, reg, (c.current(weather) or {}).get("exteriorTempEntityId"))
    for role in STATION_ROLES:
        c.field("weather_station", role, lambda role=role: station[role])

    c.rooms(_areas(hass))

    c.field("house_screen", "alarmEntityId", lambda: (_ids(hass, "alarm_control_panel") or [None])[0])
    c.field("house_screen", "waterHeaterEntityId", lambda: _water_heater(hass))
    c.whole("house_locks", lambda: _locks(hass))

    c.field("energy_entities", "tariffEntityId", lambda: _tariff(hass))

    def family() -> list[dict[str, Any]]:
        people = sorted(_name(s) for s in hass.states.async_all("person") if _available(s))
        # A calendar named after a member is theirs, so its events take the
        # member's colour; the ones already on the screen win a tie.
        shown = [cal.get("entityId") for cal in c.current("calendar_entities") or [] if isinstance(cal, dict)]
        calendars: dict[str, str] = {}
        for s in sorted(hass.states.async_all("calendar"), key=lambda s: s.entity_id not in shown):
            if _available(s):
                calendars.setdefault(_name(s).strip().casefold(), s.entity_id)

        def member(name: str, color: str) -> dict[str, Any]:
            return {"name": name, "color": color, "calendarEntityId": calendars.get(name.strip().casefold())}

        members = [member(n, _COLORS[i % len(_COLORS)]) for i, n in enumerate(people)]
        # A shared member, so tasks and events can be for the whole family.
        return [*members, member("Família", "green")]

    c.whole("family_members", family)
    c.whole("todo_lists", lambda: [{"entityId": t} for t in _ids(hass, "todo")])
    c.whole("vacuums", lambda: _vacuums(hass))
    # Not a choice: each robot's entities follow its device.
    derived = vacuum_entities(hass, c.current("vacuums") or [])
    if derived != data.get("vacuum_entities"):
        c.changed["vacuum_entities"] = derived

    # The assistant's name on the screen matches its wake word.
    c.field("assistant", "wakePhrase", lambda: _wake_phrase(hass, reg))
    phrase = (c.current("assistant") or {}).get("wakePhrase") or "Ok Nabu"
    c.field("assistant", "name", lambda: _GREETING.sub("", phrase).strip() or phrase)

    return c.changed
