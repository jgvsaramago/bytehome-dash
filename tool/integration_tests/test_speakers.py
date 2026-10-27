"""Checks the integration's speaker handling without Home Assistant installed.

Run: python tool/integration_tests/test_speakers.py custom_components/bytehomedash
(needs voluptuous). Stands in for the few HA pieces speakers.py/llm_api.py use.
"""
from pathlib import Path
root = Path(sys.argv[1])
# --- minimal homeassistant stand-ins -------------------------------------
def mod(name, **attrs):
    m = types.ModuleType(name); m.__dict__.update(attrs); sys.modules[name] = m; return m
class Event:
    def __init__(self, data): self.data = data
class Bus:
    def __init__(self): self.handlers = {}; self.fired = []
    def async_listen(self, t, h): self.handlers.setdefault(t, []).append(h)
    def async_fire(self, t, d): self.fired.append((t, d)); [h(Event(d)) for h in self.handlers.get(t, [])]
class Hass:
    def __init__(self): self.data = {}; self.bus = Bus()
mod("homeassistant"); mod("homeassistant.core", Event=Event, HomeAssistant=Hass, callback=lambda f: f)
class Tool: pass
class API:
    def __init__(self, hass, id, name): self.hass = hass
class APIInstance:
    def __init__(self, **kw): self.__dict__.update(kw)
llm = types.SimpleNamespace(Tool=Tool, API=API, APIInstance=APIInstance, LLMContext=object, ToolInput=object)
mod("homeassistant.helpers", llm=llm, device_registry=types.SimpleNamespace())
mod("homeassistant.helpers.aiohttp_client", async_get_clientsession=None)
import datetime
mod("homeassistant.util", dt=types.SimpleNamespace(now=datetime.datetime.now, parse_date=lambda s: datetime.date.fromisoformat(s)))
mod("homeassistant.util.json", JsonObjectType=dict)
pkg = mod("bhd"); pkg.__path__ = [str(root)]
def load(name):
    spec = importlib.util.spec_from_file_location(f"bhd.{name}", root / f"{name}.py"); m = importlib.util.module_from_spec(spec); sys.modules[f"bhd.{name}"] = m; spec.loader.exec_module(m); return m
const = load("const"); speakers = load("speakers")
mod("aiohttp", ClientTimeout=lambda **k: None, ClientSession=object, ClientError=Exception)
load("web_cards"); llm_api = load("llm_api")

async def main():
    hass = Hass(); hass.data["bhd"] = {}
    const.DOMAIN = "bhd"; speakers.DOMAIN = "bhd"; llm_api.DOMAIN = "bhd"
    speakers.async_setup_speakers(hass)
    fire = lambda d: hass.bus.async_fire("esphome.lva_speaker", d)
    # pending then done, other satellite isolated
    fire({"device_id": "sat1", "run": "1", "status": "pending"})
    fire({"device_id": "sat2", "run": "5", "status": "pending"})
    async def later(): await asyncio.sleep(0.2); fire({"device_id": "sat1", "run": "1", "status": "done", "speaker_id": "ana", "identified": "true", "score": "0.81"})
    asyncio.create_task(later())
    t = time.monotonic(); r = await speakers.async_speaker_for(hass, "sat1")
    assert r["speaker_id"] == "ana" and r["identified"] and abs(r["score"] - 0.81) < 1e-9 and time.monotonic() - t < 1, r
    speakers._WAIT = 0.3
    assert await speakers.async_speaker_for(hass, "sat2") is None          # never finished: gives up, generic
    assert await speakers.async_speaker_for(hass, None) is None             # typed request
    assert await speakers.async_speaker_for(hass, "sat3") is None           # speaker id off on that satellite
    fire({"device_id": "sat1", "run": "2", "status": "pending"})            # next run clears the old result
    assert await speakers.async_speaker_for(hass, "sat1") is None
    speakers._FRESH = 0.0
    fire({"device_id": "sat1", "run": "3", "status": "done", "speaker_id": "ana", "identified": "true", "score": "0.8"})
    await asyncio.sleep(0.01)
    assert await speakers.async_speaker_for(hass, "sat1") is None           # stale
    # prompts
    hass.data["bhd"]["data"] = {"family_members": [{"name": "Ana", "speakerId": "ana", "calendarEntityId": "calendar.ana", "todoEntityId": "todo.ana"}]}
    p = llm_api._speaker_prompt(hass, {"speaker_id": "ana", "identified": True, "score": 0.81})
    assert "Ana" in p and "calendar.ana" in p and "todo.ana" in p and "not authentication" in p, p
    p = llm_api._speaker_prompt(hass, {"speaker_id": "ana", "identified": True, "score": 0.7})
    assert "no personal settings" in p and "calendar.ana" not in p, p
    p = llm_api._speaker_prompt(hass, {"speaker_id": None, "identified": False, "score": 0.2})
    assert "wasn't recognised" in p and "calendar.ana" not in p, p
    assert llm_api._speaker_prompt(hass, None) == ""
    print("integration speaker tests: all passed")
asyncio.run(main())
