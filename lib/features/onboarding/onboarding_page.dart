import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/widgets/mascot.dart';
import '../../models/profile.dart';
import '../../state/profile.dart';
import 'big_slider.dart';
import 'choice_grid.dart';

/// 60 seconds, sliders and taps only — no typing except your name.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  final _name = TextEditingController(text: 'يوسف');
  int _step = 0;
  double _height = 175, _weight = 75, _age = 27, _target = 80, _budget = 4000, _gymDays = 4;
  bool _male = true;
  Goal _goal = Goal.bulk;
  Activity _activity = Activity.light;

  static const _steps = 5;

  void _next() {
    if (_step == _steps - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    await ref.read(profileProvider.notifier).save(
      Profile(
        name: _name.text.trim().isEmpty ? 'بطل' : _name.text.trim(),
        heightCm: _height,
        weightKg: _weight,
        age: _age.round(),
        male: _male,
        activity: _activity,
        goal: _goal,
        targetKg: _target,
        monthlyBudget: _budget.round(),
        gymDays: _gymDays.round(),
      ),
    );
    await ref.read(weightsProvider.notifier).log(_weight);
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['أهلًا يا بطل', 'جسمك', 'عايز توصل لفين؟', 'يومك', 'الفلوس والجيم'];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  _steps,
                  (i) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 6,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      decoration: BoxDecoration(
                        color: i <= _step ? AppColors.lime : Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Mascot(mood: _step == _steps - 1 ? 'proud' : 'happy', size: 64),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(titles[_step], style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))
                        .animate(key: ValueKey(_step))
                        .fadeIn()
                        .slideX(begin: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: _pages,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_hello(), _body(), _goalStep(), _day(), _money()],
                ),
              ),
              FilledButton(
                onPressed: _next,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                child: Text(_step == _steps - 1 ? 'يلا نبدأ' : 'التالي'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hello() => ListView(
    children: [
      const Text(
        'أنا كوتش بلال. هخلّيك تاكل صح وتتمرن صح من غير ما تكتب ولا تحسب حاجة.\nبس جاوبني على كام سؤال بالسحب.',
        style: TextStyle(fontSize: 17, color: AppColors.muted, height: 1.7),
      ),
      const SizedBox(height: 24),
      TextField(
        controller: _name,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        decoration: const InputDecoration(labelText: 'اسمك'),
      ),
      const SizedBox(height: 16),
      ChoiceGrid<bool>(
        values: const [true, false],
        selected: _male,
        label: (v) => v ? 'راجل' : 'ست',
        onPick: (v) => setState(() => _male = v),
      ),
    ],
  );

  Widget _body() => ListView(
    children: [
      BigSlider(label: 'الطول', unit: 'سم', value: _height, min: 140, max: 210, onChanged: (v) => setState(() => _height = v)),
      BigSlider(label: 'الوزن', unit: 'كيلو', value: _weight, min: 40, max: 160, step: 0.5, onChanged: (v) => setState(() => _weight = v)),
      BigSlider(label: 'السن', unit: 'سنة', value: _age, min: 14, max: 70, onChanged: (v) => setState(() => _age = v)),
    ],
  );

  Widget _goalStep() => ListView(
    children: [
      ChoiceGrid<Goal>(
        values: Goal.values,
        selected: _goal,
        label: (g) => g.label,
        sub: (g) => g.hint,
        onPick: (g) => setState(() => _goal = g),
      ),
      const SizedBox(height: 16),
      BigSlider(label: 'الوزن اللي عايزه', unit: 'كيلو', value: _target, min: 40, max: 160, step: 0.5, onChanged: (v) => setState(() => _target = v)),
    ],
  );

  Widget _day() => ListView(
    children: [
      ChoiceGrid<Activity>(
        values: Activity.values,
        selected: _activity,
        label: (a) => a.label,
        onPick: (a) => setState(() => _activity = a),
      ),
    ],
  );

  Widget _money() => ListView(
    children: [
      BigSlider(label: 'ميزانية الأكل في الشهر', unit: 'جنيه', value: _budget, min: 1500, max: 20000, step: 250, onChanged: (v) => setState(() => _budget = v)),
      BigSlider(label: 'أيام الجيم في الأسبوع', unit: 'أيام', value: _gymDays, min: 1, max: 7, onChanged: (v) => setState(() => _gymDays = v)),
    ],
  );
}
