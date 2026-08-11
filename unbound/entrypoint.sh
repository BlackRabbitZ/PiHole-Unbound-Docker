#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md
set -eu

ROOT_KEY=/var/lib/unbound/root.key
PACKAGED_KEY=/usr/share/dnssec-root/trusted-key.key

mkdir -p /var/lib/unbound /run/unbound

if [ ! -s "$ROOT_KEY" ]; then
  if [ ! -s "$PACKAGED_KEY" ]; then
    echo "FEHLER: DNSSEC-Root-Trust-Anchor fehlt: $PACKAGED_KEY" >&2
    exit 1
  fi
  cp "$PACKAGED_KEY" "$ROOT_KEY"
fi

chown unbound:unbound "$ROOT_KEY" /var/lib/unbound /run/unbound
chmod 0644 "$ROOT_KEY"

# RFC5011-Trust-Anchor aktualisieren. Ein vorübergehender Netzfehler darf den
# Start nicht blockieren, solange ein gültiger paketierter Anchor vorhanden ist.
unbound-anchor -a "$ROOT_KEY" >/dev/null 2>&1 || true
chown unbound:unbound "$ROOT_KEY" /var/lib/unbound /run/unbound
chmod 0644 "$ROOT_KEY"

unbound-checkconf /etc/unbound/unbound.conf
exec unbound -d -c /etc/unbound/unbound.conf
