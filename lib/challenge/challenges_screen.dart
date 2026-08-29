/// «التحدّيات» — duels on one tab, the friend graph on the other. Pushed from
/// the header's swords icon with the house rise route, and built from the same
/// chrome as «حسابي» (ScreenHeader + SectionCard) so it introduces no new
/// visual vocabulary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/strings.dart';
import '../core/theme/kalimat_colors.dart';
import '../core/theme/metrics.dart';
import '../game/widgets/screen_header.dart';
import '../game/widgets/segment_toggle.dart';
import 'challenges_tab.dart';
import 'friends_tab.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key, this.initialTab = 0});

  /// 0 = duels, 1 = friends. Opening «تحدَّ صديقًا» with no friends yet sends
  /// the player straight to the friends tab.
  final int initialTab;

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final c = context.kalimatColors;
    return Scaffold(
      backgroundColor: c.surfacePage,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Metrics.appMaxWidth),
            child: Column(
              children: [
                ScreenHeader(
                  title: S.challenges,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: Metrics.s4),
                  child: SegmentToggle(
                    options: const [S.myChallenges, S.friends],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Metrics.gutter,
                      vertical: Metrics.s5,
                    ),
                    child: _tab == 0
                        ? ChallengesTab(onGoToFriends: () => _goTo(1))
                        : const FriendsTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goTo(int tab) => setState(() => _tab = tab);
}
