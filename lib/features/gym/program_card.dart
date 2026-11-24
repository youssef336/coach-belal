import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/gemini/gemini_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/program.dart';

/// Your current training block: which week, which phase, and why.
class ProgramCard extends ConsumerWidget {
  const ProgramCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(programProvider);
    final reason = ref.read(programProvider.notifier).changeReason();

    if (p == null) {
      return GlassCard(
        onTap: () => showNewProgramSheet(context, ref),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: AppColors.lime),
            SizedBox(width: 12),
            Expanded(child: Text('الكوتش يحلل جسمك ويبنيلك برنامج كامل', style: TextStyle(fontWeight: FontWeight.w800))),
            Icon(Icons.chevron_left_rounded, color: AppColors.muted),
          ],
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
              Text('أسبوع ${p.week.clamp(1, p.weeks)} من ${p.weeks}', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var w = 1; w <= p.weeks; w++)
                Expanded(
                  child: Container(
                    height: 8,
                    margin: const EdgeInsetsDirectional.only(end: 4),
                    decoration: BoxDecoration(
                      color: w < p.week ? AppColors.lime : (w == p.week ? (p.deload ? AppColors.sky : AppColors.orange) : Colors.white12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(p.phase, style: TextStyle(color: p.deload ? AppColors.sky : AppColors.orange, fontWeight: FontWeight.w800)),
          if (p.why.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(p.why, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.6))),
          if (reason != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.lime.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(child: Text('$reason — وقت برنامج جديد', style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700))),
                  TextButton(onPressed: () => showNewProgramSheet(context, ref), child: const Text('غيّره')),
                ],
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(onPressed: () => showNewProgramSheet(context, ref), child: const Text('الكوتش يغيّره')),
            ),
        ],
      ),
    );
  }
}

const _focusChips = ['صدر أكبر', 'دراع', 'كتف عريض', 'ضهر V', 'رجل', 'بطن', 'قوة', 'لياقة وحرق'];

Future<void> showNewProgramSheet(BuildContext context, WidgetRef ref) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
  builder: (_) => const _NewProgramSheet(),
);

class _NewProgramSheet extends ConsumerStatefulWidget {
  const _NewProgramSheet();

  @override
  ConsumerState<_NewProgramSheet> createState() => _NewProgramSheetState();
}

class _NewProgramSheetState extends ConsumerState<_NewProgramSheet> {
  final _picked = <String>{};
  bool _busy = false;
  bool _wishes = false;
  Uint8List? _photo;
  String _mime = 'image/jpeg';

  Future<void> _snap() async {
    final f = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 75);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    setState(() {
      _photo = bytes;
      _mime = f.mimeType ?? 'image/jpeg';
    });
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      final p = await ref.read(programProvider.notifier).generate(focus: _picked.join('، '), bodyPhoto: _photo, photoMime: _mime);
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'برنامج جديد: ${p.title} (${p.weeks} أسابيع)');
      }
    } on CoachError catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الكوتش يقرر', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text(
            'هيشوف طولك ووزنك وهدفك، وكل عضلة اتمرنت قد إيه، والأرقام اللي وقفت، ويبنيلك البرنامج اللي جسمك محتاجه — بتمارين جديدة عشان جسمك ميتعودش.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _busy ? null : _snap,
            icon: Icon(_photo == null ? Icons.accessibility_new_rounded : Icons.check_circle_rounded, color: AppColors.lime),
            label: Text(_photo == null ? 'صوّر جسمك عشان يشوفك (اختياري)' : 'الكوتش هيشوف صورتك ✓'),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('الصورة بتروح للكوتش بس ومبتتحفظش', style: TextStyle(color: AppColors.muted, fontSize: 11)),
          ),
          if (!_wishes)
            TextButton(onPressed: () => setState(() => _wishes = true), child: const Text('عندي طلب معين؟'))
          else ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _focusChips)
                  FilterChip(
                    label: Text(c),
                    selected: _picked.contains(c),
                    onSelected: (v) => setState(() => v ? _picked.add(c) : _picked.remove(c)),
                    selectedColor: AppColors.lime,
                    checkmarkColor: AppColors.bg,
                    labelStyle: TextStyle(color: _picked.contains(c) ? AppColors.bg : AppColors.text, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _go,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: Text(_busy ? 'الكوتش بيحلل جسمك..' : 'يلا يا كوتش'),
          ),
        ],
      ),
    ),
  );
}
