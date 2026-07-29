import 'dart:math' as math;

import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';

/// Los dos años de historia que enseña la demo, generados en memoria.
///
/// Este archivo es DETERMINISTA y no toca disco, red ni `SharedPreferences`:
/// dado el mismo «hoy» produce exactamente los mismos registros. Eso es lo que
/// permite repetir una captura la semana que viene y que salga idéntica, y es
/// también lo que lo hace comprobable desde una prueba unitaria
/// (`test/core/demo/demo_dataset_test.dart`). La parte que sí escribe —
/// preferencias, base de datos, sesión — vive aparte, en `demo_seeder.dart`.
///
/// **La forma de los datos cuenta una historia.** Un generador puramente
/// aleatorio produce gráficas que parecen ruido y no lucen en una captura: aquí
/// las series siguen la trayectoria de alguien que llevó dos años cuidándose —
/// mejora rápida al principio, mesetas por el camino, un repunte cada fin de
/// año — así que las gráficas se leen de un vistazo y los semáforos clínicos
/// pasan de ámbar a verde. Los valores están dentro de rangos fisiológicos
/// plausibles y son coherentes entre familias: el músculo en kg sale del peso
/// de ese mismo día, el VLDL de los triglicéridos, el IMC de peso y talla.
class DemoDataset {
  final List<AnthropometricRecord> anthropometric;
  final List<VitalSignRecord> vitalSigns;
  final List<LipidRecord> lipids;
  final List<BodyCompositionRecord> bodyComposition;

  const DemoDataset({
    required this.anthropometric,
    required this.vitalSigns,
    required this.lipids,
    required this.bodyComposition,
  });

  int get totalRecords =>
      anthropometric.length +
      vitalSigns.length +
      lipids.length +
      bodyComposition.length;
}

/// Ventana que cubre la demo, en días (dos años).
const int _spanDays = 730;

/// Talla del personaje, en cm (constante: un adulto no crece).
const double _heightCm = 176.0;

/// Báscula de bioimpedancia del personaje. Coincide con el catálogo de
/// respaldo de `MeasuringDeviceProvider`, así que la ficha del dispositivo en
/// Perfil enseña el mismo aparato que firma las mediciones.
const String demoDeviceName = 'Omron HBF-514C';

/// Semilla fija. No es un detalle: es lo que hace que dos capturas tomadas con
/// una semana de diferencia enseñen exactamente los mismos números.
const int _seed = 20260729;

/// Construye la historia completa. [today] existe para las pruebas; en la app
/// siempre es la fecha real, de modo que la demo termina «hoy» y las pantallas
/// muestran datos recientes en vez de un archivo muerto.
DemoDataset buildDemoDataset({DateTime? today, String language = 'es'}) {
  final end = _atHour(today ?? DateTime.now(), 8);
  final start = end.subtract(const Duration(days: _spanDays));
  final rnd = math.Random(_seed);
  final notes = _DemoNotes(language);

  final anthropometric = _buildAnthropometric(start, end, rnd, notes);
  return DemoDataset(
    anthropometric: anthropometric,
    vitalSigns: _buildVitalSigns(start, end, rnd, notes),
    lipids: _buildLipids(start, end, rnd, notes),
    // La composición corporal se pesa el mismo día que el peso: las dos series
    // salen de subirse a la misma báscula, así que comparten fecha y el
    // músculo en kg se calcula sobre el peso de ese día.
    bodyComposition: _buildBodyComposition(anthropometric, rnd, notes),
  );
}

// ── La curva ───────────────────────────────────────────────────────────────

/// Progreso 0→1 a lo largo de los dos años, con la forma de un cambio real y
/// no la de una recta: fuerte al principio, con mesetas y alguna recaída.
double _trend(double t) {
  final base = 1 - math.pow(1 - t, 1.7).toDouble();
  // Ondulación lenta: tres mesetas repartidas por los dos años.
  final plateau = 0.05 * math.sin(t * 2 * math.pi * 2.5);
  return (base - plateau).clamp(0.0, 1.0);
}

/// Repunte de fiestas: entre el 15 de diciembre y el 8 de enero todo el mundo
/// se desvía un poco. Devuelve 0..1 según lo metido que se esté en las fechas.
double _holidays(DateTime d) {
  if (d.month == 12 && d.day >= 15) return (d.day - 14) / 17.0;
  if (d.month == 1 && d.day <= 8) return (9 - d.day) / 17.0;
  return 0;
}

/// Interpola [from]→[to] siguiendo [_trend], con el repunte de fiestas y un
/// temblor pequeño para que la línea no salga plástica.
///
/// [holidayEffect] va en las unidades de la serie y con el signo del deterioro
/// (peso sube, HDL baja), y [jitter] es la amplitud del temblor.
double _series(
  double from,
  double to,
  double t,
  DateTime date,
  math.Random rnd, {
  double holidayEffect = 0,
  double jitter = 0,
}) {
  final value = from + (to - from) * _trend(t);
  final bump = holidayEffect * _holidays(date);
  final noise = jitter == 0 ? 0.0 : (rnd.nextDouble() * 2 - 1) * jitter;
  return value + bump + noise;
}

DateTime _atHour(DateTime day, int hour, [int minute = 0]) =>
    DateTime(day.year, day.month, day.day, hour, minute);

double _round(double v, int decimals) {
  final f = math.pow(10, decimals);
  return (v * f).round() / f;
}

// ── Antropometría (peso, talla, IMC, perímetros) ───────────────────────────

/// Un pesaje semanal: 105 registros en dos años. Es la cadencia de alguien
/// constante sin llegar a obsesivo, y da a la gráfica puntos de sobra.
List<AnthropometricRecord> _buildAnthropometric(
  DateTime start,
  DateTime end,
  math.Random rnd,
  _DemoNotes notes,
) {
  final records = <AnthropometricRecord>[];
  var i = 0;

  for (
    var date = start;
    !date.isAfter(end);
    date = date.add(const Duration(days: 7)), i++
  ) {
    final t = date.difference(start).inDays / _spanDays;
    final at = _atHour(date, 7, 20);

    // 92,4 → 76,8 kg. Empieza en sobrepeso claro (IMC 29,8) y termina en
    // normalidad (IMC 24,8), rozando el objetivo de 75 kg sin alcanzarlo: así
    // el panel enseña la barra de progreso viva y no un objetivo ya cumplido.
    final weight = _round(
      _series(
        92.4,
        76.8,
        t,
        date,
        rnd,
        holidayEffect: 1.4,
        jitter: 0.35,
      ),
      1,
    );
    final bmi = _round(weight / math.pow(_heightCm / 100, 2), 1);

    // La cinta métrica sale una vez al mes, no cada semana.
    final tape = i % 4 == 0;

    records.add(
      AnthropometricRecord(
        id: 'demo-anthro-$i',
        date: at,
        weight: weight,
        height: _heightCm,
        bmi: bmi,
        waistCm: tape
            ? _round(_series(104, 87.5, t, date, rnd, jitter: 0.4), 1)
            : null,
        hipCm: tape
            ? _round(_series(108, 99, t, date, rnd, jitter: 0.4), 1)
            : null,
        lowerAbdomenCm: tape
            ? _round(_series(106, 91, t, date, rnd, jitter: 0.4), 1)
            : null,
        // El brazo SUBE: se pierde grasa y se gana músculo.
        armCm: tape
            ? _round(_series(32.8, 34.9, t, date, rnd, jitter: 0.2), 1)
            : null,
        legCm: tape
            ? _round(_series(58.6, 57.1, t, date, rnd, jitter: 0.3), 1)
            : null,
        chestBustCm: tape
            ? _round(_series(106.5, 101.2, t, date, rnd, jitter: 0.4), 1)
            : null,
        comment: notes.pick(notes.weight, i, every: 6),
        createdAt: at,
        updatedAt: at,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Signos vitales (tensión y pulso) ───────────────────────────────────────

/// Una toma cada dos días, más una segunda toma vespertina de vez en cuando:
/// ~420 lecturas. Es la familia con más registros porque es la que se mide en
/// casa, y es la que llena de verdad la gráfica de los filtros de 7 y 30 días.
List<VitalSignRecord> _buildVitalSigns(
  DateTime start,
  DateTime end,
  math.Random rnd,
  _DemoNotes notes,
) {
  final records = <VitalSignRecord>[];
  var i = 0;

  for (
    var date = start;
    !date.isAfter(end);
    date = date.add(const Duration(days: 2)), i++
  ) {
    final t = date.difference(start).inDays / _spanDays;

    // 138/88 con pulso 78 → 118/76 con pulso 62: de «elevada» a «normal».
    // El semáforo del panel cruza de ámbar a verde a lo largo de la serie.
    var systolic = _series(
      138,
      118,
      t,
      date,
      rnd,
      holidayEffect: 4,
      jitter: 4.5,
    );
    var diastolic = _series(
      88,
      75.5,
      t,
      date,
      rnd,
      holidayEffect: 2.5,
      jitter: 3,
    );
    var heartRate = _series(78, 61.5, t, date, rnd, holidayEffect: 3, jitter: 5);

    // Reparto realista del contexto: casi siempre en reposo, y una de cada
    // seis tomas justo después de entrenar (que es cuando el pulso se dispara,
    // y por eso conviene que la app lo sepa distinguir).
    final roll = rnd.nextDouble();
    final String activity;
    String symptom = 'normal';
    if (roll < 0.16) {
      activity = 'ejercicio';
      systolic += 14;
      diastolic += 5;
      heartRate += 38;
    } else {
      activity = 'reposo';
    }

    // Un 4 % de tomas con síntoma: son las que hacen que el historial tenga
    // algo que contar y que los filtros por síntoma no salgan vacíos.
    final symptomRoll = rnd.nextDouble();
    if (symptomRoll < 0.018) {
      symptom = 'mareo';
      systolic -= 9;
      diastolic -= 6;
    } else if (symptomRoll < 0.030) {
      symptom = 'dolor';
      systolic += 11;
      diastolic += 6;
    } else if (symptomRoll < 0.045) {
      symptom = 'fatiga';
      heartRate += 9;
    }

    final at = _atHour(date, 7, 10 + rnd.nextInt(40));
    records.add(
      _vitalSign(
        id: 'demo-vitals-$i-am',
        at: at,
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        activity: activity,
        symptom: symptom,
        comment: notes.pick(notes.vitals, i, every: 11),
      ),
    );

    // Segunda toma del día (~18 %): por la tarde la tensión sube un poco.
    if (rnd.nextDouble() < 0.18) {
      records.add(
        _vitalSign(
          id: 'demo-vitals-$i-pm',
          at: _atHour(date, 20, 5 + rnd.nextInt(45)),
          systolic: systolic + 3 + rnd.nextInt(4),
          diastolic: diastolic + 2 + rnd.nextInt(3),
          heartRate: heartRate + (activity == 'ejercicio' ? -30 : 4),
          activity: 'reposo',
          symptom: 'normal',
        ),
      );
    }
  }
  return records;
}

VitalSignRecord _vitalSign({
  required String id,
  required DateTime at,
  required double systolic,
  required double diastolic,
  required double heartRate,
  required String activity,
  required String symptom,
  String? comment,
}) {
  return VitalSignRecord(
    id: id,
    date: at,
    // Los topes son la red de seguridad del generador: por mucho que se sumen
    // el repunte de fiestas, el entrenamiento y el temblor, ninguna lectura
    // sale del rango que un tensiómetro doméstico podría enseñar.
    systolic: systolic.round().clamp(95, 172),
    diastolic: diastolic.round().clamp(58, 108),
    heartRate: heartRate.round().clamp(48, 168),
    activityState: activity,
    symptom: symptom,
    comment: comment,
    createdAt: at,
    updatedAt: at,
    isSynced: true,
  );
}

// ── Perfil lipídico ────────────────────────────────────────────────────────

/// Un panel de laboratorio cada ~90 días: 9 analíticas en dos años, que es lo
/// que se hace de verdad. Pocos puntos, pero es la familia donde más se nota
/// la mejora: el colesterol entra en «límite alto» y sale en «óptimo».
List<LipidRecord> _buildLipids(
  DateTime start,
  DateTime end,
  math.Random rnd,
  _DemoNotes notes,
) {
  const labs = [
    'Laboratorio Clínico Andes',
    'Unidad Diagnóstica Bio-Salud',
    'Centro Médico San Rafael',
  ];

  final records = <LipidRecord>[];
  var i = 0;

  // El desfase inicial cuadra la última analítica con «hoy». Sin él, la serie
  // terminaría diez días atrás y la tarjeta del panel abriría con un resultado
  // rancio: en una captura, lo primero que se mira es la fecha.
  const offset = _spanDays % 90;

  for (
    var date = start.add(const Duration(days: offset));
    !date.isAfter(end);
    date = date.add(const Duration(days: 90)), i++
  ) {
    final t = date.difference(start).inDays / _spanDays;
    final at = _atHour(date, 8, 30);

    final ldl = _round(_series(158, 101, t, date, rnd, jitter: 3), 0);
    // El HDL es el único que mejora SUBIENDO, así que el repunte de fiestas
    // va con signo negativo: en diciembre baja.
    final hdl = _round(
      _series(38, 55, t, date, rnd, holidayEffect: -2, jitter: 1.5),
      0,
    );
    final triglycerides = _round(
      _series(212, 117, t, date, rnd, holidayEffect: 14, jitter: 8),
      0,
    );
    // Friedewald: VLDL ≈ TG/5, y el total es la suma de las tres fracciones.
    // Cuadrar la aritmética importa — si no, la analítica no se sostiene ante
    // cualquiera que sepa leerla, y una captura es justo donde se mira.
    final vldl = _round(triglycerides / 5, 0);
    final total = _round(ldl + hdl + vldl, 0);

    records.add(
      LipidRecord(
        id: 'demo-lipid-$i',
        date: at,
        totalCholesterol: total,
        ldl: ldl,
        hdl: hdl,
        vldl: vldl,
        triglycerides: triglycerides,
        // Sin `labCode`: el catálogo de laboratorios lo sirve la API y la demo
        // corre sin red, así que se guarda como «Otro» con el nombre escrito a
        // mano — el mismo camino que recorre un usuario sin cobertura. Los
        // semáforos caen entonces al criterio ATP III, que es el de fábrica.
        labName: labs[i % labs.length],
        comment: notes.pick(notes.lipids, i, every: 3),
        createdAt: at,
        updatedAt: at,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Composición corporal ───────────────────────────────────────────────────

/// Una lectura de bioimpedancia por cada pesaje, con la misma fecha: es la
/// misma báscula. El músculo en kg se deriva del peso de ese día y del % de
/// músculo esquelético, para que las dos familias no se contradigan.
List<BodyCompositionRecord> _buildBodyComposition(
  List<AnthropometricRecord> weighIns,
  math.Random rnd,
  _DemoNotes notes,
) {
  if (weighIns.isEmpty) return const [];

  final start = weighIns.first.date;
  final records = <BodyCompositionRecord>[];

  for (var i = 0; i < weighIns.length; i++) {
    final weighIn = weighIns[i];
    final date = weighIn.date;
    final t = date.difference(start).inDays / _spanDays;

    final bodyFat = _round(
      _series(31.4, 20.6, t, date, rnd, holidayEffect: 0.6, jitter: 0.3),
      1,
    );
    final musclePct = _round(
      _series(28.3, 36.4, t, date, rnd, holidayEffect: -0.3, jitter: 0.2),
      1,
    );

    records.add(
      BodyCompositionRecord(
        id: 'demo-body-$i',
        date: date,
        bodyFatPercent: bodyFat,
        // Derivado, no inventado: kg de músculo = peso del día × % músculo.
        muscleMassKg: _round(weighIn.weight * musclePct / 100, 1),
        musclePct: musclePct,
        visceralFatLevel: _series(13.4, 6.6, t, date, rnd, jitter: 0.4)
            .round()
            .clamp(1, 30),
        metabolicAge: _series(52.4, 37.6, t, date, rnd, jitter: 0.6)
            .round()
            .clamp(18, 80),
        // El metabolismo basal BAJA al bajar el peso total, aunque suba el
        // músculo: es lo que de verdad marca la báscula, y conviene que la
        // demo no enseñe una fisiología de fantasía.
        bmrKcal: _series(1782, 1655, t, date, rnd, jitter: 9).round(),
        bodyWaterPercent: _round(
          _series(48.1, 56.4, t, date, rnd, jitter: 0.3),
          1,
        ),
        boneMassKg: _round(_series(3.18, 3.02, t, date, rnd, jitter: 0.03), 2),
        deviceName: demoDeviceName,
        comment: notes.pick(notes.body, i, every: 8),
        createdAt: date,
        updatedAt: date,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Comentarios ────────────────────────────────────────────────────────────

/// Las notas que el personaje deja en algunos registros. Son DATOS DEL USUARIO,
/// no interfaz, así que no pasan por el sistema de traducción: se eligen aquí
/// según el idioma con el que arranca la demo, para que una captura en inglés
/// no enseñe comentarios en español. Los idiomas sin juego propio caen al
/// inglés, que es el que menos desentona en una web de portafolio.
class _DemoNotes {
  final List<String> weight;
  final List<String> vitals;
  final List<String> lipids;
  final List<String> body;

  factory _DemoNotes(String language) =>
      language == 'es' ? _DemoNotes._spanish() : _DemoNotes._english();

  const _DemoNotes._({
    required this.weight,
    required this.vitals,
    required this.lipids,
    required this.body,
  });

  factory _DemoNotes._spanish() => const _DemoNotes._(
    weight: [
      'Después de dos semanas sin fallar al gimnasio.',
      'Semana de viaje, comí fuera casi todos los días.',
      'Cambié el pan de la cena por fruta.',
      'Se nota en la ropa más que en la báscula.',
      'Fiestas. Toca volver a la rutina.',
      'Primera vez por debajo de los 80 kg.',
    ],
    vitals: [
      'Medida antes del desayuno, en ayunas.',
      'Dormí mal, cinco horas escasas.',
      'Segunda toma; la primera salió alta.',
      'Día tranquilo, sin café.',
      'Justo al terminar de correr 5 km.',
    ],
    lipids: [
      'Ayuno de 12 horas. Control trimestral.',
      'El médico bajó la dosis a la mitad.',
      'Tres meses con dieta mediterránea.',
      'Control anual completo.',
    ],
    body: [
      'Medición de la mañana, en ayunas.',
      'La grasa visceral bajó otro punto.',
      'Empecé rutina de fuerza tres días por semana.',
    ],
  );

  factory _DemoNotes._english() => const _DemoNotes._(
    weight: [
      'Two weeks without missing a single gym session.',
      'Travel week, ate out almost every day.',
      'Swapped bread at dinner for fruit.',
      'Shows in how clothes fit more than on the scale.',
      'Holidays. Time to get back to the routine.',
      'First time under 80 kg.',
    ],
    vitals: [
      'Taken before breakfast, fasting.',
      'Slept badly, barely five hours.',
      'Second reading; the first one came out high.',
      'Quiet day, no coffee.',
      'Right after a 5 km run.',
    ],
    lipids: [
      '12-hour fast. Quarterly check.',
      'Doctor cut the dose in half.',
      'Three months on a Mediterranean diet.',
      'Full annual check-up.',
    ],
    body: [
      'Morning reading, fasting.',
      'Visceral fat down another point.',
      'Started strength training three days a week.',
    ],
  );

  /// La nota que toca en el registro [i], o `null` si a ese no le toca. Sólo
  /// uno de cada [every] lleva comentario: si los llevaran todos, el historial
  /// se leería como una novela y dejaría de parecer el uso real de una app.
  String? pick(List<String> pool, int i, {required int every}) =>
      i % every == 0 ? pool[(i ~/ every) % pool.length] : null;
}
