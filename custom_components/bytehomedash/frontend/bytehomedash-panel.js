// "ByteHomeDash" sidebar panel: maps the kiosk screen onto this
// house's entities. Design: the "Painel HA" board of the kiosk redesign.
//
// Talks to the integration's websocket commands (see
// custom_components/bytehomedash/__init__.py): `get_settings` /
// `set_settings` for the data, `list_screens` for the "screen connected"
// card. Saved changes reach connected screens live. No build step, no
// dependencies; colours come from HA's own theme variables, so it follows
// the user's light/dark theme.
//
// Only what maps the kiosk onto entities lives here; the screen's own
// settings (brightness, restart) are on the screen, and meals, tasks and
// list icons are edited from the screen.

(() => {
  "use strict";

  const DOMAIN = "bytehomedash";
  // Which values the integration chose on its own (see suggest.py).
  const AUTO_KEY = "auto_choices";

  // ---------- Texts ----------
  // i18n/<language>.json next to this file: nested JSON (i18next style),
  // `{name}` placeholders, plurals as `<key>_one` / `<key>_other` (or any
  // other CLDR category) picked by `count`. English is the source and the
  // fallback for anything missing.
  const HERE = new URL(import.meta.url);
  // The module's own `?v=` fingerprint (see panel.py), so an update isn't
  // hidden by the browser cache.
  const VERSION = HERE.searchParams.get("v");
  let TEXTS = {};
  let EN = {};
  let LOCALE = "en";

  const lookup = (dict, key) => key.split(".").reduce((o, part) => (o && typeof o === "object" ? o[part] : undefined), dict);
  const found = (key) => typeof lookup(TEXTS, key) === "string" || typeof lookup(EN, key) === "string";

  // t("people.count", { count: 2 }) -> "2 people". `fallback` is returned
  // when neither language has the key (default: the key itself).
  function t(key, params, fallback) {
    let k = key;
    if (params && typeof params.count === "number") {
      let cat = "other";
      try {
        cat = new Intl.PluralRules(LOCALE).select(params.count);
      } catch (_) {}
      k = [`${key}_${cat}`, `${key}_other`].find(found) || key;
    }
    let s = lookup(TEXTS, k);
    if (typeof s !== "string") s = lookup(EN, k);
    if (typeof s !== "string") return fallback === undefined ? key : fallback;
    return params ? s.replace(/\{(\w+)\}/g, (m, n) => (params[n] === undefined || params[n] === null ? m : String(params[n]))) : s;
  }

  // HA's UI language: "pt", "en-GB"…
  const hassLanguage = (hass) => (hass && (hass.locale?.language || hass.language)) || "en";

  async function fetchTexts(code) {
    const res = await fetch(new URL(`i18n/${code}.json${VERSION ? `?v=${VERSION}` : ""}`, HERE));
    if (!res.ok) throw new Error(`${res.status}`);
    return res.json();
  }

  // English, and the language's own file when there is one.
  async function fetchLanguage(language) {
    const code = language.split("-")[0].toLowerCase();
    const en = await fetchTexts("en").catch(() => ({}));
    const own = code === "en" ? en : await fetchTexts(code).catch(() => null);
    return { en, own };
  }

  function applyTexts(language, { en, own }) {
    EN = en;
    TEXTS = own || en;
    // HA's "pt" is European Portuguese (Intl's bare "pt" is Brazilian).
    LOCALE = !own ? "en" : language === "pt" ? "pt-PT" : language;
    SUBS = buildSubs();
    SECTIONS = buildSections();
  }

  // ---------- Icons (24×24 stroke paths) ----------
  const I = {
    cal: "M4 6h16v14H4zM4 10h16M8 3v4M16 3v4",
    people: "M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2.5 20c.5-3.5 3.2-5.5 6.5-5.5s6 2 6.5 5.5M16 4.5a3.5 3.5 0 0 1 0 6.5M18.5 14.8c1.7.8 2.8 2.6 3 5.2",
    weather: "M7 18h10a4 4 0 0 0 .6-7.95A6 6 0 0 0 6.2 9.1 4.5 4.5 0 0 0 7 18z",
    thermo: "M10 4a2 2 0 1 1 4 0v10.2a4 4 0 1 1-4 0zM12 9v7",
    rooms: "M3 3h18v18H3zM3 12h8v9M11 3v5M15 12h6",
    home: "M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z",
    flash: "M13 2L4 14h7l-1 8 9-12h-7z",
    car: "M5 17v-6l2.2-5h9.6l2.2 5v6M3 11h18v6H3zM7 14h.01M17 14h.01M6 17v2M18 17v2",
    fuel: "M4 21V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v16M3 21h13M4 10h11M15 8l3 3v7a1.5 1.5 0 0 0 3 0V9l-3-3",
    light: "M9 18h6M10 21h4M12 3a6 6 0 0 0-3.5 10.9c.6.5 1 1.2 1 2.1h5c0-.9.4-1.6 1-2.1A6 6 0 0 0 12 3z",
    climate: "M12 2v20M4.9 7l14.2 10M4.9 17L19.1 7M9 4l3 2 3-2M9 20l3-2 3 2",
    window: "M5 3h14v18H5zM12 3v18M5 12h14",
    cover: "M4 4h16M5 4v16M19 4v16M5 8h14M5 12h14M5 16h14",
    lock: "M6 11h12v10H6zM8.5 11V7.5a3.5 3.5 0 0 1 7 0V11",
    alarm: "M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z",
    scene: "M12 3l1.8 4.7 4.7 1.8-4.7 1.8L12 16l-1.8-4.7-4.7-1.8 4.7-1.8zM19 15l.8 2.2 2.2.8-2.2.8L19 21l-.8-2.2-2.2-.8 2.2-.8z",
    camera: "M3 7h11v10H3zM14 10.5l7-3.5v10l-7-3.5",
    battery: "M7 5h10v16H7zM10 2h4v3M10 12h4",
    gauge: "M4 18a8 8 0 1 1 16 0M12 18l4-6",
    plug: "M9 2v5M15 2v5M6 7h12v4a6 6 0 0 1-12 0zM12 17v5",
    toggle: "M8 7h8a5 5 0 0 1 0 10H8A5 5 0 0 1 8 7zM8 9.5a2.5 2.5 0 1 0 0 5 2.5 2.5 0 0 0 0-5",
    script: "M8 4h11v13a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3v-1h11v1M8 4a2 2 0 0 0-2 2v10M11 8h5M11 12h5",
    fridge: "M6 2h12v20H6zM6 9h12M9 5v2M9 12v3",
    tv: "M3 6h18v12H3zM8 21h8",
    washer: "M4 2h16v20H4zM4 7h16M12 18a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM7 4.5h.01M10 4.5h.01",
    oven: "M3 3h18v18H3zM3 8h18M7 5.5h.01M11 5.5h.01M7 12h10v6H7z",
    heatpump: "M3 4h18v12H3zM12 7a3 3 0 1 0 0 6 3 3 0 0 0 0-6M12 10V7M7 19v2M17 19v2",
    socket: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM9 9v3M15 9v3M9 16h6",
    check: "M5 12.5l4.5 4.5L19 7.5",
    alert: "M12 3l10 18H2zM12 10v5M12 18h.01",
    info: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM12 11v6M12 7.5h.01",
    dot: "M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6z",
    plus: "M12 5v14M5 12h14",
    block: "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20zM5 5l14 14",
    screen: "M5 2h14v20H5zM11 18h2",
    menu: "M4 6h16M4 12h16M4 18h16",
    back: "M19 12H5M11 6l-6 6 6 6",
    chevronDown: "M6 9l6 6 6-6",
    chevronRight: "M9 6l6 6-6 6",
    up: "M12 19V5M6 11l6-6 6 6",
    down: "M12 5v14M18 13l-6 6-6-6",
    trash: "M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3",
    close: "M6 6l12 12M18 6L6 18",
    search: "M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4",
    mic: "M9 3h6v11H9zM5 11a7 7 0 0 0 14 0M12 18v3",
    grip: "M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01",
    vacuum: "M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 6.5a2 2 0 1 0 0 4 2 2 0 0 0 0-4zM7.5 15.5h9",
  };

  // The kiosk's person palette (KPersonColor), by the key stored in HA.
  // An older saved "red" is drawn pink on the screen, so it shows as pink.
  const COLORS = [
    { key: "blue", get name() { return t("colors.blue"); }, hex: "#1864AB" },
    { key: "amber", get name() { return t("colors.amber"); }, hex: "#C2410C" },
    { key: "green", get name() { return t("colors.green"); }, hex: "#2B8A3E" },
    { key: "accent", get name() { return t("colors.accent"); }, hex: "#5F3DC4" },
    { key: "pink", get name() { return t("colors.pink"); }, hex: "#C2255C" },
  ];
  const HOLIDAY_RED = "#B42318";
  const colorIndex = (key, fallback) => {
    if (key === "red") return 4;
    const i = COLORS.findIndex((c) => c.key === key);
    return i >= 0 ? i : fallback;
  };
  // Same test the screen uses to draw a calendar as holidays.
  const isHoliday = (text) => /feriado|holiday/i.test(text || "");

  // IndividualSensorIconKey on the screen side.
  const APPLIANCES = [
    { key: "boiler", get name() { return t("appliances.boiler"); }, icon: I.heatpump },
    { key: "fridge", get name() { return t("appliances.fridge"); }, icon: I.fridge },
    { key: "tv", get name() { return t("appliances.tv"); }, icon: I.tv },
    { key: "washer", get name() { return t("appliances.washer"); }, icon: I.washer },
    { key: "oven", get name() { return t("appliances.oven"); }, icon: I.oven },
    { key: "plug", get name() { return t("appliances.plug"); }, icon: I.socket },
  ];

  // The car types (CarKind on the screen side).
  const CAR_KINDS = [
    { key: "electric", get name() { return t("cars.kinds.electric"); }, icon: I.flash },
    { key: "fuel", get name() { return t("cars.kinds.fuel"); }, icon: I.fuel },
  ];

  // ---------- What each sub-section edits, and where it's stored ----------
  // Built once the texts are loaded (and again if the language changes).
  let SUBS = {};
  const buildSubs = () => ({
    pessoas: {
      type: "list", store: "family_members", ns: "people", title: t("people.title"), req: "name", add: t("people.add"),
      blank: () => ({ name: "", color: null, calendarEntityId: "", todoEntityId: "", speakerId: "", personEntityId: "" }),
      empty: t("people.empty"),
      fields: [
        { k: "name", t: "text", label: t("people.fields.name.label"), req: true, ph: t("people.fields.name.ph") },
        { k: "calendarEntityId", t: "entity", dom: ["calendar"], label: t("people.fields.calendarEntityId.label"), opt: true, help: t("people.fields.calendarEntityId.help") },
        { k: "todoEntityId", t: "entity", dom: ["todo"], label: t("people.fields.todoEntityId.label"), opt: true, help: t("people.fields.todoEntityId.help") },
        { k: "speakerId", t: "text", label: t("people.fields.speakerId.label"), opt: true, ph: t("people.fields.speakerId.ph"), help: t("people.fields.speakerId.help") },
        { k: "personEntityId", t: "entity", dom: ["person"], label: t("people.fields.personEntityId.label"), opt: true, help: t("people.fields.personEntityId.help") },
        { k: "color", t: "color", label: t("people.fields.color.label"), full: true, help: t("people.fields.color.help") },
      ],
    },
    outros: {
      type: "list", store: "calendar_entities", ns: "calendars", title: t("calendars.title"), req: "entityId", add: t("calendars.add"),
      blank: () => ({ entityId: "", color: "green" }),
      hint: t("calendars.hint"),
      empty: t("calendars.empty"),
      fields: [
        { k: "entityId", t: "entity", dom: ["calendar"], label: t("calendars.fields.entityId.label"), req: true },
        { k: "color", t: "color", label: t("calendars.fields.color.label") },
      ],
    },
    meteo: {
      type: "form", store: "temperature_entities", ns: "weather", title: t("weather.title"),
      fields: [
        { k: "exteriorTempEntityId", t: "entity", dom: ["sensor"], label: t("weather.fields.exteriorTempEntityId.label"), req: true, help: t("weather.fields.exteriorTempEntityId.help") },
        { k: "weatherStateEntityId", t: "entity", dom: ["weather"], label: t("weather.fields.weatherStateEntityId.label"), req: true, help: t("weather.fields.weatherStateEntityId.help") },
        { k: "sunEntityId", t: "entity", dom: ["sun"], label: t("weather.fields.sunEntityId.label"), opt: true, help: t("weather.fields.sunEntityId.help") },
        { k: "warningEntityId", t: "entity", dom: ["sensor"], label: t("weather.fields.warningEntityId.label"), opt: true, help: t("weather.fields.warningEntityId.help") },
        { k: "fireRiskEntityId", t: "entity", dom: ["sensor"], label: t("weather.fields.fireRiskEntityId.label"), opt: true },
        { k: "uvEntityId", t: "entity", dom: ["sensor"], label: t("weather.fields.uvEntityId.label"), opt: true },
      ],
    },
    assistente: {
      type: "form", store: "assistant", ns: "assistant", title: t("assistant.title"),
      fields: [
        { k: "name", t: "text", label: t("assistant.fields.name.label"), ph: t("assistant.fields.name.ph"), help: t("assistant.fields.name.help") },
        { k: "wakePhrase", t: "text", label: t("assistant.fields.wakePhrase.label"), ph: t("assistant.fields.wakePhrase.ph"), help: t("assistant.fields.wakePhrase.help") },
      ],
    },
    estacao: {
      type: "form", store: "weather_station", ns: "weather_station", title: t("weather_station.title"),
      hint: t("weather_station.hint"),
      fields: [
        { k: "feels", t: "entity", dom: ["sensor"], label: t("weather_station.fields.feels.label"), opt: true },
        { k: "dewPoint", t: "entity", dom: ["sensor"], label: t("weather_station.fields.dewPoint.label"), opt: true },
        { k: "humidity", t: "entity", dom: ["sensor"], label: t("weather_station.fields.humidity.label"), opt: true },
        { k: "pressure", t: "entity", dom: ["sensor"], label: t("weather_station.fields.pressure.label"), opt: true },
        { k: "wind", t: "entity", dom: ["sensor"], label: t("weather_station.fields.wind.label"), opt: true },
        { k: "windDir", t: "entity", dom: ["sensor"], label: t("weather_station.fields.windDir.label"), opt: true },
        { k: "gust", t: "entity", dom: ["sensor"], label: t("weather_station.fields.gust.label"), opt: true },
        { k: "gustMax", t: "entity", dom: ["sensor"], label: t("weather_station.fields.gustMax.label"), opt: true },
        { k: "rain", t: "entity", dom: ["sensor"], label: t("weather_station.fields.rain.label"), opt: true },
        { k: "rainRate", t: "entity", dom: ["sensor"], label: t("weather_station.fields.rainRate.label"), opt: true },
        { k: "uv", t: "entity", dom: ["sensor"], label: t("weather_station.fields.uv.label"), opt: true },
        { k: "irradiance", t: "entity", dom: ["sensor"], label: t("weather_station.fields.irradiance.label"), opt: true },
      ],
    },
    areas: {
      type: "areas", store: "rooms", ns: "rooms", title: t("rooms.title"),
      hint: t("rooms.hint"),
      fields: [
        { k: "lightEntityId", t: "entity", dom: ["light", "switch"], label: t("rooms.fields.lightEntityId.label"), help: t("rooms.fields.lightEntityId.help") },
        { k: "climateEntityId", t: "entity", dom: ["climate"], label: t("rooms.fields.climateEntityId.label"), help: t("rooms.fields.climateEntityId.help") },
        { k: "windowEntityId", t: "entity", dom: ["binary_sensor"], label: t("rooms.fields.windowEntityId.label"), help: t("rooms.fields.windowEntityId.help") },
        { k: "coverEntityId", t: "entity", dom: ["cover"], label: t("rooms.fields.coverEntityId.label"), help: t("rooms.fields.coverEntityId.help") },
        { k: "secondaryEntityId", t: "entity", dom: null, label: t("rooms.fields.secondaryEntityId.label"), opt: true, full: true, help: t("rooms.fields.secondaryEntityId.help") },
      ],
    },
    alarme: {
      type: "form", store: "house_screen", ns: "alarm", title: t("alarm.title"),
      fields: [
        { k: "alarmEntityId", t: "entity", dom: ["alarm_control_panel"], label: t("alarm.fields.alarmEntityId.label"), full: true },
        { k: "waterHeaterEntityId", t: "entity", dom: ["water_heater", "climate"], label: t("alarm.fields.waterHeaterEntityId.label"), full: true },
        { k: "waterHeaterTempEntityId", t: "entity", dom: ["sensor"], label: t("alarm.fields.waterHeaterTempEntityId.label"), opt: true },
        { k: "waterHeaterPowerEntityId", t: "entity", dom: ["sensor"], label: t("alarm.fields.waterHeaterPowerEntityId.label"), opt: true },
      ],
    },
    cenarios: {
      type: "list", store: "house_scenes", ns: "scenes", title: t("scenes.title"), req: "entityId", add: t("scenes.add"),
      blank: () => ({ name: "", entityId: "" }), empty: t("scenes.empty"), itemIcon: I.scene,
      fields: [
        { k: "name", t: "text", label: t("scenes.fields.name.label"), ph: t("scenes.fields.name.ph") },
        { k: "entityId", t: "entity", dom: ["scene", "script"], label: t("scenes.fields.entityId.label"), req: true },
      ],
    },
    fechaduras: {
      type: "list", store: "house_locks", ns: "locks", title: t("locks.title"), req: "entityId", add: t("locks.add"),
      blank: () => ({ name: "", entityId: "" }), empty: t("locks.empty"), itemIcon: I.lock,
      fields: [
        { k: "name", t: "text", label: t("locks.fields.name.label"), ph: t("locks.fields.name.ph") },
        { k: "entityId", t: "entity", dom: ["lock", "cover", "binary_sensor"], label: t("locks.fields.entityId.label"), req: true, help: t("locks.fields.entityId.help") },
      ],
    },
    aspiradores: {
      type: "list", store: "vacuums", ns: "vacuums", title: t("vacuums.title"), req: "entityId", add: t("vacuums.add"),
      blank: () => ({ name: "", entityId: "", where: "" }), empty: t("vacuums.empty"), itemIcon: I.vacuum,
      hint: t("vacuums.hint"),
      fields: [
        { k: "entityId", t: "entity", dom: ["vacuum"], label: t("vacuums.fields.entityId.label"), req: true, full: true },
        { k: "name", t: "text", label: t("vacuums.fields.name.label"), ph: t("vacuums.fields.name.ph"), opt: true, help: t("vacuums.fields.name.help") },
        { k: "where", t: "text", label: t("vacuums.fields.where.label"), ph: t("vacuums.fields.where.ph"), opt: true, help: t("vacuums.fields.where.help") },
      ],
    },
    camaras: {
      type: "list", store: "house_cameras", ns: "cameras", title: t("cameras.title"), req: "entityId", add: t("cameras.add"),
      blank: () => ({ name: "", entityId: "" }), empty: t("cameras.empty"), itemIcon: I.camera,
      fields: [
        { k: "name", t: "text", label: t("cameras.fields.name.label"), ph: t("cameras.fields.name.ph") },
        { k: "entityId", t: "entity", dom: ["camera"], label: t("cameras.fields.entityId.label"), req: true },
      ],
    },
    fluxo: {
      type: "form", store: "energy_entities", ns: "energy_flow", title: t("energy_flow.title"),
      fields: [
        { k: "solarPowerEntityId", t: "entity", dom: ["sensor"], label: t("energy_flow.fields.solarPowerEntityId.label"), help: t("energy_flow.fields.solarPowerEntityId.help") },
        { k: "gridPowerEntityId", t: "entity", dom: ["sensor"], label: t("energy_flow.fields.gridPowerEntityId.label"), help: t("energy_flow.fields.gridPowerEntityId.help") },
        { k: "batteryPowerEntityId", t: "entity", dom: ["sensor"], label: t("energy_flow.fields.batteryPowerEntityId.label"), help: t("energy_flow.fields.batteryPowerEntityId.help") },
        { k: "batterySocEntityId", t: "entity", dom: ["sensor"], label: t("energy_flow.fields.batterySocEntityId.label"), help: t("energy_flow.fields.batterySocEntityId.help") },
        { k: "homePowerEntityId", t: "entity", dom: ["sensor"], label: t("energy_flow.fields.homePowerEntityId.label"), full: true, help: t("energy_flow.fields.homePowerEntityId.help") },
        { k: "tariffEntityId", t: "entity", dom: ["sensor", "select"], label: t("energy_flow.fields.tariffEntityId.label"), opt: true, full: true, help: t("energy_flow.fields.tariffEntityId.help") },
      ],
      adv: [
        { k: "solarZeroThresholdW", t: "number", label: t("energy_flow.fields.solarZeroThresholdW.label"), suffix: "W" },
        { k: "gridZeroThresholdW", t: "number", label: t("energy_flow.fields.gridZeroThresholdW.label"), suffix: "W" },
        { k: "batteryZeroThresholdW", t: "number", label: t("energy_flow.fields.batteryZeroThresholdW.label"), suffix: "W" },
        { k: "homeZeroThresholdW", t: "number", label: t("energy_flow.fields.homeZeroThresholdW.label"), suffix: "W" },
      ],
    },
    consumos: {
      type: "list", store: "individual_sensors", ns: "consumers", title: t("consumers.title"), req: "powerEntityId", add: t("consumers.add"), max: 4,
      blank: () => ({ name: "", icon: "plug", powerEntityId: "", temperatureEntityId: "" }),
      hint: t("consumers.hint"), empty: t("consumers.empty"),
      fields: [
        { k: "name", t: "text", label: t("consumers.fields.name.label"), ph: t("consumers.fields.name.ph") },
        { k: "powerEntityId", t: "entity", dom: ["sensor"], label: t("consumers.fields.powerEntityId.label"), req: true },
        { k: "icon", t: "icon", label: t("consumers.fields.icon.label") },
        { k: "temperatureEntityId", t: "entity", dom: ["sensor"], label: t("consumers.fields.temperatureEntityId.label"), opt: true },
      ],
    },
    listas: {
      type: "list", store: "todo_lists", ns: "lists", title: t("lists.title"), req: "entityId", add: t("lists.add"),
      blank: () => ({ entityId: "" }), itemIcon: I.check,
      hint: t("lists.hint"),
      empty: t("lists.empty"),
      fields: [{ k: "entityId", t: "entity", dom: ["todo"], label: t("lists.fields.entityId.label"), req: true, full: true }],
    },
    carros: {
      type: "list", store: "ev_cars", ns: "cars", title: t("cars.title"), req: "name", add: t("cars.add"), max: 4,
      blank: () => ({ name: "", kind: "electric", homeEntityId: "" }), itemIcon: I.car,
      hint: t("cars.hint"),
      empty: t("cars.empty"),
      // The fields depend on the car's type; `fields` is every one of them,
      // so a car switched between types keeps what was typed for each.
      fieldsFor: (item) => {
        const base = [
          { k: "name", t: "text", label: t("cars.fields.name.label"), req: true, ph: t("cars.fields.name.ph") },
          { k: "kind", t: "seg", label: t("cars.fields.kind.label"), full: true, options: CAR_KINDS },
          { k: "homeEntityId", t: "entity", dom: ["device_tracker", "binary_sensor", "person"], label: t("cars.fields.homeEntityId.label"), opt: true, full: true, help: t("cars.fields.homeEntityId.help") },
        ];
        if (item.kind === "fuel") {
          return base.concat([
            { k: "fuelEntityId", t: "entity", dom: ["sensor"], label: t("cars.fields.fuelEntityId.label"), help: t("cars.fields.fuelEntityId.help") },
            { k: "rangeEntityId", t: "entity", dom: ["sensor"], label: t("cars.fields.rangeEntityId.label") },
            { k: "lockEntityId", t: "entity", dom: ["lock", "binary_sensor"], label: t("cars.fields.lockEntityId.label"), full: true, help: t("cars.fields.lockEntityId.help") },
          ]);
        }
        return base.concat([
          { k: "batterySocEntityId", t: "entity", dom: ["sensor"], label: t("cars.fields.batterySocEntityId.label"), help: t("cars.fields.batterySocEntityId.help") },
          { k: "rangeEntityId", t: "entity", dom: ["sensor"], label: t("cars.fields.rangeEntityId.label") },
          { k: "chargingEntityId", t: "entity", dom: ["binary_sensor", "sensor"], label: t("cars.fields.chargingEntityId.label") },
          { k: "plugConnectedEntityId", t: "entity", dom: ["binary_sensor", "sensor"], label: t("cars.fields.plugConnectedEntityId.label"), help: t("cars.fields.plugConnectedEntityId.help") },
          { k: "chargeLimitEntityId", t: "entity", dom: ["number", "sensor"], label: t("cars.fields.chargeLimitEntityId.label"), help: t("cars.fields.chargeLimitEntityId.help") },
          { k: "chargePowerEntityId", t: "entity", dom: ["sensor"], label: t("cars.fields.chargePowerEntityId.label") },
        ]);
      },
    },
  });

  let SECTIONS = [];
  const buildSections = () => [
    { id: "familia", icon: I.people, ns: "sections.family", title: t("sections.family.title"), desc: t("sections.family.desc"), intro: t("sections.family.intro"), subs: ["pessoas"] },
    { id: "calendarios", icon: I.cal, ns: "sections.calendars", title: t("sections.calendars.title"), desc: t("sections.calendars.desc"), intro: t("sections.calendars.intro"), subs: ["outros"] },
    { id: "meteo", icon: I.weather, ns: "sections.weather", title: t("sections.weather.title"), desc: t("sections.weather.desc"), intro: t("sections.weather.intro"), subs: ["meteo", "estacao"] },
    { id: "divisoes", icon: I.rooms, ns: "sections.rooms", title: t("sections.rooms.title"), desc: t("sections.rooms.desc"), intro: t("sections.rooms.intro"), subs: ["areas"] },
    { id: "casa", icon: I.home, ns: "sections.house", title: t("sections.house.title"), desc: t("sections.house.desc"), intro: t("sections.house.intro"), subs: ["alarme", "cenarios", "fechaduras", "camaras"] },
    { id: "energia", icon: I.flash, ns: "sections.energy", title: t("sections.energy.title"), desc: t("sections.energy.desc"), intro: t("sections.energy.intro"), subs: ["fluxo", "consumos"] },
    { id: "assistente", icon: I.mic, ns: "sections.assistant", title: t("sections.assistant.title"), desc: t("sections.assistant.desc"), intro: t("sections.assistant.intro"), subs: ["assistente"] },
    { id: "listas", icon: I.check, ns: "sections.lists", title: t("sections.lists.title"), desc: t("sections.lists.desc"), intro: t("sections.lists.intro"), subs: ["listas"] },
    { id: "aspiradores", icon: I.vacuum, ns: "sections.vacuums", title: t("sections.vacuums.title"), desc: t("sections.vacuums.desc"), intro: t("sections.vacuums.intro"), subs: ["aspiradores"] },
    { id: "carros", icon: I.car, ns: "sections.cars", title: t("sections.cars.title"), desc: t("sections.cars.desc"), intro: t("sections.cars.intro"), subs: ["carros"] },
  ];

  // ---------- Small helpers ----------
  const clone = (o) => (o === undefined ? undefined : JSON.parse(JSON.stringify(o)));
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const str = (v) => (v === null || v === undefined ? "" : String(v));
  // "a, b e c" / "a, b, and c" in the panel's language.
  const joinList = (a) => {
    try {
      return new Intl.ListFormat(LOCALE, { type: "conjunction" }).format(a);
    } catch (_) {
      return a.join(", ");
    }
  };

  function svg(path, size = 24, attrs = {}) {
    const NS = "http://www.w3.org/2000/svg";
    const el = document.createElementNS(NS, "svg");
    el.setAttribute("width", size);
    el.setAttribute("height", size);
    el.setAttribute("viewBox", "0 0 24 24");
    el.setAttribute("fill", "none");
    el.setAttribute("stroke", attrs.stroke || "currentColor");
    el.setAttribute("stroke-width", attrs.sw || 1.8);
    el.setAttribute("stroke-linecap", "round");
    el.setAttribute("stroke-linejoin", "round");
    el.setAttribute("aria-hidden", "true");
    if (attrs.style) el.setAttribute("style", attrs.style);
    const p = document.createElementNS(NS, "path");
    p.setAttribute("d", path);
    el.appendChild(p);
    return el;
  }

  // h("div.cls", {attrs, onEvent}, ...children)
  function h(tag, props, ...children) {
    const [name, ...classes] = tag.split(".");
    const el = document.createElement(name);
    if (classes.length) el.className = classes.join(" ");
    for (const [k, v] of Object.entries(props || {})) {
      if (v === undefined || v === null || v === false) continue;
      if (k.startsWith("on")) el.addEventListener(k.slice(2).toLowerCase(), v);
      else if (k === "style") el.setAttribute("style", v);
      else if (k === "text") el.textContent = v;
      else if (k === "value" || k === "placeholder" || k === "inputMode" || k === "title") el[k] = v;
      else el.setAttribute(k, v === true ? "" : v);
    }
    for (const c of children.flat()) {
      if (c === null || c === undefined || c === false) continue;
      el.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
    }
    return el;
  }

  // Every field an item of a list can have (for cars, both types').
  function listFields(def) {
    if (!def.fieldsFor) return def.fields;
    const seen = {};
    return [...def.fieldsFor({}), ...def.fieldsFor({ kind: "fuel" })].filter((f) => !seen[f.k] && (seen[f.k] = true));
  }

  // Cars saved before they became a list: the fixed {left, right} pair.
  function carsList(raw) {
    if (Array.isArray(raw)) return raw;
    if (!raw || typeof raw !== "object") return [];
    return ["left", "right"].map((slot) => raw[slot]).filter((c) => c && Object.values(c).some((v) => str(v).trim()));
  }

  // ---------- Stored value <-> draft ----------
  function toDraft(subId, raw, ctx) {
    const def = SUBS[subId];
    if (def.type === "list") {
      return (subId === "carros" ? carsList(raw) : Array.isArray(raw) ? raw : []).map((it, i) => {
        const d = def.blank();
        for (const f of listFields(def)) {
          if (f.t === "color") d[f.k] = it[f.k] ?? (subId === "outros" ? "accent" : COLORS[i % COLORS.length].key);
          else d[f.k] = str(it[f.k]) || (f.t === "icon" || f.t === "seg" ? d[f.k] : "");
        }
        return d;
      });
    }
    if (def.type === "form") {
      const src = raw && typeof raw === "object" ? raw : {};
      const d = {};
      for (const f of [...def.fields, ...(def.adv || [])]) d[f.k] = str(src[f.k]);
      return d;
    }
    if (def.type === "areas") {
      // A save from before rooms pointed at real areas (a free-typed `name`,
      // no `areaId`) is matched by name — same migration as RoomsStore.read.
      const byId = {};
      const byName = {};
      (Array.isArray(raw) ? raw : []).forEach((it) => {
        if (it.areaId) byId[it.areaId] = it;
        else if (it.name) byName[String(it.name).trim().toLowerCase()] = it;
      });
      const d = {};
      for (const a of ctx.areas) {
        const it = byId[a.area_id] || byName[(a.name || "").trim().toLowerCase()] || {};
        d[a.area_id] = {};
        for (const f of def.fields) d[a.area_id][f.k] = str(it[f.k]);
      }
      // The saved order is the Casa page's; areas new since go last, by floor.
      const ids = new Set(ctx.areas.map((a) => a.area_id));
      const saved = [...new Set((Array.isArray(raw) ? raw : []).map((it) => it.areaId).filter((id) => ids.has(id)))];
      d[AREA_ORDER] = [...saved, ...ctx.areas.map((a) => a.area_id).filter((id) => !saved.includes(id))];
      return d;
    }
    return raw;
  }

  // The areas draft keeps the Casa page's order under this key, beside the
  // rows keyed by area id.
  const AREA_ORDER = "__order";

  function fromDraft(subId, draft, ctx) {
    const def = SUBS[subId];
    const val = (v) => (str(v).trim() === "" ? null : str(v).trim());
    if (def.type === "list") {
      const kept = draft.filter((it) => str(it[def.req]).trim());
      return {
        dropped: draft.length - kept.length,
        value: kept.map((it) => {
          const out = {};
          // A car keeps only its own type's entities.
          for (const f of def.fieldsFor ? def.fieldsFor(it) : def.fields) out[f.k] = f.t === "color" ? it[f.k] : val(it[f.k]);
          // A consumption with no name is labelled after its sensor.
          if (subId === "consumos" && !out.name) out.name = ctx.entityName(out.powerEntityId);
          return out;
        }),
      };
    }
    if (def.type === "form") {
      const out = {};
      for (const f of def.fields) out[f.k] = val(draft[f.k]);
      for (const f of def.adv || []) out[f.k] = str(draft[f.k]).trim() === "" ? null : Number(draft[f.k]);
      return { dropped: 0, value: out };
    }
    if (def.type === "areas") {
      // Every area is saved, even with nothing chosen: an emptied field is
      // the user's choice, so the integration won't guess it again.
      const out = [];
      for (const id of draft[AREA_ORDER]) {
        const it = draft[id] || {};
        const row = { areaId: id };
        for (const f of def.fields) row[f.k] = val(it[f.k]);
        out.push(row);
      }
      return { dropped: 0, value: out };
    }
    return { dropped: 0, value: draft };
  }

  const STYLE = `
    :host { display:block; height:100%; }
    .ha {
      --fd-bg: var(--primary-background-color, #FAFAFA);
      --fd-card: var(--card-background-color, #FFFFFF);
      --fd-text: var(--primary-text-color, #212121);
      --fd-sec: var(--secondary-text-color, #727272);
      --fd-border: var(--divider-color, #E0E0E0);
      --fd-primary: var(--primary-color, #03A9F4);
      --fd-error: var(--error-color, #DB4437);
      --fd-warn: var(--warning-color, #FFA600);
      --fd-ok: var(--success-color, #43A047);
      --fd-faint: color-mix(in srgb, var(--fd-sec) 45%, transparent);
      --fd-input: color-mix(in srgb, var(--fd-text) 4%, var(--fd-card));
      --fd-menu: color-mix(in srgb, var(--fd-text) 3%, var(--fd-card));
      --fd-primary-text: color-mix(in srgb, var(--fd-primary) 72%, var(--fd-text));
      --fd-primary-tint: color-mix(in srgb, var(--fd-primary) 13%, transparent);
      --fd-row-sel: color-mix(in srgb, var(--fd-primary) 11%, transparent);
      --fd-warn-text: color-mix(in srgb, var(--fd-warn) 62%, var(--fd-text));
      --fd-warn-tint: color-mix(in srgb, var(--fd-warn) 14%, transparent);
      --fd-ok-text: color-mix(in srgb, var(--fd-ok) 75%, var(--fd-text));
      --fd-ok-tint: color-mix(in srgb, var(--fd-ok) 14%, transparent);
      --fd-info-tint: color-mix(in srgb, var(--fd-primary) 9%, transparent);
      --fd-neutral-tint: color-mix(in srgb, var(--fd-text) 6%, transparent);
      --fd-disabled-bg: color-mix(in srgb, var(--fd-text) 10%, transparent);
      --fd-disabled-fg: color-mix(in srgb, var(--fd-text) 40%, transparent);
      position:relative; height:100%; display:flex; flex-direction:column; background:var(--fd-bg); color:var(--fd-text);
      font-family: var(--ha-font-family-body, Roboto, system-ui, sans-serif); font-size:14px; -webkit-font-smoothing:antialiased;
    }
    button { font-family:inherit; cursor:pointer; transition: background-color .15s ease, color .15s ease, border-color .15s ease, box-shadow .15s ease, transform .12s ease; }
    button:active { transform: scale(.97); }
    input { font-family:inherit; }
    input::placeholder { color:inherit; opacity:.55; }
    @keyframes fdViewIn { from { opacity:0; transform:translateY(16px) } to { opacity:1; transform:none } }
    @keyframes fdFade { from { opacity:0 } to { opacity:1 } }
    @keyframes fdDrop { from { opacity:0; transform:translateY(-6px) } to { opacity:1; transform:none } }
    @keyframes fdSlideUp { from { opacity:0; transform:translateY(24px) } to { opacity:1; transform:none } }
    @keyframes fdModalIn { from { opacity:0; transform:translateY(24px) scale(.97) } to { opacity:1; transform:none } }
    @keyframes fdSpin { to { transform: rotate(360deg) } }
    @media (prefers-reduced-motion: reduce) { * { animation-duration:1ms !important; transition-duration:1ms !important } }

    .toolbar { height:56px; flex-shrink:0; box-sizing:border-box; display:flex; align-items:center; gap:12px; padding:0 var(--gutter); background:var(--fd-card); border-bottom:1px solid var(--fd-border); }
    .toolbar .title { font-size:20px; font-weight:400; }
    .icon-btn { width:40px; height:40px; border-radius:50%; border:0; background:transparent; color:var(--fd-sec); display:flex; align-items:center; justify-content:center; padding:0; flex-shrink:0; }
    .icon-btn:hover { background:var(--fd-neutral-tint); }
    .icon-btn[aria-disabled="true"] { color:var(--fd-faint); cursor:default; }
    .icon-btn[aria-disabled="true"]:hover { background:transparent; }
    .scroll { flex:1; min-height:0; overflow-y:auto; position:relative; }
    .page { max-width:920px; margin:0 auto; box-sizing:border-box; display:flex; flex-direction:column; }
    .page.enter { animation: fdViewIn .32s cubic-bezier(.2,.8,.2,1) both; }
    h1 { margin:0; font-size:var(--h1); font-weight:400; }
    .lead { margin:0; color:var(--fd-sec); font-size:14px; line-height:1.5; }

    .status { display:flex; align-items:center; gap:14px; padding:14px 16px; border-radius:12px; background:var(--fd-card); border:1px solid var(--fd-border); }
    .status .badge { width:40px; height:40px; border-radius:50%; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .status .t { font-size:15px; font-weight:500; }
    .status .s { color:var(--fd-sec); font-size:13px; }
    .status .led { width:10px; height:10px; border-radius:50%; flex-shrink:0; }

    .tiles { display:grid; gap:16px; grid-template-columns:repeat(3, minmax(0,1fr)); }
    .tile { text-align:left; border:1px solid var(--fd-border); background:var(--fd-card); color:var(--fd-text); border-radius:12px; padding:20px; display:flex; flex-direction:column; align-items:flex-start; gap:14px; min-height:200px; box-sizing:border-box; }
    .tile:hover { box-shadow:0 2px 10px rgba(0,0,0,.08); }
    .tile .ic { width:48px; height:48px; border-radius:50%; background:var(--fd-primary-tint); color:var(--fd-primary-text); display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .tile .body { flex:1; align-self:stretch; min-width:0; display:flex; flex-direction:column; gap:4px; }
    .tile .tt { font-size:17px; font-weight:500; }
    .tile .dd { color:var(--fd-sec); font-size:13.5px; line-height:1.4; }
    .tile .foot { margin-top:auto; padding-top:10px; display:flex; }
    .chip { display:inline-flex; align-items:center; gap:6px; height:28px; padding:0 12px 0 8px; border-radius:14px; font-size:13px; font-weight:500; max-width:100%; box-sizing:border-box; }
    .chip span { white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .chip.ok { background:var(--fd-ok-tint); color:var(--fd-ok-text); }
    .chip.warn { background:var(--fd-warn-tint); color:var(--fd-warn-text); }
    .chip.info { background:var(--fd-neutral-tint); color:var(--fd-sec); }
    .mobile .tiles { grid-template-columns:1fr; gap:10px; }
    .mobile .tile { flex-direction:row; padding:14px; min-height:0; }

    .back { align-self:flex-start; height:36px; padding:0 12px 0 6px; margin-left:-6px; border:0; border-radius:18px; background:transparent; color:var(--fd-primary-text); display:flex; align-items:center; gap:6px; font-size:14px; font-weight:500; }
    .back:hover { background:var(--fd-primary-tint); }
    .sec-title { display:flex; align-items:center; gap:14px; }
    .sec-title .ic { width:44px; height:44px; border-radius:50%; background:var(--fd-primary-tint); color:var(--fd-primary-text); display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .sub { display:flex; flex-direction:column; gap:10px; padding-top:16px; }
    .sub-head { display:flex; align-items:center; gap:10px; min-height:24px; }
    .sub-head h2 { margin:0; font-size:12px; font-weight:500; letter-spacing:1.2px; text-transform:uppercase; color:var(--fd-sec); }
    .dirty { display:inline-flex; align-items:center; gap:6px; font-size:12px; font-weight:500; color:var(--fd-warn-text); animation: fdFade .2s ease both; }
    .dirty i { width:7px; height:7px; border-radius:50%; background:var(--fd-warn); }
    .count { font-size:12px; color:var(--fd-sec); margin-left:auto; }
    .hint { margin:-4px 0 2px; font-size:13px; color:var(--fd-sec); line-height:1.45; }
    .stack { display:flex; flex-direction:column; gap:12px; }

    .card { background:var(--fd-card); border:1px solid var(--fd-border); border-radius:12px; position:relative; }
    .card.raised { z-index:30; }
    .card-head { display:flex; align-items:center; gap:12px; min-height:40px; padding:12px 12px 12px 20px; }
    .card-head + .grid { border-top:1px solid var(--fd-border); }
    .mobile .card-head { padding:10px 8px 10px 16px; }
    .card-head .dot { width:14px; height:14px; border-radius:50%; flex-shrink:0; }
    .card-head .hic { width:36px; height:36px; border-radius:50%; display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .card-head .txt { flex:1; min-width:0; display:flex; flex-direction:column; gap:2px; }
    .card-head .tt { font-size:16px; font-weight:500; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .card-head .ss { font-size:13px; color:var(--fd-sec); display:flex; align-items:center; gap:6px; }
    .card-head .ss.warn { color:var(--fd-warn-text); }
    .card-head .moves { display:flex; gap:2px; }
    .drag-handle { cursor:grab; touch-action:none; margin-left:-8px; }
    .reorder > .card { transition:transform .15s ease; }
    .reorder > .card.dragging { transition:none; z-index:40; box-shadow:0 8px 24px rgba(0,0,0,.18); }
    .reorder > .card.dragging .drag-handle { cursor:grabbing; }
    .grid { display:grid; grid-template-columns:repeat(2, minmax(0,1fr)); gap:16px 20px; padding:18px 20px; }
    .mobile .grid { grid-template-columns:minmax(0,1fr); padding:16px; }
    .grid .full { grid-column:1 / -1; }
    .empty { display:flex; align-items:center; gap:12px; color:var(--fd-sec); font-size:14px; line-height:1.45; padding:18px 20px; }
    .note { display:flex; align-items:flex-start; gap:10px; padding:10px 12px; border-radius:8px; background:var(--fd-info-tint); font-size:13px; line-height:1.45; }
    .adv { width:100%; height:44px; border:0; background:transparent; color:var(--fd-text); display:flex; align-items:center; gap:10px; padding:0; font-size:14px; font-weight:500; text-align:left; }
    .adv:active { transform:none; }
    .adv .lbl { flex:1; }
    .adv .val { font-weight:400; color:var(--fd-sec); font-size:13px; }

    .field { display:flex; flex-direction:column; gap:6px; min-width:0; }
    .field label { font-size:13px; font-weight:500; }
    .field label .req { color:var(--fd-error); }
    .field label .optional { font-weight:400; color:var(--fd-sec); }
    .to-auto { display:inline-flex; align-items:center; gap:4px; height:20px; padding:0 8px 0 6px; margin-left:8px; border-radius:10px; border:1px dashed var(--fd-border); background:transparent; color:var(--fd-sec); font-size:11.5px; font-weight:500; vertical-align:1px; cursor:pointer; }
    .to-auto:hover { border-color:var(--fd-primary); color:var(--fd-primary-text); }
    .auto { display:inline-flex; align-items:center; gap:4px; height:20px; padding:0 8px 0 6px; margin-left:8px; border-radius:10px; background:var(--fd-primary-tint); color:var(--fd-primary-text); font-size:11.5px; font-weight:500; vertical-align:1px; }
    .help { font-size:12.5px; color:var(--fd-sec); line-height:1.4; }
    .help.warn { color:var(--fd-warn-text); }
    .textbox { height:48px; display:flex; align-items:center; gap:8px; padding:0 14px; border-radius:8px; background:var(--fd-input); border:1px solid var(--fd-border); box-sizing:border-box; }
    .textbox:focus-within { border-color:var(--fd-primary); box-shadow:0 0 0 1px var(--fd-primary); }
    .textbox input { flex:1; min-width:0; height:44px; border:0; outline:none; background:transparent; color:var(--fd-text); font-size:15px; }
    .textbox .suffix { color:var(--fd-sec); font-size:14px; }

    .picker { position:relative; }
    .pick-btn { width:100%; min-height:56px; display:flex; align-items:center; gap:12px; padding:6px 8px 6px 14px; border-radius:8px; background:var(--fd-input); border:1px solid var(--fd-border); box-sizing:border-box; color:var(--fd-text); text-align:left; }
    .pick-btn:active { transform:none; }
    .pick-btn.open { border-color:var(--fd-primary); box-shadow:0 0 0 1px var(--fd-primary); }
    .pick-btn.missing { border-color:var(--fd-warn); }
    .pick-btn .txt { flex:1; min-width:0; display:flex; flex-direction:column; gap:1px; }
    .pick-btn .nm { font-size:15px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .pick-btn .nm.empty { color:var(--fd-sec); }
    .pick-btn .meta { font-size:12.5px; color:var(--fd-sec); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .pick-btn .clear { width:36px; height:36px; border-radius:50%; color:var(--fd-sec); display:flex; align-items:center; justify-content:center; flex-shrink:0; }
    .pick-btn .clear:hover { background:var(--fd-neutral-tint); }
    .menu { position:absolute; left:0; right:0; top:calc(100% + 4px); z-index:40; background:var(--fd-menu); border-radius:12px; box-shadow:0 8px 28px rgba(0,0,0,.22), 0 0 0 1px var(--fd-border); overflow:hidden; animation: fdDrop .16s ease-out both; }
    .menu .search { display:flex; align-items:center; gap:10px; padding:0 14px; height:52px; border-bottom:1px solid var(--fd-border); }
    .menu .search input { flex:1; min-width:0; height:48px; border:0; outline:none; background:transparent; color:var(--fd-text); font-size:15px; }
    .menu .opts { max-height:300px; overflow-y:auto; padding:4px 0; }
    .opt { width:100%; min-height:56px; border:0; background:transparent; color:var(--fd-text); display:flex; align-items:center; gap:14px; padding:6px 14px; text-align:left; }
    .opt:active { transform:none; }
    .opt:hover { background:var(--fd-neutral-tint); }
    .opt.on { background:var(--fd-row-sel); }
    .opt .txt { flex:1; min-width:0; display:flex; flex-direction:column; gap:1px; }
    .opt .nm { font-size:15px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .opt .id, .opt .area { font-size:12.5px; color:var(--fd-sec); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
    .opt .area { max-width:40%; }
    .menu .none { padding:18px 16px; color:var(--fd-sec); font-size:14px; }
    .menu .foot { padding:8px 14px; border-top:1px solid var(--fd-border); font-size:12px; color:var(--fd-sec); }

    .swatches { display:flex; align-items:center; gap:12px; min-height:48px; flex-wrap:wrap; }
    .swatch { width:36px; height:36px; border-radius:50%; border:0; padding:0; display:flex; align-items:center; justify-content:center; }
    .icons { display:flex; flex-wrap:wrap; gap:8px; }
    .seg { display:inline-flex; align-self:flex-start; gap:4px; padding:4px; border-radius:12px; background:var(--fd-input); border:1px solid var(--fd-border); }
    .seg button { height:40px; padding:0 18px; border-radius:9px; border:0; background:transparent; color:var(--fd-sec); display:flex; align-items:center; gap:8px; font-size:14px; font-weight:500; }
    .seg button.on { background:var(--fd-card); color:var(--fd-text); box-shadow:0 1px 3px rgba(0,0,0,.12); }
    .icon-opt { width:48px; height:48px; border-radius:10px; border:1.5px solid var(--fd-border); background:transparent; color:var(--fd-sec); display:flex; align-items:center; justify-content:center; padding:0; }
    .icon-opt.on { border-color:var(--fd-primary); background:var(--fd-primary-tint); color:var(--fd-primary-text); }

    .add { align-self:flex-start; height:40px; padding:0 18px 0 12px; border-radius:20px; border:1px solid var(--fd-primary-text); background:transparent; color:var(--fd-primary-text); display:flex; align-items:center; gap:8px; font-size:14px; font-weight:500; }
    .add:hover { background:var(--fd-primary-tint); }
    .add[aria-disabled="true"] { border-color:var(--fd-border); color:var(--fd-disabled-fg); cursor:default; background:transparent; }

    .bar-wrap { position:absolute; left:0; right:0; bottom:0; z-index:20; padding:0 24px 20px; pointer-events:none; }
    .bar-wrap.enter { animation: fdSlideUp .3s cubic-bezier(.2,.8,.2,1) both; }
    .mobile .bar-wrap { padding:0 8px 8px; }
    .bar { max-width:872px; margin:0 auto; pointer-events:auto; display:flex; align-items:center; gap:12px; padding:12px 12px 12px 18px; border-radius:12px; background:var(--fd-card); border:1px solid var(--fd-border); box-shadow:0 6px 24px rgba(0,0,0,.14); box-sizing:border-box; }
    .mobile .bar { flex-direction:column; align-items:stretch; }
    .bar .msg { flex:1; min-width:0; display:flex; align-items:center; gap:10px; font-size:14px; line-height:1.4; }
    .bar .msg strong { font-weight:500; }
    .bar .acts { display:flex; gap:8px; flex-shrink:0; justify-content:flex-end; }
    .spin { width:18px; height:18px; border-radius:50%; border:2.5px solid var(--fd-border); border-top-color:var(--fd-primary); animation: fdSpin .8s linear infinite; flex-shrink:0; box-sizing:border-box; }
    .btn-text { height:40px; padding:0 16px; border-radius:20px; border:0; background:transparent; color:var(--fd-primary-text); font-size:14px; font-weight:500; }
    .btn-text:hover { background:var(--fd-primary-tint); }
    .btn-text.danger { color:var(--fd-error); }
    .btn-fill { height:40px; padding:0 22px; border-radius:20px; border:0; background:var(--fd-primary); color:#FFFFFF; font-size:14px; font-weight:500; }
    .btn-fill[aria-disabled="true"] { background:var(--fd-disabled-bg); color:var(--fd-disabled-fg); cursor:default; }

    .scrim { position:fixed; inset:0; z-index:50; background:rgba(0,0,0,.45); display:flex; align-items:center; justify-content:center; padding:16px; box-sizing:border-box; animation: fdFade .2s ease both; }
    .dialog { width:100%; max-width:440px; background:var(--fd-menu); border-radius:24px; padding:24px; box-sizing:border-box; display:flex; flex-direction:column; gap:14px; box-shadow:0 16px 48px rgba(0,0,0,.3); animation: fdModalIn .25s cubic-bezier(.2,.8,.2,1) both; }
    .dialog h2 { margin:0; font-size:22px; font-weight:400; }
    .dialog .acts { display:flex; justify-content:flex-end; flex-wrap:wrap; gap:8px; padding-top:6px; }
    .loading { padding:48px 0; color:var(--fd-sec); text-align:center; }
    .error-box { padding:14px 16px; border-radius:12px; background:color-mix(in srgb, var(--fd-error) 12%, transparent); color:var(--fd-error); }
  `;

  class ByteHomeDashPanel extends HTMLElement {
    constructor() {
      super();
      this.attachShadow({ mode: "open" });
      this._hass = null;
      this._narrow = false;
      this._width = 1000;
      this._settings = null; // everything stored, as last loaded/saved
      this._loadError = null;
      this._areas = [];
      this._floorById = {};
      this._screens = undefined; // undefined: not asked yet; null: integration too old
      this._section = null;
      this._draft = {};
      this._saved = {};
      this._picker = null; // { sub, idx, k }
      this._pq = "";
      this._open = {}; // area id -> expanded
      this._adv = false;
      this._leave = false;
      this._ask = null; // { title, text, key, then }: the take-over confirmation
      this._taken = {}; // "<store>|<path>" -> true: automatic choices the user took over
      this._saving = false;
      this._msg = null; // { kind: saving|ok|err, text }
    }

    set hass(hass) {
      const first = !this._hass;
      this._hass = hass;
      if (first) this._init();
      else if (this._lang && hassLanguage(hass) !== this._lang) this._loadTexts().then(() => this._render());
    }
    get hass() {
      return this._hass;
    }
    set narrow(v) {
      const changed = this._narrow !== !!v;
      this._narrow = !!v;
      if (changed && this._hass) this._render();
    }
    set panel(v) {
      this._panel = v;
    }

    connectedCallback() {
      this._ro = new ResizeObserver(() => {
        const was = this._mobile;
        this._width = this.clientWidth;
        if (this._hass && was !== this._mobile) this._render();
      });
      this._ro.observe(this);
      this._screensTimer = setInterval(() => {
        if (!this._section) this._loadScreens();
      }, 15000);
      if (!this._keys) {
        this._keys = true;
        this.shadowRoot.addEventListener("keydown", (e) => {
          if (e.key === "Escape" && this._picker) {
            this._picker = null;
            this._render();
          }
        });
      }
      if (this._hass) this._render();
    }

    disconnectedCallback() {
      if (this._ro) this._ro.disconnect();
      clearInterval(this._screensTimer);
    }

    get _mobile() {
      return this._narrow || this._width < 700;
    }

    async _init() {
      await this._loadTexts();
      this._render(true);
      // Let the integration pick entities for anything new (areas, devices,
      // lists) before showing its choices.
      await this._ws("fill_suggestions").catch(() => {});
      await Promise.all([this._loadSettings(), this._loadScreens(), this._loadAreas(), this._loadAutoPaths()]);
      this._render();
    }

    // The texts in HA's current language; nothing renders before them.
    async _loadTexts() {
      const language = hassLanguage(this._hass);
      this._lang = language;
      const texts = await fetchLanguage(language);
      if (language !== this._lang) return; // a newer change won
      applyTexts(language, texts);
      // The open section is a SECTIONS entry: take the new language's.
      if (this._section) this._section = SECTIONS.find((s) => s.id === this._section.id);
      this._ready = true;
    }

    // What the integration can choose on its own, so a choice the user took
    // over can be given back ("Repor automático").
    async _loadAutoPaths() {
      try {
        this._autoPaths = (await this._ws("auto_paths")).auto || {};
      } catch (_) {
        this._autoPaths = {}; // integration too old
      }
    }

    _ws(type, extra = {}) {
      return this._hass.connection.sendMessagePromise({ type: `${DOMAIN}/${type}`, ...extra });
    }

    async _loadSettings() {
      try {
        const res = await this._ws("get_settings");
        this._settings = res.value || {};
        this._loadError = null;
      } catch (err) {
        this._loadError = err.message || String(err);
      }
    }

    async _loadScreens() {
      let next;
      try {
        next = (await this._ws("list_screens")).screens || [];
      } catch (_) {
        next = null; // integration older than the screen registry
      }
      const changed = JSON.stringify(next) !== JSON.stringify(this._screens);
      this._screens = next;
      if (changed && !this._section && this._settings) this._render();
    }

    async _loadAreas() {
      try {
        const [areas, floors] = await Promise.all([
          this._hass.callWS({ type: "config/area_registry/list" }),
          this._hass.callWS({ type: "config/floor_registry/list" }).catch(() => []),
        ]);
        const floorById = {};
        floors.forEach((f) => (floorById[f.floor_id] = f));
        const level = (a) => {
          const f = floorById[a.floor_id];
          return f && typeof f.level === "number" ? f.level : Number.MAX_SAFE_INTEGER;
        };
        this._areas = [...areas].sort((a, b) => level(a) - level(b) || (a.name || "").localeCompare(b.name || ""));
        this._floorById = floorById;
      } catch (_) {
        this._areas = [];
        this._floorById = {};
      }
    }

    // ---------- Entities ----------
    // The person a calendar belongs to, with their colour: such a calendar
    // always takes the person's colour, here and on the screen.
    _owner(entityId) {
      const people = this._draft.pessoas || (this._settings || {}).family_members;
      if (!entityId || !Array.isArray(people)) return null;
      const i = people.findIndex((p) => p && p.calendarEntityId === entityId);
      return i < 0 ? null : { name: str(people[i].name).trim(), color: COLORS[colorIndex(people[i].color, i % COLORS.length)] };
    }

    _entityName(id) {
      if (!id) return "";
      const st = this._hass.states[id];
      return (st && st.attributes && st.attributes.friendly_name) || (id.split(".")[1] || id).replace(/_/g, " ");
    }

    _entityArea(id) {
      const hs = this._hass;
      const reg = hs.entities && hs.entities[id];
      if (!reg) return "";
      let areaId = reg.area_id;
      if (!areaId && reg.device_id && hs.devices && hs.devices[reg.device_id]) areaId = hs.devices[reg.device_id].area_id;
      return (areaId && hs.areas && hs.areas[areaId] && hs.areas[areaId].name) || "";
    }

    _entityIcon(id) {
      const d = id.split(".")[0];
      const n = (id + " " + this._entityName(id)).toLowerCase();
      const st = this._hass.states[id];
      const dc = (st && st.attributes && st.attributes.device_class) || "";
      if (d === "sensor") {
        if (dc === "temperature" || /temperatur/.test(n)) return I.thermo;
        if (dc === "power" || dc === "energy" || /pot[eê]ncia|power|consumo/.test(n)) return I.flash;
        if (dc === "battery" || /bateria|battery|soc/.test(n)) return I.battery;
        return I.gauge;
      }
      if (d === "binary_sensor") {
        if (dc === "window" || dc === "door" || dc === "opening" || /janela|window/.test(n)) return I.window;
        if (dc === "battery_charging" || /carreg|charging/.test(n)) return I.flash;
        if (dc === "plug" || /ficha|plug/.test(n)) return I.plug;
        return I.toggle;
      }
      if (d === "cover") return dc === "garage" || dc === "gate" || /garag|port[aã]o|gate/.test(n) ? I.home : I.cover;
      const byDomain = { calendar: I.cal, weather: I.weather, light: I.light, switch: I.toggle, climate: I.climate, lock: I.lock, alarm_control_panel: I.alarm, water_heater: I.heatpump, scene: I.scene, script: I.script, camera: I.camera, number: I.gauge };
      return byDomain[d] || I.dot;
    }

    _entityOptions(dom, q) {
      const query = q.trim().toLowerCase();
      return Object.keys(this._hass.states)
        .filter((id) => !dom || dom.includes(id.split(".")[0]))
        .map((id) => ({ id, name: this._entityName(id), area: this._entityArea(id) }))
        .filter((o) => !query || (o.id + " " + o.name + " " + o.area).toLowerCase().includes(query))
        .sort((a, b) => a.name.localeCompare(b.name));
    }

    // ---------- Automatic choices ----------
    // `path` as in suggest.py: a field name, "<area id>/<field>", or "".
    _isAuto(store, path) {
      const auto = (this._settings && this._settings[AUTO_KEY]) || {};
      return !!(auto[store] && auto[store][path]);
    }

    // The auto_choices key ("<store>|<path>") an edit here would take over
    // from the integration, or null when the choice is already the user's.
    // A list is chosen as a whole, so any edit to it takes over all of it.
    _autoLock(subId, idx, k) {
      const sub = SUBS[subId];
      if (sub.type === "list") {
        const key = `${sub.store}|`;
        return this._isAuto(sub.store, "") && !this._taken[key] && same(this._draft[subId], this._saved[subId]) ? key : null;
      }
      const path = sub.type === "areas" ? `${idx}/${k}` : sub.type === "form" ? k : null;
      if (path === null) return null;
      const key = `${sub.store}|${path}`;
      const saved = (this._saved[subId] && (idx === -1 ? this._saved[subId] : this._saved[subId][idx])) || {};
      return this._isAuto(sub.store, path) && !this._taken[key] && same(this._target(subId, idx)[k], saved[k]) ? key : null;
    }

    // Stops a click on something automatic and asks first; `then` runs once
    // the user has taken it over.
    _guard(el, key, title, text, then) {
      el.addEventListener(
        "click",
        (e) => {
          e.preventDefault();
          e.stopPropagation();
          this._picker = null;
          this._ask = {
            title,
            text,
            confirm: t("auto.takeover_confirm"),
            run: () => {
              this._taken[key] = true;
              this._render();
              if (then) then();
            },
          };
          this._render();
        },
        true
      );
    }

    _renderAsk() {
      const ask = this._ask;
      const close = () => {
        this._ask = null;
        this._render();
      };
      return h(
        "div.scrim",
        { onClick: (e) => e.target === e.currentTarget && close() },
        h(
          "div.dialog",
          { role: "alertdialog", "aria-modal": "true", "aria-label": ask.title },
          ask.badge === false ? null : h("div", {}, this._autoBadge()),
          h("h2", { text: ask.title }),
          h("p.lead", { text: ask.text }),
          h(
            "div.acts",
            {},
            h("button.btn-text", { onClick: close }, t("common.cancel")),
            h(
              "button.btn-fill",
              {
                onClick: () => {
                  this._ask = null;
                  ask.run();
                },
              },
              ask.confirm
            )
          )
        )
      );
    }

    // The "Repor automático" button, where the integration could choose this
    // but the user has taken it over.
    _toAuto(subId, idx, k) {
      const sub = SUBS[subId];
      const path = sub.type === "list" ? "" : sub.type === "areas" ? `${idx}/${k}` : sub.type === "form" ? k : null;
      if (path === null || this._isAuto(sub.store, path) || !((this._autoPaths || {})[sub.store] || {})[path]) return null;
      return h(
        "button.to-auto",
        {
          type: "button",
          title: t("auto.reset_tooltip"),
          onClick: (e) => {
            e.preventDefault();
            e.stopPropagation();
            this._picker = null;
            this._ask = {
              title: t("auto.reset_title"),
              text: sub.type === "list" ? t("auto.reset_text_list", { list: sub.title }) : t("auto.reset_text_field"),
              confirm: t("auto.reset_confirm"),
              badge: false,
              run: () => this._resetAuto(subId, idx, k, path),
            };
            this._render();
          },
        },
        svg(I.scene, 12, { sw: 2 }),
        t("auto.reset")
      );
    }

    async _resetAuto(subId, idx, k, path) {
      const sub = SUBS[subId];
      this._msg = { kind: "saving" };
      this._render();
      try {
        const res = await this._ws("reset_auto", { key: sub.store, path });
        this._settings = { ...this._settings, [sub.store]: res.value, [AUTO_KEY]: { ...(this._settings[AUTO_KEY] || {}), [sub.store]: res.auto || {} } };
        // Only that choice changes here: other unsaved edits stay.
        const fresh = toDraft(subId, res.value, this._ctx());
        if (sub.type === "list") {
          this._draft[subId] = fresh;
          this._saved[subId] = clone(fresh);
        } else if (sub.type === "areas") {
          this._draft[subId][idx][k] = fresh[idx][k];
          this._saved[subId][idx][k] = fresh[idx][k];
        } else {
          this._draft[subId][k] = fresh[k];
          this._saved[subId][k] = fresh[k];
        }
        delete this._taken[`${sub.store}|${path}`];
        this._msg = { kind: "ok", text: t("auto.reset_done") };
      } catch (_) {
        this._msg = { kind: "err", text: t("auto.reset_failed") };
      }
      this._render();
    }

    _autoCount() {
      const auto = (this._settings && this._settings[AUTO_KEY]) || {};
      return Object.values(auto).reduce((n, m) => n + Object.keys(m || {}).length, 0);
    }

    _autoBadge() {
      return h("span.auto", { title: t("auto.badge_tooltip") }, svg(I.scene, 12, { sw: 2 }), t("auto.badge"));
    }

    // ---------- Navigation / state ----------
    _ctx() {
      return { areas: this._areas, entityName: (id) => this._entityName(id) };
    }

    _openSection(id) {
      const sec = SECTIONS.find((s) => s.id === id);
      this._section = sec;
      this._draft = {};
      this._saved = {};
      for (const sub of sec.subs) {
        const d = toDraft(sub, this._settings ? this._settings[SUBS[sub].store] : undefined, this._ctx());
        this._draft[sub] = d;
        this._saved[sub] = clone(d);
      }
      this._picker = null;
      this._msg = null;
      this._adv = false;
      this._open = {};
      this._taken = {};
      this._render(true);
    }

    _goHome() {
      this._section = null;
      this._leave = false;
      this._picker = null;
      this._msg = null;
      this._render(true);
      this._loadScreens();
    }

    _dirtySubs() {
      if (!this._section) return [];
      return this._section.subs.filter((s) => !same(this._draft[s], this._saved[s]));
    }

    // Typing doesn't rebuild the page (the input would lose its caret): it
    // only refreshes the "Alterado" badges, the item titles and the bar.
    _touch(fullRender) {
      if (this._msg && this._msg.kind !== "saving") this._msg = null;
      if (fullRender) return this._render();
      const root = this.shadowRoot;
      for (const sub of this._section.subs) {
        const badge = root.querySelector(`[data-dirty="${sub}"]`);
        if (badge) badge.style.display = same(this._draft[sub], this._saved[sub]) ? "none" : "";
      }
      root.querySelectorAll("[data-title]").forEach((el) => {
        const [sub, i] = el.dataset.title.split(":");
        el.textContent = this._itemTitle(sub, Number(i));
      });
      const bar = root.querySelector(".bar-wrap");
      if (bar) bar.replaceWith(this._renderBar(false));
    }

    async _save(after) {
      const dirty = this._dirtySubs();
      if (!dirty.length || this._saving) return;
      this._saving = true;
      this._picker = null;
      this._msg = { kind: "saving" };
      this._render();
      const dropped = [];
      try {
        for (const sub of dirty) {
          const def = SUBS[sub];
          let { value, dropped: n } = fromDraft(sub, this._draft[sub], this._ctx());
          // A person's calendar is stored in their colour too.
          if (sub === "outros") value = value.map((c) => (this._owner(c.entityId) ? { ...c, color: this._owner(c.entityId).color.key } : c));
          const res = await this._ws("set_settings", { key: def.store, value });
          const auto = { ...((this._settings || {})[AUTO_KEY] || {}), [def.store]: (res && res.auto) || {} };
          this._settings = { ...(this._settings || {}), [def.store]: value, [AUTO_KEY]: auto };
          if (n) dropped.push(t(`${def.ns}.dropped`, { count: n }));
          const fresh = toDraft(sub, value, this._ctx());
          this._draft[sub] = fresh;
          this._saved[sub] = clone(fresh);
        }
        this._saving = false;
        this._msg = { kind: "ok", text: dropped.length ? joinList(dropped) + "." : "" };
        this._render();
        if (after) after();
      } catch (_) {
        this._saving = false;
        this._msg = { kind: "err", text: t("bar.save_failed") };
        this._render();
      }
    }

    _discard() {
      for (const sub of this._section.subs) this._draft[sub] = clone(this._saved[sub]);
      this._taken = {};
      this._msg = null;
      this._picker = null;
      this._render();
    }

    // ---------- Rendering ----------
    // `entering` (a new view) restarts the scroll and plays the fade-up.
    _render(entering) {
      if (!this._hass || !this._ready) return;
      const root = this.shadowRoot;
      const prevScroll = root.querySelector(".scroll");
      const keepScroll = prevScroll && !entering ? prevScroll.scrollTop : 0;
      const mobile = this._mobile;
      const gutter = mobile ? 16 : 24;

      const wrap = h("div.ha" + (mobile ? ".mobile" : ""), { style: `--gutter:${gutter}px; --h1:${mobile ? 26 : 32}px` });
      const toolbar = h(
        "header.toolbar",
        {},
        this._narrow
          ? h("button.icon-btn", { "aria-label": t("common.menu"), onClick: () => this.dispatchEvent(new Event("hass-toggle-menu", { bubbles: true, composed: true })) }, svg(I.menu, 24, { sw: 2 }))
          : null,
        h("span.title", { text: "ByteHomeDash" })
      );
      const scroll = h("div.scroll", {
        onClick: (e) => {
          if (this._picker && !e.composedPath().some((n) => n.dataset && n.dataset.picker !== undefined)) {
            this._picker = null;
            this._render();
          }
        },
      });
      const page = this._section ? this._renderSection(gutter) : this._renderHome(gutter);
      if (entering) page.classList.add("enter");
      scroll.appendChild(page);
      wrap.append(toolbar, scroll);
      if (this._section) wrap.appendChild(this._renderBar(entering));
      if (this._leave && this._section) wrap.appendChild(this._renderLeave());
      else if (this._ask && this._section) wrap.appendChild(this._renderAsk());

      root.innerHTML = "";
      root.appendChild(h("style", { text: STYLE }));
      root.appendChild(wrap);
      scroll.scrollTop = keepScroll;
      const search = root.querySelector("[data-search]");
      if (search) search.focus({ preventScroll: true });
    }

    _renderHome(gutter) {
      const mobile = this._mobile;
      const page = h("div.page", { style: `padding:${mobile ? 20 : 28}px ${gutter}px 48px; gap:20px` });
      page.appendChild(
        h(
          "div",
          { style: "display:flex; flex-direction:column; gap:6px" },
          h("h1", { text: t("home.title") }),
          h("p.lead", { text: t("home.lead") })
        )
      );
      if (this._screens !== undefined) page.appendChild(this._renderStatus());
      const autoN = this._autoCount();
      if (autoN && this._settings) {
        page.appendChild(
          h(
            "div.note",
            {},
            svg(I.scene, 18, { style: "flex-shrink:0; color:var(--fd-primary-text)" }),
            h("span", { text: t("auto.home_note", { count: autoN }) })
          )
        );
      }
      if (this._loadError) {
        page.appendChild(h("div.error-box", { text: t("home.load_error", { error: this._loadError }) }));
        return page;
      }
      if (!this._settings) {
        page.appendChild(h("div.loading", { text: t("home.loading") }));
        return page;
      }
      const tiles = h("div.tiles");
      for (const sec of SECTIONS) {
        const sm = this._summary(sec.id);
        tiles.appendChild(
          h(
            "button.tile",
            { "aria-label": `${sec.title}: ${sm.text}`, onClick: () => this._openSection(sec.id) },
            h("span.ic", {}, svg(sec.icon, 26)),
            h(
              "span.body",
              {},
              h("span.tt", { text: sec.title }),
              h("span.dd", { text: sec.desc }),
              h(
                "span.foot",
                {},
                h("span.chip." + sm.kind, {}, svg(sm.kind === "ok" ? I.check : sm.kind === "warn" ? I.alert : I.info, 16, { sw: 2.4, style: "flex-shrink:0" }), h("span", { text: sm.text }))
              )
            ),
            mobile ? svg(I.chevronRight, 22, { sw: 2, style: "flex-shrink:0; color:var(--fd-sec)" }) : null
          )
        );
      }
      page.appendChild(tiles);
      return page;
    }

    _renderStatus() {
      const screens = this._screens;
      let title;
      let sub;
      let on = false;
      if (screens === null) {
        title = t("status.unknown_title");
        sub = t("status.unknown_text");
      } else if (!screens.length) {
        title = t("status.none_title");
        sub = t("status.none_text");
      } else {
        on = true;
        title = t("status.connected", { count: screens.length, name: screens[0].name });
        sub = `${screens.length > 1 ? screens.map((s) => s.name).join(", ") + " · " : ""}${t("status.live_text")}`;
      }
      return h(
        "div.status",
        {},
        h("span.badge", { style: on ? "background:var(--fd-ok-tint); color:var(--fd-ok)" : "background:var(--fd-neutral-tint); color:var(--fd-sec)" }, svg(I.screen, 22)),
        h("div", { style: "flex:1; min-width:0; display:flex; flex-direction:column; gap:2px" }, h("span.t", { text: title }), h("span.s", { text: sub })),
        h("span.led", { style: `background:${on ? "var(--fd-ok)" : "var(--fd-faint)"}` })
      );
    }

    _summary(id) {
      const S = this._settings || {};
      const chip = (text, kind) => ({ text, kind });
      const arr = (k) => (Array.isArray(S[k]) ? S[k] : []);
      const obj = (k) => (S[k] && typeof S[k] === "object" && !Array.isArray(S[k]) ? S[k] : {});
      if (id === "familia") {
        const n = arr("family_members").length;
        return n ? chip(t("people.count", { count: n }), "ok") : chip(t("sections.family.empty"), "warn");
      }
      if (id === "calendarios") {
        const cals = arr("calendar_entities");
        return cals.length ? chip(cals.map((c) => this._entityName(c.entityId).replace(/ em Portugal$/i, "")).join(" · "), "ok") : chip(t("sections.calendars.empty"), "info");
      }
      if (id === "meteo") {
        const m = obj("temperature_entities");
        const n = (m.exteriorTempEntityId ? 1 : 0) + (m.weatherStateEntityId ? 1 : 0);
        return n === 2 ? chip(t("sections.weather.complete"), "ok") : chip(t("sections.weather.partial", { count: n }), "warn");
      }
      if (id === "assistente") {
        const a = obj("assistant");
        return a.name ? chip(a.wakePhrase ? t("sections.assistant.summary", { name: a.name, phrase: a.wakePhrase }) : a.name, "ok") : chip(t("sections.assistant.unnamed"), "warn");
      }
      if (id === "listas") {
        const n = arr("todo_lists").length;
        return n ? chip(t("lists.count", { count: n }), "ok") : chip(t("sections.lists.empty"), "warn");
      }
      if (id === "divisoes") {
        const ids = new Set(this._areas.map((a) => a.area_id));
        const k = arr("rooms").filter((r) => ids.has(r.areaId) && SUBS.areas.fields.some((f) => str(r[f.k]).trim())).length;
        return chip(t("sections.rooms.summary", { count: k, total: this._areas.length }), k && k === this._areas.length ? "ok" : "info");
      }
      if (id === "casa") {
        const hs = obj("house_screen");
        const sc = arr("house_scenes").length;
        const cam = arr("house_cameras").length;
        return chip(`${hs.alarmEntityId ? t("sections.house.alarm") + " · " : ""}${t("scenes.count", { count: sc })} · ${t("cameras.count", { count: cam })}`, hs.alarmEntityId ? "ok" : "warn");
      }
      if (id === "energia") {
        const e = obj("energy_entities");
        const fl = ["solarPowerEntityId", "gridPowerEntityId", "batteryPowerEntityId", "batterySocEntityId", "homePowerEntityId"].filter((k) => e[k]).length;
        const n = arr("individual_sensors").length;
        return chip(`${t("sections.energy.sensors", { count: fl })} · ${t("consumers.count", { count: n })}`, fl === 5 ? "ok" : "warn");
      }
      if (id === "aspiradores") {
        const n = arr("vacuums").length;
        return n ? chip(t("vacuums.count", { count: n }), "ok") : chip(t("sections.vacuums.empty"), "info");
      }
      if (id === "carros") {
        const cars = carsList(S.ev_cars);
        if (!cars.length) return chip(t("sections.cars.empty"), "info");
        const missing = cars.reduce((n, c) => n + SUBS.carros.fieldsFor(c).filter((f) => f.t === "entity" && !f.opt && !c[f.k]).length, 0);
        const tail = missing ? ` · ${t("sections.cars.missing", { count: missing })}` : "";
        return chip(`${t("cars.count", { count: cars.length })}${tail}`, missing ? "warn" : "ok");
      }
      return chip("", "info");
    }

    _renderSection(gutter) {
      const sec = this._section;
      const page = h("div.page", { style: `padding:12px ${gutter}px ${this._mobile ? 150 : 120}px; gap:8px` });
      const back = () => {
        if (!this._dirtySubs().length) return this._goHome();
        this._leave = true;
        this._picker = null;
        this._render();
      };
      page.appendChild(
        h(
          "div",
          { style: "display:flex; flex-direction:column; gap:6px; padding-bottom:8px" },
          h("button.back", { onClick: back }, svg(I.back, 20, { sw: 2 }), t("common.back")),
          h("div.sec-title", {}, h("span.ic", {}, svg(sec.icon, 24)), h("h1", { text: sec.title })),
          h("p.lead", { text: sec.intro })
        )
      );
      for (const sub of sec.subs) page.appendChild(this._renderSub(sub));
      return page;
    }

    _renderSub(subId) {
      const def = SUBS[subId];
      const d = this._draft[subId];
      let count = "";
      if (def.type === "list" && d.length) {
        count = t(`${def.ns}.count`, { count: d.length });
        if (def.max) count = t("common.of_max", { items: count, max: def.max });
      }
      if (def.type === "areas") {
        const n = this._areas.filter((a) => this._areaCount(d[a.area_id]) > 0).length;
        count = t("rooms.configured", { count: n, total: this._areas.length });
      }
      const section = h(
        "section.sub",
        { "aria-label": def.title },
        h(
          "div.sub-head",
          {},
          h("h2", { text: def.title }),
          def.type === "list" && this._isAuto(def.store, "") && same(d, this._saved[subId]) ? this._autoBadge() : null,
          def.type === "list" ? this._toAuto(subId, null, null) : null,
          h("span.dirty", { "data-dirty": subId, style: same(d, this._saved[subId]) ? "display:none" : "" }, h("i"), t("common.changed")),
          count ? h("span.count", { text: count }) : null
        ),
        def.hint ? h("p.hint", { text: def.hint }) : null
      );
      if (def.type === "form") section.appendChild(this._renderFormCard(subId));
      else if (def.type === "list") section.appendChild(this._renderList(subId));
      else if (def.type === "areas") section.appendChild(this._renderAreas(subId));
      return section;
    }

    // Fields two to a row; one marked full (or left alone at the end of a
    // run) spans both. One column on a phone.
    _grid(subId, idx, item, fields, opts = {}) {
      const grid = h("div.grid");
      const cols = this._mobile ? 1 : 2;
      const cells = fields.map((f) => ({ f, full: cols === 1 || !!f.full || (f.t === "color" && subId !== "outros") }));
      let pending = null;
      for (const c of cells) {
        if (c.full) {
          if (pending) pending.full = true;
          pending = null;
        } else if (pending) {
          pending = null;
        } else {
          pending = c;
        }
      }
      if (pending) pending.full = true;
      for (const c of cells) {
        const el = this._field(c.f, subId, idx, item, opts);
        if (c.full) el.classList.add("full");
        grid.appendChild(el);
      }
      return grid;
    }

    _renderFormCard(subId) {
      const def = SUBS[subId];
      const d = this._draft[subId];
      const card = h("div.card" + (this._picker && this._picker.sub === subId ? ".raised" : ""));
      const grid = this._grid(subId, -1, d, def.fields);
      card.appendChild(grid);
      if (def.adv) {
        const values = def.adv.map((f) => str(d[f.k]).trim() || "10");
        const allSame = values.every((v) => v === values[0]);
        grid.appendChild(
          h(
            "button.adv.full",
            {
              "aria-expanded": this._adv ? "true" : "false",
              onClick: () => {
                this._adv = !this._adv;
                this._render();
              },
            },
            svg(I.chevronRight, 20, { sw: 2, style: `color:var(--fd-sec); transform:rotate(${this._adv ? 90 : 0}deg); transition:transform .2s ease` }),
            h("span.lbl", { text: t("common.advanced") }),
            this._adv ? null : h("span.val", { text: allSame ? t("energy_flow.adv_same", { value: values[0] }) : t("energy_flow.adv_mixed") })
          )
        );
        if (this._adv) {
          for (const f of def.adv) grid.appendChild(this._field(f, subId, -1, d));
          grid.appendChild(
            h("div.note.full", {}, svg(I.info, 18, { style: "flex-shrink:0" }), h("span", { text: t("energy_flow.adv_note") }))
          );
        }
      }
      return card;
    }

    _itemTitle(subId, i) {
      const def = SUBS[subId];
      const item = this._draft[subId][i];
      if (!item) return "";
      if (subId === "pessoas") return item.name.trim() || t("people.new_item");
      if (subId === "outros") return item.entityId ? this._entityName(item.entityId) : t("calendars.new_item");
      if (str(item.name).trim()) return item.name;
      if (item[def.req]) return this._entityName(item[def.req]);
      return t(`${def.ns}.new_item`);
    }

    _renderList(subId) {
      const def = SUBS[subId];
      const list = this._draft[subId];
      const stack = h("div.stack");
      if (!list.length) stack.appendChild(h("div.card", {}, h("div.empty", {}, svg(I.info, 22, { style: "flex-shrink:0" }), h("span", { text: def.empty }))));
      list.forEach((item, i) => {
        const missing = def.req && !str(item[def.req]).trim();
        let dot = null;
        let icon = null;
        if (subId === "pessoas") dot = COLORS[colorIndex(item.color, i % COLORS.length)].hex;
        else if (subId === "outros" && this._owner(item.entityId)) dot = this._owner(item.entityId).color.hex;
        else if (subId === "outros") dot = isHoliday(item.entityId + " " + this._entityName(item.entityId)) ? HOLIDAY_RED : COLORS[colorIndex(item.color, 3)].hex;
        else if (subId === "consumos") icon = (APPLIANCES.find((a) => a.key === item.icon) || APPLIANCES[5]).icon;
        else if (subId === "carros") icon = I.car;
        else icon = item.entityId ? this._entityIcon(item.entityId) : def.itemIcon;
        let subText = "";
        if (missing) subText = t(`${def.ns}.missing`);
        else if (subId === "outros" && this._owner(item.entityId)) subText = t("calendars.owner", { name: this._owner(item.entityId).name });
        else if (subId === "pessoas") subText = item.calendarEntityId ? t("people.personal_calendar", { calendar: this._entityName(item.calendarEntityId) }) : t("people.no_personal_calendar");
        else if (subId === "carros") subText = `${t(`cars.kinds.${item.kind === "fuel" ? "fuel" : "electric"}`)} · ${t(item.homeEntityId ? "cars.shows_at_home" : "cars.shows_always")}`;
        const titled = subId === "pessoas" ? !!item.name.trim() : subId === "outros" ? !!item.entityId : !!(str(item.name).trim() || item[def.req]);
        const move = (delta) => {
          const j = i + delta;
          if (j < 0 || j >= list.length) return;
          [list[i], list[j]] = [list[j], list[i]];
          this._touch(true);
        };
        const title = this._itemTitle(subId, i);
        const head = h(
          "div.card-head",
          {},
          dot ? h("span.dot", { style: `background:${dot}` }) : null,
          icon
            ? h("span.hic", { style: missing ? "background:var(--fd-warn-tint); color:var(--fd-warn-text)" : "background:var(--fd-primary-tint); color:var(--fd-primary-text)" }, svg(icon, 20))
            : null,
          h(
            "div.txt",
            {},
            h("span.tt", { "data-title": `${subId}:${i}`, text: title, style: titled ? "" : "color:var(--fd-sec)" }),
            subText ? h("span.ss" + (missing ? ".warn" : ""), {}, missing ? svg(I.alert, 14, { sw: 2.2 }) : null, subText) : null
          ),
          h(
            "div.moves",
            {},
            h("button.icon-btn", { "aria-label": t("common.move_up", { name: title }), "aria-disabled": i === 0 ? "true" : "false", onClick: () => move(-1) }, svg(I.up, 20, { sw: 2 })),
            h("button.icon-btn", { "aria-label": t("common.move_down", { name: title }), "aria-disabled": i === list.length - 1 ? "true" : "false", onClick: () => move(1) }, svg(I.down, 20, { sw: 2 })),
            h(
              "button.icon-btn",
              {
                "aria-label": t("common.remove", { name: title }),
                onClick: () => {
                  list.splice(i, 1);
                  this._touch(true);
                },
              },
              svg(I.trash, 20)
            )
          )
        );
        const raised = this._picker && this._picker.sub === subId && this._picker.idx === i;
        const fields = def.fieldsFor ? def.fieldsFor(item) : def.fields;
        stack.appendChild(h("div.card" + (raised ? ".raised" : ""), {}, head, this._grid(subId, i, item, fields, { flagMissing: true, required: t(`${def.ns}.required`) })));
      });
      const full = def.max && list.length >= def.max;
      const add = h(
        "button.add",
        {
          "aria-disabled": full ? "true" : "false",
          onClick: () => {
            if (full) return;
            const blank = def.blank();
            if (subId === "pessoas") blank.color = COLORS[list.length % COLORS.length].key;
            list.push(blank);
            this._touch(true);
          },
        },
        svg(full ? I.block : I.plus, 20, { sw: 2 }),
        full ? t("common.max_reached", { max: def.max }) : def.add
      );
      const root = h("div.stack", {}, stack, add);
      const lock = this._autoLock(subId, null, null);
      if (lock) {
        this._guard(
          root,
          lock,
          t("auto.takeover_title", { name: def.title }),
          t("auto.takeover_list")
        );
      }
      return root;
    }

    _areaCount(a) {
      return SUBS.areas.fields.filter((f) => a && str(a[f.k]).trim()).length;
    }

    _renderAreas(subId) {
      const def = SUBS[subId];
      const d = this._draft[subId];
      const out = h("div");
      if (!this._areas.length) {
        out.appendChild(
          h("div.card", {}, h("div.empty", {}, svg(I.info, 22, { style: "flex-shrink:0" }), h("span", { text: t("rooms.empty") })))
        );
        return out;
      }
      const fmt = (st, unit) => (st && !isNaN(parseFloat(st.state)) ? (Math.round(parseFloat(st.state) * 10) / 10).toLocaleString(LOCALE) + unit : null);
      const byId = Object.fromEntries(this._areas.map((a) => [a.area_id, a]));
      const order = d[AREA_ORDER];
      const group = h("div.stack.reorder");
      out.appendChild(group);
      order.forEach((id, i) => {
        const a = byId[id];
        const floor = this._floorById[a.floor_id];
        const floorName = floor ? floor.name : t("rooms.no_floor");
        const item = d[a.area_id];
        const n = this._areaCount(item);
        const open = !!this._open[a.area_id];
        const meta = [floorName, fmt(a.temperature_entity_id && this._hass.states[a.temperature_entity_id], " ºC"), fmt(a.humidity_entity_id && this._hass.states[a.humidity_entity_id], " %")]
          .filter(Boolean)
          .join(" · ");
        const toggle = () => {
          this._open[a.area_id] = !open;
          this._picker = null;
          this._render();
        };
        const head = h(
          "div.card-head",
          {},
          h("button.icon-btn.drag-handle", { "aria-label": t("rooms.drag", { name: a.name }), onPointerdown: (e) => this._drag(e, group, order, i) }, svg(I.grip, 22, { sw: 3 })),
          h("span.hic", { style: n ? "background:var(--fd-primary-tint); color:var(--fd-primary-text)" : "background:var(--fd-neutral-tint); color:var(--fd-sec)" }, svg(I.rooms, 20)),
          h(
            "div.txt",
            {},
            h("span.tt", {}, a.name || a.area_id, def.fields.some((f) => this._isAuto(def.store, `${a.area_id}/${f.k}`)) ? this._autoBadge() : null),
            h("span.ss", { text: open ? meta : t("rooms.fields_configured", { floor: floorName, count: n, total: def.fields.length }) })
          ),
          h(
            "button.icon-btn",
            { "aria-expanded": open ? "true" : "false", "aria-label": t(open ? "rooms.collapse" : "rooms.expand", { name: a.name }), onClick: toggle },
            svg(I.chevronDown, 22, { sw: 2, style: `transform:rotate(${open ? 180 : 0}deg); transition:transform .2s ease` })
          )
        );
        const raised = this._picker && this._picker.sub === subId && this._picker.idx === a.area_id;
        const card = h("div.card" + (raised ? ".raised" : ""), {}, head);
        if (open) {
          const grid = this._grid(subId, a.area_id, item, def.fields);
          grid.appendChild(h("div.note.full", {}, svg(I.info, 18, { style: "flex-shrink:0" }), h("span", { text: t("rooms.area_note", { name: a.name }) })));
          card.appendChild(grid);
        }
        group.appendChild(card);
      });
      return out;
    }

    // Drags card `from` of `group` by its handle: it follows the pointer, the
    // cards it passes slide out of its way, and `order` changes on release.
    _drag(e, group, order, from) {
      if (e.button) return;
      e.preventDefault();
      const handle = e.currentTarget;
      handle.setPointerCapture(e.pointerId);
      const cards = [...group.children];
      const card = cards[from];
      const rects = cards.map((c) => c.getBoundingClientRect());
      const gap = cards.length > 1 ? rects[1].top - rects[0].bottom : 0;
      const shift = rects[from].height + gap;
      const y0 = e.clientY;
      let to = from;
      card.classList.add("dragging");
      const move = (ev) => {
        const dy = ev.clientY - y0;
        card.style.transform = `translateY(${dy}px)`;
        const mid = rects[from].top + rects[from].height / 2 + dy;
        to = from;
        rects.forEach((r, j) => {
          const m = r.top + r.height / 2;
          if (j < from && mid < m) to = Math.min(to, j);
          if (j > from && mid > m) to = Math.max(to, j);
        });
        cards.forEach((c, j) => {
          if (j !== from) c.style.transform = j >= to && j < from ? `translateY(${shift}px)` : j <= to && j > from ? `translateY(${-shift}px)` : "";
        });
      };
      const end = () => {
        handle.removeEventListener("pointermove", move);
        handle.removeEventListener("pointerup", end);
        handle.removeEventListener("pointercancel", end);
        card.classList.remove("dragging");
        for (const c of cards) c.style.transform = "";
        if (to === from) return;
        order.splice(to, 0, ...order.splice(from, 1));
        this._touch(true);
      };
      handle.addEventListener("pointermove", move);
      handle.addEventListener("pointerup", end);
      handle.addEventListener("pointercancel", end);
    }

    _target(subId, idx) {
      const d = this._draft[subId];
      return idx === -1 ? d : d[idx];
    }

    _field(def, subId, idx, item, opts = {}) {
      const v = item[def.k];
      const wrap = h("div.field", { "data-field": `${subId}:${idx}:${def.k}` });
      const lock = this._autoLock(subId, idx, def.k);
      const label = h("label", {}, def.label);
      if (def.req) label.appendChild(h("span.req", { text: " *" }));
      if (def.opt) label.appendChild(h("span.optional", { text: ` (${t("common.optional")})` }));
      const sub = SUBS[subId];
      const path = sub.type === "areas" ? `${idx}/${def.k}` : sub.type === "form" ? def.k : null;
      if (path !== null && this._isAuto(sub.store, path) && same(item[def.k], (this._saved[subId] && (idx === -1 ? this._saved[subId] : this._saved[subId][idx]) || {})[def.k])) {
        label.appendChild(this._autoBadge());
      }
      const toAuto = sub.type !== "list" && this._toAuto(subId, idx, def.k);
      if (toAuto) label.appendChild(toAuto);
      wrap.appendChild(label);
      let help = def.help || "";
      let helpWarn = false;
      const set = (val, structural) => {
        this._target(subId, idx)[def.k] = val;
        this._touch(structural);
      };

      if (def.t === "text" || def.t === "number") {
        const input = h("input", {
          value: str(v),
          placeholder: def.ph || (def.t === "number" ? "10" : ""),
          inputMode: def.t === "number" ? "numeric" : "text",
          readOnly: !!lock,
          "aria-label": def.label,
          onInput: (e) => {
            const val = def.t === "number" ? e.target.value.replace(/[^0-9]/g, "") : e.target.value;
            if (val !== e.target.value) e.target.value = val;
            set(val, false);
          },
        });
        wrap.appendChild(h("div.textbox", {}, input, def.suffix ? h("span.suffix", { text: def.suffix }) : null));
      } else if (def.t === "entity") {
        const open = !!(this._picker && this._picker.sub === subId && this._picker.idx === idx && this._picker.k === def.k);
        const flag = def.req && !str(v).trim() && opts.flagMissing;
        const area = v ? this._entityArea(v) : "";
        const btn = h(
          "button.pick-btn" + (open ? ".open" : "") + (flag ? ".missing" : ""),
          {
            "aria-haspopup": "listbox",
            "aria-expanded": open ? "true" : "false",
            "aria-label": `${def.label}: ${v ? this._entityName(v) : t("picker.choose_entity")}`,
            onClick: () => {
              this._picker = open ? null : { sub: subId, idx, k: def.k };
              this._pq = "";
              this._render();
            },
          },
          svg(v ? this._entityIcon(v) : I.plus, 22, { style: `flex-shrink:0; color:${v ? "var(--fd-sec)" : "var(--fd-faint)"}` }),
          h("span.txt", {}, h("span.nm" + (v ? "" : ".empty"), { text: v ? this._entityName(v) : t("picker.choose_entity") }), v ? h("span.meta", { text: v + (area ? ` · ${area}` : "") }) : null),
          v && !def.req
            ? h(
                "span.clear",
                {
                  role: "button",
                  "aria-label": t("picker.clear", { label: def.label }),
                  onClick: (e) => {
                    e.stopPropagation();
                    set("", true);
                  },
                },
                svg(I.close, 18, { sw: 2 })
              )
            : null,
          svg(I.chevronDown, 22, { sw: 2, style: "flex-shrink:0; margin-right:4px; color:var(--fd-sec)" })
        );
        const picker = h("div.picker", { "data-picker": "" }, btn);
        if (open) picker.appendChild(this._renderMenu(def, subId, idx, v));
        wrap.appendChild(picker);
        if (flag) {
          help = opts.required;
          helpWarn = true;
        }
      } else if (def.t === "color") {
        const owner = subId === "outros" ? this._owner(item.entityId) : null;
        const holiday = !owner && subId === "outros" && isHoliday(item.entityId + " " + this._entityName(item.entityId));
        const locked = holiday || !!owner;
        const row = h("div.swatches", { role: "radiogroup", "aria-label": def.label });
        const current = colorIndex(v, subId === "pessoas" && typeof idx === "number" ? idx % COLORS.length : 3);
        const choices = owner ? [owner.color] : holiday ? [{ key: null, hex: HOLIDAY_RED, name: t("colors.red") }] : COLORS;
        choices.forEach((c, i) => {
          const on = locked || i === current;
          row.appendChild(
            h(
              "button.swatch",
              {
                role: "radio",
                "aria-checked": on ? "true" : "false",
                "aria-label": c.name,
                title: c.name,
                style: `background:${c.hex}; box-shadow:${on ? `0 0 0 3px var(--fd-card), 0 0 0 5px ${c.hex}` : "none"}`,
                onClick: () => {
                  if (!locked) set(c.key, true);
                },
              },
              svg(owner ? I.lock : I.check, 18, { sw: owner ? 2.2 : 3, stroke: on ? "#FFFFFF" : "transparent" })
            )
          );
        });
        if (owner) {
          row.appendChild(h("span", { style: "font-size:13px; color:var(--fd-sec); line-height:1.4", text: t("calendars.owner_color", { name: owner.name }) }));
          help = "";
        }
        if (holiday) {
          row.appendChild(h("span", { style: "font-size:13px; color:var(--fd-sec); line-height:1.4", text: t("calendars.holiday_color") }));
          help = "";
        }
        wrap.appendChild(row);
      } else if (def.t === "seg") {
        const row = h("div.seg", { role: "radiogroup", "aria-label": def.label });
        for (const o of def.options) {
          const on = (v || def.options[0].key) === o.key;
          row.appendChild(h("button" + (on ? ".on" : ""), { role: "radio", "aria-checked": on ? "true" : "false", onClick: () => !on && set(o.key, true) }, svg(o.icon, 18, { sw: 1.9 }), o.name));
        }
        wrap.appendChild(row);
      } else if (def.t === "icon") {
        const row = h("div.icons", { role: "radiogroup", "aria-label": def.label });
        for (const a of APPLIANCES) {
          const on = v === a.key;
          row.appendChild(
            h("button.icon-opt" + (on ? ".on" : ""), { role: "radio", "aria-checked": on ? "true" : "false", "aria-label": a.name, title: a.name, onClick: () => set(a.key, true) }, svg(a.icon, 24))
          );
        }
        wrap.appendChild(row);
        if (v === "boiler") {
          const hs = (this._settings && this._settings.house_screen) || {};
          const own = hs.waterHeaterEntityId || hs.waterHeaterTempEntityId || hs.waterHeaterPowerEntityId;
          help = own ? t("consumers.boiler_help_own") : t("consumers.boiler_help_shared");
        }
      }
      if (help) wrap.appendChild(h("span.help" + (helpWarn ? ".warn" : ""), { text: help }));
      if (lock && sub.type !== "list") {
        const then =
          def.t === "entity"
            ? () => {
                this._picker = { sub: subId, idx, k: def.k };
                this._pq = "";
                this._render();
              }
            : def.t === "text" || def.t === "number"
              ? () => {
                  const el = this.shadowRoot.querySelector(`[data-field="${subId}:${idx}:${def.k}"] input`);
                  if (el) el.focus();
                }
              : null;
        this._guard(
          wrap,
          lock,
          t("auto.takeover_title", { name: def.label }),
          t("auto.takeover_field"),
          then
        );
      }
      return wrap;
    }

    _renderMenu(def, subId, idx, value) {
      const menu = h("div.menu", { role: "listbox", "aria-label": t("picker.choose", { label: def.label }) });
      const optsBox = h("div.opts");
      const foot = h("div.foot");
      const LIMIT = 80;
      const fill = () => {
        const all = this._entityOptions(def.dom, this._pq);
        optsBox.innerHTML = "";
        for (const o of all.slice(0, LIMIT)) {
          const on = o.id === value;
          optsBox.appendChild(
            h(
              "button.opt" + (on ? ".on" : ""),
              {
                role: "option",
                "aria-selected": on ? "true" : "false",
                onClick: () => {
                  this._target(subId, idx)[def.k] = o.id;
                  this._picker = null;
                  this._touch(true);
                },
              },
              svg(this._entityIcon(o.id), 22, { style: "flex-shrink:0; color:var(--fd-sec)" }),
              h("span.txt", {}, h("span.nm", { text: o.name }), h("span.id", { text: o.id })),
              o.area ? h("span.area", { text: o.area }) : null,
              svg(I.check, 20, { sw: 2.4, stroke: on ? "var(--fd-primary-text)" : "transparent", style: "flex-shrink:0" })
            )
          );
        }
        if (!all.length) optsBox.appendChild(h("div.none", { text: t("picker.no_results") }));
        const scope = def.dom ? t("picker.only_domains", { domains: def.dom.map((d) => t(`domains.${d}`, null, d)).join(` ${t("picker.or")} `) }) : t("picker.any");
        foot.textContent = `${scope} · ${t("picker.results", { count: all.length })}${all.length > LIMIT ? ` · ${t("picker.search_more")}` : ""}`;
      };
      const search = h("input", {
        value: this._pq,
        placeholder: t("picker.search"),
        "aria-label": t("picker.search"),
        "data-search": "",
        onInput: (e) => {
          this._pq = e.target.value;
          fill();
        },
      });
      menu.append(h("div.search", {}, svg(I.search, 20, { sw: 2, style: "color:var(--fd-sec)" }), search), optsBox, foot);
      fill();
      return menu;
    }

    _renderBar(entering) {
      const dirty = this._dirtySubs();
      const m = this._msg;
      let icon = null;
      let strong = "";
      let text = "";
      let color = "var(--fd-sec)";
      let spin = false;
      if (m && m.kind === "saving") {
        spin = true;
        strong = t("bar.saving");
        color = "var(--fd-text)";
      } else if (m && m.kind === "err") {
        icon = I.alert;
        strong = t("bar.error");
        text = m.text;
        color = "var(--fd-error)";
      } else if (m && m.kind === "ok" && !dirty.length) {
        icon = I.check;
        strong = t("bar.saved");
        text = m.text;
        color = "var(--fd-ok)";
      } else if (dirty.length) {
        icon = I.dot;
        strong = t("bar.unsaved");
        text = (this._section.subs.length > 1 ? t("bar.unsaved_in", { sections: joinList(dirty.map((s) => SUBS[s].title)) }) : "") + ".";
        color = "var(--fd-warn-text)";
      } else {
        text = t("bar.no_changes");
      }
      const canSave = dirty.length > 0 && !this._saving;
      return h(
        "div.bar-wrap" + (entering ? ".enter" : ""),
        { role: "region", "aria-label": t("bar.region") },
        h(
          "div.bar",
          {},
          h(
            "div.msg",
            { "aria-live": "polite", style: `color:${color}` },
            spin ? h("span.spin") : null,
            icon ? svg(icon, 20, { sw: 2, style: "flex-shrink:0" }) : null,
            h("span", {}, strong ? h("strong", { text: strong }) : null, text ? (strong && !text.startsWith(".") ? " " : "") + text : null)
          ),
          h(
            "div.acts",
            {},
            canSave ? h("button.btn-text", { onClick: () => this._discard() }, t("bar.discard")) : null,
            h("button.btn-fill", { "aria-disabled": canSave ? "false" : "true", onClick: () => canSave && this._save() }, m && m.kind === "err" ? t("bar.retry") : t("bar.save"))
          )
        )
      );
    }

    _renderLeave() {
      const names = joinList(this._dirtySubs().map((s) => SUBS[s].title)) || t("leave.this_section");
      return h(
        "div.scrim",
        {},
        h(
          "div.dialog",
          { role: "alertdialog", "aria-modal": "true", "aria-label": t("leave.title") },
          h("h2", { text: t("leave.title") }),
          h("p.lead", { text: t("leave.text", { sections: names }) }),
          h(
            "div.acts",
            {},
            h(
              "button.btn-text",
              {
                onClick: () => {
                  this._leave = false;
                  this._render();
                },
              },
              t("leave.stay")
            ),
            h("button.btn-text.danger", { onClick: () => this._goHome() }, t("leave.leave")),
            h(
              "button.btn-fill",
              {
                onClick: () => {
                  this._leave = false;
                  this._save(() => this._goHome());
                },
              },
              t("leave.save_and_leave")
            )
          )
        )
      );
    }
  }

  if (!customElements.get("bytehomedash-panel")) {
    customElements.define("bytehomedash-panel", ByteHomeDashPanel);
  }
})();
