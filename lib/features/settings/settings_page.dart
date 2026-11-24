import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/gemini/gemini_client.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/settings.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final _key = TextEditingController(text: ref.read(settingsProvider).apiKey);
  late final _model = TextEditingController(text: ref.read(settingsProvider).model);
  bool _testing = false;

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    final s = ref.read(settingsProvider).copyWith(apiKey: _key.text.trim(), model: _model.text.trim().isEmpty ? Settings.defaultModel : _model.text.trim());
    await ref.read(settingsProvider.notifier).update(s);
    setState(() => _testing = true);
    try {
      final r = await GeminiClient(apiKey: s.apiKey, model: s.model).text(
        system: 'رد بكلمة واحدة بالمصري.',
        turns: const [
          GeminiTurn('user', [GeminiPart.text('قول أهلًا')]),
        ],
      );
      if (mounted) toast(context, 'شغال ✓ الكوتش بيقول: ${r.trim()}');
    } on CoachError catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('استرجاع نسخة'),
        content: TextField(controller: ctrl, maxLines: 6, decoration: const InputDecoration(hintText: 'الزق محتوى ملف النسخة هنا')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('استرجع')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Storage.importAll(ctrl.text);
      if (mounted) toast(context, 'رجعت كل حاجة — اقفل التطبيق وافتحه');
    } catch (_) {
      if (mounted) toast(context, 'ده مش ملف نسخة من Coach Belal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('مفتاح Gemini (مجاني)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                  '1. افتح aistudio.google.com/apikey\n2. Create API key\n3. انسخه والزقه هنا\nالمفتاح بيفضل على تلفونك بس.',
                  style: TextStyle(color: AppColors.muted, height: 1.7),
                ),
                const SizedBox(height: 10),
                TextField(controller: _key, obscureText: true, decoration: const InputDecoration(hintText: 'AIza...')),
                const SizedBox(height: 8),
                TextField(controller: _model, decoration: const InputDecoration(labelText: 'الموديل', helperText: 'سيبه زي ما هو لو مش فاهم')),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton(onPressed: _testing ? null : _saveAndTest, child: Text(_testing ? 'بجرّب..' : 'احفظ وجرّب'))),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'الزق',
                      onPressed: () async {
                        final c = await Clipboard.getData('text/plain');
                        if (c?.text != null) _key.text = c!.text!.trim();
                      },
                      icon: const Icon(Icons.content_paste_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: s.voiceReplies,
            onChanged: (v) => n.update(s.copyWith(voiceReplies: v)),
            title: const Text('الكوتش يرد بصوته'),
            activeThumbColor: AppColors.lime,
          ),
          SwitchListTile(
            value: s.ramadan,
            onChanged: (v) => n.update(s.copyWith(ramadan: v)),
            title: const Text('وضع رمضان 🌙'),
            subtitle: const Text('فطار وسحور، وتمرين قبل الفطار أو بعد التراويح'),
            activeThumbColor: AppColors.lime,
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded, color: AppColors.lime),
            title: const Text('نسخة احتياطية'),
            subtitle: const Text('ابعتها لنفسك على واتساب أو درايف'),
            onTap: () => SharePlus.instance.share(
              ShareParams(
                files: [XFile.fromData(utf8.encode(Storage.exportAll()), mimeType: 'application/json', name: 'coach_belal_backup.json')],
              ),
            ),
          ),
          ListTile(leading: const Icon(Icons.restore_rounded, color: AppColors.lime), title: const Text('استرجاع نسخة'), onTap: _import),
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            title: const Text('امسح كل حاجة وابدأ من الأول'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('متأكد؟'),
                  content: const Text('كل الأكل والتمارين والوزن هيتمسحوا.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('لأ')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('امسح')),
                  ],
                ),
              );
              if (ok == true) {
                await Storage.wipe();
                if (context.mounted) toast(context, 'اتمسح. اقفل التطبيق وافتحه');
              }
            },
          ),
        ],
      ),
    );
  }
}
