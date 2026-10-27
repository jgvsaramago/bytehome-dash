"""Config flow for the ByteHomeDash integration.

Single-instance, no user input: this integration just needs to exist so its
storage and websocket commands are set up. There is nothing to configure.
"""
from __future__ import annotations

from homeassistant import config_entries

from .const import DOMAIN


class ByteHomeDashConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle a config flow for ByteHomeDash."""

    VERSION = 1

    async def async_step_user(self, user_input: dict | None = None) -> config_entries.ConfigFlowResult:
        await self.async_set_unique_id(DOMAIN)
        self._abort_if_unique_id_configured()

        if user_input is not None:
            return self.async_create_entry(title="ByteHomeDash", data={})

        return self.async_show_form(step_id="user")
