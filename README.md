# Pi-hole + Unbound in Docker

[![Lizenz: GPL-3.0-only](https://img.shields.io/badge/Lizenz-GPL--3.0--only-blue.svg)](LICENSE)
[![Attribution](https://img.shields.io/badge/Attribution-BlackRabbitZ-black.svg)](ATTRIBUTION.md)
[![Docker Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker&logoColor=white)](compose.yaml)
[![CI](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/actions/workflows/validate.yml/badge.svg)](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/actions/workflows/validate.yml)

Ein reproduzierbares, gehärtetes Docker-Setup für **Pi-hole v6** als DNS-Filter vor einem eigenen **rekursiven Unbound-Resolver**.

> **Original work:** PiHole-Unbound-Docker by BlackRabbitZ  
> **Original repository:** https://github.com/BlackRabbitZ/PiHole-Unbound-Docker

## Was dieses Repository macht

```text
Clients / Router
      │
      │ DNS :53 TCP/UDP
      ▼
┌───────────────┐
│    Pi-hole    │
│ Blocking + UI │
└───────┬───────┘
        │ Docker-intern: unbound:5335
        ▼
┌───────────────┐
│    Unbound    │
│ Recursive DNS │
│ DNSSEC        │
└───────┬───────┘
        │
        ├── Root DNS
        ├── TLD DNS
        └── Authoritative DNS
```

Pi-hole blockiert unerwünschte Domains und leitet erlaubte DNS-Anfragen **nicht an Google, Cloudflare oder einen anderen öffentlichen Resolver**, sondern an den eigenen Unbound-Container. Unbound löst die Domains rekursiv über die DNS-Hierarchie auf und validiert DNSSEC.

## Sicherheitsmerkmale

- Pi-hole Docker Release **2026.07.2** bewusst gepinnt
- Unbound wird lokal aus **Alpine Linux 3.24.1** + Alpine-Unbound-Paket gebaut
- Unbound-Port **5335 ist nicht am Docker-Host veröffentlicht**
- Pi-hole → Unbound über Docker-Service-Name `unbound#5335`
- DNSSEC-Validierung in Unbound
- QNAME-Minimierung
- DNS-Rebinding-/Private-Address-Härtung
- `edns-buffer-size: 1232`
- DNS Cache + Prefetch
- Rate-Limits
- versteckte Unbound-Version/Identity
- persistenter RFC5011-Trust-Anchor
- read-only Unbound-Root-Filesystem
- `no-new-privileges` für Unbound
- Docker Secret für das Pi-hole-Webpasswort
- keine unnötigen `NET_ADMIN`-/`SYS_ADMIN`-Capabilities
- Log-Rotation für Docker-Logs
- persistente Pi-hole-Konfiguration
- Backup-/Restore-Skripte
- automatisierte Konfigurations- und Build-Prüfung via GitHub Actions

## Voraussetzungen

- Docker Engine oder Docker Desktop
- Docker Compose v2 (`docker compose`)
- Port 53 TCP/UDP auf dem Host muss frei sein
- Internetzugriff auf DNS-Port 53 TCP/UDP für echte rekursive Unbound-Auflösung

Unter Linux kann insbesondere `systemd-resolved` bereits Port 53 belegen. Siehe [Troubleshooting](docs/TROUBLESHOOTING.md).

## Schnellstart

```bash
git clone https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
cd PiHole-Unbound-Docker
chmod +x scripts/*.sh unbound/entrypoint.sh
./scripts/init.sh
```

Danach `.env` prüfen. Anschließend:

```bash
./scripts/start.sh
```

Status:

```bash
./scripts/status.sh
```

DNS- und DNSSEC-Selbsttest:

```bash
./scripts/test-dns.sh
```

### Pi-hole Weboberfläche

Standardmäßig:

```text
http://HOST-IP:8080/admin/
```

Das automatisch erzeugte Webpasswort liegt lokal in:

```text
secrets/pihole_webpassword.txt
```

Es wird durch `.gitignore` vom Git-Commit ausgeschlossen.

## Clients auf Pi-hole umstellen

Trage die **LAN-IP des Docker-Hosts** als DNS-Server in deinem Router/DHCP-Server ein. Beispiel:

```text
Docker-Host: 192.168.178.10
DNS-Server für Clients: 192.168.178.10
```

Nicht die Docker-interne Container-IP verwenden.

Weitere Hinweise: [Netzwerk & Router](docs/NETWORK.md).

## Konfiguration

Kopiere `.env.example` nach `.env` – `init.sh` erledigt dies automatisch.

Wichtige Werte:

```dotenv
TZ=Europe/Berlin
PIHOLE_BIND_IP=0.0.0.0
PIHOLE_DNS_PORT=53
PIHOLE_HTTP_PORT=8080
PIHOLE_HTTPS_PORT=8443
PIHOLE_DNSSEC=false
PIHOLE_QUERY_LOGGING=true
UNBOUND_THREADS=1
UNBOUND_VERBOSITY=0
```

### Warum `PIHOLE_DNSSEC=false`?

Unbound übernimmt bereits die DNSSEC-Validierung. Doppeltes Validieren ist für dieses Design nicht erforderlich. Wer bewusst beide Ebenen aktivieren möchte, kann den Wert ändern und das Verhalten selbst testen.

### Warum kein öffentlicher Unbound-Port?

Nur Pi-hole soll Unbound benutzen. Clients sprechen ausschließlich mit Pi-hole auf Port 53. Der Unbound-Dienst wird mit `expose` nur für das Docker-Netz sichtbar gemacht.

## Nützliche Befehle

```bash
# Start / Build
./scripts/start.sh

# Container stoppen
./scripts/stop.sh

# Status
./scripts/status.sh

# Logs beider Dienste
./scripts/logs.sh

# Nur Unbound-Logs
./scripts/logs.sh unbound

# DNSSEC-/Resolver-Test
./scripts/test-dns.sh

# Backup
./scripts/backup.sh

# Restore
./scripts/restore.sh backups/pihole-unbound-YYYYMMDD-HHMMSS.tar.gz
```

Alternativ mit `make`:

```bash
make init
make up
make status
make test
make backup
```

Direkt mit Docker Compose:

```bash
docker compose ps
docker compose logs -f pihole
docker compose logs -f unbound
docker compose restart pihole
docker compose restart unbound
```

## Updates

Das Repository verwendet absichtlich einen **gepinnten Pi-hole-Release** statt `latest`. Dadurch verändert sich ein produktives Setup nicht unbemerkt durch einen Image-Neubau.

Vor einem Upgrade:

1. Pi-hole Release Notes prüfen.
2. Backup erstellen.
3. `FROM pihole/pihole:...` in `pihole/Dockerfile` aktualisieren.
4. GitHub-CI bzw. `docker compose config` und Build prüfen.
5. Neu bauen und DNSSEC-Selbsttest ausführen.

Details: [UPDATES.md](docs/UPDATES.md).

## Backup

```bash
./scripts/backup.sh
```

Das Backup kann Pi-hole-Konfiguration und Webpasswort enthalten und wird deshalb mit restriktiven Dateirechten erzeugt. **Backups niemals in Git committen.**

## Datenschutz

Pi-hole protokolliert standardmäßig DNS-Anfragen. Wer weniger Client-/Domain-Daten speichern möchte, sollte die Pi-hole-Privacy-/Logging-Einstellungen bewusst konfigurieren oder `PIHOLE_QUERY_LOGGING=false` verwenden.

## Grenzen dieses Setups

Dieses Repository verbessert DNS-Privatsphäre und Filterung, aber:

- DNS ist zwischen Clients und Pi-hole im LAN standardmäßig unverschlüsselt.
- Rekursive DNS-Abfragen zu Root/TLD/autoritativen Servern erfolgen klassisch über DNS, nicht DoH/DoT.
- Ein VPN, Firewalling, Endpoint-Security oder Browser-Schutz wird dadurch nicht ersetzt.
- Clients mit hart codiertem DoH/DoT können Pi-hole ggf. umgehen.
- DNS-Blocklisten sind kein vollständiger Malware-/Phishing-Schutz.

## Projektstruktur

```text
PiHole-Unbound-Docker/
├── compose.yaml
├── .env.example
├── pihole/
│   └── Dockerfile
├── unbound/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── unbound.conf
├── scripts/
│   ├── init.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── status.sh
│   ├── logs.sh
│   ├── test-dns.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── update.sh
├── docs/
├── LICENSE
├── ATTRIBUTION.md
├── NOTICE
└── THIRD_PARTY.md
```

## Lizenz und Attribution

Die von **BlackRabbitZ** erstellten Teile dieses Repositories stehen unter **GNU GPL Version 3 (GPL-3.0-only)** plus den zusätzlichen Attribution-Bedingungen in [`ATTRIBUTION.md`](ATTRIBUTION.md) gemäß GPLv3 §7(b)/(c).

Bei Weitergabe/Fork-Veröffentlichung muss mindestens erhalten bleiben:

```text
Original work: PiHole-Unbound-Docker by BlackRabbitZ
Original repository: https://github.com/BlackRabbitZ/PiHole-Unbound-Docker
```

Pi-hole, Unbound, Alpine Linux und weitere Drittkomponenten behalten ihre eigenen Lizenzen. Siehe [`THIRD_PARTY.md`](THIRD_PARTY.md).

## Quellen / technische Grundlage

- Pi-hole Docker: https://docs.pi-hole.net/docker/
- Pi-hole Docker-Konfiguration: https://docs.pi-hole.net/docker/configuration/
- Pi-hole + Unbound: https://docs.pi-hole.net/guides/dns/unbound/
- Offizielles Pi-hole Docker Repository: https://github.com/pi-hole/docker-pi-hole
- Unbound: https://github.com/NLnetLabs/unbound
- Alpine Linux: https://alpinelinux.org/

---

**BlackRabbitZ · Security / Infrastructure Projects**
