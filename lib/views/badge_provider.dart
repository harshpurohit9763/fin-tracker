import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/views/badge_model.dart';
import 'package:personal_finance/views/badge_repo.dart';

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository();
});

final badgeListProvider =
    StateNotifierProvider<BadgeListNotifier, AsyncValue<List<Badge>>>((ref) {
  return BadgeListNotifier(ref.read(badgeRepositoryProvider));
});

class BadgeListNotifier extends StateNotifier<AsyncValue<List<Badge>>> {
  final BadgeRepository _repository;

  BadgeListNotifier(this._repository) : super(const AsyncValue.loading()) {
    _fetchBadges();
  }

  Future<void> _fetchBadges() async {
    state = const AsyncValue.loading();
    try {
      final badges = await _repository.getAllBadges();
      // If the provider is disposed before the future completes, do not update state.
      if (mounted) {
        state = AsyncValue.data(badges);
      }
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }

  Future<void> addBadge(Badge badge) async {
    try {
      await _repository.addBadge(badge);
      await _fetchBadges();
    } catch (e, s) {
      if (mounted) {
        state = AsyncValue.error(e, s);
      }
    }
  }
}
