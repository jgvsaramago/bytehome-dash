"""Constants for the ByteHomeDash integration."""

DOMAIN = "bytehomedash"

STORAGE_KEY = f"{DOMAIN}.settings"
STORAGE_VERSION = 1

# Where settings lived while the integration was called flutter_homeassistant;
# copied over on first load under the new name.
LEGACY_STORAGE_KEY = "flutter_homeassistant.settings"

EVENT_SETTINGS_UPDATED = f"{DOMAIN}_settings_updated"

# Cards to show / a card to open in a screen's Assistente (llm_api.py).
EVENT_ASSISTANT = f"{DOMAIN}_assistant"

# Settings earlier versions of the app stored and nothing reads any more;
# dropped from storage when the integration loads.
OBSOLETE_KEYS = (
    "calendar_entries",
    "energy_individual_sensors",
    "energy_page_settings",
    "house_mode",
    "mqtt",
    "music_assistant",
    "rooms_config",
)
