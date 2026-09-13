/// Shared rules for daily puzzles, friend duels, and word-list generation.
library;

import 'letters.dart';

const int kWordLength = 4;
const int kMaxGuesses = 6;
const int kGameplayVersion = 2;

/// Stored answers keep display spelling, without marks or hidden characters.
bool isPlayableWord(String word) =>
    word.length == kWordLength &&
    word
        .split('')
        .every(
          (letter) =>
              kKeyboardLetters.contains(letter) ||
              kTargetOnlyLetters.contains(letter),
        );

bool isCompatibleBoard(List<String> guesses) =>
    guesses.length <= kMaxGuesses && guesses.every(isPlayableWord);

final _resultGrid = RegExp(
  '^[012]{$kWordLength}([|][012]{$kWordLength}){0,${kMaxGuesses - 1}}'
  r'$',
);

bool isCompatibleGrid(String grid) => _resultGrid.stringMatch(grid) == grid;
