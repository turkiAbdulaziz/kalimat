do $$
declare
  saved record;
  actual jsonb;
  duel_id uuid;
  bad_grid text;
begin
  if exists (select 1 from public.game_results)
     or exists (select 1 from public.challenges)
     or exists (select 1 from public.challenge_participants) then
    raise exception 'Old gameplay survived reset';
  end if;
  for saved in select * from test_checks.preserved loop
    case saved.name
      when 'users' then select jsonb_agg(to_jsonb(t) order by id) into actual from auth.users t;
      when 'profiles' then select jsonb_agg(to_jsonb(t) order by id) into actual from public.profiles t;
      when 'friendships' then select jsonb_agg(to_jsonb(t) order by user_a) into actual from public.friendships t;
      when 'policies' then select jsonb_agg(to_jsonb(t) order by tablename, policyname) into actual from pg_policies t where schemaname = 'public';
      when 'rpcs' then select jsonb_agg(jsonb_build_array(oid::regprocedure::text, proacl::text, pg_get_functiondef(oid)) order by oid) into actual from pg_proc where pronamespace = 'public'::regnamespace;
    end case;
    if actual is distinct from saved.data then raise exception '% changed', saved.name; end if;
  end loop;
  if exists (select 1 from pg_class where oid in ('public.daily_words'::regclass, 'public.challenge_words'::regclass, 'public.profiles'::regclass, 'public.friendships'::regclass, 'public.game_results'::regclass, 'public.challenges'::regclass, 'public.challenge_participants'::regclass) and not relrowsecurity) then
    raise exception 'RLS was disabled';
  end if;
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
  perform public.submit_result(public.riyadh_today(), true, 1, '2222', 1000);
  perform public.submit_result(public.riyadh_today() - 1, false, null, '0000|0000|0000|0000|0000|0000', 2000);
  select challenge_id into duel_id from public.create_challenge('00000000-0000-0000-0000-000000000002');
  perform public.submit_challenge_result(duel_id, true, 1, 1000, '2222');
  perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
  foreach bad_grid in array array['22222','0000|22222','', '222', '3333', '0000|0000|0000|0000|0000|0000|0000', E'2222\n'] loop
    begin
      perform public.submit_result(public.riyadh_today(), true, 1, bad_grid, 1000);
      raise exception 'Daily accepted invalid grid: %', bad_grid;
    exception when check_violation then null;
    end;
    begin
      perform public.submit_challenge_result(duel_id, true, 1, 1000, bad_grid);
      raise exception 'Duel accepted invalid grid: %', bad_grid;
    exception when check_violation then null;
    end;
  end loop;
  perform public.submit_challenge_result(duel_id, false, 6, 2000, '0000|0000|0000|0000|0000|0000');
  if (select status from public.challenges where id = duel_id) <> 'complete' then
    raise exception 'Duel RPC no longer completes games';
  end if;
  begin
    insert into public.daily_words values ('2027-09-01', 366, 'مدرسة');
    raise exception 'Accepted five-letter daily word';
  exception when check_violation then null;
  end;
  begin
    insert into public.challenge_words(word) values ('مدرسة');
    raise exception 'Accepted five-letter duel word';
  exception when check_violation then null;
  end;
  begin
    update public.challenges set word = 'مدرسة' where id = duel_id;
    raise exception 'Accepted five-letter challenge';
  exception when check_violation then null;
  end;
end $$;
select 'PASS: reset, accounts, profiles, friendships, RLS, policies, RPCs, four-cell results and six-row limits';
