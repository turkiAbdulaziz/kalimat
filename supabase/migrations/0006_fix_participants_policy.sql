-- 0004's "participants read own match" policy checks membership through a
-- subquery on challenges — a table with RLS on and zero policies (by design:
-- the word column must stay client-unreadable). Evaluated as the
-- authenticated role, that subquery is itself subject to challenges' RLS and
-- always comes back empty, so the policy never passes: participants couldn't
-- select their duel's rows, and — the part that matters — Realtime never
-- delivered the live opponent-progress events the M6 pill listens for.
-- Found by live verification 2026-09-03 (REST read of own row: 0 rows;
-- confirmed postgres_changes subscription: no event on opponent update).
--
-- Fix: route the membership check through a security-definer helper, the
-- same pattern are_friends() uses in 0005.

create or replace function public.is_challenge_participant(p_challenge_id uuid, p_user uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from challenges c
    where c.id = p_challenge_id and p_user in (c.creator_id, c.opponent_id)
  );
$$;

-- Called from inside policy evaluation, which runs as the querying role —
-- so unlike 0005's internal helpers this one must stay executable by
-- authenticated (Realtime's delivery check impersonates that role too).
revoke execute on function public.is_challenge_participant(uuid, uuid) from public;
grant execute on function public.is_challenge_participant(uuid, uuid) to authenticated;

drop policy if exists "participants read own match" on public.challenge_participants;
create policy "participants read own match" on public.challenge_participants
  for select to authenticated
  using (is_challenge_participant(challenge_id, auth.uid()));
