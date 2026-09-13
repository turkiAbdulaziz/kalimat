# Four-letter test-game reset

`0008_four_letter_gameplay.sql` changes daily puzzles and friend duels to four letters and six attempts. Historical migrations stay intact. This is a coordinated test-data reset: five-letter clients are unsupported after deployment.

The migration deletes `game_results`, `challenge_participants`, `challenges`, `daily_words`, and `challenge_words`. It preserves `auth.users`, profiles (including names, ratings and six-digit friend codes), friendships, RLS, policies, grants and all existing RPC signatures. Word constraints become four characters. Result grids accept one to six rows of four cells; nullable unfinished duel grids remain supported.

The updated client runs gameplay version 2 before resolving its startup word. It clears the cached daily answer, daily/duel boards, queued results, local statistics, and help-seen flag once. Authentication, onboarding, display name, settings and reminder time survive. The completion marker is written only after every clear succeeds. Old or malformed saves are ignored even after migration; incompatible server daily answers fall back to bundled words, and incompatible duels offer retry/back.

## Deploy

1. Finish local validation and prepare the updated client build. Pause test-client traffic for the backup and switch; resume using updated clients. This prevents writes between the backup cutoff and migration.
2. Configure a direct or session-pooler PostgreSQL connection through libpq environment variables or a local service plus `.pgpass`. Do not put credentials in this repository or pass them as CLI arguments. Put PostgreSQL's `psql`, `pg_dump`, and `pg_restore`, plus `dart`, on PATH.
3. Run from the repository root, with `PGDATABASE` explicitly identifying the target database:

   ```sh
   PGSERVICE=kalimat-test PGDATABASE=postgres bash tool/deploy_four_letter.sh /private/backup/kalimat
   ```

   Choose an existing writable private backup location. The script checks deterministic generation, refuses an already-applied reset, writes a full custom-format database backup with private permissions, verifies its archive catalog, then applies migration + both seeds + seed checks + the `0008` migration-history entry in one transaction. A failure rolls back the switch. Never apply migration 0008 alone to an active service and seed later.
4. Check that `daily_words` has 365 rows and `challenge_words` has 200, `get_daily_word()` matches the updated bundle for the server's Riyadh date, old gameplay is empty, and the preserved friend relationship still works. Play daily and duel games with updated clients. New devices keep puzzle numbering from September 1, 2026.

Do not replay 0008. Both the script and migration reject replay before deleting new games. Supabase CLI migrations will recognize the script's history entry. Existing deployments created manually in the SQL editor may still need their historical 0001–0007 history reconciled before using the CLI for future migrations; this script does not guess historical deployment state.

For recovery, restore the full backup into a separate database first and verify it before replacing a live database. A post-switch rollback also requires compatible clients and local gameplay handling; restoring server rows alone does not restore device statistics.

## Local verification

An isolated PostgreSQL 17.11 database used minimal `auth.users`/`auth.uid()` test scaffolding and the actual historical migrations 0001–0007, then populated accounts, profiles, an accepted friendship, old word pools, a daily result and a duel with participant progress.

`tool/test_four_letter_migration.sh` verified:

- An intentional failure after the reset rolled back all changes.
- The deployment script produced a custom-format backup and applied the migration and seeds together.
- Old gameplay was removed; account/profile/friendship snapshots, RLS, policies, function definitions, signatures and grants stayed identical.
- Existing daily/duel RPCs accepted four-cell wins and six-row losses, and a new duel completed normally.
- Five-cell, mixed-width, empty, short, invalid-character, newline and seven-row result grids failed.
- All three word tables rejected five-letter answers; seed sizes, normalized disjointness and September 1 puzzle dates matched.
- Re-running deployment refused and retained the newly created four-letter results.

To repeat on a fresh disposable PostgreSQL cluster (no Supabase project needed): create an empty database named `kalimat_four_letter_test`, set `PGHOST`, `PGPORT`, `PGDATABASE`, and PostgreSQL tools on PATH, then run `bash tool/test_four_letter_migration.sh`. The fixture creates cluster roles `authenticated` and `anon`, so use an isolated cluster. The test backup is written under `/tmp/kalimat-four-letter-backups`.

Client validation completed on 2026-09-13: all 170 Flutter tests passed, `flutter analyze` reported no issues, and the iOS integration suite passed all eight 1320×2868 App Store captures. The final daily, help, sign-in, profile and duel light/dark screenshots were visually reviewed.

Production rollout was confirmed applied by the account owner on 2026-09-13. The local implementation tests did not independently verify live Supabase Auth or Realtime transport.
