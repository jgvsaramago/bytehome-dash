#!/bin/sh
# One-off, on the Pi: moves a kiosk set up as flutter-homeassistant over to
# the bytehomedash names (service, env file, app and data directories).
# Safe to re-run; anything already moved is skipped.
#   sudo sh migrate-to-bytehomedash.sh
set -eu

USER_HOME=$(getent passwd "${SUDO_USER:?run with sudo from the kiosk user}" | cut -d: -f6)
OLD=flutter-homeassistant
NEW=bytehomedash

timeout 30 systemctl stop "$OLD.service" 2>/dev/null || true

if [ -f "/etc/systemd/system/$OLD.service" ]; then
  sed "s/$OLD/$NEW/g" "/etc/systemd/system/$OLD.service" > "/etc/systemd/system/$NEW.service"
  systemctl disable "$OLD.service" 2>/dev/null || true
  rm "/etc/systemd/system/$OLD.service"
fi
if [ -d "/etc/systemd/system/$OLD.service.d" ]; then
  mv "/etc/systemd/system/$OLD.service.d" "/etc/systemd/system/$NEW.service.d"
fi
if [ -f "/etc/$OLD.env" ]; then
  mv "/etc/$OLD.env" "/etc/$NEW.env"
fi

for dir in "$USER_HOME/$OLD:$USER_HOME/$NEW" \
           "$USER_HOME/src/$OLD:$USER_HOME/src/$NEW" \
           "$USER_HOME/.local/share/$OLD:$USER_HOME/.local/share/$NEW"; do
  from=${dir%%:*}
  to=${dir#*:}
  if [ -d "$from" ] && [ ! -e "$to" ]; then
    mv "$from" "$to"
  fi
done

systemctl daemon-reload
systemctl enable "$NEW.service"
systemctl start "$NEW.service"
systemctl --no-pager status "$NEW.service" | head -5
