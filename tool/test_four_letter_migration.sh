#!/usr/bin/env bash
# Run against a NEW disposable database, with PostgreSQL tools on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ${PGDATABASE:-} != kalimat_four_letter_test ]]; then
  echo 'Set PGDATABASE=kalimat_four_letter_test to an empty disposable database.' >&2
  exit 2
fi
psql -X -v ON_ERROR_STOP=1 -f tool/sql/test_four_letter_bootstrap.sql
# Deliberately fail after the reset and verify the entire reset rolls back.
if psql -X -v ON_ERROR_STOP=1 --single-transaction \
    -f supabase/migrations/0008_four_letter_gameplay.sql \
    -c 'select 1 / 0;' > /tmp/kalimat-migration-rollback.log 2>&1; then
  echo 'Expected transaction failure' >&2; exit 1
fi
[[ "$(psql -XAt -c 'select word from public.daily_words limit 1')" == 'مدرسة' ]]
bash tool/deploy_four_letter.sh /tmp/kalimat-four-letter-backups
psql -X -v ON_ERROR_STOP=1 -f tool/sql/test_four_letter_assertions.sql
# A second deployment must refuse, preserving newly created results.
if bash tool/deploy_four_letter.sh /tmp/kalimat-four-letter-backups; then
  echo 'Reset incorrectly ran twice' >&2; exit 1
fi
[[ "$(psql -XAt -c 'select count(*) from public.game_results')" == 2 ]]
echo 'PASS: rollback and replay protection'
