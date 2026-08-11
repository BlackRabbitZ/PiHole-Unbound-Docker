SHELL := /bin/sh

.PHONY: init up down status logs test backup update validate

init:
	./scripts/init.sh

up:
	./scripts/start.sh

down:
	./scripts/stop.sh

status:
	./scripts/status.sh

logs:
	./scripts/logs.sh

test:
	./scripts/test-dns.sh

backup:
	./scripts/backup.sh

update:
	./scripts/update.sh

validate:
	python3 scripts/validate.py
	docker compose config --quiet
