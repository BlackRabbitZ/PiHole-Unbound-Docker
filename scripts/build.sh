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

docker compose config --quiet

case "${1:-}" in
    "")
        echo "[+] Baue Pi-hole- und Unbound-Images ..."
        docker compose build
        ;;
    --pull)
        echo "[+] Baue Images und prüfe Basis-Images erneut ..."
        docker compose build --pull
        ;;
    pihole|unbound)
        echo "[+] Baue Service: $1"
        docker compose build "$1"
        ;;
    *)
        echo "Verwendung: $0 [--pull|pihole|unbound]" >&2
        exit 2
        ;;
esac

echo ""
echo "Build abgeschlossen. Images:"
docker compose images
