import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/storage.dart';
import '../models/profile.dart';

class ProfileNotifier extends Notifier<Profile?> {
  @override
  Profile? build() {
    final raw = Storage.readMap('profile', 'main');
    return raw == null ? null : Profile.fromJson(raw);
  }

  Future<void> save(Profile p) async {
    state = p;
    await Storage.writeMap('profile', 'main', p.toJson());
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile?>(ProfileNotifier.new);

class WeightEntry {
  const WeightEntry(this.day, this.kg);
  final String day;
  final double kg;
}

class WeightsNotifier extends Notifier<List<WeightEntry>> {
  @override
  List<WeightEntry> build() {
    final all = Storage.readAll('weights').map((j) => WeightEntry(j['day'] as String, (j['kg'] as num).toDouble())).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return all;
  }

  /// One weigh-in per day; the latest wins. Also updates the profile weight.
  Future<void> log(double kg) async {
    final day = dayKey(DateTime.now());
    await Storage.writeMap('weights', day, {'day': day, 'kg': kg});
    state = [...state.where((w) => w.day != day), WeightEntry(day, kg)]..sort((a, b) => a.day.compareTo(b.day));
    final p = ref.read(profileProvider);
    if (p != null) await ref.read(profileProvider.notifier).save(p.copyWith(weightKg: kg));
  }
}

final weightsProvider = NotifierProvider<WeightsNotifier, List<WeightEntry>>(WeightsNotifier.new);
