-- 0007: in-app account deletion.
--
-- App Store Review Guideline 5.1.1(v): an app that lets people create an
-- account must let them delete it from inside the app. Kalimat's Google /
-- Apple linking is account creation, so «حسابي» gains «حذف الحساب», backed
-- by this RPC.
--
-- Deleting the auth.users row is the whole story. Every public table that
-- names a user references auth.users(id) ON DELETE CASCADE — profiles (and
-- with it the friend code), game_results, friendships (both sides and the
-- requester), challenges as creator or opponent, challenge_participants.
-- challenges.winner_id is ON DELETE SET NULL, so a finished duel the
-- opponent still has on their list keeps its row and simply loses the winner
-- mark. Nothing lives in storage buckets.
--
-- The function runs as its owner (postgres), which is what gives it delete
-- rights on the auth schema — the authenticated role has none, by design.
-- Same discipline as 0003/0005: uid comes from auth.uid(), never a parameter,
-- so a caller can only ever delete themselves.
--
-- After it returns, the caller's JWT still names a user that no longer
-- exists; the client signs out locally (SignOutScope.local — a global
-- sign-out would only 403 against the vanished session).

create or replace function public.delete_account()
returns void language plpgsql volatile security definer set search_path = public as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke execute on function public.delete_account() from public;
grant execute on function public.delete_account() to authenticated;
