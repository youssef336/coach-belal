import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/gemini/gemini_client.dart';
import '../../core/theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/mascot.dart';
import '../../state/coach_actions.dart';

/// A week of groceries at the cheapest Egyptian prices, one tap to WhatsApp.
class ShoppingPage extends ConsumerStatefulWidget {
  const ShoppingPage({super.key});

  @override
  ConsumerState<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends ConsumerState<ShoppingPage> {
  List<ShoppingItem>? _items;
  String _note = '';
  String? _error;
  final _checked = <int>{};
  bool _pricing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
      _checked.clear();
    });
    try {
      final (items, note) = await ref.read(coachActionsProvider).shoppingList();
      if (mounted) {
        setState(() {
          _items = items;
          _note = note;
        });
      }
    } on CoachError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _refreshPrices() async {
    setState(() => _pricing = true);
    try {
      await ref.read(coachActionsProvider).refreshPrices();
      if (mounted) toast(context, 'جبت أسعار النهارده من جوجل، الكوتش هيستخدمها');
      await _load();
    } on CoachError catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _pricing = false);
    }
  }

  void _share() {
    final items = _items ?? const [];
    final total = items.fold<int>(0, (s, i) => s + i.price);
    final text = [
      '🛒 لستة الأسبوع — Coach Belal',
      for (final i in items) '• ${i.name} — ${i.qty} (${i.price} ج)',
      'الإجمالي تقريبًا: $total ج',
    ].join('\n');
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final total = items?.fold<int>(0, (s, i) => s + i.price) ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('لستة السوبرماركت', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            tooltip: 'أسعار النهارده من جوجل',
            onPressed: _pricing ? null : _refreshPrices,
            icon: _pricing ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.price_change_rounded),
          ),
          if (items != null && items.isNotEmpty) IconButton(tooltip: 'شارك', onPressed: _share, icon: const Icon(Icons.share_rounded)),
        ],
      ),
      body: _error != null
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Mascot(mood: 'worried', size: 90), const SizedBox(height: 12), Text(_error!), TextButton(onPressed: _load, child: const Text('جرّب تاني'))]))
          : items == null
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Mascot(size: 90), SizedBox(height: 12), Text('الكوتش بيلف على السوبرماركت..')]))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                GlassCard(
                  color: AppColors.orange,
                  child: Row(
                    children: [
                      Expanded(child: Text(_note, style: const TextStyle(color: AppColors.bg, fontWeight: FontWeight.w700))),
                      const SizedBox(width: 10),
                      Text('$total ج', style: const TextStyle(color: AppColors.bg, fontSize: 26, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (var k = 0; k < items.length; k++)
                  CheckboxListTile(
                    value: _checked.contains(k),
                    onChanged: (v) => setState(() => v! ? _checked.add(k) : _checked.remove(k)),
                    activeColor: AppColors.lime,
                    checkColor: AppColors.bg,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${items[k].name} — ${items[k].qty}',
                      style: TextStyle(fontWeight: FontWeight.w700, decoration: _checked.contains(k) ? TextDecoration.lineThrough : null),
                    ),
                    subtitle: items[k].tip.isEmpty ? null : Text(items[k].tip, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    secondary: Text('${items[k].price} ج', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.lime)),
                  ),
                const SizedBox(height: 8),
                const Text('الأسعار تقريبية. زرار 💲 فوق بيجيب أسعار النهارده من جوجل.', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
    );
  }
}
