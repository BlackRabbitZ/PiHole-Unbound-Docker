# Änderungen dieser Überarbeitung

Diese Dateien sind als direkt einspielbares Update für das bestehende Repository gedacht.

## Neu

- `docs/INSTALLATION.md`
  - vollständige Installation von Docker Engine und Compose
  - Port-53-Prüfung
  - Klonen und Initialisieren des Projekts
  - getrennte Erklärung von Image-Build und Container-Erstellung
  - Verifikation, Logs, Tests, Router-Konfiguration und Deinstallation
- `scripts/build.sh`
  - separater Build-Workflow
  - `--pull` für erneute Prüfung der Base-Images
  - gezielter Build von `pihole` oder `unbound`

## Geändert

- `README.md`
  - komplett neu strukturiert
  - Installation, Build und Container-Start klar getrennt
  - detaillierter Schnellstart
  - neue Befehlsübersicht
  - bessere Verlinkung der Dokumentation
- `scripts/start.sh`
  - startet standardmäßig ohne unnötigen Rebuild
  - `--build` ermöglicht weiterhin Build + Start in einem Schritt
  - Docker/Compose-Prüfung ergänzt
- `Makefile`
  - neues Target `build`
  - neues Target `rebuild`

## Empfohlene Commit-Message

```text
docs: add complete Docker installation and build workflow
```

## Einspielen

Die Dateien aus diesem Paket in die entsprechenden Pfade des vorhandenen Repositories kopieren. Danach:

```bash
chmod +x scripts/build.sh scripts/start.sh
git add README.md docs/INSTALLATION.md scripts/build.sh scripts/start.sh Makefile
git commit -m "docs: add complete Docker installation and build workflow"
git push
```
