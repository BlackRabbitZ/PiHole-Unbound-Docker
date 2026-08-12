# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ../ATTRIBUTION.md

FROM alpine:3.24.1

ARG UNBOUND_THREADS=1
ARG UNBOUND_VERBOSITY=0

RUN apk add --no-cache \
      unbound \
      bind-tools \
      ca-certificates \
      tzdata \
    && mkdir -p /var/lib/unbound /run/unbound \
    && chown -R unbound:unbound /var/lib/unbound /run/unbound

COPY unbound/unbound.conf /etc/unbound/unbound.conf
COPY unbound/entrypoint.sh /usr/local/bin/unbound-entrypoint

# unbound-checkconf benötigt den konfigurierten Trust Anchor bereits beim Build.
# Das Runtime-Volume kann diese Datei später verdecken; entrypoint.sh stellt sie
# in diesem Fall aus dem Alpine-Paket wieder her.
RUN chmod 0755 /usr/local/bin/unbound-entrypoint \
    && sed -i "s/__UNBOUND_THREADS__/${UNBOUND_THREADS}/g; s/__UNBOUND_VERBOSITY__/${UNBOUND_VERBOSITY}/g" /etc/unbound/unbound.conf \
    && cp /usr/share/dnssec-root/trusted-key.key /var/lib/unbound/root.key \
    && chown unbound:unbound /var/lib/unbound/root.key \
    && chmod 0644 /var/lib/unbound/root.key \
    && unbound-checkconf /etc/unbound/unbound.conf

EXPOSE 5335/tcp 5335/udp

# Nur lokale Dienstbereitschaft prüfen. Echte Rekursion und DNSSEC werden
# separat durch scripts/test-dns.sh getestet, damit der Healthcheck nicht von
# einer externen Testdomain abhängt.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD dig @127.0.0.1 -p 5335 localhost A +time=2 +tries=1 +short | grep -qx '127.0.0.1' || exit 1

ENTRYPOINT ["/usr/local/bin/unbound-entrypoint"]
