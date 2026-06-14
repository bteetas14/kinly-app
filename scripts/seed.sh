#!/usr/bin/env sh
set -eu

DATABASE_URL="${DATABASE_URL:-postgres://kinly:kinly@localhost:5432/kinly?sslmode=disable}"

for seed in database/seeds/*.sql; do
  echo "Applying ${seed}"
  psql "${DATABASE_URL}" -v ON_ERROR_STOP=1 -f "${seed}"
done
