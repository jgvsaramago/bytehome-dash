"""Who is speaking, per voice satellite and run (reported by the satellite).

Linux Voice Assistant (the ByteHomeDash fork, `--speaker-id`) identifies the
speaker locally and fires `esphome.lva_speaker` over its ESPHome connection
— "pending" when a run starts, then the result once end of speech is
identified, while HA is still transcribing. HA adds the satellite's
`device_id`, so each satellite's result is its own.

`async_speaker_for(device_id)` is what a conversation turn asks: it waits
briefly for a pending result, and only returns a result that belongs to the
run in progress (fresh, and cleared when the next run starts). No result
(speaker id off, or a typed request) means nothing is known.

Each result is also forwarded to the satellite's screen (the
`bytehomedash_assistant` event, action "speaker"), whose Assistente shows
who it is talking to.
"""
from __future__ import annotations

import asyncio
import time
from dataclasses import dataclass, field
from typing import Any

from homeassistant.core import Event, HomeAssistant, callback
from homeassistant.helpers import device_registry as dr

from .const import DOMAIN, EVENT_ASSISTANT
from .phones import member_for_speaker

EVENT_SPEAKER = "esphome.lva_speaker"

# A pending result is waited for at most this long when the agent starts its
# turn; identification itself takes ~0.1 s and finishes during speech-to-text.
_WAIT = 2.0
# A result older than this belongs to an earlier conversation.
_FRESH = 120.0


@dataclass
class _Run:
    run: str
    started: float
    done: asyncio.Event = field(default_factory=asyncio.Event)
    result: dict[str, Any] | None = None


@callback
def async_setup_speakers(hass: HomeAssistant) -> None:
    runs: dict[str, _Run] = hass.data[DOMAIN].setdefault("speaker_runs", {})

    @callback
    def _on_event(event: Event) -> None:
        data = event.data
        device_id = data.get("device_id")
        if not device_id:
            return
        run = str(data.get("run", ""))
        if data.get("status") == "pending":
            runs[device_id] = _Run(run, time.monotonic())
            _tell_screen(device_id, {"status": "pending"})
            return
        current = runs.get(device_id)
        if current is None or current.run != run:
            # A result without its "pending" (e.g. HA restarted mid-run).
            current = runs[device_id] = _Run(run, time.monotonic())
        current.result = {
            "speaker_id": data.get("speaker_id") or None,
            "identified": str(data.get("identified", "")).lower() == "true",
            "score": _float(data.get("score")),
            "reason": data.get("reason") or None,
            "source": data.get("source"),
        }
        current.done.set()
        member = member_for_speaker(hass, current.result["speaker_id"]) if current.result["identified"] else None
        _tell_screen(
            device_id,
            {
                "status": "done",
                "identified": current.result["identified"],
                "speaker_id": current.result["speaker_id"],
                "name": member["name"].strip() if member else None,
            },
        )

    @callback
    def _tell_screen(device_id: str, data: dict[str, Any]) -> None:
        device = dr.async_get(hass).async_get(device_id)
        if device is not None:
            hass.bus.async_fire(EVENT_ASSISTANT, {"action": "speaker", "screen": device.name_by_user or device.name, **data})

    hass.bus.async_listen(EVENT_SPEAKER, _on_event)


async def async_speaker_for(hass: HomeAssistant, device_id: str | None) -> dict[str, Any] | None:
    """The speaker of this satellite's current run, or None if not known."""
    if not device_id:
        return None
    current = hass.data.get(DOMAIN, {}).get("speaker_runs", {}).get(device_id)
    if current is None or time.monotonic() - current.started > _FRESH:
        return None
    if current.result is None:
        try:
            await asyncio.wait_for(current.done.wait(), _WAIT)
        except asyncio.TimeoutError:
            return None
    return current.result


def _float(value: Any) -> float | None:
    try:
        return float(value)
    except (TypeError, ValueError):
        return None
