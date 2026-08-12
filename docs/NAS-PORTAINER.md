# NAS- & Portainer-Standalone-Deployment

Für NAS-Systeme und Portainer enthält das Repository zusätzlich die Datei **`compose.nas.yaml`**.

Diese Variante ist absichtlich unabhängig vom normalen Build-Setup des Repositories. Sie benötigt **keine lokalen Dockerfiles, keine Secret-Datei, keine `.env` und keine zusätzlichen Unbound-Konfigurationsdateien**.

## Geeignet für

- Portainer Stacks
- Synology Container Manager / Docker
- QNAP Container Station
- Unraid Docker Compose / Compose Manager
- TrueNAS SCALE mit Docker-/Compose-Unterstützung
- normale Docker-Hosts, auf denen nur eine einzelne Compose-Datei verwendet werden soll

> [!NOTE]
> Je nach NAS-Version und Hersteller kann die Docker-/Compose-Oberfläche unterschiedlich aussehen. Die zugrunde liegende Datei verwendet normale Docker-Compose-Funktionen und keine Portainer-spezifischen Extensions.

## Was die Standalone-Datei automatisch erledigt

`compose.nas.yaml` startet zwei fertige Images:

- **Pi-hole**: `pihole/pihole:2026.07.2`
- **Unbound**: gepinntes Multi-Arch-Image von `ghcr.io/klutchell/unbound`

Unbound wird **nicht** direkt am NAS veröffentlicht. Nur Pi-hole erreicht Unbound über das interne Docker-Netzwerk.

```text
Clients / Router
      │
      │ DNS :53 TCP/UDP
      ▼
   Pi-hole
      │
      │ Docker-intern: unbound:53
      ▼
   Unbound
      │
      ▼
Root / TLD / autoritative DNS-Server
```

Die Pi-hole-Konfiguration wird im benannten Docker-Volume `pihole-data` gespeichert und bleibt bei Container-Neuerstellungen erhalten.

---

## Variante A: Portainer

1. **Stacks** öffnen.
2. **Add stack** auswählen.
3. Einen Namen vergeben, zum Beispiel `pihole-unbound`.
4. **Web editor** auswählen.
5. Den vollständigen Inhalt von `compose.nas.yaml` einfügen.
6. Optional unter **Environment variables** Werte anpassen.
7. **Deploy the stack** auswählen.

### Sinnvolle optionale Variablen

| Variable | Standard | Zweck |
|---|---:|---|
| `TZ` | `Europe/Berlin` | Zeitzone |
| `PIHOLE_BIND_IP` | `0.0.0.0` | Host-IP, an die Pi-hole gebunden wird |
| `PIHOLE_DNS_PORT` | `53` | DNS-Port auf dem NAS |
| `PIHOLE_HTTP_PORT` | `8080` | HTTP-Port für das Dashboard |
| `PIHOLE_HTTPS_PORT` | `8443` | HTTPS-Port für das Dashboard |
| `PIHOLE_QUERY_LOGGING` | `true` | Pi-hole Query Logging |
| `PIHOLE_DNSMASQ_USER` | `pihole` | Nur bei speziellen NAS-Problemen ändern |

> [!IMPORTANT]
> Für die normale Nutzung als DNS-Server sollte der externe DNS-Port **53** bleiben. Ein anderer Host-Port ist hauptsächlich für Tests sinnvoll, weil Router und Clients DNS standardmäßig auf Port 53 erwarten.

---

## Variante B: Docker Compose auf einem NAS

Nur die Datei `compose.nas.yaml` auf das NAS kopieren und anschließend im Verzeichnis der Datei ausführen:

```bash
docker compose -f compose.nas.yaml pull
docker compose -f compose.nas.yaml up -d
```

Status anzeigen:

```bash
docker compose -f compose.nas.yaml ps
```

Logs anzeigen:

```bash
docker compose -f compose.nas.yaml logs -f
```

---

## Erstes Pi-hole-Passwort

Die Standalone-Datei enthält bewusst **kein universelles Standardpasswort**.

Wenn noch kein Passwort in der persistenten Pi-hole-Konfiguration vorhanden ist, erzeugt Pi-hole beim ersten Start ein zufälliges Webpasswort. Dieses findest du im Pi-hole-Container-Log.

Mit Docker Compose:

```bash
docker compose -f compose.nas.yaml logs pihole
```

In Portainer:

1. **Containers** öffnen.
2. Den Pi-hole-Container des Stacks öffnen.
3. **Logs** öffnen.
4. Nach `random password` suchen.

Danach erreichst du das Dashboard normalerweise unter:

```text
http://NAS-IP:8080/admin/
```

oder per HTTPS:

```text
https://NAS-IP:8443/admin/
```

Nach dem ersten Login solltest du dein eigenes Passwort setzen.

---

## Port 53 muss frei sein

Pi-hole muss für den normalen Einsatz TCP **und** UDP Port 53 am NAS belegen können.

Typische Konflikte:

- bereits installierter DNS-Server
- AdGuard Home
- eine zweite Pi-hole-Instanz
- NAS-interner DNS-Dienst
- `systemd-resolved` auf normalen Linux-Hosts

Auf einem Linux-basierten Host kannst du prüfen:

```bash
sudo ss -lntup | grep ':53 '
```

oder:

```bash
sudo lsof -i :53
```

Wenn Port 53 bereits durch einen benötigten NAS-Dienst verwendet wird, muss zuerst entschieden werden, welcher Dienst DNS bereitstellen soll. Pi-hole einfach auf einen anderen Port zu legen hilft bei normalen Routern/Clients meist nicht, weil diese DNS auf Port 53 erwarten.

---

## Synology-Hinweis

Pi-hole dokumentiert, dass einzelne Systeme wie Synology den DNS-Prozess möglicherweise als `root` benötigen.

Die Standalone-Datei verwendet standardmäßig weiterhin den sichereren Wert:

```text
PIHOLE_DNSMASQ_USER=pihole
```

Nur wenn Pi-hole auf einer betroffenen Synology trotz freiem Port 53 keine DNS-Anfragen beantworten kann, in den Stack-Variablen testweise setzen:

```text
PIHOLE_DNSMASQ_USER=root
```

Anschließend den Stack neu deployen.

---

## DNS-Funktion testen

Von einem anderen Gerät im LAN:

```bash
nslookup example.org NAS-IP
```

oder unter Linux/macOS:

```bash
dig @NAS-IP example.org A
```

Auf dem Docker-Host kannst du zusätzlich prüfen, ob Pi-hole Unbound intern erreicht:

```bash
docker compose -f compose.nas.yaml exec pihole dig @unbound example.org A
```

DNSSEC-Test über Unbound:

```bash
docker compose -f compose.nas.yaml exec pihole dig @unbound dnssec.works A
```

Eine absichtlich fehlerhafte DNSSEC-Zone sollte nicht erfolgreich aufgelöst werden:

```bash
docker compose -f compose.nas.yaml exec pihole dig @unbound fail01.dnssec.works A
```

---

## Update

Neue Images ziehen und Stack neu erstellen:

```bash
docker compose -f compose.nas.yaml pull
docker compose -f compose.nas.yaml up -d
```

> [!NOTE]
> Das Unbound-Image ist in dieser Datei zusätzlich per Digest gepinnt. Dadurch ändert es sich nicht unbemerkt. Bei einem Repository-Update kann der Digest bewusst auf einen geprüften neueren Build angehoben werden.

---

## Standalone vs. normale Repository-Variante

| Funktion | `compose.yaml` | `compose.nas.yaml` |
|---|---|---|
| Eigene Images lokal bauen | ✅ | ❌ |
| Eigene Unbound-Konfiguration im Repo | ✅ | ❌ |
| Docker Secret für Webpasswort | ✅ | ❌ |
| Nur eine einzelne Datei nötig | ❌ | ✅ |
| Portainer Web Editor | mit gesamtem Repo | ✅ direkt |
| NAS-freundliche Named Volumes | teilweise | ✅ |
| Maximale Kontrolle / Hardening | ✅ | reduziert |
| Einfachstes Deployment | ❌ | ✅ |

Die normale `compose.yaml` bleibt die **Advanced-/Hardening-Variante** des Projekts. `compose.nas.yaml` ist die bewusst vereinfachte **Standalone-Variante** für Systeme, auf denen eine einzelne Compose-Datei praktischer ist.
