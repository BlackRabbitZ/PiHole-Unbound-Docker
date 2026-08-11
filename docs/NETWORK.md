# Netzwerk & Router

## Empfohlenes Setup

1. Docker-Host erhält eine feste LAN-IP oder DHCP-Reservation.
2. Pi-hole veröffentlicht TCP/UDP Port 53 auf dieser Host-IP.
3. Router/DHCP verteilt **nur die LAN-IP des Docker-Hosts** als DNS-Server.
4. Pi-hole leitet erlaubte Anfragen intern an Unbound weiter.

Beispiel:

```text
Router:      192.168.178.1
Docker Host: 192.168.178.10
Clients DNS: 192.168.178.10
```

In `.env` kann die Portbindung auf genau diese Host-IP beschränkt werden:

```dotenv
PIHOLE_BIND_IP=192.168.178.10
```

## Zweiter DNS-Server

Ein externer öffentlicher DNS-Server als „Secondary DNS“ kann Pi-hole umgehen, weil Clients ihn eigenständig verwenden können. Für echte Redundanz ist ein **zweites Pi-hole/Unbound-System** sinnvoller.

## VLANs

Bei mehreren VLANs muss die Firewall DNS von den Client-VLANs zur Pi-hole-Host-IP auf TCP/UDP 53 erlauben. Antworten müssen zurückgeroutet werden können.

## DHCP

Dieses Repository aktiviert Pi-hole **nicht als DHCP-Server**. DHCP in Docker benötigt je nach Netzwerkdesign Host Networking, Macvlan/Ipvlan oder einen Relay und zusätzliche Berechtigungen. Das bewusst schlanke DNS-only-Design vermeidet diese Komplexität.

## IPv6

IPv6-DNS muss separat bedacht werden. Wenn der Router über Router Advertisements einen anderen IPv6-DNS-Server verteilt, können Clients Pi-hole über IPv6 umgehen. Das ist routerabhängig und sollte im LAN geprüft werden.
