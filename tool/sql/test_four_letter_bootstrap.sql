-- Disposable PostgreSQL test database only. Minimal Supabase auth scaffolding.
create role authenticated nologin;
create role anon nologin;
create schema auth;
create table auth.users (id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
create publication supabase_realtime;
\ir ../../supabase/migrations/0001_schema.sql
\ir ../../supabase/migrations/0002_policies.sql
\ir ../../supabase/migrations/0003_functions.sql
\ir ../../supabase/migrations/0004_challenges.sql
\ir ../../supabase/migrations/0005_challenge_functions.sql
\ir ../../supabase/migrations/0006_fix_participants_policy.sql
\ir ../../supabase/migrations/0007_delete_account.sql
insert into auth.users values
 ('00000000-0000-0000-0000-000000000001', 'one@example.test'),
 ('00000000-0000-0000-0000-000000000002', 'two@example.test');
update public.profiles set display_name = 'ليلى' where id = '00000000-0000-0000-0000-000000000001';
insert into public.friendships (user_a, user_b, requested_by, status) values
 ('00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'accepted');
insert into public.daily_words values ('2026-09-01', 1, 'مدرسة');
insert into public.challenge_words(word) values ('مكتبة');
insert into public.game_results(user_id, word_date, won, guesses, grid) values
 ('00000000-0000-0000-0000-000000000001', current_date, true, 1, '22222');
insert into public.challenges(id, creator_id, opponent_id, word) values
 ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'مكتبة');
insert into public.challenge_participants(challenge_id, user_id, guesses_used, finished, won, grid) values
 ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 1, true, true, '22222'),
 ('00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 2, false, false, '00000|00000');
create schema test_checks;
create table test_checks.preserved as
select 'users' as name, jsonb_agg(to_jsonb(t) order by id) as data from auth.users t
union all select 'profiles', jsonb_agg(to_jsonb(t) order by id) from public.profiles t
union all select 'friendships', jsonb_agg(to_jsonb(t) order by user_a) from public.friendships t
union all select 'policies', jsonb_agg(to_jsonb(t) order by tablename, policyname) from pg_policies t where schemaname = 'public'
union all select 'rpcs', jsonb_agg(jsonb_build_array(oid::regprocedure::text, proacl::text, pg_get_functiondef(oid)) order by oid)
  from pg_proc where pronamespace = 'public'::regnamespace;
