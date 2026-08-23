import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/game/engine/keyboard_state.dart';
import 'package:kalimat/game/engine/models.dart';

const c = TileState.correct;
const p = TileState.present;
const a = TileState.absent;

void main() {
  test('states are keyed by canonical class', () {
    final s = updateKeyStates({}, ['أ', 'ة', 'ى'], [c, p, a]);
    expect(s['ا'], c); // أ stored under ا
    expect(s['ه'], p); // ة stored under ه
    expect(s['ي'], a); // ى stored under ي
    expect(s.containsKey('أ'), isFalse);
  });

  test('states only upgrade, never downgrade', () {
    var s = updateKeyStates({}, ['ب'], [p]);
    s = updateKeyStates(s, ['ب'], [a]); // absent must not overwrite present
    expect(s['ب'], p);
    s = updateKeyStates(s, ['ب'], [c]);
    expect(s['ب'], c);
    s = updateKeyStates(s, ['ب'], [p]); // present must not overwrite correct
    expect(s['ب'], c);
  });

  test('equivalence classes share hint state across spellings', () {
    var s = updateKeyStates({}, ['إ'], [c]);
    // A later أ marked absent must not downgrade the shared ا class.
    s = updateKeyStates(s, ['أ'], [a]);
    expect(s['ا'], c);
  });

  test('best state within a single row wins', () {
    final s = updateKeyStates({}, ['ب', 'ب'], [a, c]);
    expect(s['ب'], c);
  });
}
