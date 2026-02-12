#!/usr/bin/env bash
set -euo pipefail

ZIP_PATH=${ZIP_PATH:-/home/server/kanban_ubuntu24.zip}
APP_DIR=${APP_DIR:-/opt/kanban}
APP_USER=${APP_USER:-kanban}
APP_GROUP=${APP_GROUP:-kanban}
SERVICE_NAME=${SERVICE_NAME:-kanban}

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)." >&2
  exit 1
fi

if [ ! -f "$ZIP_PATH" ]; then
  echo "Zip not found: $ZIP_PATH" >&2
  exit 1
fi

TMP_DIR=$(mktemp -d /tmp/kanban_update.XXXXXX)

unzip -q "$ZIP_PATH" -d "$TMP_DIR"

rsync -a --delete \
  --exclude '.venv' \
  --exclude 'instance' \
  --exclude 'backups' \
  --exclude '.env' \
  "$TMP_DIR/" "$APP_DIR/"

chown -R "$APP_USER":"$APP_GROUP" "$APP_DIR"

if [ ! -d "$APP_DIR/.venv" ]; then
  python3 -m venv "$APP_DIR/.venv"
fi

"$APP_DIR/.venv/bin/pip" install --upgrade pip
"$APP_DIR/.venv/bin/pip" install -r "$APP_DIR/requirements.txt"

systemctl restart "$SERVICE_NAME"

rm -rf "$TMP_DIR"

echo "Update completed and service restarted."
