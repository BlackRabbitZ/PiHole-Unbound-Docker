#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu

ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo "FEHLER: Docker wurde nicht gefunden." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "FEHLER: Docker Compose v2 ('docker compose') wurde nicht gefunden." >&2
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
  echo "[+] .env aus .env.example erstellt"
fi

mkdir -p secrets etc-pihole backups
chmod 700 secrets backups 2>/dev/null || true

PASS_FILE=secrets/pihole_webpassword.txt
if [ ! -s "$PASS_FILE" ]; then
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 32 | tr -d '\n' > "$PASS_FILE"
  elif [ -r /dev/urandom ]; then
    od -An -N32 -tx1 /dev/urandom | tr -d ' \n' > "$PASS_FILE"
  else
    echo "FEHLER: Kein sicherer Zufallszahlengenerator verfügbar." >&2
    exit 1
  fi
  chmod 600 "$PASS_FILE"
  echo "[+] Starkes Pi-hole-Webpasswort erzeugt: $PASS_FILE"
else
  echo "[=] Vorhandenes Pi-hole-Webpasswort wird beibehalten."
fi

docker compose config >/dev/null

echo ""
echo "Initialisierung abgeschlossen."
echo "Prüfe .env und starte danach mit:"
echo "  ./scripts/start.sh"
