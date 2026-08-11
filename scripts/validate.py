#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 BlackRabbitZ
# Zusätzliche Attribution-Bedingungen: siehe ATTRIBUTION.md
"""Statische Repository-Prüfungen ohne laufende Docker-Engine."""

from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []


def require(path: str) -> Path:
    p = ROOT / path
    if not p.exists():
        errors.append(f"Fehlt: {path}")
    return p


def must_contain(path: str, *needles: str) -> None:
    p = require(path)
    if not p.exists():
        return
    text = p.read_text(encoding="utf-8")
    for needle in needles:
        if needle not in text:
            errors.append(f"{path}: erwarteter Inhalt fehlt: {needle!r}")


for required in (
    "compose.yaml",
    ".env.example",
    "LICENSE",
    "NOTICE",
    "ATTRIBUTION.md",
    "THIRD_PARTY.md",
    "README.md",
    "pihole/Dockerfile",
    "unbound/Dockerfile",
    "unbound/unbound.conf",
    "unbound/entrypoint.sh",
):
    require(required)

must_contain(
    "compose.yaml",
    'FTLCONF_dns_upstreams: "unbound#5335"',
    'FTLCONF_dns_listeningMode: "ALL"',
    "WEBPASSWORD_FILE: pihole_webpassword",
    "no-new-privileges:true",
    "read_only: true",
)
must_contain(
    "unbound/unbound.conf",
    "port: 5335",
    "harden-dnssec-stripped: yes",
    "qname-minimisation: yes",
    "edns-buffer-size: 1232",
    'auto-trust-anchor-file: "/var/lib/unbound/root.key"',
)
must_contain("pihole/Dockerfile", "FROM pihole/pihole:2026.07.2")
must_contain("unbound/Dockerfile", "FROM alpine:3.24.1")
must_contain("ATTRIBUTION.md", "BlackRabbitZ", "PiHole-Unbound-Docker")

compose = (ROOT / "compose.yaml").read_text(encoding="utf-8")
# Unbound darf keinen Host-Port veröffentlichen.
unbound_block = compose.split("  unbound:", 1)[1].split("\n  pihole:", 1)[0]
if re.search(r"^\s+ports:\s*$", unbound_block, flags=re.M):
    errors.append("compose.yaml: Unbound darf keine Host-Ports veröffentlichen")

# Kein echtes Secret darf im Repository liegen.
secret = ROOT / "secrets/pihole_webpassword.txt"
if secret.exists():
    errors.append("secrets/pihole_webpassword.txt darf nicht versioniert werden")

# GPL-Text grob gegen versehentliche Kürzung schützen.
license_text = (ROOT / "LICENSE").read_text(encoding="utf-8", errors="replace")
if "GNU GENERAL PUBLIC LICENSE" not in license_text or "Version 3, 29 June 2007" not in license_text:
    errors.append("LICENSE scheint nicht der vollständige GPLv3-Text zu sein")

if errors:
    print("VALIDIERUNG FEHLGESCHLAGEN")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Repository-Validierung: OK")
