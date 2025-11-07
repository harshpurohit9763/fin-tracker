import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_expense_tracker/asset_model.dart';
import 'package:offline_expense_tracker/db_helper.dart';

class AssetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addAsset(Asset asset) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseHelper.assetsTable, asset.toMap());
  }

  Future<List<Asset>> getAllAssets() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps =
        await db.query(DatabaseHelper.assetsTable, orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Asset.fromMap(maps[i]));
  }

  Future<int> updateAsset(Asset asset) async {
    final db = await _dbHelper.database;
    return await db.update(
      DatabaseHelper.assetsTable,
      asset.toMap(),
      where: '${DatabaseHelper.colAssetId} = ?',
      whereArgs: [asset.id],
    );
  }

  Future<int> deleteAsset(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      DatabaseHelper.assetsTable,
      where: '${DatabaseHelper.colAssetId} = ?',
      whereArgs: [id],
    );
  }
}

final assetRepositoryProvider = Provider((ref) => AssetRepository());

final assetListProvider =
    StateNotifierProvider<AssetListNotifier, AsyncValue<List<Asset>>>((ref) {
  return AssetListNotifier(ref);
});

class AssetListNotifier extends StateNotifier<AsyncValue<List<Asset>>> {
  final Ref _ref;
  late final AssetRepository _repository;

  AssetListNotifier(this._ref) : super(const AsyncValue.loading()) {
    _repository = _ref.read(assetRepositoryProvider);
    _fetchAssets();
  }

  Future<void> _fetchAssets() async {
    state = const AsyncValue.loading();
    try {
      final assets = await _repository.getAllAssets();
      state = AsyncValue.data(assets);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> addAsset(Asset asset) async {
    await _repository.addAsset(asset);
    await _fetchAssets();
  }

  Future<void> updateAsset(Asset asset) async {
    await _repository.updateAsset(asset);
    await _fetchAssets();
  }

  Future<void> deleteAsset(int id) async {
    await _repository.deleteAsset(id);
    await _fetchAssets();
  }

  Future<void> deleteMultipleAssets(List<int> ids) async {
    for (var id in ids) {
      await _repository.deleteAsset(id);
    }
    await _fetchAssets();
  }
}
