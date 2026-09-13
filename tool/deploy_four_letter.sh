#!/usr/bin/env bash
# Requires PGHOST/PGPORT/PGDATABASE/PGUSER and .pgpass (or PGSERVICE).
# No credentials on the command line or in generated files.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ $# != 1 ]]; then
  echo "Usage: $0 BACKUP_DIRECTORY (database selected through libpq environment)" >&2
  exit 2
fi
: "${PGDATABASE:?Set PGDATABASE explicitly to the intended test database}"
command -v psql >/dev/null
command -v pg_dump >/dev/null
command -v pg_restore >/dev/null
DART_BIN="${DART_BIN:-dart}"
"$DART_BIN" tool/build_wordlists.dart --check
if [[ "$(psql -XAt -v ON_ERROR_STOP=1 -c "select count(*) from pg_constraint where conrelid = 'public.daily_words'::regclass and conname = 'daily_words_four_letters'")" != 0 ]]; then
  echo 'Four-letter reset already applied; refusing to clear new gameplay.' >&2
  exit 1
fi
umask 077
mkdir -p "$1"
backup_path="$1/five-letter-test-$(date -u +%Y%m%dT%H%M%SZ)-$$.dump"
# Full database backup includes affected data, constraints, identity and friendships.
# Pause client traffic before invoking this script so the backup is the cutoff.
pg_dump --format=custom --file="$backup_path"
pg_restore --list "$backup_path" > "$backup_path.contents"
echo "Backup ready: $backup_path"
# -1 wraps the migration, seeds, sanity checks and migration-history entry.
psql -X -v ON_ERROR_STOP=1 --single-transaction \
  -f supabase/migrations/0008_four_letter_gameplay.sql \
  -f supabase/seed/daily_words_seed.sql \
  -f supabase/seed/challenge_words_seed.sql \
  -f tool/sql/verify_four_letter_seeds.sql \
  -f tool/sql/record_four_letter_migration.sql
echo 'Four-letter migration and seeds committed. Resume only updated clients.'
