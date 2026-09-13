-- One-time reset of TEST gameplay for the four-letter client.
-- Apply with both regenerated seeds in ONE transaction (tool/deploy_four_letter.sh).
-- Accounts, profiles, friend codes, friendships, policies, grants and RPCs survive.
-- Historical migrations intentionally retain the previous game's rules.

lock table public.game_results, public.challenge_participants,
  public.challenges, public.daily_words, public.challenge_words
  in access exclusive mode;

-- Prevent an accidental manual replay from clearing new four-letter games.
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conrelid = 'public.daily_words'::regclass
      and conname = 'daily_words_four_letters'
  ) then
    raise exception 'Four-letter reset already applied; do not replay it';
  end if;
end $$;

delete from public.game_results;
delete from public.challenge_participants;
delete from public.challenges;
delete from public.daily_words;
delete from public.challenge_words;

alter table public.daily_words
  drop constraint daily_words_word_check,
  add constraint daily_words_four_letters check (char_length(word) = 4);
alter table public.challenge_words
  drop constraint challenge_words_word_check,
  add constraint challenge_words_four_letters check (char_length(word) = 4);
alter table public.challenges
  drop constraint challenges_word_check,
  add constraint challenges_four_letters check (char_length(word) = 4);
alter table public.game_results
  drop constraint game_results_grid_check,
  add constraint game_results_four_cell_grid
    check (grid ~ '^[012]{4}([|][012]{4}){0,5}$' and grid !~ E'[\\n\\r]');
alter table public.challenge_participants
  drop constraint challenge_participants_grid_check,
  add constraint challenge_participants_four_cell_grid
    check (grid ~ '^[012]{4}([|][012]{4}){0,5}$' and grid !~ E'[\\n\\r]');
