do $$
begin
  if (select count(*) from public.daily_words) <> 365
      or (select count(*) from public.challenge_words) <> 200 then
    raise exception 'Unexpected answer pool size';
  end if;
  if exists (select 1 from public.daily_words
      where word_date <> date '2026-09-01' + (puzzle_no - 1)) then
    raise exception 'Daily dates do not match puzzle numbering';
  end if;
  if (select count(distinct translate(word, 'أإآةىؤئ', 'اااهيوي'))
      from (select word from public.daily_words union all
            select word from public.challenge_words) words) <> 565 then
    raise exception 'Normalized answer pools overlap';
  end if;
end $$;
