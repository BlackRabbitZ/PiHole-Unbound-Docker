#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md
set -eu

ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

fail() {
  echo "FEHLER: $*" >&2
  exit 1
}

warn() {
  echo "WARNUNG: $*" >&2
}

get_env() {
  key=$1
  default=$2
  value=""
  if [ -f .env ]; then
    value=$(sed -n "s/^${key}=//p" .env | tail -n 1 | tr -d '\r')
    value=$(printf '%s' "$value" | sed 's/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')
  fi
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "$default"
  fi
}

command -v docker >/dev/null 2>&1 || fail "Docker wurde nicht gefunden."
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 ('docker compose') wurde nicht gefunden."
docker info >/dev/null 2>&1 || fail "Docker-Daemon ist nicht erreichbar. Läuft Docker und darf dein Benutzer darauf zugreifen?"

[ -f .env ] || fail ".env fehlt. Zuerst ./scripts/init.sh ausführen."
[ -s secrets/pihole_webpassword.txt ] || fail "Pi-hole-Secret fehlt oder ist leer. Zuerst ./scripts/init.sh ausführen."

mkdir -p etc-pihole backups

docker compose config --quiet || fail "compose.yaml/.env ist ungültig."

DNS_PORT=$(get_env PIHOLE_DNS_PORT 53)
BIND_IP=$(get_env PIHOLE_BIND_IP 0.0.0.0)

case "$DNS_PORT" in
  ''|*[!0-9]*) fail "PIHOLE_DNS_PORT muss numerisch sein (aktuell: $DNS_PORT)." ;;
  *) ;;
esac

if [ "$DNS_PORT" -lt 1 ] || [ "$DNS_PORT" -gt 65535 ]; then
  fail "PIHOLE_DNS_PORT liegt außerhalb 1-65535: $DNS_PORT"
fi

# Wenn bereits unser eigener Compose-Container existiert, darf dessen Portbelegung
# nicht als Fremdkonflikt gemeldet werden (z. B. beim Update/Recreate).
OWN_PROJECT=""
if docker inspect blackrabbitz-pihole >/dev/null 2>&1; then
  OWN_PROJECT=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' blackrabbitz-pihole 2>/dev/null || true)
fi

if [ "$OWN_PROJECT" != "blackrabbitz-pihole-unbound" ]; then
  if command -v ss >/dev/null 2>&1; then
    USED=$(ss -H -lntu "sport = :$DNS_PORT" 2>/dev/null || true)
    if [ -n "$USED" ]; then
      if [ "$BIND_IP" = "0.0.0.0" ] || [ "$BIND_IP" = "::" ] || [ -z "$BIND_IP" ]; then
        printf '%s\n' "$USED" >&2
        fail "Host-Port $DNS_PORT ist bereits belegt. Prüfe z. B. systemd-resolved, einen anderen DNS-Server oder einen alten Container."
      fi

      if printf '%s\n' "$USED" | grep -Eq "(^|[[:space:]])(0\\.0\\.0\\.0|\\*|\\[::\\]|${BIND_IP}):${DNS_PORT}([[:space:]]|$)"; then
        printf '%s\n' "$USED" >&2
        fail "${BIND_IP}:${DNS_PORT} kollidiert mit einem vorhandenen Listener."
      fi

      warn "Port $DNS_PORT wird auf einem anderen Interface verwendet. Da PIHOLE_BIND_IP=$BIND_IP gesetzt ist, wird der Start trotzdem versucht."
    fi
  else
    warn "'ss' ist nicht installiert; Host-Port $DNS_PORT konnte nicht vorab geprüft werden."
  fi
fi

if [ "$DNS_PORT" -ne 53 ]; then
  warn "PIHOLE_DNS_PORT=$DNS_PORT. Für Router/Clients muss DNS normalerweise auf Host-Port 53 erreichbar sein."
fi

echo "[OK] Docker erreichbar"
echo "[OK] Compose-Konfiguration gültig"
echo "[OK] Pi-hole-Secret vorhanden"
echo "[OK] Preflight abgeschlossen (Bind: ${BIND_IP}:${DNS_PORT})"
