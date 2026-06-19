import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

/// Owns the SQLite database lifecycle only: opening the connection and creating
/// the schema/indexes. All CRUD lives in the per-entity repositories
/// (see record_repositories.dart), which use [database].
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my-vitals-db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const integerType = 'INTEGER';
    const realType = 'REAL';

    await db.execute('''
CREATE TABLE anthropometric_records (
  id $idType,
  measurement_date $textType NOT NULL,
  weight $realType NOT NULL,
  height $realType NOT NULL,
  bmi $realType NOT NULL,
  comment $textType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE vital_sign_records (
  id $idType,
  measurement_date $textType NOT NULL,
  systolic $integerType NOT NULL,
  diastolic $integerType NOT NULL,
  heart_rate $integerType NOT NULL,
  activity_state $textType,
  symptom $textType,
  comment $textType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE lipid_records (
  id $idType,
  measurement_date $textType NOT NULL,
  total_cholesterol $realType,
  ldl $realType,
  hdl $realType,
  vldl $realType,
  triglycerides $realType,
  lab_name $textType,
  comment $textType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE body_composition_records (
  id $idType,
  measurement_date $textType NOT NULL,
  body_fat_percent $realType,
  muscle_mass_kg $realType,
  visceral_fat_level $integerType,
  metabolic_age $integerType,
  bmr_kcal $integerType,
  body_water_percent $realType,
  bone_mass_kg $realType,
  device_name $textType,
  comment $textType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await _createIndexes(db);
  }

  /// Creates indexes on `measurement_date` for all record tables. Every query
  /// orders by this column descending, so these indexes back those reads as the
  /// dataset grows.
  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_anthro_date ON anthropometric_records(measurement_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_vitals_date ON vital_sign_records(measurement_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_lipid_date ON lipid_records(measurement_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_body_date ON body_composition_records(measurement_date)',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
