#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md
set -eu

ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

case "${1:-}" in
  "") BUILD_FLAG="" ;;
  --build) BUILD_FLAG="--build" ;;
  *)
    echo "Verwendung: $0 [--build]" >&2
    exit 2
    ;;
esac

./scripts/preflight.sh

echo ""
echo "[+] Starte Pi-hole + Unbound ..."
if [ -n "$BUILD_FLAG" ]; then
  if ! docker compose up -d --build; then
    echo "FEHLER: Docker Compose konnte den Stack nicht starten." >&2
    docker compose ps >&2 || true
    docker compose logs --tail=100 unbound pihole >&2 || true
    exit 1
  fi
else
  if ! docker compose up -d; then
    echo "FEHLER: Docker Compose konnte den Stack nicht starten." >&2
    docker compose ps >&2 || true
    docker compose logs --tail=100 unbound pihole >&2 || true
    exit 1
  fi
fi

wait_healthy() {
  container=$1
  label=$2
  max_checks=60
  check=0

  while [ "$check" -lt "$max_checks" ]; do
    state=$(docker inspect --format '{{.State.Status}}' "$container" 2>/dev/null || true)
    health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null || true)

    if [ "$state" = "running" ] && { [ "$health" = "healthy" ] || [ "$health" = "none" ]; }; then
      echo "[OK] $label: ${health}"
      return 0
    fi

    if [ "$state" = "exited" ] || [ "$state" = "dead" ]; then
      echo "FEHLER: $label ist im Zustand '$state'." >&2
      return 1
    fi

    check=$((check + 1))
    sleep 2
  done

  echo "FEHLER: $label wurde nicht rechtzeitig healthy." >&2
  return 1
}

if ! wait_healthy blackrabbitz-unbound "Unbound"; then
  docker compose logs --tail=120 unbound >&2 || true
  exit 1
fi

if ! wait_healthy blackrabbitz-pihole "Pi-hole"; then
  docker compose logs --tail=120 pihole >&2 || true
  exit 1
fi

echo ""
docker compose ps

echo ""
echo "Stack ist gestartet und die lokalen Healthchecks sind grün."
echo "Für den vollständigen Rekursions-/DNSSEC-Test: ./scripts/test-dns.sh"
