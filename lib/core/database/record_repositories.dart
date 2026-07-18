import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';

/// Base data-access repository for a record table. Each record table shares the
/// same shape (a TEXT `id` primary key and a `measurement_date` used for
/// ordering), so the CRUD/pagination logic lives here once and concrete
/// repositories only declare their table, mappers and id accessor.
///
/// Repositories are [ChangeNotifier]s: a write notifies listeners so the screens
/// observing that entity refresh. Because each entity has its own repository,
/// adding a vital sign no longer rebuilds, say, the anthropometry screens.
abstract class RecordRepository<T> extends ChangeNotifier {
  String get table;
  T fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toMap(T record);
  String idOf(T record);

  RecordRepository() {
    refresh();
  }

  List<T> _items = [];
  bool _loaded = false;

  /// In-memory cache of all records (newest measurement first). Reads are
  /// synchronous; the database is queried once on creation and again only after
  /// a mutation, so widgets observing this repository don't each hit SQLite on
  /// every rebuild.
  List<T> get items => _items;

  /// Whether the initial load from the database has completed.
  bool get isLoaded => _loaded;

  Future<Database> get _db => DatabaseService.instance.database;

  /// Reloads the cache from the database and notifies listeners.
  Future<void> refresh() async {
    final db = await _db;
    final maps = await db.query(table, orderBy: 'measurement_date DESC');
    _items = maps.map(fromMap).toList();
    _loaded = true;
    notifyListeners();
  }

  /// Inserts (or replaces, by id) a record.
  Future<void> insert(T record) async {
    final db = await _db;
    await db.insert(
      table,
      toMap(record),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await refresh();
  }

  /// All records, newest measurement first.
  Future<List<T>> getAll() async {
    final db = await _db;
    final maps = await db.query(table, orderBy: 'measurement_date DESC');
    return maps.map(fromMap).toList();
  }

  /// Updates the row matching the record's id. Returns rows affected (0 if none).
  Future<int> update(T record) async {
    final db = await _db;
    final count = await db.update(
      table,
      toMap(record),
      where: 'id = ?',
      whereArgs: [idOf(record)],
    );
    await refresh();
    return count;
  }

  /// Deletes the row matching [id]. Returns rows affected (0 if none).
  Future<int> delete(String id) async {
    final db = await _db;
    final count = await db.delete(table, where: 'id = ?', whereArgs: [id]);
    await refresh();
    return count;
  }

  /// The single record matching [id], or null if none.
  Future<T?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return fromMap(maps.first);
  }

  /// One page of records, newest measurement first.
  Future<List<T>> getPaginated({int limit = 20, int offset = 0}) async {
    final db = await _db;
    final maps = await db.query(
      table,
      orderBy: 'measurement_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(fromMap).toList();
  }

  /// Total number of rows.
  Future<int> count() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Records not yet pushed to the server (`is_synced = 0`), oldest first so the
  /// server receives them in chronological order. Backs the outbound sync.
  Future<List<T>> getUnsynced() async {
    final db = await _db;
    final maps = await db.query(
      table,
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'measurement_date ASC',
    );
    return maps.map(fromMap).toList();
  }

  /// Marks the given ids as synced (`is_synced = 1`) after a successful upload,
  /// then refreshes the cache. No-op on an empty list.
  Future<void> markSynced(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(list.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE $table SET is_synced = 1 WHERE id IN ($placeholders)',
      list,
    );
    await refresh();
  }
}

class AnthropometricRepository extends RecordRepository<AnthropometricRecord> {
  AnthropometricRepository._();
  static final AnthropometricRepository instance = AnthropometricRepository._();

  @override
  String get table => 'anthropometric_records';
  @override
  AnthropometricRecord fromMap(Map<String, dynamic> map) =>
      AnthropometricRecord.fromMap(map);
  @override
  Map<String, dynamic> toMap(AnthropometricRecord record) => record.toMap();
  @override
  String idOf(AnthropometricRecord record) => record.id;
}

class VitalSignsRepository extends RecordRepository<VitalSignRecord> {
  VitalSignsRepository._();
  static final VitalSignsRepository instance = VitalSignsRepository._();

  @override
  String get table => 'vital_sign_records';
  @override
  VitalSignRecord fromMap(Map<String, dynamic> map) =>
      VitalSignRecord.fromMap(map);
  @override
  Map<String, dynamic> toMap(VitalSignRecord record) => record.toMap();
  @override
  String idOf(VitalSignRecord record) => record.id;
}

class LipidRepository extends RecordRepository<LipidRecord> {
  LipidRepository._();
  static final LipidRepository instance = LipidRepository._();

  @override
  String get table => 'lipid_records';
  @override
  LipidRecord fromMap(Map<String, dynamic> map) => LipidRecord.fromMap(map);
  @override
  Map<String, dynamic> toMap(LipidRecord record) => record.toMap();
  @override
  String idOf(LipidRecord record) => record.id;
}

class BodyCompositionRepository extends RecordRepository<BodyCompositionRecord> {
  BodyCompositionRepository._();
  static final BodyCompositionRepository instance =
      BodyCompositionRepository._();

  @override
  String get table => 'body_composition_records';
  @override
  BodyCompositionRecord fromMap(Map<String, dynamic> map) =>
      BodyCompositionRecord.fromMap(map);
  @override
  Map<String, dynamic> toMap(BodyCompositionRecord record) => record.toMap();
  @override
  String idOf(BodyCompositionRecord record) => record.id;
}
