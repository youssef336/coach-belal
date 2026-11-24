import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/storage.dart';
import 'core/theme.dart';
import 'features/home/shell.dart';
import 'features/onboarding/onboarding_page.dart';
import 'state/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  // No back / home bar inside the app: keep the status bar, hide the nav bar.
  // A swipe from the bottom shows it for a moment, then it hides again.
  await hideNavBar();
  SystemChrome.setSystemUIChangeCallback((visible) async {
    if (visible) {
      await Future<void>.delayed(const Duration(seconds: 3));
      await hideNavBar();
    }
  });
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: CoachBelalApp()));
}

Future<void> hideNavBar() => SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [SystemUiOverlay.top]);

class CoachBelalApp extends ConsumerWidget {
  const CoachBelalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProfile = ref.watch(profileProvider.select((p) => p != null));
    return MaterialApp(
      title: 'Coach Belal',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: hasProfile ? const Shell() : const OnboardingPage(),
    );
  }
}
