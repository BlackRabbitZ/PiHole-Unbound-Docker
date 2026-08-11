# Installation, Build und Container-Start

Diese Anleitung beschreibt den vollständigen Ablauf von einem frischen Linux-System bis zu laufenden Pi-hole- und Unbound-Containern.

## 1. Voraussetzungen

Empfohlen:

- Debian oder Ubuntu Server
- statische bzw. reservierte LAN-IP für den Docker-Host
- mindestens 1 GB RAM
- Git
- Docker Engine
- Docker Compose v2
- freier Port 53 TCP/UDP

Architektur prüfen:

```bash
uname -m
```

Docker und Compose prüfen:

```bash
docker --version
docker compose version
```

## 2. Docker Engine installieren

> Für produktive Systeme sollte Docker über das offizielle Docker-Paketrepository installiert werden. Die jeweils aktuellen und distributionsspezifischen Anweisungen stehen unter https://docs.docker.com/engine/install/.

### Debian

Grundpakete installieren:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
```

Docker-Keyring vorbereiten:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Docker-Repository hinzufügen:

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Docker installieren:

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Ubuntu

Grundpakete installieren:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git
```

Docker-Keyring vorbereiten:

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

Docker-Repository hinzufügen:

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"${UBUNTU_CODENAME:-$VERSION_CODENAME}\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Docker installieren:

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Docker-Dienst aktivieren

```bash
sudo systemctl enable --now docker
sudo systemctl status docker --no-pager
```

Installation testen:

```bash
sudo docker run --rm hello-world
sudo docker compose version
```

### Optional: Docker ohne `sudo`

```bash
sudo usermod -aG docker "$USER"
```

Danach einmal ab- und wieder anmelden. Beachte: Mitgliedschaft in der Gruppe `docker` gewährt weitreichende Rechte auf dem Host.

## 3. Prüfen, ob Port 53 frei ist

```bash
sudo ss -lntup | grep ':53 ' || true
```

Wenn bereits ein lokaler DNS-Dienst Port 53 belegt, kann Pi-hole nicht auf dem Standardport starten.

Auf Systemen mit `systemd-resolved`:

```bash
sudo systemctl status systemd-resolved --no-pager
```

Bevor ein Systemdienst deaktiviert oder umkonfiguriert wird, unbedingt prüfen, wie der Host selbst DNS auflöst. Weitere Hinweise stehen in `TROUBLESHOOTING.md`.

## 4. Repository herunterladen

```bash
git clone https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
cd PiHole-Unbound-Docker
```

Skripte ausführbar machen:

```bash
chmod +x scripts/*.sh unbound/entrypoint.sh
```

## 5. Projekt initialisieren

```bash
./scripts/init.sh
```

Dabei werden unter anderem:

- `.env` aus `.env.example` erzeugt, falls noch nicht vorhanden,
- `secrets/` angelegt,
- `etc-pihole/` angelegt,
- `backups/` angelegt,
- ein zufälliges Pi-hole-Webpasswort erzeugt,
- die Compose-Konfiguration validiert.

Webpasswort anzeigen:

```bash
cat secrets/pihole_webpassword.txt
```

## 6. `.env` konfigurieren

```bash
nano .env
```

Beispiel:

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

Wenn der Docker-Host mehrere Netzwerkinterfaces besitzt, kann `PIHOLE_BIND_IP` auf die gewünschte LAN-IP beschränkt werden.

Beispiel:

```dotenv
PIHOLE_BIND_IP=192.168.178.10
```

## 7. Compose-Konfiguration prüfen

```bash
docker compose config
```

Nur auf Syntax prüfen:

```bash
docker compose config --quiet
```

## 8. Docker-Images bauen

### Empfohlener Weg

```bash
./scripts/build.sh
```

Das Skript baut beide Services aus `compose.yaml`.

### Direkt mit Docker Compose

```bash
docker compose build
```

### Basis-Images erneut abrufen

```bash
./scripts/build.sh --pull
```

oder:

```bash
docker compose build --pull
```

### Nur Pi-hole bauen

```bash
docker compose build pihole
```

### Nur Unbound bauen

```bash
docker compose build unbound
```

### Gebaute Images anzeigen

```bash
docker image ls
```

## 9. Container erstellen und starten

```bash
./scripts/start.sh
```

Alternativ:

```bash
docker compose up -d
```

Docker Compose erzeugt die benötigten Container, das interne Netzwerk und das persistente Unbound-Volume automatisch.

Build und Start in einem Befehl:

```bash
./scripts/start.sh --build
```

oder:

```bash
docker compose up -d --build
```

## 10. Status prüfen

```bash
./scripts/status.sh
```

oder:

```bash
docker compose ps
```

Erwartet werden die Container:

```text
blackrabbitz-pihole
blackrabbitz-unbound
```

Unbound muss zunächst gesund werden, bevor Pi-hole gestartet werden kann.

## 11. Logs prüfen

```bash
./scripts/logs.sh
```

Nur Unbound:

```bash
docker compose logs -f unbound
```

Nur Pi-hole:

```bash
docker compose logs -f pihole
```

## 12. DNS und DNSSEC testen

```bash
./scripts/test-dns.sh
```

Zusätzlicher Test direkt gegen Pi-hole:

```bash
dig @127.0.0.1 example.org A
```

Von einem anderen Gerät im LAN:

```bash
dig @192.168.178.10 example.org A
```

Die IP muss durch die tatsächliche LAN-IP des Docker-Hosts ersetzt werden.

## 13. Weboberfläche öffnen

Standardmäßig:

```text
http://HOST-IP:8080/admin/
```

Beispiel:

```text
http://192.168.178.10:8080/admin/
```

Passwort:

```bash
cat secrets/pihole_webpassword.txt
```

## 14. Router oder DHCP konfigurieren

Als DNS-Server für das LAN wird die LAN-IP des Docker-Hosts eingetragen.

Beispiel:

```text
192.168.178.10
```

Nicht verwenden:

- `127.0.0.1` auf anderen Geräten
- die Docker-interne IP von Pi-hole
- die Docker-interne IP von Unbound
- Port 5335 direkt für Clients

## 15. Container verwalten

Starten:

```bash
docker compose up -d
```

Stoppen und Compose-Container entfernen:

```bash
docker compose down
```

Neu starten:

```bash
docker compose restart
```

Nur Pi-hole neu starten:

```bash
docker compose restart pihole
```

Nur Unbound neu starten:

```bash
docker compose restart unbound
```

Neu erstellen:

```bash
docker compose up -d --force-recreate
```

Neu bauen und neu erstellen:

```bash
docker compose build
docker compose up -d --force-recreate
```

## 16. Installation mit Make

Falls `make` installiert ist:

```bash
make init
make build
make up
make status
make test
```

Logs:

```bash
make logs
```

Stoppen:

```bash
make down
```

## 17. Update-Ablauf

Vor Updates zuerst Backup erstellen:

```bash
./scripts/backup.sh
```

Danach beispielsweise:

```bash
git pull
./scripts/build.sh --pull
./scripts/start.sh
./scripts/test-dns.sh
```

Bei Änderungen an gepinnten Basisversionen zuerst die jeweiligen Release Notes prüfen.

## 18. Deinstallation

Container und Netzwerk entfernen:

```bash
docker compose down
```

Container, Netzwerk und das benannte Unbound-Volume entfernen:

```bash
docker compose down -v
```

**Achtung:** `-v` entfernt persistente Docker-Volumes. Vorher ein Backup erstellen.

Die Pi-hole-Konfiguration unter `./etc-pihole` wird durch `docker compose down -v` nicht automatisch gelöscht, da sie als Bind-Mount auf dem Host liegt.

## Fehlerbehebung

Siehe:

- `TROUBLESHOOTING.md`
- `NETWORK.md`
- `UPDATES.md`

Wichtige Diagnosebefehle:

```bash
docker compose config
docker compose ps
docker compose logs --tail=200
sudo ss -lntup | grep ':53 ' || true
```
