# GitHub-Veröffentlichung

Empfohlener Repository-Name:

```text
PiHole-Unbound-Docker
```

Empfohlene Beschreibung:

```text
Hardened Pi-hole v6 + recursive Unbound DNS resolver with Docker Compose, DNSSEC, Docker Secrets, backups and security-focused defaults.
```

Empfohlene Topics:

```text
pihole
pi-hole
unbound
dns
dnssec
docker
docker-compose
privacy
adblock
network-security
homelab
raspberry-pi
self-hosted
```

## Erstes Pushen

```bash
git init
git branch -M main
git add .
git commit -m "Initial release: Pi-hole + Unbound Docker v1.0.0"
git remote add origin https://github.com/BlackRabbitZ/PiHole-Unbound-Docker.git
git push -u origin main
```

## Release erstellen

```bash
git tag -a v1.0.0 -m "PiHole-Unbound-Docker v1.0.0"
git push origin v1.0.0
```

Der Release-Workflow erstellt daraufhin ein bereinigtes `.tar.gz`-Bundle und eine SHA-256-Prüfsumme.

## GitHub-Einstellungen

Empfohlen:

- Repository öffentlich
- Issues aktivieren
- Private Vulnerability Reporting aktivieren
- Branch Protection für `main`
- Pull Request vor Merge verlangen
- GitHub Actions für Pull Requests laufen lassen
- Dependabot Alerts und Security Updates aktivieren
