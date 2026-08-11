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

RUN chmod 0755 /usr/local/bin/unbound-entrypoint \
    && sed -i "s/__UNBOUND_THREADS__/${UNBOUND_THREADS}/g; s/__UNBOUND_VERBOSITY__/${UNBOUND_VERBOSITY}/g" /etc/unbound/unbound.conf \
    && unbound-checkconf /etc/unbound/unbound.conf

EXPOSE 5335/tcp 5335/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD dig @127.0.0.1 -p 5335 dnssec.works A +time=2 +tries=1 +short | grep -q . || exit 1

ENTRYPOINT ["/usr/local/bin/unbound-entrypoint"]
