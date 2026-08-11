# Architektur

## Datenfluss

```text
LAN Client
   │
   │ DNS Query :53
   ▼
Docker Host
   │
   ▼
Pi-hole
   ├─ Blocklist-Treffer → lokale Block-Antwort
   │
   └─ erlaubt → unbound:5335
                  │
                  ├─ Cache
                  └─ Rekursive Auflösung
                       Root → TLD → authoritative DNS
```

Pi-hole und Unbound teilen ausschließlich das private Docker-Bridge-Netz `blackrabbitz-dns-backend`. Unbound wird nicht über `ports:` auf den Host veröffentlicht.

## DNSSEC

Unbound hält einen beschreibbaren RFC5011-Trust-Anchor unter `/var/lib/unbound/root.key`. Beim ersten Containerstart wird er aus dem mit dem Alpine-Paket gelieferten Root-Trust-Anchor initialisiert und danach von `unbound-anchor` aktualisiert.

## Persistenz

- `./etc-pihole` → `/etc/pihole`
- Docker Volume `blackrabbitz-unbound-state` → `/var/lib/unbound`
- `./secrets/pihole_webpassword.txt` → Docker Secret

Unbound-Caches müssen nicht persistent sein und werden nach Neustarts neu aufgebaut.

## Rechte

Für Pi-hole werden keine optionalen Host-Capabilities wie `NET_ADMIN` aktiviert, da dieses Repository DHCP ausdrücklich nicht aktiviert. Unbound erhält `no-new-privileges` und ein read-only Root-Filesystem; nur sein Trust-Anchor-Volume und tmpfs-Verzeichnisse sind beschreibbar.
