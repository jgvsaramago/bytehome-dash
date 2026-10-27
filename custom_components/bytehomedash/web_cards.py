"""Web pages as cards, for the screens' Assistente.

The conversation agent finds pages itself (its web search); this only turns
the URLs it picked into cards with real data: each page is fetched and the
data sites publish for search engines is read — schema.org JSON-LD (a
recipe's name, image, rating, rating count and time; a product's price; an
article's date; a place's address), else its Open Graph preview (title,
image, description). Nothing on a card is written by the agent.
"""
from __future__ import annotations

import asyncio
import html
import json
import re
from typing import Any
from urllib.parse import urljoin, urlparse

import aiohttp

from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession

_FETCH_TIMEOUT = aiohttp.ClientTimeout(total=8)
_MAX_BYTES = 1_500_000
_MAX_CARDS = 8

# Many sites answer an unknown client with a bot page; a browser's identity
# gets the page a person would see.
_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/124.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml",
    "Accept-Language": "pt-PT,pt;q=0.9,en;q=0.8",
}

_LD_JSON = re.compile(
    r'<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>',
    re.IGNORECASE | re.DOTALL,
)
_META = re.compile(r"<meta\s[^>]*>", re.IGNORECASE)
_ATTR = re.compile(r'([a-zA-Z:_-]+)\s*=\s*("([^"]*)"|\'([^\']*)\')')
_TITLE = re.compile(r"<title[^>]*>(.*?)</title>", re.IGNORECASE | re.DOTALL)

# schema.org types worth a card, most specific first.
_KINDS = {
    "Recipe": "recipe",
    "Product": "product",
    "NewsArticle": "news",
    "Article": "article",
    "BlogPosting": "article",
    "Restaurant": "place",
    "LocalBusiness": "place",
    "Place": "place",
    "VideoObject": "video",
}


async def async_fetch_cards(hass: HomeAssistant, urls: list[str]) -> list[dict[str, Any]]:
    """Cards for [urls], in order, skipping pages that couldn't be read."""
    session = async_get_clientsession(hass)
    unique = list(dict.fromkeys(u for u in urls if u.startswith(("http://", "https://"))))[:_MAX_CARDS]
    cards = await asyncio.gather(*(_card(session, u) for u in unique))
    return _ranked([c for c in cards if c is not None])


async def async_fetch_recipe(hass: HomeAssistant, url: str) -> dict[str, Any] | None:
    """A recipe page's own data (schema.org Recipe): title, ingredients and
    steps, as the site wrote them. None if the page has no recipe data."""
    page = await _page(async_get_clientsession(hass), url)
    if page is None:
        return None
    for block in _LD_JSON.findall(page[0]):
        data = _json(block.strip())
        for node in _nodes(data) if data is not None else ():
            types = node.get("@type")
            if "Recipe" not in (types if isinstance(types, list) else [types]):
                continue
            ingredients = [_clean(i) for i in node.get("recipeIngredient") or node.get("ingredients") or [] if isinstance(i, str)]
            steps = [_clean(t) for t in _steps(node.get("recipeInstructions"))]
            return {
                "url": page[1],
                "title": _clean(node.get("name") or ""),
                "image": _image(node.get("image")),
                "minutes": _minutes(node.get("totalTime") or node.get("cookTime")),
                "servings": _clean(str(_first(node["recipeYield"]) if isinstance(node.get("recipeYield"), list) else node.get("recipeYield") or "")) or None,
                "ingredients": [i for i in ingredients if i],
                "steps": [t for t in steps if t],
            }
    return None


def _steps(value: Any) -> list[str]:
    """recipeInstructions as plain steps: text, a list of texts, HowToStep
    objects, or HowToSections of them."""
    if isinstance(value, str):
        parts = [p for p in re.split(r"\n+|<br\s*/?>|</p>|</li>", value) if _clean(p)]
        return parts
    if isinstance(value, list):
        return [step for item in value for step in _steps(item)]
    if isinstance(value, dict):
        if "itemListElement" in value:
            return _steps(value["itemListElement"])
        return _steps(value.get("text") or value.get("name") or "")
    return []


async def _page(session: aiohttp.ClientSession, url: str) -> tuple[str, str] | None:
    """The page's HTML (up to _MAX_BYTES) and its final URL."""
    try:
        async with session.get(url, headers=_HEADERS, timeout=_FETCH_TIMEOUT, allow_redirects=True) as res:
            if res.status != 200 or "html" not in res.headers.get("Content-Type", "html"):
                return None
            # read(n) returns what has arrived so far, not the whole page.
            raw = b""
            async for chunk in res.content.iter_chunked(65536):
                raw += chunk
                if len(raw) >= _MAX_BYTES:
                    break
            return raw.decode("utf-8", errors="replace"), str(res.url)
    except (aiohttp.ClientError, asyncio.TimeoutError, ValueError):
        return None


async def _card(session: aiohttp.ClientSession, url: str) -> dict[str, Any] | None:
    fetched = await _page(session, url)
    if fetched is None:
        return None
    page, final_url = fetched
    return _card_from(page, final_url)


def _card_from(page: str, final_url: str) -> dict[str, Any] | None:
    card = _from_json_ld(page, final_url) or {}
    meta = _meta(page)
    if "kind" not in card:
        # No JSON-LD (YouTube, for one): its video meta tags still say what it is.
        if meta.get("og:type", "").startswith("video"):
            card["kind"] = "video"
            card["duration"] = _seconds(meta.get("duration"))
            card["channel"] = meta.get("author") or meta.get("og:video:director")
        elif meta.get("og:type") == "article" and meta.get("article:published_time"):
            card["kind"] = "article"
            card["date"] = meta.get("article:published_time")
            card["section"] = meta.get("article:section")
        else:
            card["kind"] = "page"
    card = {k: v for k, v in card.items() if v is not None}
    card["url"] = final_url
    card["title"] = card.get("title") or meta.get("og:title") or _first(_TITLE.findall(page))
    card["image"] = card.get("image") or meta.get("og:image") or meta.get("twitter:image")
    card["description"] = card.get("description") or meta.get("og:description") or meta.get("description")
    card["site"] = meta.get("og:site_name") or urlparse(final_url).hostname.removeprefix("www.")
    if card.get("image"):
        card["image"] = urljoin(final_url, card["image"])
    for key in ("title", "description", "site", "section", "channel"):
        if card.get(key):
            card[key] = _clean(card[key])
    if card.get("description"):
        card["description"] = card["description"][:180]
    return card if card.get("title") else None


def _from_json_ld(page: str, url: str) -> dict[str, Any] | None:
    best: tuple[int, dict] | None = None
    for block in _LD_JSON.findall(page):
        data = _json(block.strip())
        if data is None:
            continue
        for node in _nodes(data):
            types = node.get("@type")
            types = types if isinstance(types, list) else [types]
            for rank, (schema, kind) in enumerate(_KINDS.items()):
                if schema in types and (best is None or rank < best[0]):
                    best = (rank, {"kind": kind, **_fields(node, kind)})
    return best[1] if best else None


def _json(text: str) -> Any:
    """JSON-LD as written; a few sites HTML-escape the whole block."""
    for candidate in (text, html.unescape(text)):
        try:
            return json.loads(candidate)
        except ValueError:
            continue
    return None


def _nodes(data: Any):
    """Every object in a JSON-LD document, through @graph and lists."""
    if isinstance(data, list):
        for item in data:
            yield from _nodes(item)
    elif isinstance(data, dict):
        yield data
        for key in ("@graph", "mainEntity", "itemListElement"):
            if key in data:
                yield from _nodes(data[key])


def _fields(node: dict, kind: str) -> dict[str, Any]:
    out: dict[str, Any] = {
        "title": node.get("name") or node.get("headline"),
        "image": _image(node.get("image") or node.get("thumbnailUrl")),
        "description": node.get("description") if isinstance(node.get("description"), str) else None,
    }
    rating = node.get("aggregateRating")
    if isinstance(rating, dict):
        value, count = _number(rating.get("ratingValue")), _number(rating.get("ratingCount") or rating.get("reviewCount"))
        best = _number(rating.get("bestRating")) or 5
        if value is not None:
            out["rating"] = round(value * 5 / best, 1) if best and best != 5 else value
            out["rating_count"] = int(count) if count is not None else None
    if kind == "recipe":
        out["minutes"] = _minutes(node.get("totalTime") or node.get("cookTime"))
        servings = node.get("recipeYield")
        servings = servings[0] if isinstance(servings, list) and servings else servings
        if isinstance(servings, (str, int, float)) and str(servings).strip():
            out["servings"] = _clean(str(servings))
    elif kind == "product":
        offer = node.get("offers")
        offer = offer[0] if isinstance(offer, list) and offer else offer
        if isinstance(offer, dict):
            price = _number(offer.get("price") or offer.get("lowPrice"))
            if price is not None:
                out["price"] = price
                out["currency"] = offer.get("priceCurrency")
    elif kind in ("article", "news"):
        out["date"] = node.get("datePublished")
        section = node.get("articleSection")
        section = section[0] if isinstance(section, list) and section else section
        if isinstance(section, str) and section:
            out["section"] = section
    elif kind == "video":
        out["duration"] = _seconds(node.get("duration"))
        out["date"] = node.get("uploadDate")
        author = node.get("author") or node.get("creator")
        author = author[0] if isinstance(author, list) and author else author
        out["channel"] = author.get("name") if isinstance(author, dict) else author if isinstance(author, str) else None
        out["views"] = _views(node.get("interactionStatistic"))
    elif kind == "place":
        address = node.get("address")
        if isinstance(address, dict):
            out["address"] = ", ".join(str(address[k]) for k in ("streetAddress", "addressLocality") if address.get(k))
        elif isinstance(address, str):
            out["address"] = address
        cuisine = node.get("servesCuisine")
        if isinstance(cuisine, list):
            cuisine = ", ".join(str(c) for c in cuisine[:2])
        if isinstance(cuisine, str) and cuisine:
            out["cuisine"] = cuisine
        if isinstance(node.get("priceRange"), str):
            out["price_range"] = node["priceRange"]
    return {k: v for k, v in out.items() if v is not None}


def _ranked(cards: list[dict]) -> list[dict]:
    """Recipes with ratings first, by rating weighted by how many people
    rated (a 4.8 from 2,000 beats a 5.0 from 3); otherwise the agent's order."""

    def score(card: dict) -> float:
        rating, count = card.get("rating"), card.get("rating_count") or 0
        if rating is None:
            return -1
        prior, weight = 4.0, 10
        return (rating * count + prior * weight) / (count + weight)

    if sum(1 for c in cards if c.get("rating") is not None) >= 2:
        return sorted(cards, key=score, reverse=True)
    return cards


def _meta(page: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for tag in _META.findall(page[:300_000]):
        attrs = {m.group(1).lower(): m.group(3) if m.group(3) is not None else m.group(4) for m in _ATTR.finditer(tag)}
        key = attrs.get("property") or attrs.get("name") or attrs.get("itemprop")
        if key and attrs.get("content") and key.lower() not in out:
            out[key.lower()] = attrs["content"]
    return out


def _image(value: Any) -> str | None:
    if isinstance(value, str):
        return value
    if isinstance(value, list) and value:
        return _image(value[0])
    if isinstance(value, dict):
        return value.get("url") or value.get("contentUrl")
    return None


def _number(value: Any) -> float | None:
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.replace(",", "."))
        except ValueError:
            return None
    return None


def _minutes(value: Any) -> int | None:
    """ISO 8601 duration (PT1H30M) to minutes."""
    if not isinstance(value, str):
        return None
    m = re.fullmatch(r"P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:\d+S)?", value.strip())
    if not m or not any(m.groups()):
        return None
    days, hours, minutes = (int(g or 0) for g in m.groups())
    return days * 1440 + hours * 60 + minutes or None


def _seconds(value: Any) -> int | None:
    """ISO 8601 duration (PT8M42S) to seconds."""
    if not isinstance(value, str):
        return None
    m = re.fullmatch(r"P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)(?:\.\d+)?S)?", value.strip())
    if not m or not any(m.groups()):
        return None
    days, hours, minutes, seconds = (int(g or 0) for g in m.groups())
    return ((days * 24 + hours) * 60 + minutes) * 60 + seconds or None


def _views(value: Any) -> int | None:
    """A video's view count, from its interactionStatistic."""
    for stat in value if isinstance(value, list) else [value]:
        if isinstance(stat, dict) and "Watch" in str(stat.get("interactionType")):
            count = _number(stat.get("userInteractionCount"))
            return int(count) if count is not None else None
    return None


def _clean(text: str) -> str:
    return re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", "", str(text)))).strip()


def _first(values: list[str]) -> str | None:
    return values[0] if values else None
