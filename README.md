# Pi-hole + Unbound in Docker

Ein reproduzierbares und gehärtetes Docker-Setup für **Pi-hole v6** als DNS-Filter vor einem eigenen **rekursiven Unbound-Resolver**.

> Original work: PiHole-Unbound-Docker by BlackRabbitZ  
> Original repository: https://github.com/BlackRabbitZ/PiHole-Unbound-Docker

## Übersicht

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

Pi-hole filtert DNS-Anfragen und leitet erlaubte Abfragen nicht an einen öffentlichen Resolver wie Google oder Cloudflare weiter. Stattdessen fragt Pi-hole den lokalen Unbound-Container ab. Unbound löst Domains rekursiv über die DNS-Hierarchie auf und validiert DNSSEC.

## Inhaltsverzeichnis

- [Funktionen](#funktionen)
- [Voraussetzungen](#voraussetzungen)
- [Schnellinstallation](#schnellinstallation)
- [Docker installieren](#docker-installieren)
- [Images bauen](#images-bauen)
- [Container erstellen und starten](#container-erstellen-und-starten)
- [Installation prüfen](#installation-prüfen)
- [Pi-hole-Weboberfläche](#pi-hole-weboberfläche)
- [Clients und Router konfigurieren](#clients-und-router-konfigurieren)
- [Konfiguration](#konfiguration)
- [Betrieb](#betrieb)
- [Updates](#updates)
- [Backup und Restore](#backup-und-restore)
- [Sicherheit und Datenschutz](#sicherheit-und-datenschutz)
- [Projektstruktur](#projektstruktur)
- [Lizenz und Attribution](#lizenz-und-attribution)

## Funktionen

- Pi-hole Docker Release bewusst gepinnt
- Unbound wird lokal aus Alpine Linux und dem Alpine-Unbound-Paket gebaut
- Rekursive DNS-Auflösung ohne öffentlichen Upstream-Resolver
- DNSSEC-Validierung durch Unbound
- QNAME-Minimierung
- DNS-Rebinding-/Private-Address-Härtung
- EDNS-Puffergröße 1232 Byte
- DNS-Cache und Prefetch
- Rate-Limits
- versteckte Unbound-Version und Identity
- persistenter RFC5011-Trust-Anchor
- read-only Root-Filesystem für Unbound
- `no-new-privileges` für Unbound
- Docker Secret für das Pi-hole-Webpasswort
- persistente Pi-hole-Konfiguration
- Docker-Logrotation
- Backup- und Restore-Skripte
- DNS-/DNSSEC-Selbsttest
- automatisierte Konfigurations- und Build-Prüfungen über GitHub Actions

## Voraussetzungen

Benötigt werden:

- Linux-Host, Server, NAS oder VM mit Docker-Unterstützung
- Docker Engine oder Docker Desktop
- Docker Compose v2 als `docker compose`
- Git
- freier Port `53/tcp` und `53/udp` auf dem Docker-Host
- ausgehender DNS-Verkehr auf Port 53 TCP/UDP für die rekursive Auflösung

Prüfen:

```bash
docker --version
docker compose version
git --version
```

Unter Linux kann beispielsweise `systemd-resolved` Port 53 belegen. Hinweise dazu stehen in `docs/TROUBLESHOOTING.md`.

## Schnellinstallation

Wenn Docker und Docker Compose bereits installiert sind:

```bash
git clone https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
cd PiHole-Unbound-Docker
chmod +x scripts/*.sh unbound/entrypoint.sh
./scripts/init.sh
```

Danach `.env` kontrollieren:

```bash
nano .env
```

Images bauen:

```bash
./scripts/build.sh
```

Container erstellen und starten:

```bash
./scripts/start.sh
```

Status prüfen:

```bash
./scripts/status.sh
```

DNS und DNSSEC testen:

```bash
./scripts/test-dns.sh
```

Die ausführliche Schritt-für-Schritt-Anleitung befindet sich in **[`docs/INSTALLATION.md`](docs/INSTALLATION.md)**.

## Docker installieren

Das Projekt benötigt Docker Engine und Docker Compose v2. Für produktive Linux-Systeme sollte Docker über das offizielle Docker-Paketrepository installiert werden.

Nach der Installation müssen diese Befehle funktionieren:

```bash
docker --version
docker compose version
```

Eine ausführliche Anleitung für Debian und Ubuntu sowie Hinweise für andere Plattformen findest du in **[`docs/INSTALLATION.md`](docs/INSTALLATION.md)**.

## Images bauen

Dieses Repository verwendet zwei Docker-Images:

1. **Pi-hole** auf Basis des in `pihole/Dockerfile` gepinnten offiziellen Pi-hole-Images.
2. **Unbound** auf Basis des in `unbound/Dockerfile` definierten Alpine-Images.

Beide Images bauen:

```bash
./scripts/build.sh
```

Alternativ direkt mit Docker Compose:

```bash
docker compose build
```

Mit erneuter Prüfung der Base-Images:

```bash
./scripts/build.sh --pull
```

Oder:

```bash
docker compose build --pull
```

Nur ein einzelnes Image bauen:

```bash
docker compose build pihole
docker compose build unbound
```

Vor dem Build kann die aufgelöste Compose-Konfiguration geprüft werden:

```bash
docker compose config
```

## Container erstellen und starten

Nachdem die Images gebaut wurden:

```bash
./scripts/start.sh
```

Das entspricht im Wesentlichen:

```bash
docker compose up -d
```

Falls Build und Start bewusst in einem Schritt erfolgen sollen:

```bash
./scripts/start.sh --build
```

Oder direkt:

```bash
docker compose up -d --build
```

Docker Compose erstellt dabei unter anderem:

- den Container `blackrabbitz-unbound`
- den Container `blackrabbitz-pihole`
- das interne Docker-Netz `blackrabbitz-dns-backend`
- das persistente Volume `blackrabbitz-unbound-state`

Die persistente Pi-hole-Konfiguration liegt im lokalen Verzeichnis `./etc-pihole`.

### Container neu erstellen

```bash
docker compose up -d --force-recreate
```

### Container stoppen

```bash
./scripts/stop.sh
```

Oder:

```bash
docker compose down
```

## Installation prüfen

Containerstatus:

```bash
docker compose ps
```

Logs:

```bash
./scripts/logs.sh
```

Nur Pi-hole:

```bash
docker compose logs -f pihole
```

Nur Unbound:

```bash
docker compose logs -f unbound
```

DNS-/DNSSEC-Selbsttest:

```bash
./scripts/test-dns.sh
```

Direkter DNS-Test gegen den Docker-Host:

```bash
dig @127.0.0.1 example.org
```

Von einem anderen Gerät im LAN muss statt `127.0.0.1` die LAN-IP des Docker-Hosts verwendet werden.

## Pi-hole-Weboberfläche

Standardmäßig:

```text
http://HOST-IP:8080/admin/
```

Das bei der Initialisierung automatisch erzeugte Webpasswort liegt lokal in:

```text
secrets/pihole_webpassword.txt
```

Anzeigen:

```bash
cat secrets/pihole_webpassword.txt
```

Die Datei ist über `.gitignore` vom Commit ausgeschlossen und sollte nicht veröffentlicht werden.

## Clients und Router konfigurieren

Trage die LAN-IP des Docker-Hosts als DNS-Server in Router oder DHCP-Server ein.

Beispiel:

```text
Docker-Host:             192.168.178.10
DNS-Server für Clients:  192.168.178.10
```

Nicht die interne Docker-IP eines Containers verwenden.

Weitere Hinweise: [`docs/NETWORK.md`](docs/NETWORK.md).

## Konfiguration

`./scripts/init.sh` kopiert `.env.example` automatisch nach `.env`, falls die Datei noch nicht existiert.

Wichtige Standardwerte:

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

Unbound übernimmt bereits die DNSSEC-Validierung. Eine zweite Validierung in Pi-hole ist für dieses Design nicht erforderlich.

### Warum wird Unbound nicht am Host veröffentlicht?

Nur Pi-hole soll Unbound verwenden. Clients kommunizieren ausschließlich mit Pi-hole auf Port 53. Unbound ist über Port 5335 nur im internen Docker-Netz erreichbar.

## Betrieb

Nützliche Befehle:

```bash
# Initialisierung
./scripts/init.sh

# Images bauen
./scripts/build.sh

# Starten
./scripts/start.sh

# Build + Start
./scripts/start.sh --build

# Stoppen
./scripts/stop.sh

# Status
./scripts/status.sh

# Logs
./scripts/logs.sh

# DNS/DNSSEC testen
./scripts/test-dns.sh

# Backup
./scripts/backup.sh

# Restore
./scripts/restore.sh backups/pihole-unbound-YYYYMMDD-HHMMSS.tar.gz
```

Mit `make`:

```bash
make init
make build
make up
make status
make test
make logs
make backup
```

Direkt mit Docker Compose:

```bash
docker compose build
docker compose up -d
docker compose ps
docker compose logs -f pihole
docker compose logs -f unbound
docker compose restart pihole
docker compose restart unbound
docker compose down
```

## Updates

Das Projekt verwendet absichtlich gepinnte Basisversionen statt `latest`. Dadurch wird ein produktiver Resolver nicht unbemerkt auf eine neue Haupt- oder Nebenversion umgestellt.

Vor einem Upgrade:

1. Backup erstellen.
2. Release Notes der verwendeten Komponenten prüfen.
3. Version im jeweiligen Dockerfile aktualisieren.
4. `docker compose config` ausführen.
5. Images neu bauen.
6. Container neu erstellen/starten.
7. DNS- und DNSSEC-Test ausführen.
8. Logs auf Fehler prüfen.

```bash
./scripts/backup.sh
./scripts/build.sh --pull
./scripts/start.sh
./scripts/test-dns.sh
```

Weitere Hinweise: [`docs/UPDATES.md`](docs/UPDATES.md).

## Backup und Restore

Backup erstellen:

```bash
./scripts/backup.sh
```

Restore:

```bash
./scripts/restore.sh backups/pihole-unbound-YYYYMMDD-HHMMSS.tar.gz
```

Backups können Pi-hole-Konfiguration und sensible Daten enthalten. Sie dürfen nicht in Git eingecheckt oder öffentlich geteilt werden.

## Sicherheit und Datenschutz

Pi-hole kann DNS-Anfragen protokollieren. Wer weniger Client- oder Domain-Daten speichern möchte, kann die Pi-hole-Privacy-Einstellungen anpassen oder in `.env` setzen:

```dotenv
PIHOLE_QUERY_LOGGING=false
```

Dieses Projekt verbessert DNS-Privatsphäre und Filterung, ersetzt aber keine Firewall, kein VPN, keine Endpoint-Security und keinen Browser-Schutz.

Zu beachten:

- DNS zwischen Clients und Pi-hole ist im LAN standardmäßig unverschlüsselt.
- Rekursive DNS-Anfragen an Root-, TLD- und autoritative Server erfolgen klassisch über DNS.
- Clients mit eigenem DoH/DoT können den lokalen DNS-Resolver gegebenenfalls umgehen.
- DNS-Blocklisten sind kein vollständiger Malware- oder Phishing-Schutz.

## Projektstruktur

```text
PiHole-Unbound-Docker/
├── compose.yaml
├── .env.example
├── Makefile
├── pihole/
│   └── Dockerfile
├── unbound/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   └── unbound.conf
├── scripts/
│   ├── init.sh
│   ├── build.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── status.sh
│   ├── logs.sh
│   ├── test-dns.sh
│   ├── backup.sh
│   ├── restore.sh
│   └── update.sh
├── docs/
│   ├── INSTALLATION.md
│   ├── ARCHITECTURE.md
│   ├── NETWORK.md
│   ├── TROUBLESHOOTING.md
│   ├── UPDATES.md
│   └── GITHUB_PUBLISHING.md
├── LICENSE
├── ATTRIBUTION.md
├── NOTICE
└── THIRD_PARTY.md
```

## Dokumentation

- [Installation und Build](docs/INSTALLATION.md)
- [Architektur](docs/ARCHITECTURE.md)
- [Netzwerk und Router](docs/NETWORK.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Updates](docs/UPDATES.md)
- [GitHub-Veröffentlichung](docs/GITHUB_PUBLISHING.md)

## Lizenz und Attribution

Die von BlackRabbitZ erstellten Teile dieses Repositories stehen unter GNU GPL Version 3 (`GPL-3.0-only`) plus den zusätzlichen Attribution-Bedingungen in `ATTRIBUTION.md` gemäß GPLv3 §7(b)/(c).

Bei Weitergabe oder Veröffentlichung eines Forks muss mindestens erhalten bleiben:

```text
Original work: PiHole-Unbound-Docker by BlackRabbitZ
Original repository: https://github.com/BlackRabbitZ/PiHole-Unbound-Docker
```

Pi-hole, Unbound, Alpine Linux und weitere Drittkomponenten behalten ihre jeweiligen Lizenzen. Siehe `THIRD_PARTY.md`.

## Technische Quellen

- Pi-hole Docker: https://docs.pi-hole.net/docker/
- Pi-hole Docker-Konfiguration: https://docs.pi-hole.net/docker/configuration/
- Pi-hole + Unbound: https://docs.pi-hole.net/guides/dns/unbound/
- Pi-hole Docker Repository: https://github.com/pi-hole/docker-pi-hole
- Unbound: https://github.com/NLnetLabs/unbound
- Alpine Linux: https://alpinelinux.org/
- Docker Engine Installation: https://docs.docker.com/engine/install/
- Docker Compose Installation: https://docs.docker.com/compose/install/

---

BlackRabbitZ · Security / Infrastructure Projects
