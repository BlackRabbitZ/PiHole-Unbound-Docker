#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md
set -eu

ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

docker compose ps

show_status() {
  container=$1
  label=$2

  if ! docker inspect "$container" >/dev/null 2>&1; then
    printf '\n--- %s ---\n' "$label"
    echo "nicht erstellt"
    return
  fi

  state=$(docker inspect --format '{{.State.Status}}' "$container")
  health=$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}kein Healthcheck{{end}}' "$container")
  restarts=$(docker inspect --format '{{.RestartCount}}' "$container")

  printf '\n--- %s ---\n' "$label"
  echo "Status:    $state"
  echo "Health:    $health"
  echo "Restarts:  $restarts"
}

show_status blackrabbitz-pihole "Pi-hole"
show_status blackrabbitz-unbound "Unbound"
