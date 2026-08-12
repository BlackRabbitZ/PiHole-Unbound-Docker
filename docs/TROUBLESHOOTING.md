# Troubleshooting

## Preflight zuerst ausführen

```bash
./scripts/preflight.sh
```

Der Preflight prüft Docker/Compose, das Pi-hole-Secret, die Compose-Konfiguration und – soweit `ss` verfügbar ist – Konflikte am konfigurierten DNS-Host-Port.


## Port 53 ist bereits belegt

Prüfen:

```bash
sudo ss -lntup | grep ':53 '
```

Auf vielen Linux-Systemen kann `systemd-resolved` Port 53 lokal verwenden. Die korrekte Anpassung hängt von Distribution und Netzwerksetup ab. Vor Änderungen sicherstellen, dass die Namensauflösung des Hosts danach weiterhin funktioniert.

Docker-Fehler sieht oft so aus:

```text
bind: address already in use
```

## Containerstatus

```bash
docker compose ps
./scripts/status.sh
```

## Logs

```bash
./scripts/logs.sh
./scripts/logs.sh pihole
./scripts/logs.sh unbound
```

## Unbound ist unhealthy

Der Docker-Healthcheck prüft bewusst nur die lokale Dienstbereitschaft über die eingebaute `localhost`-Zone. Dadurch hängt der Containerstatus nicht von einer externen Testdomain ab.

Direkt testen:

```bash
docker exec blackrabbitz-unbound dig @127.0.0.1 -p 5335 localhost A
docker exec blackrabbitz-unbound dig @127.0.0.1 -p 5335 example.com A
```

DNSSEC:

```bash
docker exec blackrabbitz-unbound dig @127.0.0.1 -p 5335 +dnssec dnssec.works A
docker exec blackrabbitz-unbound dig @127.0.0.1 -p 5335 fail01.dnssec.works A
```

`dnssec.works` sollte `NOERROR` liefern. `fail01.dnssec.works` sollte durch DNSSEC-Validierung `SERVFAIL` ergeben.

## ISP blockiert oder proxyt Port 53

Ein echter rekursiver Resolver muss Root-/TLD-/autoritative DNS-Server direkt über Port 53 erreichen können. Manche Netze oder ISPs blockieren oder transparent proxyen diese Anfragen. Die offizielle Pi-hole-Unbound-Dokumentation empfiehlt, den direkten Zugriff auf Root-Server vor dem Einsatz zu prüfen.

## Pi-hole startet, löst aber nichts auf

Prüfen, ob der Upstream korrekt gesetzt ist:

```bash
docker exec blackrabbitz-pihole pihole-FTL --config dns.upstreams
```

Erwartet wird sinngemäß:

```text
unbound#5335
```

Dann prüfen, ob Docker den Service auflösen kann:

```bash
docker exec blackrabbitz-pihole getent hosts unbound
```

## Weboberfläche nicht erreichbar

Standard:

```text
http://HOST-IP:8080/admin/
```

Prüfen:

```bash
docker compose ps
sudo ss -lntp | grep ':8080 '
```

## Passwort vergessen

Das durch `init.sh` erzeugte Secret steht lokal in:

```text
secrets/pihole_webpassword.txt
```

Diese Datei niemals committen oder öffentlich teilen.


## Vollständiger End-to-End-Test

```bash
./scripts/test-dns.sh
```

Das Skript prüft lokalen Unbound-Readiness, echte rekursive Auflösung, gültiges und absichtlich ungültiges DNSSEC, den Pi-hole-Upstream sowie die Auflösung Pi-hole → Unbound → Internet.
