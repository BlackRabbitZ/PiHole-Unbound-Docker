# Updates

## Pi-hole

Pi-hole ist in `pihole/Dockerfile` auf eine konkrete Version gepinnt. Das verhindert unbeabsichtigte Breaking Changes durch `latest`.

Upgrade-Ablauf:

```bash
./scripts/backup.sh
```

1. Offizielle Pi-hole Docker Release Notes lesen.
2. `FROM pihole/pihole:VERSION` aktualisieren.
3. Commit/PR erstellen.
4. CI abwarten.
5. Lokal neu bauen:

```bash
docker compose build --pull --no-cache
docker compose up -d
./scripts/test-dns.sh
```

## Alpine / Unbound

Der Unbound-Container verwendet einen gepinnten Alpine-Stable-Release. Alpine-Sicherheitsupdates werden beim Neubau innerhalb des ausgewählten Branches über `apk add` berücksichtigt. Bei einer neuen Alpine-Major/Minor-Serie sollte die Dockerfile-Basis bewusst aktualisiert und `unbound-checkconf` erneut ausgeführt werden.

## Rollback

Bei Problemen:

1. Vorherigen Git-Stand oder vorherige Image-Version wiederherstellen.
2. Backup einspielen, falls Pi-hole-Daten migriert wurden.
3. Container neu starten.
