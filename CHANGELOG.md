# Changelog


## [1.0.2] - 2026-08-11

### Fixed
- Seed the packaged DNSSEC root trust anchor during the Unbound image build so `unbound-checkconf` can validate the configuration successfully.
- Runtime behavior remains unchanged: `entrypoint.sh` still recreates/updates the trust anchor in the persistent `/var/lib/unbound` volume when needed.

## [1.0.1] - 2026-08-11

### Fixed
- ShellCheck SC1007 warnings in repository helper scripts.
- Documented intentional container-side command substitution to suppress false-positive SC2016 warnings.

## 1.0.0 – 2026-08-11

- Erstveröffentlichung
- Pi-hole v6 Docker Setup
- eigener Unbound-Container auf Alpine Linux
- DNSSEC, QNAME-Minimierung, Caching und Hardening
- Docker Secret für Webpasswort
- persistente Konfiguration
- Backup/Restore/Update/Test-Skripte
- GitHub Actions, Dependabot und Repository-Templates
- GPL-3.0-only + BlackRabbitZ Attribution gemäß GPLv3 §7
