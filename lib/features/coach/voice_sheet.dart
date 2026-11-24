import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../core/voice.dart';
import '../../core/widgets/glass_card.dart';
import '../../models/chat_message.dart';
import '../../state/chat.dart';
import '../home/shell.dart';

/// Hold-free voice note: tap to start, tap to send. Then jump to the chat.
Future<void> recordAndSend(BuildContext context, WidgetRef ref) async {
  final bytes = await showModalBottomSheet<Uint8List>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => const _VoiceSheet(),
  );
  if (bytes == null || bytes.length < 8000) return; // under ~0.25 s: an accidental tap
  ref.read(tabProvider.notifier).go(Tabs.coach);
  await ref.read(chatProvider.notifier).send(media: bytes, mimeType: 'audio/wav', kind: ChatKind.voice);
}

/// Camera (or gallery) → the coach. [prompt] sets what the coach should do with it.
Future<void> snapAndSend(BuildContext context, WidgetRef ref, {String prompt = '', bool gallery = false}) async {
  final file = await ImagePicker().pickImage(
    source: gallery ? ImageSource.gallery : ImageSource.camera,
    maxWidth: 1280,
    imageQuality: 80,
  );
  if (file == null) return;
  final bytes = await file.readAsBytes();
  ref.read(tabProvider.notifier).go(Tabs.coach);
  await ref.read(chatProvider.notifier).send(text: prompt, media: bytes, mimeType: file.mimeType ?? 'image/jpeg', kind: ChatKind.image);
}

/// Form check: a 10-15 s clip of one set.
Future<void> formCheck(BuildContext context, WidgetRef ref) async {
  final file = await ImagePicker().pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 15));
  if (file == null) return;
  final bytes = await file.readAsBytes();
  if (bytes.length > 18 * 1024 * 1024) {
    if (context.mounted) toast(context, 'الفيديو كبير، صوّر 10 ثواني بس');
    return;
  }
  ref.read(tabProvider.notifier).go(Tabs.coach);
  await ref.read(chatProvider.notifier).send(
    text: 'ده فيديو لسِت بعمله. اعرف التمرين، وقولي غلطات الأداء (الضهر، الركبة، المدى، السرعة) وإزاي أصلحها، وهل الوزن مناسب.',
    media: bytes,
    mimeType: file.mimeType ?? 'video/mp4',
    kind: ChatKind.video,
  );
}

class _VoiceSheet extends StatefulWidget {
  const _VoiceSheet();

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  final _rec = VoiceRecorder();
  bool _on = false;
  int _secs = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final ok = await _rec.start();
    if (!mounted) return;
    if (!ok) {
      toast(context, 'محتاج إذن المايك');
      Navigator.pop(context);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _on = true);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secs++);
      if (_secs >= 60) _send();
    });
  }

  Future<void> _send() async {
    _t?.cancel();
    final bytes = await _rec.stop();
    HapticFeedback.lightImpact();
    if (mounted) Navigator.pop(context, bytes);
  }

  @override
  void dispose() {
    _t?.cancel();
    if (_on) _rec.cancel();
    _rec.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_on ? 'بسمعك.. قول أكلت إيه أو عايز إيه' : 'بجهز المايك..', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('0:${_secs.toString().padLeft(2, '0')}', style: const TextStyle(color: AppColors.muted, fontSize: 15)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _on ? _send : null,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, size: 48, color: AppColors.bg),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.08, duration: 700.ms),
          ),
          const SizedBox(height: 14),
          const Text('دوس عشان تبعت', style: TextStyle(color: AppColors.muted)),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: AppColors.muted))),
        ],
      ),
    ),
  );
}
