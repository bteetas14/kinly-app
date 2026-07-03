#!/usr/bin/env sh
set -eu

DATABASE_URL="${DATABASE_URL:-postgres://kinly:kinly@localhost:5432/kinly?sslmode=disable}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-database/migrations}"

psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -c \
  "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMPTZ NOT NULL DEFAULT now())"

for migration in "${MIGRATIONS_DIR}"/*.up.sql; do
  version="$(basename "${migration}" .up.sql)"
  applied="$(psql "${DATABASE_URL}" -At -v version="${version}" -c "SELECT EXISTS (SELECT 1 FROM schema_migrations WHERE version = :'version')")"
  if [ "${applied}" = "t" ]; then
    echo "Skipping ${migration}"
    continue
  fi

  echo "Applying ${migration}"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -v version="${version}" -v migration="${migration}" <<'SQL'
BEGIN;
\i :migration
INSERT INTO schema_migrations (version) VALUES (:'version');
COMMIT;
SQL
done
