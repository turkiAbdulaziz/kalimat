# Four-letter vocabulary

The answer pools are manually curated source files, committed with the app:

- `assets/words/answers.txt`: 365 daily answers, in puzzle order.
- `tool/curated/duel_answers.txt`: 200 separate friend-duel answers.
- `tool/curated/guess_additions.txt`: reviewed dictionary additions, including familiar words absent from the frequency source.

Choose familiar standard Arabic nouns, adjectives and common verbs. Keep correct display spelling (for example `إوزة`, `شاطئ`, `مأوى`). Do not add proper names, dialect-only vocabulary, insults, spelling errors, obscure words, or short words padded to four letters with an article or attached pronoun. Ordinary plurals and common verb conjugations are allowed. A common noun or adjective that can also be a person's name is judged by its ordinary meaning (`جميل`, `وردة`, `كريم`). Avoid articles and attached pronouns as answer padding; the broader guess dictionary may accept such grammatical forms.

Answers contain exactly four allowed letters, without marks or invisible characters. Matching remains lenient: أ/إ/آ→ا, ة→ه, ى→ي, ؤ→و, ئ→ي. Normalized duplicates are prohibited within and across answer pools. These rules and the generator use the same pure-Dart rules and normalization as the app.

The wider accepted-guess dictionary uses the local FrequencyWords Arabic 50k subtitle-frequency source (MIT), filtered to four allowed letters, plus reviewed additions. Subtitle frequency is a source for guesses, not automatic answer selection. The previous five-letter Wordle source and morphological word generator are not used.

Source: https://github.com/hermitdave/FrequencyWords/blob/master/content/2018/ar/ar_50k.txt

Local input: `tool/raw/freq_ar_50k.txt` (git-ignored). SHA-256:
`bbe98b4b92902b392bdefa2e555a108fdb42a5dd79d261674be5ab666229e19f`.
Keep this input unchanged for reproducibility; verify the hash when downloading it on a fresh checkout. The app only needs the committed generated dictionary.

Run from the repository root:

```sh
dart run tool/build_wordlists.dart
dart run tool/build_wordlists.dart --check
```

The generator never creates or selects answer lists. It requires exactly 365 and 200 curated answers and validates the complete input before writing any output. It emits a sorted normalized dictionary and deterministic SQL seeds; `--check` makes no writes and fails if a committed output differs. The current dictionary contains 7,918 guesses. All 565 answers pass dictionary membership and normalized uniqueness checks.

Puzzle 1 remains September 1, 2026. Daily ordering matches the bundled list through August 31, 2027. After that, bundled answers cycle while the online RPC returns no unseeded date, so the client falls back to the bundle until the next schedule is seeded. Do not reorder a live schedule without an intentional migration.
