-- RLS policies. All writes to game_results go through RPCs (0003);
-- daily_words has no policies at all (unreadable by clients).

create policy "profiles read"       on public.profiles for select to authenticated using (true);
create policy "profiles insert own" on public.profiles for insert to authenticated with check (id = auth.uid());
create policy "profiles update own" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

create policy "results read own" on public.game_results for select to authenticated
  using (user_id = auth.uid());
-- No insert/update/delete policies on game_results: submit_result() only.
