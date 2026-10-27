# Changelog

One version for the whole project: each release has the app (built for
flutter-pi, attached to the GitHub release) and the Home Assistant
integration (installed through HACS from the same release). Install both
from the same release.

## 0.1.0

First release.

### App

- **Pages:** Home (house at a glance, the week, today's tasks, meals and
  shopping), Calendar (day, week, month and agenda), Tasks, Meals, Lists,
  House (rooms, climate, energy, cars, vacuums, cameras) and Music (Music
  Assistant), with light and dark themes.
- **Assistant:** the voice assistant on screen (Linux Voice Assistant with
  a reSpeaker): the answer shown as it's spoken, rows for the devices it
  acted on and for what its tools did (with Undo / Yes / No), web results
  as cards, sending a page to a phone, and who is speaking recognised by
  voice, with Settings › Recognised voices to register each person.
- **Cooking mode:** a recipe one step at a time, with timers that keep
  counting, ingredients to tick off and rescale, and voice control;
  minimised to a bubble.
- **Messages:** left by voice or written on the screen, in Lists and in a
  window each time the screen wakes until they're seen; optionally sent to
  the person's phone.
- **Browser:** a floating, modal or full-screen web view with its own
  volume, minimised to a bubble; its own settings (home page, search
  engine, how it opens) and a ⋮ menu to add the page to a meal or send it
  to a phone.
- **Intercom (Hikvision, optional):** the screen registers as an indoor
  extension over SIP: it rings, shows the door's live video, talks both
  ways and opens the door; call history with a picture of each ring.
  Without one, the screen shows a camera in its place.
- **Settings:** screen and sound, language, theme, doorbell tones, the
  voices the assistant recognises, the browser.
- **The screen in Home Assistant (MQTT):** brightness, on/off, theme,
  volume and the board's sensors.
- **Languages:** English and Portuguese, following Home Assistant's
  language unless one is chosen in Settings.

### Home Assistant integration

- **Settings panel** in the sidebar: people, calendars, lists, rooms, the
  House page, energy, cars, vacuums and the assistant; every entity the app
  shows is chosen here, with best-guess defaults.
- **Shared store** for what the screens edit (meal plan, tasks, messages),
  so every screen shows the same.
- **Agent tools** (the ByteHomeDash LLM API, alongside Assist): web results
  as cards, opening one, sending a page to a phone, planning meals (asking
  before replacing), the ingredients of planned meals for the shopping list,
  Cooking mode, events in a person's own calendar, the screens' tasks,
  messages, the doorbell calls and opening a page on the screen.
- **Speaker identification:** who is speaking (from the voice satellite)
  added to each turn, with that person's calendar and to-do list.
- **Languages:** the panel and the texts sent to screens and phones in
  English and Portuguese.
