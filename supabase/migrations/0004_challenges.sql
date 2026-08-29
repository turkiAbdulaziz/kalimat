-- Duels «التحدّيات»: friend graph + head-to-head matches on a word pool that
-- is disjoint from the daily rotation (so a duel can never spoil a future
-- «كلمة اليوم»). Run after 0003_functions.sql, then 0005_challenge_functions.sql
-- and the seed (supabase/seed/challenge_words_seed.sql).

-- ---------------------------------------------------------------- profiles

alter table public.profiles
  add column if not exists friend_code text unique,
  -- Reserved for the future stranger queue; nothing reads it yet.
  add column if not exists rating int not null default 1000;

-- 6 Arabic-Indic digits on screen, ASCII on the wire. Retries on collision.
create or replace function public.new_friend_code()
returns text language plpgsql volatile security definer set search_path = public as $$
declare code text;
begin
  loop
    code := lpad((floor(random() * 1000000))::int::text, 6, '0');
    exit when not exists (select 1 from profiles where friend_code = code);
  end loop;
  return code;
end $$;

update public.profiles set friend_code = public.new_friend_code()
  where friend_code is null;
alter table public.profiles alter column friend_code set not null;

-- Mint the code with the profile (replaces the 0001 version).
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name, friend_code)
  values (new.id, 'لاعب ' || substr(md5(new.id::text), 1, 4), new_friend_code())
  on conflict (id) do nothing;
  return new;
end $$;

-- Friend codes must not be harvestable: profiles are no longer world-readable.
-- Every cross-user name lookup goes through a security-definer RPC (the
-- leaderboards in 0003, the friend RPCs in 0005).
drop policy if exists "profiles read" on public.profiles;
create policy "profiles read own" on public.profiles for select to authenticated
  using (id = auth.uid());

-- --------------------------------------------------------- challenge words

create table if not exists public.challenge_words (
  id   int generated always as identity primary key,
  word text not null unique check (char_length(word) = 5)
);
-- RLS on with NO policies, exactly like daily_words: the pool is only ever
-- reachable through create_challenge().
alter table public.challenge_words enable row level security;

-- -------------------------------------------------------------- friendships

-- One row per pair, canonically ordered (user_a < user_b) so a pair can
-- never be duplicated by two simultaneous requests.
create table if not exists public.friendships (
  user_a       uuid not null references auth.users(id) on delete cascade,
  user_b       uuid not null references auth.users(id) on delete cascade,
  requested_by uuid not null references auth.users(id) on delete cascade,
  status       text not null default 'pending' check (status in ('pending', 'accepted')),
  created_at   timestamptz not null default now(),
  primary key (user_a, user_b),
  check (user_a < user_b)
);
-- RPC-only (0005): no policies.
alter table public.friendships enable row level security;
create index if not exists friendships_user_b_idx on public.friendships (user_b);

-- --------------------------------------------------------------- challenges

create table if not exists public.challenges (
  id          uuid primary key default gen_random_uuid(),
  creator_id  uuid not null references auth.users(id) on delete cascade,
  opponent_id uuid not null references auth.users(id) on delete cascade,
  -- Display spelling. Never returned by a list RPC — only by get_challenge()
  -- to a participant who is opening the board.
  word        text not null check (char_length(word) = 5),
  source      text not null default 'friend' check (source in ('friend', 'random')),
  status      text not null default 'active' check (status in ('active', 'complete', 'expired')),
  winner_id   uuid references auth.users(id) on delete set null, -- null = draw
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default now() + interval '48 hours',
  check (creator_id <> opponent_id)
);
-- RPC-only: the word column makes this table client-unreadable by design.
alter table public.challenges enable row level security;
create index if not exists challenges_creator_idx  on public.challenges (creator_id, created_at desc);
create index if not exists challenges_opponent_idx on public.challenges (opponent_id, created_at desc);
-- expire_stale_challenges() sweeps on every list call; keep it off a seq scan.
create index if not exists challenges_active_expiry_idx
  on public.challenges (expires_at) where status = 'active';

create table if not exists public.challenge_participants (
  challenge_id uuid not null references public.challenges(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  guesses_used int  not null default 0,      -- live progress, drives the opponent pill
  finished     boolean not null default false,
  won          boolean,
  duration_ms  int,
  grid         text check (grid ~ '^[012]{5}([|][012]{5}){0,5}$'),
  started_at   timestamptz,
  finished_at  timestamptz,
  primary key (challenge_id, user_id)
);
alter table public.challenge_participants enable row level security;

-- SELECT only, and only for the two players — this is what Realtime filters
-- against. Every write goes through an RPC in 0005.
drop policy if exists "participants read own match" on public.challenge_participants;
create policy "participants read own match" on public.challenge_participants
  for select to authenticated using (
    exists (
      select 1 from public.challenges c
      where c.id = challenge_id and auth.uid() in (c.creator_id, c.opponent_id)
    )
  );

-- Live opponent progress rides on postgres_changes for this table.
do $$
begin
  alter publication supabase_realtime add table public.challenge_participants;
exception
  when duplicate_object then null;
end $$;
