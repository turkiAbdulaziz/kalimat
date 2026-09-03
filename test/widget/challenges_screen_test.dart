/// «التحدّيات»: the duel list's three groups and its empty state, the friends
/// tab's code card and empty state, and the ٦-digit code field.
///
/// Everything is fed by overridden providers — the repositories are never
/// constructed, so the suite stays offline/unconfigured.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalimat/backend/backend_providers.dart';
import 'package:kalimat/challenge/challenges_screen.dart';
import 'package:kalimat/challenge/models.dart';
import 'package:kalimat/core/strings.dart';
import 'package:kalimat/core/theme/kalimat_theme.dart';
import 'package:kalimat/core/theme/motion_scope.dart';
import 'package:kalimat/core/utils/arabic_digits.dart';
import 'package:kalimat/game/data/local_store.dart';
import 'package:kalimat/game/state/settings_controller.dart';
import 'package:kalimat/game/widgets/code_field.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _myId = 'me';

ChallengeSummary _duel({
  required String id,
  required String name,
  required ChallengeStatus status,
  String? winnerId,
  ChallengeSide mine = const ChallengeSide(),
  ChallengeSide theirs = const ChallengeSide(),
}) => ChallengeSummary(
  id: id,
  opponentId: 'them-$id',
  opponentName: name,
  status: status,
  winnerId: winnerId,
  mine: mine,
  theirs: theirs,
);

Future<Widget> _screen(
  WidgetTester tester, {
  List<ChallengeSummary> challenges = const [],
  List<Friend> friends = const [],
  List<FriendRequest> requests = const [],
  MyPlayerCard? card,
  int initialTab = 0,
}) async {
  // Motion off keeps the empty state's sample-row flip (Future.delayed
  // staggers) out of the pump timeline — same trick as sign_in_screen_test.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.withData({
        'settings': '{"dark":false,"hints":true,"motion":false}',
      });
  final store = (await tester.runAsync(LocalStore.create))!;
  return ProviderScope(
    overrides: [
      localStoreProvider.overrideWithValue(store),
      currentUserIdProvider.overrideWithValue(_myId),
      myChallengesProvider.overrideWith((ref) async => challenges),
      friendsProvider.overrideWith((ref) async => friends),
      friendRequestsProvider.overrideWith((ref) async => requests),
      myPlayerCardProvider.overrideWith((ref) async => card),
    ],
    child: MaterialApp(
      theme: kalimatTheme(Brightness.light),
      builder: (context, child) => MotionScope(enabled: false, child: child!),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: ChallengesScreen(initialTab: initialTab),
      ),
    ),
  );
}

void main() {
  testWidgets('no duels yet shows the invitation, not empty sections', (
    tester,
  ) async {
    await tester.pumpWidget(await _screen(tester));
    await tester.pumpAndSettle();

    expect(find.text(S.challengeFriend), findsOneWidget);
    expect(find.text(S.noChallengesHint), findsOneWidget);
    for (final section in [S.yourTurn, S.waitingOpponent, S.challengeDone]) {
      expect(find.text(section), findsNothing);
    }
  });

  testWidgets('duels are grouped by whose move it is', (tester) async {
    await tester.pumpWidget(
      await _screen(
        tester,
        challenges: [
          // Their move is done, mine isn't: my turn, and their score is the
          // target shown under their name.
          _duel(
            id: 'a',
            name: 'ليلى',
            status: ChallengeStatus.active,
            theirs: const ChallengeSide(
              finished: true,
              won: true,
              guesses: 3,
            ),
          ),
          _duel(
            id: 'b',
            name: 'محمد',
            status: ChallengeStatus.active,
            mine: const ChallengeSide(finished: true, won: true, guesses: 4),
          ),
          _duel(
            id: 'c',
            name: 'نورة',
            status: ChallengeStatus.complete,
            winnerId: _myId,
            mine: const ChallengeSide(finished: true, won: true, guesses: 2),
            theirs: const ChallengeSide(finished: true, won: true, guesses: 5),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(S.yourTurn), findsOneWidget); // section label only
    expect(find.text(S.waitingOpponent), findsOneWidget);
    expect(find.text(S.challengeDone), findsOneWidget);

    expect(find.text('ليلى: ٣/٦'), findsOneWidget); // the score to beat
    expect(find.text('٤/٦'), findsOneWidget); // my score, still waiting
    expect(find.text(S.challengeWon), findsOneWidget); // server verdict
    expect(find.text('٢/٦ · ٥/٦'), findsOneWidget);
  });

  testWidgets('a lost duel reads as خسرت for the loser', (tester) async {
    await tester.pumpWidget(
      await _screen(
        tester,
        challenges: [
          _duel(
            id: 'd',
            name: 'ليلى',
            status: ChallengeStatus.complete,
            winnerId: 'them-d',
            mine: const ChallengeSide(finished: true, won: true, guesses: 5),
            theirs: const ChallengeSide(finished: true, won: true, guesses: 3),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(S.challengeLost), findsOneWidget);
    expect(find.text('٥/٦ · ٣/٦'), findsOneWidget);
  });

  testWidgets('friends tab shows my code in Arabic-Indic tiles', (
    tester,
  ) async {
    await tester.pumpWidget(
      await _screen(
        tester,
        initialTab: 1,
        card: const MyPlayerCard(friendCode: '482917', wins: 7, losses: 3),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CodeDisplay), findsOneWidget);
    for (final d in toArabicDigits('482917').split('')) {
      expect(find.text(d), findsWidgets);
    }
    expect(find.text(S.noFriends), findsOneWidget);
    expect(find.text(S.addFriend), findsOneWidget);
    expect(find.text(S.requests), findsNothing); // no pending requests
  });

  testWidgets('a pending request offers قبول / رفض', (tester) async {
    await tester.pumpWidget(
      await _screen(
        tester,
        initialTab: 1,
        card: const MyPlayerCard(friendCode: '482917'),
        requests: const [FriendRequest(id: 'u9', displayName: 'سارة')],
        friends: const [
          Friend(
            id: 'u8',
            displayName: 'ليلى',
            friendCode: '112233',
            wins: 7,
            losses: 3,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('${S.requests} ١'), findsOneWidget);
    expect(find.text('سارة'), findsOneWidget);
    expect(find.text(S.accept), findsOneWidget);
    expect(find.text(S.decline), findsOneWidget);

    expect(find.text('ليلى'), findsOneWidget);
    expect(find.text('٧ ${S.winsLabel} · ٣ ${S.lossesLabel}'), findsOneWidget);
    expect(find.text(S.challengeAction), findsOneWidget);
  });

  testWidgets('the code field takes Arabic-Indic input as ASCII digits', (
    tester,
  ) async {
    var typed = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: kalimatTheme(Brightness.light),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: CodeField(autofocus: false, onChanged: (v) => typed = v),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '٤٨٢٩١٧');
    await tester.pump();

    expect(typed, '482917');
    expect(find.text('٤'), findsOneWidget);
    expect(find.text('٧'), findsOneWidget);
  });
}
