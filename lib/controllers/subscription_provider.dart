import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_finance/db/db_helper.dart';
import 'package:personal_finance/models/subscription_model.dart';

class SubscriptionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addSubscription(Subscription sub) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.subscriptionsTable, sub.toMap());
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.subscriptionsTable,
        orderBy: '${DatabaseHelper.colSubNextDueDate} ASC');
    return List.generate(maps.length, (i) => Subscription.fromMap(maps[i]));
  }

  Future<int> updateSubscription(Subscription sub) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.subscriptionsTable,
      sub.toMap(),
      where: '${DatabaseHelper.colSubId} = ?',
      whereArgs: [sub.id],
    );
  }

  Future<int> deleteSubscription(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.subscriptionsTable,
      where: '${DatabaseHelper.colSubId} = ?',
      whereArgs: [id],
    );
  }
}

final subscriptionRepositoryProvider =
    Provider((ref) => SubscriptionRepository());

final subscriptionListProvider = StateNotifierProvider<SubscriptionListNotifier,
    AsyncValue<List<Subscription>>>((ref) {
  return SubscriptionListNotifier(ref);
});

class SubscriptionListNotifier
    extends StateNotifier<AsyncValue<List<Subscription>>> {
  final Ref _ref;
  late final SubscriptionRepository _repository;

  SubscriptionListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(subscriptionRepositoryProvider);
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    state = const AsyncValue.loading();
    try {
      final subs = await _repository.getAllSubscriptions();
      state = AsyncValue.data(subs);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addSubscription(Subscription sub) async {
    await _repository.addSubscription(sub);
    await _fetchSubscriptions();
  }

  Future<void> updateSubscription(Subscription sub) async {
    await _repository.updateSubscription(sub);
    await _fetchSubscriptions();
  }

  Future<void> deleteSubscription(int id) async {
    await _repository.deleteSubscription(id);
    await _fetchSubscriptions();
  }
}
