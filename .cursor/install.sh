#!/usr/bin/env bash
# Cloud Agent install: refresh gems + prepare Postgres databases.
# Must terminate. Idempotent. Safe under non-interactive `bash -lc`.
set -euo pipefail

export PATH="${HOME}/.local/share/mise/shims:${HOME}/.local/bin:/usr/local/bin:${PATH}"

if ! command -v bundle >/dev/null 2>&1; then
  if command -v mise >/dev/null 2>&1; then
    mise install
  else
    echo "error: Ruby/Bundler not found and mise is unavailable" >&2
    exit 127
  fi
fi

# System packages needed by native gems (idempotent).
if ! dpkg -s libvips42 >/dev/null 2>&1 && ! dpkg -s libvips42t64 >/dev/null 2>&1; then
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libvips42t64 libvips-dev || \
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libvips42 libvips-dev
fi

# Local Postgres on the default image (no Docker in Cloud Agents).
sudo service postgresql start
until pg_isready -q; do sleep 1; done

export DB_HOST="${DB_HOST:-127.0.0.1}"
export DB_PORT="${DB_PORT:-5432}"
export DB_USERNAME="${DB_USERNAME:-postgres}"
export DB_PASSWORD="${DB_PASSWORD:-postgres}"

# Ensure password auth works for the app's default credentials.
sudo -u postgres psql -v ON_ERROR_STOP=1 <<'SQL' >/dev/null
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'postgres') THEN
    CREATE ROLE postgres SUPERUSER LOGIN PASSWORD 'postgres';
  ELSE
    ALTER ROLE postgres WITH LOGIN PASSWORD 'postgres';
  END IF;
END
$$;
SQL

bundle install
bin/rails db:prepare
