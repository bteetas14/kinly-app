#!/usr/bin/env sh
set -eu

DATABASE_URL="${DATABASE_URL:-postgres://kinly:kinly@localhost:5432/kinly?sslmode=disable}"

for migration in database/migrations/*.up.sql; do
  echo "Applying ${migration}"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${migration}"
done
