#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

[ -s secrets/pihole_webpassword.txt ] || {
  echo "FEHLER: Secret fehlt. Zuerst ./scripts/init.sh ausführen." >&2
  exit 1
}

docker compose config >/dev/null
docker compose up -d --build

echo ""
echo "Container gestartet. Status:"
docker compose ps
