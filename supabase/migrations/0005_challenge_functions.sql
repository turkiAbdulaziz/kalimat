-- Duel RPCs. Same discipline as 0003: security definer, uid stamped
-- server-side, results write-once, and the word never leaves a list query.

-- ------------------------------------------------------------------ helpers

-- Canonical pair ordering for friendships (user_a < user_b).
-- Compared as uuid, not text: the friendships CHECK uses the uuid operator,
-- and a text comparison would follow the database collation instead.
create or replace function public.pair_lo(a uuid, b uuid) returns uuid
language sql immutable as $$ select case when a < b then a else b end $$;

create or replace function public.pair_hi(a uuid, b uuid) returns uuid
language sql immutable as $$ select case when a < b then b else a end $$;

create or replace function public.are_friends(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from friendships
    where user_a = pair_lo(a, b) and user_b = pair_hi(a, b) and status = 'accepted'
  );
$$;

-- Duels left unplayed past their window stop counting. Called lazily by the
-- list RPC — no cron job to keep alive on the free tier.
create or replace function public.expire_stale_challenges() returns void
language sql volatile security definer set search_path = public as $$
  update challenges set status = 'expired'
  where status = 'active' and expires_at < now();
$$;

-- ------------------------------------------------------------------ friends

-- The only cross-user lookup path. Returns a status word plus the target's
-- display name; rate-limited so 6-digit codes can't be swept cheaply.
create or replace function public.send_friend_request(p_code text)
returns table (result text, user_id uuid, display_name text)
language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
        target profiles%rowtype;
        existing friendships%rowtype;
begin
  if me is null then raise exception 'not authenticated'; end if;

  if (select count(*) from friendships
      where requested_by = me and created_at > now() - interval '1 day') >= 30 then
    return query select 'rate_limited'::text, null::uuid, null::text; return;
  end if;

  select * into target from profiles where friend_code = trim(p_code);
  if not found then
    return query select 'not_found'::text, null::uuid, null::text; return;
  end if;
  if target.id = me then
    return query select 'self'::text, null::uuid, null::text; return;
  end if;

  select * into existing from friendships
  where user_a = pair_lo(me, target.id) and user_b = pair_hi(me, target.id);

  if found then
    if existing.status = 'accepted' then
      return query select 'already_friends'::text, target.id, target.display_name; return;
    end if;
    -- They already asked us: answering with a request of our own accepts it.
    if existing.requested_by <> me then
      update friendships set status = 'accepted'
      where user_a = existing.user_a and user_b = existing.user_b;
      return query select 'accepted'::text, target.id, target.display_name; return;
    end if;
    return query select 'pending'::text, target.id, target.display_name; return;
  end if;

  insert into friendships (user_a, user_b, requested_by)
  values (pair_lo(me, target.id), pair_hi(me, target.id), me);
  return query select 'sent'::text, target.id, target.display_name;
end $$;

create or replace function public.respond_friend_request(p_user_id uuid, p_accept boolean)
returns void language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'not authenticated'; end if;
  if p_accept then
    update friendships set status = 'accepted'
    where user_a = pair_lo(me, p_user_id) and user_b = pair_hi(me, p_user_id)
      and status = 'pending' and requested_by <> me;   -- can't accept your own
  else
    delete from friendships
    where user_a = pair_lo(me, p_user_id) and user_b = pair_hi(me, p_user_id)
      and status = 'pending';
  end if;
end $$;

create or replace function public.remove_friend(p_user_id uuid)
returns void language sql volatile security definer set search_path = public as $$
  delete from friendships
  where user_a = pair_lo(auth.uid(), p_user_id)
    and user_b = pair_hi(auth.uid(), p_user_id);
$$;

-- Friends with the head-to-head record against you.
create or replace function public.get_friends()
returns table (user_id uuid, display_name text, friend_code text, wins int, losses int)
language sql stable security definer set search_path = public as $$
  with f as (
    select case when user_a = auth.uid() then user_b else user_a end as fid
    from friendships
    where status = 'accepted' and auth.uid() in (user_a, user_b)
  )
  select p.id, p.display_name, p.friend_code,
         coalesce(s.wins, 0)::int, coalesce(s.losses, 0)::int
  from f
  join profiles p on p.id = f.fid
  left join lateral (
    select count(*) filter (where c.winner_id = auth.uid())::int as wins,
           count(*) filter (where c.winner_id = p.id)::int       as losses
    from challenges c
    where c.status = 'complete'
      and ((c.creator_id = auth.uid() and c.opponent_id = p.id)
        or (c.creator_id = p.id and c.opponent_id = auth.uid()))
  ) s on true
  order by p.display_name;
$$;

-- Incoming requests waiting on you (outgoing ones need no UI).
create or replace function public.get_friend_requests()
returns table (user_id uuid, display_name text, created_at timestamptz)
language sql stable security definer set search_path = public as $$
  select p.id, p.display_name, f.created_at
  from friendships f
  join profiles p on p.id = f.requested_by
  where f.status = 'pending' and f.requested_by <> auth.uid()
    and auth.uid() in (f.user_a, f.user_b)
  order by f.created_at desc;
$$;

-- My own code, for «رمزي» on the friends tab.
create or replace function public.get_my_profile()
returns table (friend_code text, display_name text, wins int, losses int, draws int)
language sql stable security definer set search_path = public as $$
  select p.friend_code, p.display_name,
         coalesce(s.wins, 0)::int, coalesce(s.losses, 0)::int, coalesce(s.draws, 0)::int
  from profiles p
  left join lateral (
    select count(*) filter (where c.winner_id = p.id)::int as wins,
           count(*) filter (where c.winner_id is not null and c.winner_id <> p.id)::int as losses,
           count(*) filter (where c.winner_id is null)::int as draws
    from challenges c
    where c.status = 'complete' and p.id in (c.creator_id, c.opponent_id)
  ) s on true
  where p.id = auth.uid();
$$;

-- --------------------------------------------------------------- challenges

-- The OUT columns are prefixed: an OUT parameter named `word` would shadow
-- the challenges.word column inside this body.
create or replace function public.create_challenge(p_opponent_id uuid)
returns table (challenge_id uuid, challenge_word text, opponent_name text)
language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
        picked text;
        new_id uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if not are_friends(me, p_opponent_id) then raise exception 'not friends'; end if;

  if (select count(*) from challenges
      where creator_id = me and created_at > now() - interval '1 day') >= 50 then
    raise exception 'too many challenges';
  end if;
  if (select count(*) from challenges
      where status = 'active'
        and ((creator_id = me and opponent_id = p_opponent_id)
          or (creator_id = p_opponent_id and opponent_id = me))) >= 5 then
    raise exception 'too many open challenges with this player';
  end if;

  select w.word into picked from challenge_words w order by random() limit 1;
  if picked is null then raise exception 'challenge word pool is empty'; end if;

  insert into challenges (creator_id, opponent_id, word)
  values (me, p_opponent_id, picked)
  returning challenges.id into new_id;

  insert into challenge_participants (challenge_id, user_id)
  values (new_id, me), (new_id, p_opponent_id);

  return query
    select new_id, picked, p.display_name from profiles p where p.id = p_opponent_id;
end $$;

-- Opening the board. Participants only; stamps started_at on the first open.
-- The opponent's grid stays hidden until they finish.
create or replace function public.get_challenge(p_id uuid)
returns table (
  id uuid, word text, status text, winner_id uuid, expires_at timestamptz,
  opponent_id uuid, opponent_name text,
  my_guesses int, my_finished boolean, my_won boolean, my_duration_ms int,
  their_guesses int, their_finished boolean, their_won boolean,
  their_duration_ms int, their_grid text
)
language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
        c challenges%rowtype;
        them uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  select * into c from challenges where challenges.id = p_id;
  if not found or me not in (c.creator_id, c.opponent_id) then
    raise exception 'no such challenge';
  end if;
  them := case when c.creator_id = me then c.opponent_id else c.creator_id end;

  update challenge_participants set started_at = now()
  where challenge_id = p_id and user_id = me and started_at is null;

  return query
    select c.id, c.word, c.status, c.winner_id, c.expires_at,
           them, p.display_name,
           mine.guesses_used, mine.finished, mine.won, mine.duration_ms,
           theirs.guesses_used, theirs.finished, theirs.won, theirs.duration_ms,
           case when theirs.finished then theirs.grid else null end
    from profiles p
    join challenge_participants mine
      on mine.challenge_id = p_id and mine.user_id = me
    join challenge_participants theirs
      on theirs.challenge_id = p_id and theirs.user_id = them
    where p.id = them;
end $$;

-- One column, fired per guess: this is the payload the opponent's board
-- listens to. Never moves backwards, never touches a finished row.
create or replace function public.update_challenge_progress(p_id uuid, p_guesses int)
returns void language sql volatile security definer set search_path = public as $$
  update challenge_participants set guesses_used = p_guesses
  where challenge_id = p_id and user_id = auth.uid()
    and not finished and p_guesses between guesses_used and 6;
$$;

-- Write-once. Decides the duel as soon as both sides are in:
-- a win beats a loss, then fewer guesses, then the faster solve.
create or replace function public.submit_challenge_result(
  p_id uuid, p_won boolean, p_guesses int, p_duration_ms int, p_grid text
) returns void language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
        c challenges%rowtype;
        a challenge_participants%rowtype;   -- creator
        b challenge_participants%rowtype;   -- opponent
        decided uuid;
begin
  if me is null then raise exception 'not authenticated'; end if;
  if p_guesses is null or p_guesses not between 1 and 6 then
    raise exception 'bad guesses';
  end if;
  select * into c from challenges where challenges.id = p_id;
  if not found or me not in (c.creator_id, c.opponent_id) then
    raise exception 'no such challenge';
  end if;

  update challenge_participants
     set finished = true, won = p_won, guesses_used = p_guesses,
         duration_ms = p_duration_ms, grid = p_grid, finished_at = now()
   where challenge_id = p_id and user_id = me and not finished;

  select * into a from challenge_participants
    where challenge_id = p_id and user_id = c.creator_id;
  select * into b from challenge_participants
    where challenge_id = p_id and user_id = c.opponent_id;

  if a.finished and b.finished then
    decided := case
      when a.won and not b.won then a.user_id
      when b.won and not a.won then b.user_id
      when not a.won and not b.won then null
      when a.guesses_used < b.guesses_used then a.user_id
      when b.guesses_used < a.guesses_used then b.user_id
      -- nulls last: an unknown clock loses to a measured one.
      when coalesce(a.duration_ms, 2147483647) < coalesce(b.duration_ms, 2147483647)
        then a.user_id
      when coalesce(b.duration_ms, 2147483647) < coalesce(a.duration_ms, 2147483647)
        then b.user_id
      else null
    end;
    update challenges set status = 'complete', winner_id = decided
    where challenges.id = p_id;
  end if;
end $$;

-- The list screen's single query. Never returns `word`.
create or replace function public.get_my_challenges(p_limit int default 30)
returns table (
  id uuid, opponent_id uuid, opponent_name text, status text, winner_id uuid,
  created_at timestamptz, expires_at timestamptz,
  my_guesses int, my_finished boolean, my_won boolean, my_duration_ms int,
  their_guesses int, their_finished boolean, their_won boolean, their_duration_ms int
)
language plpgsql volatile security definer set search_path = public as $$
declare me uuid := auth.uid();
begin
  if me is null then raise exception 'not authenticated'; end if;
  perform expire_stale_challenges();
  return query
    select c.id,
           case when c.creator_id = me then c.opponent_id else c.creator_id end,
           p.display_name, c.status, c.winner_id, c.created_at, c.expires_at,
           mine.guesses_used, mine.finished, mine.won, mine.duration_ms,
           theirs.guesses_used, theirs.finished, theirs.won, theirs.duration_ms
    from challenges c
    join challenge_participants mine
      on mine.challenge_id = c.id and mine.user_id = me
    join challenge_participants theirs
      on theirs.challenge_id = c.id and theirs.user_id <> me
    join profiles p on p.id = theirs.user_id
    where me in (c.creator_id, c.opponent_id)
    order by c.created_at desc
    limit least(p_limit, 100);
end $$;

-- Internal helpers: functions are EXECUTE-to-PUBLIC by default, and these
-- are only ever called from inside the security-definer RPCs above.
revoke execute on function public.new_friend_code()          from public;
revoke execute on function public.are_friends(uuid, uuid)    from public;
revoke execute on function public.expire_stale_challenges()  from public;

grant execute on function public.send_friend_request(text)                        to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean)            to authenticated;
grant execute on function public.remove_friend(uuid)                              to authenticated;
grant execute on function public.get_friends()                                    to authenticated;
grant execute on function public.get_friend_requests()                            to authenticated;
grant execute on function public.get_my_profile()                                 to authenticated;
grant execute on function public.create_challenge(uuid)                           to authenticated;
grant execute on function public.get_challenge(uuid)                              to authenticated;
grant execute on function public.update_challenge_progress(uuid, int)             to authenticated;
grant execute on function public.submit_challenge_result(uuid, boolean, int, int, text) to authenticated;
grant execute on function public.get_my_challenges(int)                           to authenticated;
