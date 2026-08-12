#!/usr/bin/env sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md
set -eu

ROOT_DIR=$(CDPATH="" cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT_DIR"

OUT_FILE=$(mktemp /tmp/blackrabbitz-dns-test.XXXXXX)
trap 'rm -f "$OUT_FILE"' EXIT HUP INT TERM

ok=0
fail=0

check() {
  name=$1
  shift
  printf '%-52s' "$name"
  if "$@" >"$OUT_FILE" 2>&1; then
    echo "OK"
    ok=$((ok + 1))
  else
    echo "FEHLER"
    sed 's/^/  /' "$OUT_FILE" || true
    fail=$((fail + 1))
  fi
}

if ! docker compose ps --status running --services | grep -qx 'unbound'; then
  echo "FEHLER: Unbound läuft nicht." >&2
  exit 1
fi
if ! docker compose ps --status running --services | grep -qx 'pihole'; then
  echo "FEHLER: Pi-hole läuft nicht." >&2
  exit 1
fi

check "Unbound beantwortet lokalen Readiness-Test" \
  docker compose exec -T unbound sh -ec \
  'dig @127.0.0.1 -p 5335 localhost A +time=2 +tries=1 +short | grep -qx "127.0.0.1"'

# The command substitution below intentionally runs inside the container.
# shellcheck disable=SC2016
check "Unbound löst rekursiv ins Internet auf" \
  docker compose exec -T unbound sh -ec \
  'test -n "$(dig @127.0.0.1 -p 5335 example.com A +time=5 +tries=2 +short)"'

check "DNSSEC: gültige Zone wird validiert (AD)" \
  docker compose exec -T unbound sh -ec \
  'dig @127.0.0.1 -p 5335 +dnssec dnssec.works A +time=5 +tries=2 | grep -Eq "flags:.* ad[; ]"'

check "DNSSEC: absichtlich defekte Zone wird verworfen" \
  docker compose exec -T unbound sh -ec \
  'dig @127.0.0.1 -p 5335 fail01.dnssec.works A +time=5 +tries=2 | grep -q "status: SERVFAIL"'

check "Pi-hole-Upstream zeigt auf Unbound" \
  docker compose exec -T pihole sh -ec \
  'pihole-FTL --config dns.upstreams | grep -q "unbound#5335"'

check "Pi-hole beantwortet lokale DNS-Anfrage" \
  docker compose exec -T pihole sh -ec \
  'dig -p "$(pihole-FTL --config dns.port)" +short +norecurse +retry=0 @127.0.0.1 pi.hole | grep -q .'

# The command substitution below intentionally runs inside the container.
# shellcheck disable=SC2016
check "Pi-hole löst über Unbound Internet-DNS auf" \
  docker compose exec -T pihole sh -ec \
  'test -n "$(dig @127.0.0.1 example.com A +time=5 +tries=2 +short)"'

printf '\nErgebnis: %s OK, %s Fehler\n' "$ok" "$fail"
[ "$fail" -eq 0 ]
