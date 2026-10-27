"""Each person's phone, for the screens' Assistente ("Enviar para o telemóvel").

A person (panel, "Pessoas") is linked to Home Assistant's own person entity
(`personEntityId`); when that's left empty, the HA person with the same name
is used. That person's device trackers lead to their phones with the Home
Assistant app (the `mobile_app` integration), and each such phone has the
`notify.mobile_app_<device>` service the link is sent with. A tap on the
notification opens the page.
"""
from __future__ import annotations

import unicodedata
from typing import Any

import voluptuous as vol

from homeassistant.components import websocket_api
from homeassistant.core import HomeAssistant
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers import config_validation as cv, device_registry as dr, entity_registry as er
from homeassistant.util import slugify

from .const import DOMAIN
from .i18n import tr


def _norm(text: str) -> str:
    plain = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    return "".join(ch for ch in plain.lower() if ch.isalnum())


def _members(hass: HomeAssistant) -> list[dict[str, Any]]:
    members = (hass.data.get(DOMAIN, {}).get("data") or {}).get("family_members") or []
    return [m for m in members if isinstance(m, dict) and (m.get("name") or "").strip()]


def _person_of(hass: HomeAssistant, member: dict[str, Any]) -> str | None:
    """The member's HA person entity: chosen in the panel, else by name."""
    chosen = (member.get("personEntityId") or "").strip()
    if chosen:
        return chosen
    name = _norm(member.get("name") or "")
    for state in hass.states.async_all("person"):
        if _norm(state.name) == name:
            return state.entity_id
    return None


def _phone_of(hass: HomeAssistant, member: dict[str, Any]) -> tuple[str, str] | None:
    """(notify service, device name) for the member's first phone with the
    Home Assistant app, or None."""
    person = _person_of(hass, member)
    state = hass.states.get(person) if person else None
    if state is None:
        return None
    ents, devs = er.async_get(hass), dr.async_get(hass)
    for tracker in state.attributes.get("device_trackers") or []:
        entry = ents.async_get(tracker)
        device = devs.async_get(entry.device_id) if entry and entry.device_id else None
        if device is None or entry.platform != "mobile_app":
            continue
        service = f"mobile_app_{slugify(device.name or '')}"
        if hass.services.has_service("notify", service):
            return service, device.name_by_user or device.name or ""
    return None


def member_named(hass: HomeAssistant, name: str) -> dict[str, Any] | None:
    """The person called [name] ("Ana Sofia", or just a first name)."""
    want = _norm(name)
    members = _members(hass)
    return next((m for m in members if _norm(m["name"]) == want), None) or next(
        (m for m in members if _norm(m["name"].split()[0]) == want), None
    )


async def async_notify(hass: HomeAssistant, member: dict[str, Any], title: str, message: str, url: str | None = None) -> str:
    """A notification on [member]'s phone (opening [url] when tapped);
    returns the phone's name. Raises HomeAssistantError when they have none
    or it can't be sent."""
    phone = _phone_of(hass, member)
    if phone is None:
        raise HomeAssistantError(tr(hass, "phone.no_phone", name=member["name"].strip()))
    data: dict[str, Any] = {"title": title, "message": message}
    if url:
        # iOS opens `url`, Android `clickAction`.
        data["data"] = {"url": url, "clickAction": url}
    await hass.services.async_call("notify", phone[0], data, blocking=True)
    return phone[1]


async def async_send(hass: HomeAssistant, member: dict[str, Any], url: str, title: str | None) -> str:
    """Sends a page to [member]'s phone; returns the phone's name."""
    return await async_notify(hass, member, title or tr(hass, "phone.default_title"), url, url)


def members(hass: HomeAssistant) -> list[dict[str, Any]]:
    """The people configured in the panel (Pessoas)."""
    return _members(hass)


def member_for_speaker(hass: HomeAssistant, speaker_id: str | None) -> dict[str, Any] | None:
    """The person whose "Identificação por voz" is [speaker_id]."""
    if not speaker_id:
        return None
    sid = speaker_id.strip().lower()
    return next((m for m in _members(hass) if (m.get("speakerId") or "").strip().lower() == sid), None)


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/phones"})
@websocket_api.async_response
async def websocket_phones(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """The people a link can be sent to: `[{name, device}]`."""
    phones = []
    for member in _members(hass):
        if phone := _phone_of(hass, member):
            phones.append({"name": member["name"].strip(), "device": phone[1]})
    connection.send_result(msg["id"], phones)


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/send_to_phone",
        vol.Required("name"): cv.string,
        vol.Required("url"): cv.string,
        vol.Optional("title"): cv.string,
    }
)
@websocket_api.async_response
async def websocket_send_to_phone(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """Sends a page to a person's phone; the result comes once Home Assistant
    has handed it to the notify service."""
    member = next((m for m in _members(hass) if m["name"].strip() == msg["name"]), None)
    if member is None:
        connection.send_error(msg["id"], "no_phone", tr(hass, "phone.not_a_person", name=msg["name"]))
        return
    try:
        device = await async_send(hass, member, msg["url"], msg.get("title"))
    except HomeAssistantError as err:
        connection.send_error(msg["id"], "send_failed", str(err))
        return
    connection.send_result(msg["id"], {"device": device})
