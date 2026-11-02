#!/usr/bin/env bash
# Runs the SQL tests in supabase/tests against a throwaway local Postgres.
# No Docker needed. Requires Postgres server binaries (default: /usr/lib/postgresql/16/bin).
# Each test file fails by raising an exception; any psql error fails the run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PGBIN="${PGBIN:-/usr/lib/postgresql/16/bin}"
PORT="${PGTEST_PORT:-54329}"
DATA="$(mktemp -d)"

# Postgres refuses to run as root, so drop to the postgres user when needed.
if [ "$(id -u)" = "0" ]; then
  chown postgres "$DATA"
  RUN=(runuser -u postgres --)
else
  RUN=()
fi

cleanup() {
  "${RUN[@]}" "$PGBIN/pg_ctl" -D "$DATA" -m immediate stop >/dev/null 2>&1 || true
  rm -rf "$DATA"
}
trap cleanup EXIT

"${RUN[@]}" "$PGBIN/initdb" -D "$DATA" -U postgres --auth=trust >/dev/null
"${RUN[@]}" "$PGBIN/pg_ctl" -D "$DATA" -o "-p $PORT -k $DATA -c listen_addresses=''" -w start >/dev/null

PSQL=("${RUN[@]}" "$PGBIN/psql" -h "$DATA" -p "$PORT" -U postgres -v ON_ERROR_STOP=1 -q)

# Build a template database (stand-ins + migrations) once; every test file then
# runs against its own fresh copy, so tests cannot interfere with each other.
"${PSQL[@]}" -d postgres -c "create database template_app" >/dev/null
run_file() { "${PSQL[@]}" -d "$1" -f "$2" >/dev/null; }

run_file template_app "$ROOT/supabase/tests/support/00_supabase_stubs.sql"

shopt -s nullglob
for f in "$ROOT"/supabase/migrations/*.sql; do
  echo "migrate  $(basename "$f")"
  run_file template_app "$f"
done

fail=0
n=0
for f in "$ROOT"/supabase/tests/*_test.sql; do
  n=$((n + 1))
  "${PSQL[@]}" -d postgres -c "create database test_$n template template_app" >/dev/null
  if run_file "test_$n" "$f"; then
    echo "PASS     $(basename "$f")"
  else
    echo "FAIL     $(basename "$f")"
    fail=1
  fi
done
exit $fail
