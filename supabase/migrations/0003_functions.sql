-- RPCs. The server clock (Asia/Riyadh) is the authority for "today";
-- future words are never exposed to clients.

create or replace function public.riyadh_today() returns date
language sql stable as $$ select (now() at time zone 'Asia/Riyadh')::date $$;

create or replace function public.get_daily_word()
returns table (word_date date, puzzle_no int, word text)
language sql stable security definer set search_path = public as $$
  select word_date, puzzle_no, word from daily_words where word_date = riyadh_today();
$$;
grant execute on function public.get_daily_word() to authenticated;

-- Anti-abuse: uid stamped server-side; date window max 7 days back, never
-- future; unique(user_id, word_date) makes it idempotent; live marks
-- same-day submissions (only those count for the daily leaderboard).
create or replace function public.submit_result(
  p_word_date date, p_won boolean, p_guesses int, p_grid text, p_duration_ms int default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_word_date > riyadh_today() or p_word_date < riyadh_today() - 7 then
    raise exception 'date out of range';
  end if;
  if p_won and (p_guesses is null or p_guesses not between 1 and 6) then
    raise exception 'bad guesses';
  end if;
  insert into game_results (user_id, word_date, won, guesses, grid, duration_ms, live)
  values (auth.uid(), p_word_date, p_won, p_guesses, p_grid, p_duration_ms,
          p_word_date = riyadh_today())
  on conflict (user_id, word_date) do nothing;
end $$;
grant execute on function public.submit_result(date,boolean,int,text,int) to authenticated;

-- Daily leaderboard: today's LIVE results, best first.
create or replace function public.get_daily_leaderboard(p_limit int default 50)
returns table (display_name text, guesses int, won boolean, duration_ms int)
language sql stable security definer set search_path = public as $$
  select coalesce(p.display_name, 'لاعب'), r.guesses, r.won, r.duration_ms
  from game_results r left join profiles p on p.id = r.user_id
  where r.word_date = riyadh_today() and r.live
  order by r.won desc, r.guesses asc nulls last, r.duration_ms asc nulls last
  limit least(p_limit, 100);
$$;

-- Global leaderboard: wins + avg guesses, minimum 5 games.
create or replace function public.get_global_leaderboard(p_limit int default 50)
returns table (display_name text, games int, wins int, avg_guesses numeric)
language sql stable security definer set search_path = public as $$
  select coalesce(p.display_name, 'لاعب'), count(*)::int,
         (count(*) filter (where r.won))::int,
         round(avg(r.guesses) filter (where r.won), 2)
  from game_results r left join profiles p on p.id = r.user_id
  group by r.user_id, p.display_name
  having count(*) >= 5
  order by count(*) filter (where r.won) desc, avg(r.guesses) filter (where r.won) asc
  limit least(p_limit, 100);
$$;
grant execute on function public.get_daily_leaderboard(int) to authenticated;
grant execute on function public.get_global_leaderboard(int) to authenticated;
