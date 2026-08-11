#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
set -eu

ok=0
fail=0

check() {
  name=$1
  shift
  printf '%-45s' "$name"
  if "$@" >/tmp/blackrabbitz-dns-test.out 2>&1; then
    echo "OK"
    ok=$((ok + 1))
  else
    echo "FEHLER"
    sed 's/^/  /' /tmp/blackrabbitz-dns-test.out || true
    fail=$((fail + 1))
  fi
}

check "Pi-hole beantwortet lokale DNS-Anfrage" \
  docker exec blackrabbitz-pihole dig @127.0.0.1 pi.hole A +time=3 +tries=1 +short

check "Unbound löst rekursiv auf" \
  docker exec blackrabbitz-unbound sh -c 'test -n "$(dig @127.0.0.1 -p 5335 example.com A +time=5 +tries=1 +short)"'

check "DNSSEC gültige Zone wird akzeptiert" \
  docker exec blackrabbitz-unbound sh -c 'dig @127.0.0.1 -p 5335 +dnssec dnssec.works A +time=5 +tries=1 | grep -q "status: NOERROR"'

check "DNSSEC ungültige Zone wird verworfen" \
  docker exec blackrabbitz-unbound sh -c 'dig @127.0.0.1 -p 5335 fail01.dnssec.works A +time=5 +tries=1 | grep -q "status: SERVFAIL"'

check "Pi-hole kann über Unbound Internet-DNS auflösen" \
  docker exec blackrabbitz-pihole sh -c 'test -n "$(dig @127.0.0.1 example.com A +time=5 +tries=1 +short)"'

rm -f /tmp/blackrabbitz-dns-test.out
printf '\nErgebnis: %s OK, %s Fehler\n' "$ok" "$fail"
[ "$fail" -eq 0 ]
