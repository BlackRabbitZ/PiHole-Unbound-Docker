<div align="center">

# 🛡️ Pi-hole + Unbound in Docker

### Privacy-first DNS filtering with your own recursive resolver

**Pi-hole v6 · Unbound · Docker Compose · DNSSEC · Hardening · Backups**

[![Validate](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/actions/workflows/validate.yml/badge.svg)](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/actions/workflows/validate.yml)
[![License](https://img.shields.io/github/license/BlackRabbitZ/PiHole-Unbound-Docker?style=flat-square)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/BlackRabbitZ/PiHole-Unbound-Docker?style=flat-square)](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/commits/main)
[![Stars](https://img.shields.io/github/stars/BlackRabbitZ/PiHole-Unbound-Docker?style=flat-square)](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/stargazers)
[![Issues](https://img.shields.io/github/issues/BlackRabbitZ/PiHole-Unbound-Docker?style=flat-square)](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/issues)
[![Docker Compose](https://img.shields.io/badge/Docker%20Compose-v2-2496ED?logo=docker&logoColor=white&style=flat-square)](https://docs.docker.com/compose/)
[![Pi-hole](https://img.shields.io/badge/Pi--hole-v6-96060C?logo=pihole&logoColor=white&style=flat-square)](https://pi-hole.net/)
[![Unbound](https://img.shields.io/badge/Resolver-Unbound-2E3440?style=flat-square)](https://nlnetlabs.nl/projects/unbound/about/)

Ein reproduzierbares und gehärtetes Docker-Setup für **Pi-hole** als netzwerkweiten DNS-Filter vor einem eigenen **rekursiven Unbound-Resolver**.

[Installation](#-installation) · [Build](#-docker-images-bauen) · [Architektur](#-architektur) · [Betrieb](#-betrieb) · [Dokumentation](#-dokumentation) · [Sicherheit](#-sicherheit)

</div>

---

## ✨ Warum dieses Projekt?

Viele Pi-hole-Installationen leiten erlaubte DNS-Anfragen an öffentliche Resolver wie Google, Cloudflare oder Quad9 weiter. Dieses Projekt verfolgt einen anderen Ansatz:

> **Pi-hole filtert. Unbound löst selbst rekursiv auf.**

Damit bleibt die DNS-Auflösung unter eigener Kontrolle. Pi-hole übernimmt Filterung und Weboberfläche, während Unbound Domains direkt über Root-, TLD- und autoritative DNS-Server auflöst und DNSSEC validiert.

### Highlights

| Bereich | Umsetzung |
|---|---|
| 🧱 **Deployment** | Docker Compose v2 mit getrennten Pi-hole- und Unbound-Images |
| 🔍 **DNS-Filterung** | Pi-hole v6 für Werbung, Tracking und unerwünschte Domains |
| 🌐 **DNS-Auflösung** | Eigener rekursiver Unbound-Resolver ohne öffentlichen Upstream |
| 🔐 **DNSSEC** | Validierung durch Unbound |
| 🛡️ **Hardening** | Read-only Unbound-Filesystem, `no-new-privileges`, reduzierte Angriffsfläche |
| 🔑 **Secrets** | Pi-hole-Webpasswort über Docker Secret |
| 💾 **Persistenz** | Pi-hole-Konfiguration und Unbound-Trust-Anchor persistent gespeichert |
| 🧪 **Health Checks** | Status-, DNS- und DNSSEC-Tests über Skripte |
| 📦 **Backups** | Backup- und Restore-Workflow enthalten |
| ✅ **CI** | Konfiguration, Image-Build, Container-Health sowie DNS-/DNSSEC-End-to-End-Test mit GitHub Actions |

---

## 🧭 Inhaltsverzeichnis

- [Architektur](#-architektur)
- [Sicherheitsmerkmale](#-sicherheitsmerkmale)
- [Voraussetzungen](#-voraussetzungen)
- [Installation](#-installation)
- [Docker installieren](#1-docker-installieren)
- [Repository klonen](#2-repository-klonen)
- [Projekt initialisieren](#3-projekt-initialisieren)
- [Docker-Images bauen](#-docker-images-bauen)
- [Container erstellen und starten](#-container-erstellen-und-starten)
- [Installation prüfen](#-installation-prüfen)
- [Pi-hole-Weboberfläche](#-pi-hole-weboberfläche)
- [Router und Clients konfigurieren](#-router-und-clients-konfigurieren)
- [Konfiguration](#️-konfiguration)
- [Betrieb](#-betrieb)
- [Updates](#-updates)
- [Backup und Restore](#-backup-und-restore)
- [Sicherheit](#-sicherheit)
- [Projektstruktur](#-projektstruktur)
- [Dokumentation](#-dokumentation)
- [Lizenz und Attribution](#-lizenz-und-attribution)

---

## 🏗️ Architektur

```text
                    ┌────────────────────────────┐
                    │      Clients / Router      │
                    └─────────────┬──────────────┘
                                  │
                           DNS :53 TCP/UDP
                                  │
                                  ▼
                    ┌────────────────────────────┐
                    │          Pi-hole           │
                    │                            │
                    │  • DNS Filtering           │
                    │  • Blocklists              │
                    │  • Query Logging           │
                    │  • Web UI                  │
                    └─────────────┬──────────────┘
                                  │
                         Docker-intern
                         unbound:5335
                                  │
                                  ▼
                    ┌────────────────────────────┐
                    │          Unbound           │
                    │                            │
                    │  • Recursive DNS           │
                    │  • DNSSEC Validation       │
                    │  • Cache + Prefetch        │
                    │  • QNAME Minimization      │
                    └─────────────┬──────────────┘
                                  │
                 ┌────────────────┼────────────────┐
                 ▼                ▼                ▼
             Root DNS          TLD DNS      Authoritative DNS
```

### DNS-Fluss

```text
Client → Pi-hole → Unbound → DNS-Hierarchie → Unbound → Pi-hole → Client
```

Unbound wird **nicht direkt am Host veröffentlicht**. Nur Pi-hole kann den Resolver über das interne Docker-Netz erreichen.

---

## 🛡️ Sicherheitsmerkmale

Das Setup ist bewusst restriktiver als eine minimale Standardinstallation:

- gepinntes Pi-hole-Basisimage statt unkontrolliertem `latest`
- eigener lokal gebauter Unbound-Container
- DNSSEC-Validierung durch Unbound
- QNAME-Minimierung
- DNS-Rebinding- und Private-Address-Härtung
- EDNS-Puffergröße von `1232` Byte
- DNS-Cache und Prefetch
- Rate-Limits
- versteckte Unbound-Version und Identity
- persistenter RFC5011-Trust-Anchor
- read-only Root-Filesystem für Unbound
- `no-new-privileges` für Unbound
- keine unnötigen privilegierten Container-Rechte
- Docker Secret für das Pi-hole-Webpasswort
- persistente Pi-hole-Konfiguration
- Docker-Logrotation
- automatisierte Konfigurations-, Build-, Health- und DNS/DNSSEC-Integrationstests via GitHub Actions

> [!IMPORTANT]
> Dieses Projekt erhöht die Kontrolle über DNS-Auflösung und Filterung. Es ersetzt keine Firewall, kein VPN, keine Endpoint-Security und keinen Browser-Schutz.

---

## 📋 Voraussetzungen

Empfohlen wird ein Linux-Host, Server, NAS oder eine VM mit Docker-Unterstützung.

| Voraussetzung | Empfehlung |
|---|---|
| Docker | Docker Engine / Docker Desktop |
| Compose | Docker Compose v2 (`docker compose`) |
| Git | aktuelle Distribution-Version |
| DNS-Port | `53/tcp` und `53/udp` müssen frei sein |
| Netzwerk | ausgehender DNS-Verkehr über TCP/UDP Port 53 |
| RAM | mindestens 512 MB frei, mehr empfohlen |
| Architektur | typischerweise `amd64` oder `arm64` |

Versionen prüfen:

```bash
docker --version
docker compose version
git --version
```

> [!WARNING]
> Unter Linux kann beispielsweise `systemd-resolved` Port 53 belegen. Prüfe vor dem Start, ob DNS-Port 53 bereits verwendet wird. Weitere Hinweise findest du unter [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

---

# 🚀 Installation

## 1. Docker installieren

Das Projekt benötigt **Docker Engine** und **Docker Compose v2**.

Für Debian/Ubuntu empfiehlt sich die Installation über das offizielle Docker-Paketrepository. Eine vollständige Schritt-für-Schritt-Anleitung befindet sich in:

**➡️ [`docs/INSTALLATION.md`](docs/INSTALLATION.md)**

Nach der Installation müssen folgende Befehle ohne Fehler funktionieren:

```bash
docker --version
docker compose version
```

Optional kannst du prüfen, ob Docker grundsätzlich funktioniert:

```bash
docker run --rm hello-world
```

---

## 2. Repository klonen

```bash
git clone https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
cd PiHole-Unbound-Docker
```

Skripte ausführbar machen:

```bash
chmod +x scripts/*.sh unbound/entrypoint.sh
```

---

## 3. Projekt initialisieren

```bash
./scripts/init.sh
```

Das Initialisierungsskript erstellt beziehungsweise vorbereitet unter anderem die lokale `.env`-Konfiguration und benötigte Secret-Dateien.

Anschließend die Konfiguration kontrollieren:

```bash
nano .env
```

Mindestens Zeitzone, Ports und Bind-Adresse sollten zum eigenen Netzwerk passen.

---

# 🏭 Docker-Images bauen

Dieses Repository verwendet **zwei lokal gebaute Images**:

| Service | Dockerfile | Aufgabe |
|---|---|---|
| `pihole` | `pihole/Dockerfile` | DNS-Filter, Blocklisten und Weboberfläche |
| `unbound` | `unbound/Dockerfile` | rekursive DNS-Auflösung und DNSSEC |

### Beide Images bauen

```bash
./scripts/build.sh
```

Alternativ direkt mit Docker Compose:

```bash
docker compose build
```

### Base-Images vorher aktualisieren

```bash
./scripts/build.sh --pull
```

oder:

```bash
docker compose build --pull
```

### Nur einen Service bauen

```bash
./scripts/build.sh pihole
./scripts/build.sh unbound
```

Alternativ:

```bash
docker compose build pihole
docker compose build unbound
```

### Compose-Konfiguration vor dem Build prüfen

```bash
docker compose config
```

> [!TIP]
> Durch die Trennung von **Build** und **Start** kannst du Fehler beim Image-Build erkennen, bevor bestehende Container verändert werden.

---

# ▶️ Container erstellen und starten

Nachdem die Images erfolgreich gebaut wurden:

```bash
./scripts/start.sh
```

`start.sh` führt automatisch `./scripts/preflight.sh` aus. Dabei werden Docker/Compose, Secret, Compose-Konfiguration und ein möglicher Konflikt am konfigurierten DNS-Host-Port geprüft.

Das entspricht im Wesentlichen:

```bash
docker compose up -d
```

Docker Compose erstellt beim ersten Start automatisch die benötigten Container, Netzwerke und Volumes.

### Build und Start in einem Schritt

```bash
./scripts/start.sh --build
```

oder direkt:

```bash
docker compose up -d --build
```

### Container bewusst neu erstellen

```bash
docker compose up -d --force-recreate
```

### Erwartete Komponenten

| Komponente | Zweck |
|---|---|
| `blackrabbitz-pihole` | Pi-hole DNS + Weboberfläche |
| `blackrabbitz-unbound` | rekursiver DNS-Resolver |
| internes DNS-Netz | Kommunikation zwischen Pi-hole und Unbound |
| Unbound-State-Volume | persistenter Resolver-/Trust-Anchor-State |
| `./etc-pihole` | persistente Pi-hole-Konfiguration |

---

## ⚡ Schnellstart

Wenn Docker und Docker Compose bereits installiert sind:

```bash
git clone https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
cd PiHole-Unbound-Docker
chmod +x scripts/*.sh unbound/entrypoint.sh

./scripts/init.sh
nano .env

./scripts/build.sh
./scripts/start.sh
./scripts/status.sh
./scripts/test-dns.sh
```

Oder mit `make`:

```bash
make init
make build
make up
make status
make test
```

---

## ✅ Installation prüfen

### Containerstatus

```bash
docker compose ps
```

oder:

```bash
./scripts/status.sh
```

Beide Services sollten laufen beziehungsweise einen gesunden Status erreichen.

### Logs anzeigen

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

### DNS und DNSSEC testen

```bash
./scripts/test-dns.sh
```

Direkter DNS-Test gegen den Docker-Host:

```bash
dig @127.0.0.1 example.org
```

Von einem anderen Gerät im LAN muss statt `127.0.0.1` die LAN-IP des Docker-Hosts verwendet werden.

---

## 🌐 Pi-hole-Weboberfläche

Standardmäßig erreichst du die Pi-hole-Oberfläche unter:

```text
http://HOST-IP:8080/admin/
```

Beispiel:

```text
http://192.168.178.10:8080/admin/
```

Das bei der Initialisierung erzeugte Webpasswort liegt lokal unter:

```text
secrets/pihole_webpassword.txt
```

Passwort anzeigen:

```bash
cat secrets/pihole_webpassword.txt
```

> [!CAUTION]
> Secret-Dateien und Backups niemals in Git committen oder öffentlich teilen.

---

## 📡 Router und Clients konfigurieren

Trage die **LAN-IP des Docker-Hosts** als DNS-Server in deinem Router oder DHCP-Server ein.

Beispiel:

| Einstellung | Wert |
|---|---|
| Docker-Host | `192.168.178.10` |
| DNS-Server für Clients | `192.168.178.10` |
| Pi-hole Web UI | `http://192.168.178.10:8080/admin/` |

**Nicht** die interne Docker-IP eines Containers verwenden.

Weitere Hinweise findest du in [`docs/NETWORK.md`](docs/NETWORK.md).

---

## ⚙️ Konfiguration

`./scripts/init.sh` kopiert `.env.example` automatisch nach `.env`, sofern die Datei noch nicht existiert.

Wichtige Einstellungen:

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

Unbound übernimmt bereits die DNSSEC-Validierung. Eine zweite Validierung durch Pi-hole ist für dieses Design nicht erforderlich.

### Warum wird Unbound nicht direkt veröffentlicht?

Clients sollen ausschließlich mit Pi-hole kommunizieren. Pi-hole erreicht Unbound intern über den Docker-Service und Port `5335`. Dadurch ist der rekursive Resolver nicht unnötig direkt im LAN erreichbar.

---

## 🧰 Betrieb

### Projekt-Skripte

| Aufgabe | Befehl |
|---|---|
| Initialisieren | `./scripts/init.sh` |
| Preflight / Port- und Compose-Prüfung | `./scripts/preflight.sh` |
| Images bauen | `./scripts/build.sh` |
| Images mit Pull bauen | `./scripts/build.sh --pull` |
| Container starten | `./scripts/start.sh` |
| Build + Start | `./scripts/start.sh --build` |
| Container stoppen | `./scripts/stop.sh` |
| Status anzeigen | `./scripts/status.sh` |
| Logs anzeigen | `./scripts/logs.sh` |
| DNS/DNSSEC testen | `./scripts/test-dns.sh` |
| Backup erstellen | `./scripts/backup.sh` |
| Restore durchführen | `./scripts/restore.sh <backup.tar.gz>` |

### Mit Make

```bash
make init
make build
make up
make status
make test
make logs
make backup
```

### Direkt mit Docker Compose

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

---

## 🔄 Updates

Das Projekt verwendet bewusst gepinnte Basisversionen statt `latest`. Dadurch wird ein produktiver DNS-Resolver nicht unbemerkt durch einen Image-Neubau auf eine neue Version umgestellt.

Empfohlener Upgrade-Ablauf:

```bash
./scripts/backup.sh

git pull

docker compose config

./scripts/build.sh --pull
./scripts/start.sh
./scripts/test-dns.sh
```

Danach Logs prüfen:

```bash
docker compose logs --tail=100 pihole
docker compose logs --tail=100 unbound
```

Weitere Hinweise: [`docs/UPDATES.md`](docs/UPDATES.md).

---

## 💾 Backup und Restore

Backup erstellen:

```bash
./scripts/backup.sh
```

Restore:

```bash
./scripts/restore.sh backups/pihole-unbound-YYYYMMDD-HHMMSS.tar.gz
```

> [!WARNING]
> Backups können Pi-hole-Konfiguration, DNS-Daten und sensible Zugangsinformationen enthalten. Sie gehören nicht in ein öffentliches Repository.

---

## 🔒 Sicherheit

Pi-hole kann DNS-Anfragen protokollieren. Wer weniger Client- oder Domain-Daten speichern möchte, kann das Query Logging deaktivieren:

```dotenv
PIHOLE_QUERY_LOGGING=false
```

### Sicherheitsgrenzen

Dieses Setup verbessert DNS-Privatsphäre und Filterung, aber:

- DNS zwischen Clients und Pi-hole ist im LAN standardmäßig unverschlüsselt.
- Rekursive DNS-Anfragen an Root-, TLD- und autoritative Server erfolgen klassisch über DNS.
- Clients mit eigenem DoH/DoT können den lokalen Resolver gegebenenfalls umgehen.
- DNS-Blocklisten sind kein vollständiger Malware- oder Phishing-Schutz.
- Host-Firewall, Betriebssystem-Updates und sichere Netzwerksegmentierung bleiben weiterhin wichtig.

Sicherheitsprobleme bitte nicht öffentlich als normalen Issue veröffentlichen. Siehe [`SECURITY.md`](SECURITY.md).

---

## 📁 Projektstruktur

```text
PiHole-Unbound-Docker/
├── .github/
│   └── workflows/
│       ├── release.yml
│       └── validate.yml
├── docs/
│   ├── INSTALLATION.md
│   ├── ARCHITECTURE.md
│   ├── NETWORK.md
│   ├── TROUBLESHOOTING.md
│   ├── UPDATES.md
│   └── GITHUB_PUBLISHING.md
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
├── .env.example
├── compose.yaml
├── Makefile
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
└── LICENSE
```

---

## 📚 Dokumentation

| Dokument | Inhalt |
|---|---|
| [`INSTALLATION.md`](docs/INSTALLATION.md) | vollständige Installation, Docker-Setup, Build und Start |
| [`ARCHITECTURE.md`](docs/ARCHITECTURE.md) | DNS-Fluss und technische Architektur |
| [`NETWORK.md`](docs/NETWORK.md) | Router-, DHCP- und Client-Konfiguration |
| [`TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | häufige Fehler und Port-53-Probleme |
| [`UPDATES.md`](docs/UPDATES.md) | kontrollierte Updates und Versionswechsel |
| [`SECURITY.md`](SECURITY.md) | Sicherheitsrichtlinie und Meldung von Schwachstellen |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Beiträge zum Projekt |

---

## 🤝 Mitwirken

Pull Requests und konstruktive Verbesserungen sind willkommen.

Vor größeren Änderungen bitte zuerst [`CONTRIBUTING.md`](CONTRIBUTING.md) lesen. Fehler oder Verbesserungsvorschläge können über die [GitHub Issues](https://github.com/BlackRabbitZ/PiHole-Unbound-Docker/issues) eingereicht werden.

---

## 📜 Lizenz und Attribution

Die von **BlackRabbitZ** erstellten Teile dieses Repositories stehen unter **GNU GPL Version 3 (`GPL-3.0-only`)** plus den zusätzlichen Attribution-Bedingungen in [`ATTRIBUTION.md`](ATTRIBUTION.md) gemäß GPLv3 §7(b)/(c).

Bei Weitergabe oder Veröffentlichung eines Forks muss mindestens erhalten bleiben:

```text
Original work: PiHole-Unbound-Docker by BlackRabbitZ
Original repository: https://github.com/BlackRabbitZ/PiHole-Unbound-Docker
```

Pi-hole, Unbound, Alpine Linux und weitere Drittkomponenten behalten ihre jeweiligen Lizenzen. Siehe [`THIRD_PARTY.md`](THIRD_PARTY.md).

---

## 🔗 Technische Grundlagen

- [Pi-hole Docker Documentation](https://docs.pi-hole.net/docker/)
- [Pi-hole Docker Configuration](https://docs.pi-hole.net/docker/configuration/)
- [Pi-hole + Unbound Guide](https://docs.pi-hole.net/guides/dns/unbound/)
- [Official Pi-hole Docker Repository](https://github.com/pi-hole/docker-pi-hole)
- [NLnet Labs Unbound](https://github.com/NLnetLabs/unbound)
- [Docker Engine](https://docs.docker.com/engine/install/)
- [Docker Compose](https://docs.docker.com/compose/install/)

---

<div align="center">

### Built for privacy, control and reproducibility.

**BlackRabbitZ · Security / Infrastructure Projects**

[⬆ Nach oben](#️-pi-hole--unbound-in-docker)

</div>
