import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/workout.dart';

/// Opens short YouTube videos that show the exercise's correct form.
class HowToVideoButton extends StatelessWidget {
  const HowToVideoButton({super.key, required this.exercise});
  final Exercise exercise;

  Future<void> _open(BuildContext context) async {
    final name = exercise.name.replaceAll(RegExp(r'\s*\(.*\)'), '');
    final uri = Uri.https('www.youtube.com', '/results', {'search_query': '$name proper form shorts', 'sp': 'EgIYAQ=='});
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) toast(context, 'مقدرتش أفتح يوتيوب');
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.danger.withValues(alpha: 0.16),
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: () => _open(context),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF4D4D), size: 20),
            SizedBox(width: 6),
            Text('فيديو الشرح', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    ),
  );
}
