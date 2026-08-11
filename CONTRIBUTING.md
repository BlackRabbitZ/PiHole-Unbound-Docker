# Mitwirken

Beiträge sind willkommen.

## Vor einem Pull Request

```bash
shellcheck scripts/*.sh unbound/entrypoint.sh
python scripts/validate.py
docker compose config
docker build -f unbound/Dockerfile .
```

Bitte:

- keine Secrets oder echten privaten Netzwerkdaten committen,
- sicherheitsrelevante Defaults nicht ohne Begründung lockern,
- neue externe Images/Actions begründen,
- Pi-hole-/Alpine-Versionen nur nach Prüfung der Upstream-Release-Notes aktualisieren,
- bestehende Lizenz-/Attribution-Hinweise erhalten.

Beiträge werden unter denselben Lizenzbedingungen wie das Projekt akzeptiert, sofern nicht ausdrücklich anders gekennzeichnet.
