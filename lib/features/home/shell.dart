import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/glass_card.dart';
import '../../state/coach_actions.dart';
import '../coach/chat_page.dart';
import '../food/food_page.dart';
import '../gym/gym_page.dart';
import '../progress/progress_page.dart';
import 'home_page.dart';

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
}

abstract final class Tabs {
  static const home = 0, coach = 1, food = 2, gym = 3, progress = 4;
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  @override
  void initState() {
    super.initState();
    // Once a week the coach looks at the scale and adjusts your calories.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final why = await ref.read(coachActionsProvider).weeklyAdjust();
      if (why != null && mounted) toast(context, 'الكوتش: $why');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [HomePage(), ChatPage(), FoodPage(), GymPage(), ProgressPage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(tabProvider.notifier).go,
        height: 68,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.mic_rounded), label: 'الكوتش'),
          NavigationDestination(icon: Icon(Icons.restaurant_rounded), label: 'الأكل'),
          NavigationDestination(icon: Icon(Icons.fitness_center_rounded), label: 'الجيم'),
          NavigationDestination(icon: Icon(Icons.local_fire_department_rounded), label: 'التقدم'),
        ],
      ),
    );
  }
}
