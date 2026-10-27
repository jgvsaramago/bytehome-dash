"""Agent tools for the household data the screens keep (and HA's Assist
doesn't reach): the ingredients of planned meals, events in a person's own
calendar, the screens' tasks (Tarefas), messages left for someone, and the
doorbell calls a screen saw.

Only what Assist can't do on its own is here: adding to a to-do list,
reading calendars and announcing on the satellites are Assist's own tools,
so these hand the agent what it needs for them instead of duplicating them.
"""
from __future__ import annotations

from datetime import datetime, timedelta
import re
from typing import Any

import voluptuous as vol

from collections.abc import Awaitable, Callable

from homeassistant.components import websocket_api
from homeassistant.core import HomeAssistant
from homeassistant.exceptions import HomeAssistantError
from homeassistant.helpers import config_validation as cv, device_registry as dr, llm
from homeassistant.util import dt as dt_util, ulid as ulid_util
from homeassistant.util.json import JsonObjectType

from .const import DOMAIN, EVENT_ASSISTANT, EVENT_SETTINGS_UPDATED
from .phones import async_notify, member_for_speaker, member_named, members
from .i18n import tr, tr_list
from .speakers import async_speaker_for
from .web_cards import async_fetch_recipe

MEALS = {"pequeno-almoço": ("pa", "08:00"), "almoço": ("almoco", "13:00"), "jantar": ("jantar", "20:00")}
_MEAL_NAMES = {meal_id: name for name, (meal_id, _) in MEALS.items()}
# For the agent (it answers in the user's language anyway).
_WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]




def screen_of(hass: HomeAssistant, context: llm.LLMContext) -> str | None:
    """The asking device's name (the screen's voice satellite is named after
    the screen), or None for a typed request."""
    if not context.device_id:
        return None
    device = dr.async_get(hass).async_get(context.device_id)
    return (device.name_by_user or device.name) if device else None


def show_result(hass: HomeAssistant, context: llm.LLMContext, result: dict[str, Any]) -> None:
    """What a tool did, for the screen's Assistente to show under the answer
    (an event made, a task done…): see the app's `_Result`."""
    hass.bus.async_fire(EVENT_ASSISTANT, {"action": "result", "screen": screen_of(hass, context), "result": result})


def add_undo(hass: HomeAssistant, undo: Callable[[], Awaitable[None]]) -> str:
    """Keeps how to undo an action for the screen's "Desfazer"; the token
    goes with the result (the last 20 are kept)."""
    undos: dict[str, Callable[[], Awaitable[None]]] = hass.data[DOMAIN].setdefault("undo", {})
    token = ulid_util.ulid_now()
    undos[token] = undo
    for old in list(undos)[:-20]:
        undos.pop(old)
    return token


def day_label(hass: HomeAssistant, day: datetime | Any) -> str:
    """"Quinta, 30 out" (or "Hoje" / "Amanhã")."""
    today = dt_util.now().date()
    d = day.date() if isinstance(day, datetime) else day
    if d == today:
        return tr(hass, "day.today")
    if d == today + timedelta(days=1):
        return tr(hass, "day.tomorrow")
    return tr(hass, "day.date", weekday=tr_list(hass, "day.weekdays")[d.weekday()], day=d.day, month=tr_list(hass, "day.months_short")[d.month - 1])


def _data(hass: HomeAssistant) -> dict[str, Any]:
    return hass.data.get(DOMAIN, {}).get("data") or {}


async def _save(hass: HomeAssistant, key: str, value: Any) -> None:
    domain_data = hass.data.get(DOMAIN, {})
    store, data = domain_data.get("store"), domain_data.get("data")
    if store is None or data is None:
        raise HomeAssistantError("The ByteHomeDash integration isn't set up.")
    data[key] = value
    await store.async_save(data)
    hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": key})


async def _who(hass: HomeAssistant, llm_context: llm.LLMContext, person: str | None) -> dict[str, Any] | str:
    """The person meant: named, else the recognised speaker. A string is the
    error to give the agent."""
    if person:
        return member_named(hass, person) or f"{person} isn't one of the household's people."
    speaker = await async_speaker_for(hass, llm_context.device_id)
    member = member_for_speaker(hass, speaker.get("speaker_id")) if speaker and speaker.get("identified") else None
    return member or "The speaker's voice wasn't recognised: ask who it is for."


def member_id(name: str) -> str:
    """The id the screens save tasks against (FamilyMember.id there)."""
    return re.sub(r"[^a-z0-9à-ÿ]+", "_", name.strip().lower()).strip("_")


def _norm(text: str) -> str:
    return re.sub(r"\s+", " ", text.strip().lower())


# --- Meal plan → shopping list ---------------------------------------------


def shopping_list_name(hass: HomeAssistant) -> str | None:
    """The list the screens show as Compras: the first chosen list with the
    cart icon, or whose name says it."""
    data = _data(hass)
    icons = data.get("todo_list_icons") or {}
    ids = [m.get("entityId") for m in data.get("todo_lists") or [] if isinstance(m, dict) and m.get("entityId")]
    states = [s for s in (hass.states.get(i) for i in ids) if s is not None]
    for state in states:
        if icons.get(state.entity_id) == "cart" or re.search(r"compra|shopping|mercearia|supermercado", state.name, re.I):
            return state.name
    return states[0].name if states else None


class GetMealIngredientsTool(llm.Tool):
    name = "get_meal_ingredients"
    description = (
        "The ingredients of the recipes in the family's meal plan for the coming "
        "days, read from each recipe's page, and the name of the shopping list. "
        "Add what's needed to that list with Assist's own list tool."
    )
    parameters = vol.Schema({vol.Optional("days", description="How many days from today (default 7)"): vol.All(int, vol.Range(min=1, max=14))})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        plan = _data(hass).get("meal_plan") or {}
        today = dt_util.now().date()
        meals: list[dict[str, Any]] = []
        for offset in range(tool_input.tool_args.get("days", 7)):
            day = (today + timedelta(days=offset)).isoformat()
            for meal_id, name in _MEAL_NAMES.items():
                entry = plan.get(f"{day}|{meal_id}")
                if not isinstance(entry, dict) or not entry.get("dish"):
                    continue
                meal: dict[str, Any] = {"date": day, "meal": name, "dish": entry["dish"]}
                if url := entry.get("url"):
                    recipe = await async_fetch_recipe(hass, url)
                    if recipe and recipe["ingredients"]:
                        meal["ingredients"] = recipe["ingredients"]
                        if recipe.get("servings"):
                            meal["servings"] = recipe["servings"]
                    else:
                        meal["note"] = "The recipe page has no ingredient list."
                else:
                    meal["note"] = "No recipe linked: just the dish's name."
                meals.append(meal)
        return {"meals": meals, "shopping_list": shopping_list_name(hass)}


# --- Calendar ----------------------------------------------------------------


class CreateCalendarEventTool(llm.Tool):
    name = "create_calendar_event"
    description = (
        "Create an event in a household member's own calendar (set in the "
        "screens' Pessoas). Without a person, it goes in the recognised "
        "speaker's calendar."
    )
    parameters = vol.Schema(
        {
            vol.Required("title", description="What it is, e.g. 'Dentista'"): str,
            vol.Required("start", description="YYYY-MM-DDTHH:MM, or YYYY-MM-DD for an all-day event"): str,
            vol.Optional("end", description="Same format as start; default 1 hour (all-day: that day)"): str,
            vol.Optional("person", description="Whose calendar, by name ('Família' for the shared one); leave out for the speaker"): str,
            vol.Optional("location"): str,
            vol.Optional("description"): str,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        who = await _who(hass, llm_context, args.get("person"))
        if isinstance(who, str):
            return {"error": who}
        calendar = (who.get("calendarEntityId") or "").strip()
        state = hass.states.get(calendar) if calendar else None
        if state is None:
            return {"error": f"{who['name']} has no calendar set in Pessoas."}
        if not int(state.attributes.get("supported_features", 0)) & 1:
            return {"error": f"{state.name} can't take new events."}
        data: dict[str, Any] = {"summary": args["title"]}
        if len(args["start"]) == 10:
            start = dt_util.parse_date(args["start"])
            end = dt_util.parse_date(args["end"][:10]) if args.get("end") else start
            if start is None or end is None:
                return {"error": "Dates must be YYYY-MM-DD."}
            data.update(start_date=start.isoformat(), end_date=(end + timedelta(days=1)).isoformat())
        else:
            start_dt = dt_util.parse_datetime(args["start"])
            end_dt = dt_util.parse_datetime(args["end"]) if args.get("end") else None
            if start_dt is None:
                return {"error": "start must be YYYY-MM-DDTHH:MM."}
            start_dt = start_dt if start_dt.tzinfo else start_dt.replace(tzinfo=dt_util.get_default_time_zone())
            end_dt = end_dt if end_dt is None or end_dt.tzinfo else end_dt.replace(tzinfo=dt_util.get_default_time_zone())
            data.update(start_date_time=start_dt.isoformat(), end_date_time=(end_dt or start_dt + timedelta(hours=1)).isoformat())
        for key in ("location", "description"):
            if args.get(key):
                data[key] = args[key]
        try:
            await hass.services.async_call("calendar", "create_event", data, target={"entity_id": calendar}, blocking=True)
        except HomeAssistantError as err:
            return {"error": str(err)}
        if "start_date_time" in data:
            start = dt_util.parse_datetime(data["start_date_time"])
            when = f"{day_label(hass, dt_util.as_local(start))} · {dt_util.as_local(start):%H:%M}"
        else:
            start = dt_util.parse_date(data["start_date"])
            when = f"{day_label(hass, start)} · {tr(hass, 'event.all_day')}"

        async def undo() -> None:
            await _delete_event(hass, calendar, args["title"], data)

        show_result(
            hass,
            llm_context,
            {
                "kind": "event",
                "title": args["title"],
                "state": f"{when} · {state.name}",
                "undo": add_undo(hass, undo),
            },
        )
        return {"created": args["title"], "calendar": state.name, "person": who["name"]}


async def _delete_event(hass: HomeAssistant, entity_id: str, summary: str, data: dict[str, Any]) -> None:
    """Deletes the event create_calendar_event just made ("Desfazer"): found
    by its title and start in that calendar."""
    component = hass.data.get("calendar")
    entity = component.get_entity(entity_id) if component else None
    if entity is None:
        raise HomeAssistantError("Calendar not found")
    if "start_date_time" in data:
        start = dt_util.parse_datetime(data["start_date_time"])
    else:
        start = dt_util.start_of_local_day(dt_util.parse_date(data["start_date"]))
    events = await entity.async_get_events(hass, start - timedelta(minutes=1), start + timedelta(days=1))
    for event in events:
        if event.summary == summary and event.uid:
            await entity.async_delete_event(event.uid, recurrence_id=event.recurrence_id)
            return
    raise HomeAssistantError("The event wasn't found")


# --- Tasks (Tarefas) ----------------------------------------------------------


def _chores(hass: HomeAssistant) -> tuple[list[dict[str, Any]], list[str]]:
    raw = _data(hass).get("chores") or {}
    tasks = [t for t in raw.get("tasks") or [] if isinstance(t, dict) and t.get("id")]
    return tasks, [d for d in raw.get("done") or [] if isinstance(d, str)]


def _on_day(task: dict[str, Any], day: datetime) -> bool:
    days = task.get("days")
    return day.weekday() in days if isinstance(days, list) else task.get("date") == day.date().isoformat()


def _names(hass: HomeAssistant) -> dict[str, str]:
    return {member_id(m["name"]): m["name"].strip() for m in members(hass)}


def _day(value: str | None) -> datetime | None:
    if not value:
        return dt_util.now()
    parsed = dt_util.parse_date(value)
    return datetime.combine(parsed, datetime.min.time()) if parsed else None


class GetChoresTool(llm.Tool):
    name = "get_chores"
    description = "The household's tasks for a day (the screens' Tarefas page): who does each, its deadline and whether it's done."
    parameters = vol.Schema({vol.Optional("date", description="YYYY-MM-DD, default today"): str})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        day = _day(tool_input.tool_args.get("date"))
        if day is None:
            return {"error": "date must be YYYY-MM-DD"}
        tasks, done = _chores(hass)
        names, key = _names(hass), day.date().isoformat()
        return {
            "date": key,
            "tasks": [
                {"task": t.get("title"), "who": names.get(t.get("who"), t.get("who")), "due": t.get("due") or None, "done": f"{key}|{t['id']}" in done}
                for t in tasks
                if _on_day(t, day)
            ],
        }


class AddChoreTool(llm.Tool):
    name = "add_chore"
    description = (
        "Add a household task to the screens' Tarefas page, for one person: once "
        "on a date, or repeating on weekdays."
    )
    parameters = vol.Schema(
        {
            vol.Required("title", description="The task, e.g. 'Tirar o lixo'"): str,
            vol.Optional("person", description="Who does it, by name ('Família' for everyone); leave out for the speaker"): str,
            vol.Optional("date", description="YYYY-MM-DD for a one-off task (default today)"): str,
            vol.Optional("weekdays", description="Repeat on these weekdays, 0 = Monday … 6 = Sunday"): [vol.All(int, vol.Range(min=0, max=6))],
            vol.Optional("due", description="Deadline, HH:MM"): str,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        who = await _who(hass, llm_context, args.get("person"))
        if isinstance(who, str):
            return {"error": who}
        if args.get("due") and not re.fullmatch(r"\d{2}:\d{2}", args["due"]):
            return {"error": "due must be HH:MM"}
        task: dict[str, Any] = {"id": f"t{int(dt_util.utcnow().timestamp() * 1000)}", "title": args["title"].strip(), "who": member_id(who["name"])}
        if args.get("weekdays"):
            task.update(days=sorted(set(args["weekdays"])), date=None)
        else:
            day = _day(args.get("date"))
            if day is None:
                return {"error": "date must be YYYY-MM-DD"}
            task.update(days=None, date=day.date().isoformat())
        if args.get("due"):
            task["due"] = args["due"]
        tasks, done = _chores(hass)
        await _save(hass, "chores", {"tasks": [*tasks, task], "done": done})
        when = ", ".join(_WEEKDAYS[d] for d in task["days"]) if task["days"] else task["date"]
        label = (
            " · ".join(tr_list(hass, "day.weekdays_short")[d] for d in task["days"])
            if task["days"]
            else day_label(hass, dt_util.parse_date(task["date"])).lower()
        )

        async def undo() -> None:
            tasks_now, done_now = _chores(hass)
            await _save(hass, "chores", {"tasks": [t for t in tasks_now if t["id"] != task["id"]], "done": done_now})

        show_result(
            hass,
            llm_context,
            {
                "kind": "task",
                "title": task["title"],
                "state": " · ".join(
                    [tr(hass, "tasks.section"), label, *([tr(hass, "tasks.until", time=task["due"])] if task.get("due") else []), who["name"]]
                ),
                "undo": add_undo(hass, undo),
            },
        )
        return {"added": task["title"], "who": who["name"], "when": when}


class CompleteChoreTool(llm.Tool):
    name = "complete_chore"
    description = "Tick off a task on the screens' Tarefas page as done (or not done) for a day."
    parameters = vol.Schema(
        {
            vol.Required("task", description="The task's name, as the user says it"): str,
            vol.Optional("person", description="Whose task, when several people have one with that name"): str,
            vol.Optional("date", description="YYYY-MM-DD, default today"): str,
            vol.Optional("done", description="false to untick (default true)"): bool,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        day = _day(args.get("date"))
        if day is None:
            return {"error": "date must be YYYY-MM-DD"}
        tasks, done = _chores(hass)
        names, want = _names(hass), _norm(args["task"])
        today = [t for t in tasks if _on_day(t, day)]
        matches = [t for t in today if _norm(t.get("title") or "") == want] or [t for t in today if want in _norm(t.get("title") or "")]
        if person := args.get("person"):
            member = member_named(hass, person)
            matches = [t for t in matches if member and t.get("who") == member_id(member["name"])]
        if not matches:
            return {"error": "No task like that on that day.", "tasks": [t.get("title") for t in today]}
        if len(matches) > 1:
            return {"error": "Several tasks match; say whose.", "matches": [{"task": t.get("title"), "who": names.get(t.get("who"))} for t in matches]}
        task, key = matches[0], f"{day.date().isoformat()}|{matches[0]['id']}"
        marks = set(done)
        if args.get("done", True):
            marks.add(key)
        else:
            marks.discard(key)
        await _save(hass, "chores", {"tasks": tasks, "done": sorted(marks)})
        who = names.get(task.get("who"))
        if args.get("done", True):
            show_result(
                hass,
                llm_context,
                {
                    "kind": "task_done",
                    "title": task.get("title"),
                    "state": " · ".join([tr(hass, "tasks.section"), tr(hass, "tasks.done_at", time=f"{dt_util.now():%H:%M}"), *([who] if who else [])]),
                },
            )
        return {"task": task.get("title"), "who": who, "done": args.get("done", True)}


# --- Messages ------------------------------------------------------------------


async def async_leave_message(
    hass: HomeAssistant, text: str, to: dict[str, Any] | None, sender: dict[str, Any] | None, phone: bool = True
) -> tuple[dict[str, Any], list[str]]:
    """Adds a message to the screens' shared `family_messages` (dropping
    week-old ones) and, with [phone], notifies the recipient's phone, or
    everyone's but the sender's when it's for everyone. Returns the message
    and whose phones it reached."""
    message = {
        "id": ulid_util.ulid_now(),
        "to": to["name"].strip() if to else None,
        "from": sender["name"].strip() if sender else None,
        "text": text.strip(),
        "at": dt_util.utcnow().isoformat(),
    }
    week_ago = (dt_util.utcnow() - timedelta(days=7)).isoformat()
    kept = [m for m in _data(hass).get("family_messages") or [] if isinstance(m, dict) and (m.get("at") or "") >= week_ago]
    await _save(hass, "family_messages", [*kept, message])
    phones: list[str] = []
    if phone:
        title = tr(hass, "recado.from", name=message["from"]) if message["from"] else tr(hass, "recado.title")
        for member in [to] if to else [m for m in members(hass) if m is not sender]:
            try:
                await async_notify(hass, member, title, message["text"])
                phones.append(member["name"].strip())
            except HomeAssistantError:
                pass
    return message, phones


@websocket_api.websocket_command(
    {
        vol.Required("type"): "bytehomedash/leave_message",
        vol.Required("text"): cv.string,
        vol.Optional("to"): vol.Any(cv.string, None),
        vol.Optional("from"): vol.Any(cv.string, None),
        vol.Optional("phone", default=True): bool,
    }
)
@websocket_api.async_response
async def websocket_leave_message(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """A message written on a screen (Listas › Recados › "Escrever um
    recado"): stored like one left through the assistant."""
    to = member_named(hass, msg["to"]) if msg.get("to") else None
    if msg.get("to") and to is None:
        connection.send_error(msg["id"], "not_a_person", tr(hass, "phone.not_a_person", name=msg["to"]))
        return
    sender = member_named(hass, msg["from"]) if msg.get("from") else None
    try:
        message, phones = await async_leave_message(hass, msg["text"], to, sender, msg["phone"])
    except HomeAssistantError as err:
        connection.send_error(msg["id"], "failed", str(err))
        return
    connection.send_result(msg["id"], {"message": message, "phones": phones})


class LeaveMessageTool(llm.Tool):
    name = "leave_message"
    description = (
        "Leave a message for someone in the household: it stays on the screens "
        "until they see it, and goes to their phone too. Without a person, it's "
        "for everyone."
    )
    parameters = vol.Schema(
        {
            vol.Required("text", description="The message, as it should be read"): str,
            vol.Optional("person", description="Who it's for, by name; leave out for everyone"): str,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        to = None
        if person := args.get("person"):
            to = member_named(hass, person)
            if to is None:
                return {"error": f"{person} isn't one of the household's people."}
        speaker = await async_speaker_for(hass, llm_context.device_id)
        sender = member_for_speaker(hass, speaker.get("speaker_id")) if speaker and speaker.get("identified") else None
        message, phones = await async_leave_message(hass, args["text"], to, sender)
        show_result(
            hass,
            llm_context,
            {
                "kind": "note",
                "title": tr(hass, "recado.for", name=message["to"]) if message["to"] else tr(hass, "recado.for_all"),
                "state": f"«{message['text']}»" + (f" · {tr(hass, 'recado.sent_to_phone')}" if phones else ""),
            },
        )
        return {"left_for": message["to"] or "everyone", "sent_to_phones_of": phones}


class MarkMessagesSeenTool(llm.Tool):
    name = "mark_messages_seen"
    description = (
        "The user saw the household's unseen messages (\"visto\", \"já vi\"): mark "
        "them seen on every screen. With later true (\"mais tarde\"), just close "
        "the messages on the screen; they show again the next time it wakes."
    )
    parameters = vol.Schema({vol.Optional("later", description="Only close them for now"): bool})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        screen = screen_of(hass, llm_context)
        if tool_input.tool_args.get("later"):
            hass.bus.async_fire(EVENT_ASSISTANT, {"action": "messages", "screen": screen, "seen": False})
            return {"closed": True}
        speaker = await async_speaker_for(hass, llm_context.device_id)
        member = member_for_speaker(hass, speaker.get("speaker_id")) if speaker and speaker.get("identified") else None
        now = dt_util.utcnow().isoformat()
        messages = [m for m in _data(hass).get("family_messages") or [] if isinstance(m, dict)]
        unseen = [m for m in messages if not m.get("seen_at")]
        for m in unseen:
            m["seen_at"] = now
            if member:
                m["seen_by"] = member["name"].strip()
        if unseen:
            await _save(hass, "family_messages", messages)
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "messages", "screen": screen, "seen": True})
        return {"marked_seen": len(unseen)}


# --- Doorbell -------------------------------------------------------------------


class GetDoorbellCallsTool(llm.Tool):
    name = "get_doorbell_calls"
    description = "Who rang the apartment's doorbell recently, as the screens saw it: when, and whether it was answered or the door opened."
    parameters = vol.Schema({vol.Optional("days", description="How many days back (default 1: today)"): vol.All(int, vol.Range(min=1, max=30))})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        published = _data(hass).get("doorbell_calls") or {}
        # The intercom is optional; only screens that have one publish calls.
        if not published:
            return {"error": "No screen has an intercom set up, so there are no doorbell calls to report."}
        since = dt_util.start_of_local_day() - timedelta(days=tool_input.tool_args.get("days", 1) - 1)
        calls: list[dict[str, Any]] = []
        for screen_calls in published.values():
            for call in screen_calls if isinstance(screen_calls, list) else []:
                at = dt_util.parse_datetime(call.get("at") or "")
                if at is None or at < since:
                    continue
                # Several screens see the same ring.
                if any(abs((at - c["_at"]).total_seconds()) < 60 for c in calls):
                    continue
                calls.append({"_at": at, **call})
        calls.sort(key=lambda c: c["_at"], reverse=True)
        days = tool_input.tool_args.get("days", 1)
        span = tr(hass, "calls.today") if days == 1 else tr(hass, "calls.last_days", days=days)
        door = tr(hass, "calls.door")
        show_result(
            hass,
            llm_context,
            {
                "kind": "calls",
                "title": tr(hass, "calls.rang", count=len(calls), span=span) if calls else tr(hass, "calls.none", span=span),
                "state": door,
                "lines": [
                    {
                        "time": dt_util.as_local(c["_at"]).strftime("%H:%M" if days == 1 else "%d/%m %H:%M"),
                        "label": door,
                        "state": tr(hass, "calls.answered") if c.get("answered") else tr(hass, "calls.missed"),
                        "tone": "ok" if c.get("answered") else "danger",
                    }
                    for c in calls[:6]
                ],
            },
        )
        return {
            "calls": [
                {
                    "time": dt_util.as_local(c["_at"]).strftime("%Y-%m-%d %H:%M"),
                    "answered": bool(c.get("answered")),
                    "door_opened": bool(c.get("door_opened")),
                    "missed": bool(c.get("missed")),
                }
                for c in calls
            ],
            "note": "Only calls a screen saw; nobody is identified (the screen keeps a picture, shown in the door history).",
        }
