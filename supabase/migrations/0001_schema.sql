-- كلمات (Kalimat) schema. Run in the Supabase SQL editor (or CLI) in order:
-- 0001_schema.sql, 0002_policies.sql, 0003_functions.sql, then the seed
-- (supabase/seed/daily_words_seed.sql).

create table public.daily_words (
  word_date  date primary key,               -- Asia/Riyadh calendar date
  puzzle_no  int  not null unique,
  word       text not null check (char_length(word) = 5)  -- display spelling
);
-- RLS on with NO policies: clients cannot read this table at all.
-- The only access path is the get_daily_word() RPC (security definer).
alter table public.daily_words enable row level security;

create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'لاعب',
  created_at   timestamptz not null default now()
);
alter table public.profiles enable row level security;

create table public.game_results (
  id          bigint generated always as identity primary key,
  user_id     uuid not null references auth.users(id) on delete cascade,
  word_date   date not null,
  won         boolean not null,
  guesses     int check (guesses between 1 and 6),  -- null when lost
  grid        text check (grid ~ '^[012]{5}([|][012]{5}){0,5}$'),
  duration_ms int,
  live        boolean not null default true,        -- false = backfilled offline sync
  created_at  timestamptz not null default now(),
  unique (user_id, word_date)                       -- one result per user per day
);
alter table public.game_results enable row level security;
create index on public.game_results (word_date, won, guesses, duration_ms);

-- Auto-create a profile row for every new auth user.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, 'لاعب ' || substr(md5(new.id::text), 1, 4))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
