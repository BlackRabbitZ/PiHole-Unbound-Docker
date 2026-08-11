#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu
ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

ARCHIVE=${1:-}
if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "Verwendung: ./scripts/restore.sh backups/pihole-unbound-YYYYMMDD-HHMMSS.tar.gz" >&2
  exit 1
fi

case "$ARCHIVE" in
  *.tar.gz|*.tgz) ;;
  *) echo "FEHLER: Nur .tar.gz/.tgz-Backups werden akzeptiert." >&2; exit 1 ;;
esac

# Keine absoluten Pfade oder Parent-Traversal aus dem Archiv zulassen.
if tar -tzf "$ARCHIVE" | grep -Eq '(^/|(^|/)\.\.(/|$))'; then
  echo "FEHLER: Unsicherer Pfad im Archiv erkannt." >&2
  exit 1
fi

docker compose down 2>/dev/null || true
tar -xzf "$ARCHIVE" -C "$ROOT_DIR"
chmod 600 secrets/pihole_webpassword.txt 2>/dev/null || true

echo "Restore abgeschlossen. Start mit: ./scripts/start.sh"
