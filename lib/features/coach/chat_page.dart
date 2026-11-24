import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/voice.dart';
import '../../core/widgets/mascot.dart';
import '../../state/chat.dart';
import '../../state/settings.dart';
import '../settings/settings_page.dart';
import 'message_bubble.dart';
import 'voice_sheet.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _sendText([String? preset]) {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    ref.read(chatProvider.notifier).send(text: text);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final hasKey = ref.watch(settingsProvider.select((s) => s.hasKey));
    final messages = chat.messages.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        titleSpacing: 16,
        title: Row(
          children: [
            Mascot(mood: chat.mood, size: 40, bounce: chat.thinking),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('كوتش بلال', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(
                  chat.thinking ? 'بيكتب..' : 'بيسمعك دلوقتي',
                  style: const TextStyle(fontSize: 12, color: AppColors.lime),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'سكّت الكوتش',
            icon: const Icon(Icons.volume_off_rounded),
            onPressed: CoachVoice.instance.stop,
          ),
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!hasKey)
            MaterialBanner(
              backgroundColor: AppColors.orange.withValues(alpha: 0.15),
              content: const Text('الكوتش محتاج مفتاح Gemini المجاني عشان يتكلم'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage())),
                  child: const Text('حطه دلوقتي'),
                ),
              ],
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: messages.length + (chat.thinking ? 1 : 0),
              itemBuilder: (_, i) {
                if (chat.thinking && i == 0) return const _Typing();
                final m = messages[chat.thinking ? i - 1 : i];
                return MessageBubble(key: ValueKey(m.id), message: m);
              },
            ),
          ),
          _Chips(onText: _sendText),
          _InputBar(controller: _input, onSend: _sendText),
        ],
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
          (i) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(color: AppColors.lime, shape: BoxShape.circle),
          ).animate(onPlay: (c) => c.repeat(reverse: true), delay: (i * 150).ms).fadeIn(duration: 400.ms).moveY(begin: 3, end: -3),
        ),
      ),
    ),
  );
}

class _Chips extends ConsumerWidget {
  const _Chips({required this.onText});
  final void Function(String) onText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chips = <(String, VoidCallback)>[
      ('📸 صوّر التلاجة', () => snapAndSend(context, ref, prompt: 'دي صورة التلاجة/المطبخ عندي. شوف الموجود واقترحلي أكلة سهلة جدًا منه تناسب هدفي، بسعراتها وبروتينها وتكلفتها. أنا لسه ماكلتهاش.')),
      ('🧾 صوّر المنيو', () => snapAndSend(context, ref, prompt: 'دي صورة منيو مطعم. اختارلي أحسن أوردر لهدفي وميزانيتي، وقولي أشيل إيه. أنا لسه مطلبتش.')),
      ('🍫 نفسي في حاجة', () => onText('نفسي أوي في حاجة حلوة أو أكلة وحشة دلوقتي. إيه أذكى حاجة آكلها من غير ما أبوظ يومي؟')),
      ('🏋️ صوّر الجهاز', () => snapAndSend(context, ref, prompt: 'دي صورة جهاز في الجيم. قولي اسمه وبيشتغل على إيه وإزاي أستخدمه صح، وابنيلي تمرين النهارده يكون فيه.')),
      ('🎥 شوف أدائي', () => formCheck(context, ref)),
      ('😴 كسلان النهارده', () => onText('أنا كسلان جدًا النهارده ومش هروح الجيم. اديني 10 دقايق في البيت من غير أجهزة.')),
    ];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ActionChip(
          label: Text(chips[i].$1, style: const TextStyle(fontWeight: FontWeight.w700)),
          onPressed: chips[i].$2,
          backgroundColor: AppColors.bg,
          side: const BorderSide(color: Colors.white24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
        ),
      ),
    );
  }
}

class _InputBar extends ConsumerWidget {
  const _InputBar({required this.controller, required this.onSend});
  final TextEditingController controller;
  final void Function([String?]) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
    color: AppColors.surface,
    padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'صورة',
            onPressed: () => snapAndSend(context, ref),
            icon: const Icon(Icons.photo_camera_rounded, color: AppColors.lime),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'ولا اكتب لو مش كسلان..',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(99), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => controller.text.trim().isEmpty
                ? IconButton.filled(
                    tooltip: 'سجّل فويس',
                    style: IconButton.styleFrom(backgroundColor: AppColors.orange, minimumSize: const Size(54, 54)),
                    onPressed: () => recordAndSend(context, ref),
                    icon: const Icon(Icons.mic_rounded, color: AppColors.bg, size: 28),
                  )
                : IconButton.filled(
                    tooltip: 'ابعت',
                    style: IconButton.styleFrom(backgroundColor: AppColors.lime, minimumSize: const Size(54, 54)),
                    onPressed: () => onSend(),
                    icon: const Icon(Icons.send_rounded, color: AppColors.bg),
                  ),
          ),
        ],
      ),
    ),
  );
}
