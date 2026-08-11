#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu
ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

mkdir -p backups
STAMP=$(date '+%Y%m%d-%H%M%S')
OUT="backups/pihole-unbound-${STAMP}.tar.gz"

FILES=""
for f in .env etc-pihole secrets/pihole_webpassword.txt; do
  if [ -e "$f" ]; then
    FILES="$FILES $f"
  fi
done

# shellcheck disable=SC2086
tar -czf "$OUT" $FILES
chmod 600 "$OUT" 2>/dev/null || true

echo "Backup erstellt: $OUT"
echo "ACHTUNG: Das Backup kann Konfiguration und Webpasswort enthalten. Sicher aufbewahren."
