#!/usr/bin/env bash
# Cloud Agent start: bring up Postgres on every boot.
set -euo pipefail

sudo service postgresql start
until pg_isready -q; do sleep 1; done

export DB_HOST="${DB_HOST:-127.0.0.1}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USERNAME="${DB_USERNAME:-postgres}"
export DB_PASSWORD="${DB_PASSWORD:-postgres}"
