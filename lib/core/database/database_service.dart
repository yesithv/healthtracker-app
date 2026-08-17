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
    _database = await _initDB(_fileName);
    return _database!;
  }

  /// La demo escribe en un archivo APARTE. No es cosmético: es la garantía de
  /// que sembrar dos años de mediciones de mentira —y dejar que el visitante
  /// registre las suyas— no pueda tocar ni borrar el historial real de quien
  /// tenga la app instalada en el mismo dispositivo.
  static bool _useDemo = false;

  static String get _fileName =>
      _useDemo ? 'my-vitals-demo.db' : 'my-vitals-db.db';

  /// Elige a qué archivo apunta la PRÓXIMA apertura. Lo gobierna `DemoSession`
  /// al entrar y al salir de la demo; cambiarlo con una conexión ya abierta no
  /// hace nada por sí solo, hay que pasar después por [reopen].
  static void useDemoDatabase(bool value) {
    _useDemo = value;
  }

  /// Cierra la conexión actual y abre la que toque según [useDemoDatabase].
  ///
  /// Los repositorios cachean en memoria lo que leyeron, así que quien llame
  /// aquí tiene que refrescarlos después o seguirán enseñando los registros de
  /// la base anterior.
  Future<void> reopen() async {
    final previous = _database;
    _database = null;
    await previous?.close();
    await database;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _createDB,
          onUpgrade: _upgradeDB,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Bumped whenever the schema changes. v2: `lab_code` on lipid_records (lab picker).
  /// v3: perímetros corporales en anthropometric_records + muscle_pct en
  /// body_composition_records (paridad con lo que guarda el legacy).
  /// v4: módulo de medicamentos (medications, medication_doses, medication_logs).
  static const int _dbVersion = 4;

  /// Incremental migrations for existing installs. Each step is idempotent-friendly
  /// and additive (no destructive changes to the user's local data).
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE lipid_records ADD COLUMN lab_code TEXT');
    }
    if (oldVersion < 3) {
      for (final col in [
        'waist_cm',
        'hip_cm',
        'lower_abdomen_cm',
        'arm_cm',
        'leg_cm',
        'chest_bust_cm',
      ]) {
        await db.execute(
          'ALTER TABLE anthropometric_records ADD COLUMN $col REAL',
        );
      }
      await db.execute(
        'ALTER TABLE body_composition_records ADD COLUMN muscle_pct REAL',
      );
      // Normaliza tallas importadas del servidor en METROS (< 3) al canon local en cm:
      // la captura siempre produjo cm (mínimo 50), así que < 3 solo puede ser metros.
      await db.execute(
        'UPDATE anthropometric_records SET height = height * 100 WHERE height < 3',
      );
    }
    if (oldVersion < 4) {
      // `onUpgrade` no ejecuta `_createDB`/`_createIndexes`, así que las tablas
      // e índices nuevos deben crearse aquí explícitamente para instalaciones ya
      // existentes.
      await _createMedicationTables(db);
      await _createMedicationIndexes(db);
    }
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
  waist_cm $realType,
  hip_cm $realType,
  lower_abdomen_cm $realType,
  arm_cm $realType,
  leg_cm $realType,
  chest_bust_cm $realType,
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
  lab_code $textType,
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
  muscle_pct $realType,
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

    await _createMedicationTables(db);
    await _createIndexes(db);
    await _createMedicationIndexes(db);
  }

  /// Tablas del módulo de medicamentos (v4). Separadas para poder crearlas tanto
  /// en instalaciones nuevas (desde [_createDB]) como en las que migran desde una
  /// versión anterior (desde [_upgradeDB]). `medications` guarda identidad, pauta
  /// e inventario; `medication_doses` las horas de toma; `medication_logs` los
  /// eventos reales (tomado/omitido).
  Future<void> _createMedicationTables(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT';
    const integerType = 'INTEGER';
    const realType = 'REAL';

    await db.execute('''
CREATE TABLE medications (
  id $idType,
  name $textType NOT NULL,
  form $textType,
  strength_value $realType,
  strength_unit $textType,
  dose_quantity $realType NOT NULL,
  color $textType,
  shape $textType,
  notes $textType,
  frequency_type $textType NOT NULL,
  days_of_week $integerType,
  interval_days $integerType,
  anchor_date $textType,
  start_date $textType,
  end_date $textType,
  is_active $integerType NOT NULL DEFAULT 1,
  stock_quantity $realType,
  stock_tracking_enabled $integerType NOT NULL DEFAULT 0,
  refill_threshold $realType,
  refill_lead_days $integerType,
  pack_size $realType,
  refill_alert_enabled $integerType NOT NULL DEFAULT 1,
  refill_snoozed_until $textType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE medication_doses (
  id $idType,
  medication_id $textType NOT NULL,
  hour $integerType NOT NULL,
  minute $integerType NOT NULL,
  quantity $realType,
  notif_id $integerType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE medication_logs (
  id $idType,
  medication_id $textType NOT NULL,
  dose_id $textType,
  scheduled_at $textType NOT NULL,
  status $textType NOT NULL,
  taken_at $textType,
  quantity $realType,
  created_at $textType NOT NULL,
  updated_at $textType NOT NULL,
  is_synced $integerType DEFAULT 0
)
''');
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

  /// Indexes backing the medication reads: ordering the list by name, and
  /// looking up a medication's doses / logs (the latter also ordered by date).
  Future<void> _createMedicationIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_med_name ON medications(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_med_dose_med ON medication_doses(medication_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_med_log_med_date ON medication_logs(medication_id, scheduled_at)',
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
