#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

./scripts/backup.sh

echo "[+] Basis-Images neu laden und Container neu bauen ..."
docker compose build --pull --no-cache
docker compose up -d

echo "[+] Status"
docker compose ps

echo ""
echo "Hinweis: Pi-hole ist absichtlich im pihole/Dockerfile auf eine Version gepinnt."
echo "Ein Versionsupgrade erfordert die bewusste Änderung dieser FROM-Zeile nach Prüfung der Release Notes."
