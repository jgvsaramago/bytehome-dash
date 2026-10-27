"""Tools for conversation agents: show web pages as cards on a screen.

Registered as the "ByteHomeDash" LLM API, enabled next to "Assist" in a
conversation agent's options. The agent searches the web with its own tool
and then calls `show_web_results` with the pages it picked; the cards
(web_cards.py) go to the screen the request came from, whose Assistente
shows them. `open_result` opens one of them in that screen's browser
("abre a segunda").
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any
from urllib.parse import urlparse

import voluptuous as vol

from homeassistant.core import HomeAssistant
from homeassistant.exceptions import HomeAssistantError
from homeassistant.components import websocket_api
from homeassistant.helpers import config_validation as cv, llm
from homeassistant.util import dt as dt_util
from homeassistant.util.json import JsonObjectType

from .const import DOMAIN, EVENT_ASSISTANT, EVENT_SETTINGS_UPDATED
from .phones import async_send, member_for_speaker, member_named
from .i18n import tr
from .speakers import async_speaker_for
from .household_tools import (
    MEALS,
    AddChoreTool,
    CompleteChoreTool,
    CreateCalendarEventTool,
    GetChoresTool,
    GetDoorbellCallsTool,
    GetMealIngredientsTool,
    LeaveMessageTool,
    MarkMessagesSeenTool,
    add_undo,
    day_label,
    screen_of as _screen,
    show_result,
)
from .web_cards import async_fetch_cards, async_fetch_recipe

_PROMPT = (
    "You are speaking through a wall screen that can show web pages as cards. "
    "Whenever the user asks for recipes, products, shops or prices, news or "
    "articles, places, restaurants or videos, ALWAYS do this instead of "
    "answering from memory: 1) search the web; 2) call show_web_results with "
    "the URLs of the 3 to 6 best pages (the pages themselves, not search or "
    "list pages, preferably from different sites); 3) answer in one or two "
    "short spoken sentences, e.g. \"Encontrei quatro receitas de lasanha, estão "
    "no ecrã.\" Never write out a whole recipe, ingredient list or article, "
    "never read URLs, and don't describe every card: the screen shows the "
    "title, image, rating and time read from each page. For restaurants and "
    "other places, pick each place's page on a review site (TheFork, "
    "TripAdvisor, Zomato and the like) rather than its own website, so the "
    "card can show its rating, number of reviews, cuisine and address. If the "
    "user then asks to open one (\"abre a segunda\", \"a do Pingo Doce\", \"a "
    "com melhor nota\"), call open_result with its number from "
    "show_web_results' result. To plan a meal (\"põe a terceira no jantar de "
    "quinta\", \"almoço de amanhã é pizza\"), call plan_meals with the "
    "card's number or the dish, the date and the meal. To make a meal plan "
    "(\"cria o plano de refeições para os próximos dois dias, tenho tomate, arroz "
    "e cogumelos para gastar\"): call get_meal_plan; search the web for recipes "
    "that use what they have (several different dishes, no repeats, nothing "
    "already planned that week); show them with show_web_results; then plan "
    "all the meals in one plan_meals call by card number (lunch and dinner "
    "unless they say otherwise; the day starts tomorrow if today's dinner time "
    "has passed). If plan_meals returns needs_confirmation, say which meals "
    "already had something (dish and day) and ask whether to replace them; "
    "only on a yes call plan_meals again for those with replace true. Then "
    "answer briefly, e.g. \"Planeei quatro refeições até quarta, estão em "
    "Receitas.\" For a shopping list from the plan (\"põe na lista "
    "de compras o que falta para as refeições da semana\"): call "
    "get_meal_ingredients; if the user didn't say what they already have, ask "
    "once, naming only the main ingredients; then read the shopping list with "
    "Assist's todo tool, and add with Assist's list tool each missing "
    "ingredient once (merge repeats, leave out salt, pepper, oil and water), "
    "to the list get_meal_ingredients names; then say how many you added. To "
    "follow a recipe while cooking (\"lê-me a receita da segunda passo a "
    "passo\", \"a receita do jantar de hoje\"), call show_recipe with step 1 "
    "and read that step only; \"próximo passo\" calls it with the next step, "
    "\"repete\" reads the same step again, \"o que preciso?\" reads the "
    "ingredients; \"minimiza\", \"sai\", \"continua\" or \"volta à receita\" "
    "call kitchen_mode. Events go in someone's own calendar with "
    "create_calendar_event (\"marca-me\" is the speaker's). The screens' "
    "household tasks are get_chores, add_chore and complete_chore. "
    "leave_message leaves a message on the screens and the person's phone; "
    "when the user says \"visto\", \"já vi\" or \"mais tarde\" about messages, "
    "call mark_messages_seen (later true for \"mais tarde\"). "
    "get_doorbell_calls says who rang. show_on_screen opens a page of the "
    "screen (calendar, tasks, door camera…) when the user asks to see it. To send a page to "
    "someone's phone (\"envia-me a segunda\", \"manda isso para a Rita\"), "
    "call send_to_phone with the card's number; \"me\" is the recognised "
    "speaker, so leave the person out. Only describe a recipe "
    "step by step if the user explicitly asks to be told it. End your reply "
    "with a question only when you need the user's answer (a missing detail, "
    "a choice such as \"Queres que abra a segunda?\"): a reply ending in a "
    "question keeps the microphone listening for the answer, any other ends "
    "the conversation, so don't add \"Mais alguma coisa?\" or similar. Don't say "
    "anything before you have the answer: text written before a slow search "
    "starts the voice early and it times out before the rest arrives."
)

_WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
_MEALS = MEALS


class ShowWebResultsTool(llm.Tool):
    name = "show_web_results"
    description = (
        "Show web pages as cards (image, title, site, rating, rating count, "
        "time or price) on the screen the user is talking to. Use it for every "
        "request for recipes, products, articles, places or videos, after "
        "searching the web. Pass the URLs of the pages themselves, best first."
    )
    parameters = vol.Schema(
        {
            vol.Required("urls", description="Page URLs, best first (3 to 6)"): [str],
            vol.Optional("title", description="A short heading for the cards, e.g. 'Lasanha'"): str,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        cards = await async_fetch_cards(hass, args["urls"])
        screen = _screen(hass, llm_context)
        hass.data[DOMAIN].setdefault("last_cards", {})[screen] = cards
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "cards", "screen": screen, "title": args.get("title"), "cards": cards})
        if not cards:
            return {"shown": 0, "error": "None of those pages could be read; try others."}
        return {
            "shown": len(cards),
            "cards": [
                {k: v for k, v in {"number": i + 1, **_summary(c)}.items() if v is not None}
                for i, c in enumerate(cards)
            ],
        }


class OpenResultTool(llm.Tool):
    name = "open_result"
    description = "Open one of the cards shown by show_web_results in the screen's browser."
    parameters = vol.Schema({vol.Required("number", description="The card's number, from 1"): int})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        screen = _screen(hass, llm_context)
        cards = hass.data[DOMAIN].get("last_cards", {}).get(screen) or []
        number = tool_input.tool_args["number"]
        if not 1 <= number <= len(cards):
            return {"error": f"There is no card {number}; {len(cards)} are shown."}
        card = cards[number - 1]
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "open", "screen": screen, "url": card["url"]})
        return {"opened": card.get("title"), "site": card.get("site")}


class SendToPhoneTool(llm.Tool):
    name = "send_to_phone"
    description = (
        "Send one of the cards shown by show_web_results (or another web page) to "
        "a household member's phone, as a notification that opens it. Without a "
        "person, it goes to whoever is speaking (recognised by voice)."
    )
    parameters = vol.Schema(
        {
            vol.Optional("number", description="A card's number from show_web_results"): int,
            vol.Optional("url", description="A page's URL, when it isn't a card"): str,
            vol.Optional("person", description="Who gets it, by name; leave out for the speaker"): str,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        screen = _screen(hass, llm_context)
        if (number := args.get("number")) is not None:
            cards = hass.data.get(DOMAIN, {}).get("last_cards", {}).get(screen) or []
            if not 1 <= number <= len(cards):
                return {"error": f"There is no card {number}; {len(cards)} are shown."}
            url, title = cards[number - 1]["url"], cards[number - 1].get("title")
        elif args.get("url"):
            url, title = args["url"], None
        else:
            return {"error": "Give a card number or a URL."}
        if person := args.get("person"):
            member = member_named(hass, person)
            if member is None:
                return {"error": f"{person} isn't one of the household's people."}
        else:
            speaker = await async_speaker_for(hass, llm_context.device_id)
            member = member_for_speaker(hass, speaker.get("speaker_id")) if speaker and speaker.get("identified") else None
            if member is None:
                return {"error": "The speaker's voice wasn't recognised: ask who should get it."}
        try:
            device = await async_send(hass, member, url, title)
        except HomeAssistantError as err:
            return {"error": str(err)}
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "sent", "screen": screen, "url": url, "name": member["name"].strip()})
        host = urlparse(url).hostname or url
        show_result(
            hass,
            llm_context,
            {
                "kind": "sent",
                "title": tr(hass, "phone.sent_to", name=member["name"].strip()),
                "state": f"{title} · {host.removeprefix('www.')}" if title else host.removeprefix("www."),
                "url": url,
                "page_title": title or host,
            },
        )
        return {"sent_to": member["name"].strip(), "phone": device}


class ShowOnScreenTool(llm.Tool):
    name = "show_on_screen"
    description = "Open a page of the screen the user is talking to, when they ask to see it."
    parameters = vol.Schema(
        {
            vol.Required("page", description="Which page"): vol.In(
                ["início", "calendário", "tarefas", "refeições", "listas", "casa", "música", "câmara da porta", "chamadas da porta"]
            )
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        page = tool_input.tool_args["page"]
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "show", "screen": _screen(hass, llm_context), "page": page})
        return {"shown": page}


class ShowRecipeTool(llm.Tool):
    name = "show_recipe"
    description = (
        "Show a recipe on the screen to cook from, one step at a time, large "
        "(cooking mode): one of the cards shown by show_web_results, a planned "
        "meal's recipe, or a recipe page. Returns its ingredients and the step "
        "to read."
    )
    parameters = vol.Schema(
        {
            vol.Optional("number", description="A card's number from show_web_results"): int,
            vol.Optional("date", description="A planned meal's day, YYYY-MM-DD"): str,
            vol.Optional("meal", description="A planned meal"): vol.In(list(_MEALS)),
            vol.Optional("url", description="A recipe page's URL"): str,
            vol.Optional("step", description="Which step to show, from 1 (default 1)"): int,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        domain_data = hass.data.get(DOMAIN, {})
        screen = _screen(hass, llm_context)
        url = args.get("url")
        if (number := args.get("number")) is not None:
            cards = domain_data.get("last_cards", {}).get(screen) or []
            if not 1 <= number <= len(cards):
                return {"error": f"There is no card {number}; {len(cards)} are shown."}
            url = cards[number - 1]["url"]
        elif args.get("date") and args.get("meal"):
            entry = ((domain_data.get("data") or {}).get("meal_plan") or {}).get(f"{args['date']}|{_MEALS[args['meal']][0]}") or {}
            url = entry.get("url")
            if not url:
                return {"error": "That meal has no recipe linked." if entry else "Nothing is planned for that meal."}
        if not url:
            return {"error": "Give a card number, a planned meal or a URL."}
        cache = domain_data.setdefault("recipes", {})
        recipe = cache.get(url) or await async_fetch_recipe(hass, url)
        if not recipe or not recipe["steps"]:
            return {"error": "That page has no recipe steps to show."}
        cache[url] = recipe
        steps = recipe["steps"]
        step = min(max(args.get("step", 1), 1), len(steps))
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "recipe", "screen": screen, "step": step, **recipe})
        return {
            "title": recipe["title"],
            "servings": recipe.get("servings"),
            "ingredients": recipe["ingredients"],
            "step": step,
            "steps": len(steps),
            "text": steps[step - 1],
        }


_MEAL_KEYS = {"pequeno-almoço": "meals.breakfast", "almoço": "meals.lunch", "jantar": "meals.dinner"}


def _meal_slot(hass: HomeAssistant, date: str, meal: str) -> str:
    """"Quinta · jantar"."""
    day = dt_util.parse_date(date)
    name = tr(hass, _MEAL_KEYS.get(meal, "")) if meal in _MEAL_KEYS else meal
    return f"{day_label(hass, day).split(',')[0]} · {name}" if day else f"{date} · {name}"


def add_pending_meals(hass: HomeAssistant, entries: dict[str, dict[str, Any]]) -> str:
    """Replacements waiting for the user's yes, for the screen's "Sim,
    substituir" (bytehomedash/confirm_meals)."""
    pending: dict[str, dict[str, dict[str, Any]]] = hass.data[DOMAIN].setdefault("pending_meals", {})
    token = add_undo(hass, _noop)
    pending[token] = entries
    return token


async def _noop() -> None:
    return None


async def async_confirm_meals(hass: HomeAssistant, token: str, replace: bool) -> None:
    """The screen's answer to a "Substituo?": writes the waiting meals on a yes."""
    entries = hass.data.get(DOMAIN, {}).get("pending_meals", {}).pop(token, None)
    if entries is None:
        raise HomeAssistantError(tr(hass, "meals.nothing_to_confirm"))
    if not replace:
        return
    domain_data = hass.data[DOMAIN]
    data = domain_data["data"]
    data["meal_plan"] = {**(data.get("meal_plan") or {}), **entries}
    await domain_data["store"].async_save(data)
    hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": "meal_plan"})


class KitchenControlTool(llm.Tool):
    name = "kitchen_mode"
    description = (
        "Control the recipe open in cooking mode on the screen (see show_recipe): "
        "minimise it to a bubble, leave it, carry on (after it asked whether to "
        "leave), bring it back from the bubble, or show its ingredients."
    )
    parameters = vol.Schema(
        {vol.Required("action", description="What to do"): vol.In(["minimize", "exit", "continue", "open", "ingredients"])}
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        action = tool_input.tool_args["action"]
        hass.bus.async_fire(EVENT_ASSISTANT, {"action": "kitchen", "screen": _screen(hass, llm_context), "command": action})
        return {"done": action}


class GetMealPlanTool(llm.Tool):
    name = "get_meal_plan"
    description = "What is already planned in the family's meal plan (the screens' Receitas page) for the coming days."
    parameters = vol.Schema({vol.Optional("days", description="How many days from today (default 7)"): vol.All(int, vol.Range(min=1, max=31))})

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        plan = (hass.data.get(DOMAIN, {}).get("data") or {}).get("meal_plan") or {}
        today = dt_util.now().date()
        names = {meal_id: name for name, (meal_id, _) in _MEALS.items()}
        planned = []
        for offset in range(tool_input.tool_args.get("days", 7)):
            day = (today + timedelta(days=offset)).isoformat()
            for meal_id, name in names.items():
                entry = plan.get(f"{day}|{meal_id}")
                if isinstance(entry, dict) and entry.get("dish"):
                    planned.append({"date": day, "meal": name, "dish": entry["dish"], "where": entry.get("where")})
        return {"today": today.isoformat(), "planned": planned}


class PlanMealsTool(llm.Tool):
    name = "plan_meals"
    description = (
        "Put meals in the family's meal plan (the screens' Receitas page), one or "
        "several at once: each one of the cards shown by show_web_results (by "
        "number, keeping its recipe link) or a dish by name. A meal that already "
        "has something planned is NOT changed unless replace is true: the result "
        "lists those under needs_confirmation, and you must ask the user whether "
        "to replace them before calling again with replace true."
    )
    parameters = vol.Schema(
        {
            vol.Required("meals", description="The meals to plan"): [
                vol.Schema(
                    {
                        vol.Required("date", description="The day, YYYY-MM-DD"): str,
                        vol.Required("meal", description="Which meal"): vol.In(list(_MEALS)),
                        vol.Optional("number", description="A card's number from show_web_results"): int,
                        vol.Optional("dish", description="The dish's name, when it isn't a card"): str,
                    }
                )
            ],
            vol.Optional("replace", description="Only after the user confirmed replacing what was planned"): bool,
        }
    )

    async def async_call(self, hass: HomeAssistant, tool_input: llm.ToolInput, llm_context: llm.LLMContext) -> JsonObjectType:
        args = tool_input.tool_args
        domain_data = hass.data.get(DOMAIN, {})
        store, data = domain_data.get("store"), domain_data.get("data")
        if store is None or data is None:
            return {"error": "The ByteHomeDash integration isn't set up."}
        cards = domain_data.get("last_cards", {}).get(_screen(hass, llm_context)) or []
        plan = dict(data.get("meal_plan") or {})
        planned, confirm, errors = [], [], []
        pending: dict[str, dict[str, Any]] = {}
        for item in args["meals"]:
            label = {"date": item["date"], "meal": item["meal"]}
            if dt_util.parse_date(item["date"]) is None:
                errors.append({**label, "error": "date must be YYYY-MM-DD"})
                continue
            entry: dict[str, Any] = {"where": "casa"}
            if (number := item.get("number")) is not None:
                if not 1 <= number <= len(cards):
                    errors.append({**label, "error": f"There is no card {number}; {len(cards)} are shown."})
                    continue
                card = cards[number - 1]
                entry.update({"dish": card.get("title") or "Receita", "url": card["url"]})
                if card.get("image"):
                    entry["image"] = card["image"]
                if card.get("site"):
                    entry["note"] = card["site"]
            elif item.get("dish"):
                entry["dish"] = item["dish"]
            else:
                errors.append({**label, "error": "Give a card number or a dish."})
                continue
            meal_id, default_time = _MEALS[item["meal"]]
            key = f"{item['date']}|{meal_id}"
            before = plan.get(key)
            if isinstance(before, dict) and before.get("dish") and before.get("dish") != entry["dish"] and not args.get("replace"):
                confirm.append({**label, "planned_now": before["dish"], "new": entry["dish"]})
                pending[key] = {**entry, "time": before.get("time") or default_time}
                continue
            entry["time"] = (before or {}).get("time") or default_time
            plan[key] = entry
            planned.append({**label, "dish": entry["dish"]})
        if planned:
            data["meal_plan"] = plan
            await store.async_save(data)
            hass.bus.async_fire(EVENT_SETTINGS_UPDATED, {"key": "meal_plan"})
        result: dict[str, Any] = {"planned": planned}
        screen = _screen(hass, llm_context)
        if args.get("replace"):
            # Answered by voice: the screen's open questions are settled.
            hass.bus.async_fire(EVENT_ASSISTANT, {"action": "result_answer", "screen": screen, "answer": "sim"})
        if planned:
            first = planned[0]
            show_result(
                hass,
                llm_context,
                {
                    "kind": "meals",
                    "title": first["dish"] if len(planned) == 1 else tr(hass, "meals.planned", count=len(planned)),
                    "state": f"{tr(hass, 'meals.section')} · {_meal_slot(hass, first['date'], first['meal'])}"
                    if len(planned) == 1
                    else f"{tr(hass, 'meals.section')} · " + ", ".join(_meal_slot(hass, p["date"], p["meal"]) for p in planned[:4]),
                    "chips": [p["dish"] for p in planned] if len(planned) > 1 else [],
                },
            )
        if confirm:
            token = add_pending_meals(hass, pending)
            one = confirm[0]
            show_result(
                hass,
                llm_context,
                {
                    "kind": "meal_question",
                    "title": _meal_slot(hass, one["date"], one["meal"]) if len(confirm) == 1 else tr(hass, "meals.already_planned", count=len(confirm)),
                    "state": tr(hass, "meals.now", old=one["planned_now"], new=one["new"])
                    if len(confirm) == 1
                    else "; ".join(f"{_meal_slot(hass, c['date'], c['meal'])}: {c['planned_now']} → {c['new']}" for c in confirm),
                    "confirm": token,
                    "yes_text": tr(hass, "meals.replaced", count=len(confirm), dish=one["new"], slot=_meal_slot(hass, one["date"], one["meal"]).lower()),
                    "no_text": tr(hass, "meals.kept", count=len(confirm), dish=one["planned_now"]),
                },
            )
            result["needs_confirmation"] = confirm
            result["note"] = "These already had a meal and were left as they are. Ask the user whether to replace them."
        if errors:
            result["errors"] = errors
        return result


def _speaker_prompt(hass: HomeAssistant, speaker: dict[str, Any] | None) -> str:
    """This turn's speaker, for the agent: who, and which personal data is
    theirs (configured per person in the panel, "Pessoas") — or that nobody
    was recognised. Empty when nothing is known (speaker id off, typed)."""
    if speaker is None:
        return ""
    caution = (
        " Voice recognition is a similarity match, not authentication: never use it to unlock, "
        "open, disarm or buy anything, or to reveal anything sensitive."
    )
    if not speaker.get("identified"):
        return (
            " The speaker's voice wasn't recognised. Don't assume who it is and don't use anyone's "
            "personal calendar, reminders or tasks; if they ask for \"my\" calendar or tasks, say you "
            "didn't recognise their voice and they can try again closer to the screen." + caution
        )
    sid = speaker["speaker_id"]
    member = member_for_speaker(hass, sid)
    score = f" (match score {speaker['score']:.2f})" if speaker.get("score") is not None else ""
    if member is None:
        return f" The speaker was recognised by voice as \"{sid}\"{score}, but no personal settings are configured for them." + caution
    personal = []
    if member.get("calendarEntityId"):
        personal.append(f"their calendar is {member['calendarEntityId']}")
    if member.get("todoEntityId"):
        personal.append(f"their to-do list / reminders are {member['todoEntityId']}")
    mine = f" When they say \"my\"/\"meu\"/\"minha\": {'; '.join(personal)}." if personal else ""
    return f" The speaker was recognised by voice as {member.get('name') or sid}{score}.{mine} You may address them by name." + caution


def _summary(card: dict[str, Any]) -> dict[str, Any]:
    keys = ("title", "site", "kind", "rating", "rating_count", "minutes", "price", "currency", "cuisine", "price_range", "address", "section", "duration", "channel", "servings")
    return {k: card.get(k) for k in keys}


class ByteHomeDashAPI(llm.API):
    def __init__(self, hass: HomeAssistant) -> None:
        super().__init__(hass=hass, id=DOMAIN, name="ByteHomeDash")

    async def async_get_api_instance(self, llm_context: llm.LLMContext) -> llm.APIInstance:
        today = dt_util.now().date()
        speaker = _speaker_prompt(self.hass, await async_speaker_for(self.hass, llm_context.device_id))
        return llm.APIInstance(
            api=self,
            api_prompt=f"{_PROMPT} Today is {_WEEKDAYS[today.weekday()]}, {today.isoformat()}.{speaker}",
            llm_context=llm_context,
            tools=[
                ShowWebResultsTool(),
                OpenResultTool(),
                SendToPhoneTool(),
                GetMealPlanTool(),
                PlanMealsTool(),
                GetMealIngredientsTool(),
                ShowRecipeTool(),
                KitchenControlTool(),
                CreateCalendarEventTool(),
                GetChoresTool(),
                AddChoreTool(),
                CompleteChoreTool(),
                LeaveMessageTool(),
                MarkMessagesSeenTool(),
                GetDoorbellCallsTool(),
                ShowOnScreenTool(),
            ],
        )


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/undo", vol.Required("token"): cv.string})
@websocket_api.async_response
async def websocket_undo(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """The Assistente's "Desfazer" on a tool's result (an event, a task)."""
    undo = hass.data.get(DOMAIN, {}).get("undo", {}).pop(msg["token"], None)
    if undo is None:
        connection.send_error(msg["id"], "expired", tr(hass, "undo.expired"))
        return
    try:
        await undo()
    except HomeAssistantError as err:
        connection.send_error(msg["id"], "failed", str(err))
        return
    connection.send_result(msg["id"])


@websocket_api.websocket_command(
    {vol.Required("type"): "bytehomedash/confirm_meals", vol.Required("token"): cv.string, vol.Required("replace"): bool}
)
@websocket_api.async_response
async def websocket_confirm_meals(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """The Assistente's "Sim, substituir" / "Não" on plan_meals' question."""
    try:
        await async_confirm_meals(hass, msg["token"], msg["replace"])
    except HomeAssistantError as err:
        connection.send_error(msg["id"], "failed", str(err))
        return
    connection.send_result(msg["id"])


@websocket_api.websocket_command({vol.Required("type"): "bytehomedash/get_recipe", vol.Required("url"): cv.string})
@websocket_api.async_response
async def websocket_get_recipe(hass: HomeAssistant, connection: websocket_api.ActiveConnection, msg: dict) -> None:
    """A recipe page's title, ingredients and steps, for the screen's Modo
    cozinha opened by touch (a planned meal's "Modo cozinhar")."""
    cache = hass.data[DOMAIN].setdefault("recipes", {})
    recipe = cache.get(msg["url"]) or await async_fetch_recipe(hass, msg["url"])
    if not recipe or not recipe["steps"]:
        connection.send_error(msg["id"], "no_recipe", tr(hass, "recipe.no_steps"))
        return
    cache[msg["url"]] = recipe
    connection.send_result(msg["id"], {**recipe, "step": 1})
