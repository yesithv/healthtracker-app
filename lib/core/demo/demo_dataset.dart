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
const double _heightCm = 165.0;

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
///
/// [includeEdgeCases] anexa un puñado de registros EXTREMOS pero válidos (topes
/// clínicos, colisiones de fecha, bordes de la ventana) para estresar las
/// gráficas, las estadísticas y el PDF sin salirse de rango. Viene **apagado por
/// defecto**: los extremos aplastan la escala de las gráficas (un IMC de 43 o de
/// 16 borra la mejora curada), así que la demo del home enseña solo la serie
/// bonita. Es opt-in —lo encienden a mano las pruebas de blindaje que ejercitan
/// el generador (`demo_edge_cases_test.dart`, `clinical_summary_edge_test.dart`)—.
/// Ver `_buildEdgeCases`.
DemoDataset buildDemoDataset({
  DateTime? today,
  String language = 'es',
  bool includeEdgeCases = false,
}) {
  final end = _atHour(today ?? DateTime.now(), 8);
  final start = end.subtract(const Duration(days: _spanDays));
  final rnd = math.Random(_seed);
  final notes = _DemoNotes(language);

  final anthropometric = _buildAnthropometric(start, end, rnd, notes);
  final base = DemoDataset(
    anthropometric: anthropometric,
    vitalSigns: _buildVitalSigns(start, end, rnd, notes),
    lipids: _buildLipids(start, end, rnd, notes),
    // La composición corporal se pesa el mismo día que el peso: las dos series
    // salen de subirse a la misma báscula, así que comparten fecha y el
    // músculo en kg se calcula sobre el peso de ese día.
    bodyComposition: _buildBodyComposition(anthropometric, rnd, notes),
  );

  if (!includeEdgeCases) return base;

  // Anexa los extremos y REORDENA cada familia por fecha. Reordenar es un no-op
  // para la serie curada (ya viene ascendente), pero coloca cada extremo en su
  // sitio y mantiene el contrato «lista ya ordenada» que asumen las gráficas
  // (`downsample`) y el resumen del PDF (`clinical_summary`).
  final edge = _buildEdgeCases(start, end, notes);
  return DemoDataset(
    anthropometric: _mergeByDate(
      base.anthropometric,
      edge.anthropometric,
      (r) => r.date,
    ),
    vitalSigns: _mergeByDate(base.vitalSigns, edge.vitalSigns, (r) => r.date),
    lipids: _mergeByDate(base.lipids, edge.lipids, (r) => r.date),
    bodyComposition: _mergeByDate(
      base.bodyComposition,
      edge.bodyComposition,
      (r) => r.date,
    ),
  );
}

/// Une [base] y [extra] y devuelve la lista ordenada ASCENDENTEMENTE por fecha.
/// Dos registros con el mismo instante quedan contiguos, pero su orden relativo
/// no está garantizado (`List.sort` no es estable): quien lea la serie no puede
/// apoyarse en cuál va primero de una colisión de fecha.
List<T> _mergeByDate<T>(
  List<T> base,
  List<T> extra,
  DateTime Function(T) dateOf,
) =>
    [...base, ...extra]..sort((a, b) => dateOf(a).compareTo(dateOf(b)));

// ── La cadencia de cada examen ─────────────────────────────────────────────

/// Las fechas en que el personaje se hizo un examen de esta familia, contadas
/// **hacia atrás desde hoy** ([end]) una cada [intervalDays] días.
///
/// Nadie se pesa «todos los día 3 del mes»: cada toma lleva un desajuste de
/// ±[jitterDays] para que las fechas no queden cuadriculadas. La primera (la más
/// reciente) se pega a hoy —sólo se adelanta, nunca cae en el futuro— para que
/// la tarjeta del panel abra con un dato fresco. Se paran las tomas al pasar de
/// [start] (la ventana de dos años) o al llegar a [maxCount].
///
/// El desajuste sale de [rnd], la misma fuente sembrada que todo lo demás, así
/// que la serie sigue siendo DETERMINISTA: el mismo «hoy» produce exactamente
/// las mismas fechas, y una captura repetida semanas después sale idéntica.
///
/// Devuelve las fechas en orden cronológico (de la más antigua a la más
/// reciente), a mediodía; cada familia les pone luego su hora concreta.
List<DateTime> _cadenceDays(
  DateTime start,
  DateTime end,
  math.Random rnd, {
  required int intervalDays,
  required int jitterDays,
  required int maxCount,
}) {
  final days = <DateTime>[];
  var anchor = end;
  for (var i = 0; i < maxCount && !anchor.isBefore(start); i++) {
    final jitter = jitterDays == 0
        ? 0
        : rnd.nextInt(jitterDays * 2 + 1) - jitterDays;
    var day = anchor.add(Duration(days: jitter));
    // Nunca en el futuro: la toma más reciente se adelanta, no se pospone.
    if (day.isAfter(end)) day = end.subtract(Duration(days: rnd.nextInt(3)));
    if (!day.isBefore(start)) {
      days.add(DateTime(day.year, day.month, day.day, 12));
    }
    anchor = anchor.subtract(Duration(days: intervalDays));
  }
  return days.reversed.toList();
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

/// Un pesaje al mes: ~24 registros en dos años. El peso de casa se mira a
/// diario, pero como dato que se ANOTA una vez al mes es la cadencia realista de
/// alguien constante sin llegar a obsesivo, y da a la gráfica puntos de sobra.
List<AnthropometricRecord> _buildAnthropometric(
  DateTime start,
  DateTime end,
  math.Random rnd,
  _DemoNotes notes,
) {
  final records = <AnthropometricRecord>[];
  final days = _cadenceDays(
    start,
    end,
    rnd,
    intervalDays: 29,
    jitterDays: 5,
    maxCount: 25,
  );

  for (var i = 0; i < days.length; i++) {
    final date = days[i];
    final t = date.difference(start).inDays / _spanDays;
    final at = _atHour(date, 7, 15 + rnd.nextInt(35));

    // 80,5 → 63,5 kg. Empieza en sobrepeso claro (IMC 29,6) y termina en
    // normalidad (IMC 23,3), rozando el objetivo de 62 kg sin alcanzarlo: así
    // el panel enseña la barra de progreso viva y no un objetivo ya cumplido.
    final weight = _round(
      _series(80.5, 63.5, t, date, rnd, holidayEffect: 1.4, jitter: 0.35),
      1,
    );
    final bmi = _round(weight / math.pow(_heightCm / 100, 2), 1);

    // La cinta métrica no sale en cada pesaje: se pasa cada dos o tres meses,
    // en uno de cada tres registros.
    final tape = i % 3 == 0;

    records.add(
      AnthropometricRecord(
        id: 'demo-anthro-$i',
        date: at,
        weight: weight,
        height: _heightCm,
        bmi: bmi,
        waistCm: tape
            ? _round(_series(95, 76, t, date, rnd, jitter: 0.4), 1)
            : null,
        // La cadera se mantiene por encima de la cintura de principio a fin, que
        // es la silueta típica de una mujer y lo que da un índice cintura-cadera
        // saludable al final de la serie.
        hipCm: tape
            ? _round(_series(112, 101, t, date, rnd, jitter: 0.4), 1)
            : null,
        lowerAbdomenCm: tape
            ? _round(_series(100, 84, t, date, rnd, jitter: 0.4), 1)
            : null,
        // El brazo baja poco: se pierde grasa, pero manteniendo tono.
        armCm: tape
            ? _round(_series(31.5, 30.0, t, date, rnd, jitter: 0.2), 1)
            : null,
        legCm: tape
            ? _round(_series(62, 57, t, date, rnd, jitter: 0.3), 1)
            : null,
        chestBustCm: tape
            ? _round(_series(102, 94, t, date, rnd, jitter: 0.4), 1)
            : null,
        comment: notes.pick(notes.weight, i, every: 4),
        createdAt: at,
        updatedAt: at,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Signos vitales (tensión y pulso) ───────────────────────────────────────

/// Una toma al mes (~24 lecturas), más una segunda toma vespertina de vez en
/// cuando y un tramo de siete días seguidos de automedición al principio —de los
/// que el médico manda tras encontrar la tensión elevada—. Se mide en casa, así
/// que es la familia que da vida a la gráfica de tensión del panel.
List<VitalSignRecord> _buildVitalSigns(
  DateTime start,
  DateTime end,
  math.Random rnd,
  _DemoNotes notes,
) {
  final records = <VitalSignRecord>[];
  final days = _cadenceDays(
    start,
    end,
    rnd,
    intervalDays: 30,
    jitterDays: 6,
    maxCount: 24,
  );

  for (var i = 0; i < days.length; i++) {
    final date = days[i];
    final t = date.difference(start).inDays / _spanDays;

    // 134/86 con pulso 76 → 114/74 con pulso 64: de «elevada» a «normal».
    // El semáforo del panel cruza de ámbar a verde a lo largo de la serie.
    var systolic = _series(134, 114, t, date, rnd, holidayEffect: 4, jitter: 4.5);
    var diastolic = _series(86, 74, t, date, rnd, holidayEffect: 2.5, jitter: 3);
    var heartRate = _series(76, 64, t, date, rnd, holidayEffect: 3, jitter: 5);

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

    // Alguna toma con síntoma: son las que hacen que el historial tenga algo que
    // contar y que los filtros por síntoma no salgan vacíos.
    final symptomRoll = rnd.nextDouble();
    if (symptomRoll < 0.05) {
      symptom = 'mareo';
      systolic -= 9;
      diastolic -= 6;
    } else if (symptomRoll < 0.10) {
      symptom = 'dolor';
      systolic += 11;
      diastolic += 6;
    } else if (symptomRoll < 0.16) {
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
        comment: notes.pick(notes.vitals, i, every: 6),
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

  // El tramo de siete días seguidos: al principio de la historia, cuando la
  // tensión salía elevada, el médico pide medir a diario una semana. Es una
  // conducta real —y es lo que enseña que la app sabe llevar una racha diaria—.
  records.addAll(_weekOfMonitoring(start, rnd, notes));

  // Las dos fuentes (mensual y el tramo diario) se entrelazan en el tiempo, así
  // que se ordena para que el historial y las gráficas salgan cronológicos.
  records.sort((a, b) => a.date.compareTo(b.date));
  return records;
}

/// Siete días consecutivos de automedición matinal, ~45 días después del
/// arranque: la tensión todavía está elevada, así que las lecturas rondan la
/// franja alta. Determinista como el resto (la variación sale de [rnd]).
List<VitalSignRecord> _weekOfMonitoring(
  DateTime start,
  math.Random rnd,
  _DemoNotes notes,
) {
  final records = <VitalSignRecord>[];
  final firstDay = start.add(const Duration(days: 45));
  for (var d = 0; d < 7; d++) {
    final date = firstDay.add(Duration(days: d));
    final t = date.difference(start).inDays / _spanDays;
    records.add(
      _vitalSign(
        id: 'demo-vitals-monitor-$d',
        at: _atHour(date, 7, 0 + rnd.nextInt(25)),
        systolic: _series(133, 130, t, date, rnd, jitter: 3.5),
        diastolic: _series(85, 83, t, date, rnd, jitter: 2.5),
        heartRate: _series(75, 73, t, date, rnd, jitter: 4),
        activity: 'reposo',
        symptom: 'normal',
        // Sólo el primer día lleva la nota que explica la semana de control.
        comment: d == 0 ? notes.monitoring : null,
      ),
    );
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

/// Un panel de laboratorio cada ~3 meses: ~9 analíticas en dos años, que es la
/// cadencia con que se controla un colesterol que se está tratando. Pocos
/// puntos, pero es la familia donde más se nota la mejora: el colesterol entra
/// en «límite alto» y sale en «óptimo». El día exacto varía (±2 semanas): a una
/// analítica se va cuando se puede pedir cita, no en fechas de reloj.
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
  final days = _cadenceDays(
    start,
    end,
    rnd,
    intervalDays: 85,
    jitterDays: 12,
    maxCount: 9,
  );

  for (var i = 0; i < days.length; i++) {
    final date = days[i];
    final t = date.difference(start).inDays / _spanDays;
    final at = _atHour(date, 8, 30);

    final ldl = _round(_series(150, 98, t, date, rnd, jitter: 3), 0);
    // El HDL es el único que mejora SUBIENDO, así que el repunte de fiestas
    // va con signo negativo: en diciembre baja. Arranca ya más alto que en un
    // hombre, que es lo habitual en una mujer.
    final hdl = _round(
      _series(42, 62, t, date, rnd, holidayEffect: -2, jitter: 1.5),
      0,
    );
    final triglycerides = _round(
      _series(190, 105, t, date, rnd, holidayEffect: 14, jitter: 8),
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
        comment: notes.pick(notes.lipids, i, every: 2),
        createdAt: at,
        updatedAt: at,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Composición corporal ───────────────────────────────────────────────────

/// Una lectura de bioimpedancia cada dos meses: se sube a la báscula uno de
/// cada dos pesajes (~12 lecturas), y siempre en un día que YA tiene pesaje, con
/// la misma fecha. Así el músculo en kg se deriva del peso de ese día y del % de
/// músculo esquelético, y las dos familias no se contradicen.
List<BodyCompositionRecord> _buildBodyComposition(
  List<AnthropometricRecord> weighIns,
  math.Random rnd,
  _DemoNotes notes,
) {
  if (weighIns.isEmpty) return const [];

  final start = weighIns.first.date;
  final records = <BodyCompositionRecord>[];

  for (var i = 0; i < weighIns.length; i += 2) {
    final weighIn = weighIns[i];
    final date = weighIn.date;
    final t = date.difference(start).inDays / _spanDays;
    final n = i ~/ 2;

    // Grasa y músculo con proporciones de mujer: la grasa arranca alta (36 %) y
    // baja a un saludable 26 %; el músculo esquelético sube del 24 % al 31 %,
    // por debajo de lo que marcaría un hombre a igual peso.
    final bodyFat = _round(
      _series(36.0, 26.0, t, date, rnd, holidayEffect: 0.6, jitter: 0.3),
      1,
    );
    final musclePct = _round(
      _series(24.0, 31.0, t, date, rnd, holidayEffect: -0.3, jitter: 0.2),
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
        visceralFatLevel: _series(
          10.4,
          4.6,
          t,
          date,
          rnd,
          jitter: 0.4,
        ).round().clamp(1, 30),
        metabolicAge: _series(
          48.4,
          33.6,
          t,
          date,
          rnd,
          jitter: 0.6,
        ).round().clamp(18, 80),
        // El metabolismo basal BAJA al bajar el peso total, aunque suba el
        // músculo: es lo que de verdad marca la báscula, y conviene que la
        // demo no enseñe una fisiología de fantasía. Los valores son más bajos
        // que en un hombre, acordes a menos masa magra.
        bmrKcal: _series(1480, 1360, t, date, rnd, jitter: 9).round(),
        // El agua corporal en una mujer ronda por debajo de la de un hombre.
        bodyWaterPercent: _round(
          _series(45.0, 52.0, t, date, rnd, jitter: 0.3),
          1,
        ),
        boneMassKg: _round(_series(2.35, 2.20, t, date, rnd, jitter: 0.03), 2),
        deviceName: demoDeviceName,
        comment: notes.pick(notes.body, n, every: 4),
        createdAt: date,
        updatedAt: date,
        isSynced: true,
      ),
    );
  }
  return records;
}

// ── Casos extremos (edge cases) ────────────────────────────────────────────

/// Un puñado de registros EXTREMOS pero dentro de rango, para blindar la app.
///
/// La serie curada cuenta una mejora bonita y suave: nunca toca los topes
/// clínicos ni las rarezas de tiempo (dos tomas en el mismo instante, valores al
/// borde del clamp, presión de pulso mínima) que un usuario real sí producirá.
/// Estos registros existen para VER CÓMO SE REVIENTA la app —gráficas de
/// `fl_chart`, estadísticas del PDF, semáforos clínicos— antes de que lo haga en
/// producción. Todo aquí cumple tres reglas:
///
///  1. **Dentro de rango.** Nada se sale de lo que un aparato podría enseñar ni
///     de los clamps del generador (tensión 95–172/58–108, pulso 48–168…).
///  2. **Coherente entre familias.** El IMC sale de peso y talla, el VLDL de los
///     triglicéridos y el total es la suma de las tres fracciones — igual que en
///     la serie curada.
///  3. **En medio de la serie, nunca lo más reciente.** Se colocan con offsets
///     fijos dentro de la ventana pero antes del último registro real de cada
///     familia, para que el panel siga abriendo con los valores actuales de
///     Camila y sea el HISTORIAL el que reciba el golpe.
///
/// Es DETERMINISTA sin depender de `rnd`: los valores van escritos a mano, así
/// que dos generaciones seguidas dan exactamente lo mismo.
DemoDataset _buildEdgeCases(DateTime start, DateTime end, _DemoNotes notes) {
  DateTime at(int daysFromStart, int hour, [int minute = 0]) =>
      _atHour(start.add(Duration(days: daysFromStart)), hour, minute);

  // ── Signos vitales ─────────────────────────────────────────────────────
  // El instante que comparten las dos tomas «gemelas»: colisión de fecha exacta
  // (misma marca de tiempo, valores distintos), el caso que rompe cualquier
  // gráfica que dé por hecho que no hay dos puntos en la misma X.
  final collision = at(255, 9, 30);
  final vitalSigns = <VitalSignRecord>[
    // Crisis hipertensiva al tope del clamp, con el pulso también al máximo.
    _vitalSign(
      id: 'demo-edge-vitals-crisis',
      at: at(150, 6, 40),
      systolic: 172,
      diastolic: 108,
      heartRate: 168,
      activity: 'ejercicio',
      symptom: 'dolor',
      comment: notes.pick(notes.edges, 0, every: 1),
    ),
    // Mínimos: hipotensión y bradicardia al borde inferior del clamp.
    _vitalSign(
      id: 'demo-edge-vitals-min',
      at: at(430, 5, 5),
      systolic: 95,
      diastolic: 58,
      heartRate: 48,
      activity: 'reposo',
      symptom: 'mareo',
      comment: notes.pick(notes.edges, 1, every: 1),
    ),
    // Presión de pulso mínima: sistólica apenas 1 mmHg por encima de la
    // diastólica. Dos líneas casi pegadas en la gráfica de tensión.
    _vitalSign(
      id: 'demo-edge-vitals-narrow',
      at: at(600, 7, 0),
      systolic: 100,
      diastolic: 99,
      heartRate: 90,
      activity: 'post-op',
      symptom: 'fatiga',
    ),
    // Colisión de tiempo A: misma marca exacta que la B, valores distintos.
    _vitalSign(
      id: 'demo-edge-vitals-collision-a',
      at: collision,
      systolic: 168,
      diastolic: 104,
      heartRate: 150,
      activity: 'ejercicio',
      symptom: 'normal',
    ),
    // Colisión de tiempo B.
    _vitalSign(
      id: 'demo-edge-vitals-collision-b',
      at: collision,
      systolic: 110,
      diastolic: 70,
      heartRate: 62,
      activity: 'reposo',
      symptom: 'normal',
    ),
  ];

  // ── Antropometría ──────────────────────────────────────────────────────
  double bmiOf(double weight) =>
      _round(weight / math.pow(_heightCm / 100, 2), 1);
  final anthropometric = <AnthropometricRecord>[
    // Obesidad extrema (IMC 43,3) sin perímetros: aísla el tope de peso/IMC.
    AnthropometricRecord(
      id: 'demo-edge-anthro-obese',
      date: at(60, 7, 20),
      weight: 118.0,
      height: _heightCm,
      bmi: bmiOf(118.0),
      comment: notes.pick(notes.edges, 2, every: 1),
      createdAt: at(60, 7, 20),
      updatedAt: at(60, 7, 20),
      isSynced: true,
    ),
    // Bajo peso (IMC 16,2): el otro extremo de la escala del IMC.
    AnthropometricRecord(
      id: 'demo-edge-anthro-underweight',
      date: at(320, 7, 25),
      weight: 44.0,
      height: _heightCm,
      bmi: bmiOf(44.0),
      createdAt: at(320, 7, 25),
      updatedAt: at(320, 7, 25),
      isSynced: true,
    ),
    // Perímetros extremos con CINTURA MAYOR QUE CADERA: WHR 1,31 (obesidad
    // androide) y WHtR 0,78, muy por encima de los cortes de alerta.
    AnthropometricRecord(
      id: 'demo-edge-anthro-circumferences',
      date: at(540, 7, 30),
      weight: 70.0,
      height: _heightCm,
      bmi: bmiOf(70.0),
      waistCm: 128.0,
      hipCm: 98.0,
      lowerAbdomenCm: 132.0,
      armCm: 42.0,
      legCm: 72.0,
      chestBustCm: 128.0,
      createdAt: at(540, 7, 30),
      updatedAt: at(540, 7, 30),
      isSynced: true,
    ),
  ];

  // ── Perfil lipídico ────────────────────────────────────────────────────
  // Friedewald: VLDL = TG/5, y el total es la suma de las tres fracciones —la
  // misma aritmética que la serie curada, para que la analítica se sostenga.
  LipidRecord lipid({
    required String id,
    required DateTime date,
    required double ldl,
    required double hdl,
    required double triglycerides,
    required String labName,
    String? comment,
  }) {
    final vldl = _round(triglycerides / 5, 0);
    return LipidRecord(
      id: id,
      date: date,
      totalCholesterol: _round(ldl + hdl + vldl, 0),
      ldl: ldl,
      hdl: hdl,
      vldl: vldl,
      triglycerides: triglycerides,
      labName: labName,
      comment: comment,
      createdAt: date,
      updatedAt: date,
      isSynced: true,
    );
  }

  final lipids = <LipidRecord>[
    // Panel muy alto: LDL 300, HDL bajo (20, el extremo de riesgo), TG 600.
    lipid(
      id: 'demo-edge-lipid-high',
      date: at(110, 8, 30),
      ldl: 300,
      hdl: 20,
      triglycerides: 600,
      labName: 'Laboratorio Clínico Andes',
      comment: notes.pick(notes.edges, 3, every: 1),
    ),
    // Panel óptimo extremo: HDL 100 (muy protector), LDL 45, TG 45.
    lipid(
      id: 'demo-edge-lipid-optimal',
      date: at(660, 8, 30),
      ldl: 45,
      hdl: 100,
      triglycerides: 45,
      labName: 'Centro Médico San Rafael',
    ),
  ];

  // ── Composición corporal ───────────────────────────────────────────────
  final bodyComposition = <BodyCompositionRecord>[
    // Topes: grasa 55 %, visceral al máximo de la escala (30), edad metabólica
    // al tope (80). Los sube todos a la vez para estresar cada semáforo.
    BodyCompositionRecord(
      id: 'demo-edge-body-max',
      date: at(95, 7, 40),
      bodyFatPercent: 55.0,
      muscleMassKg: 24.0,
      musclePct: 21.0,
      visceralFatLevel: 30,
      metabolicAge: 80,
      bmrKcal: 1900,
      bodyWaterPercent: 55.0,
      boneMassKg: 3.20,
      deviceName: demoDeviceName,
      comment: notes.pick(notes.edges, 4, every: 1),
      createdAt: at(95, 7, 40),
      updatedAt: at(95, 7, 40),
      isSynced: true,
    ),
    // Mínimos: grasa 8 %, visceral 1, edad metabólica 18 (el suelo de la escala).
    BodyCompositionRecord(
      id: 'demo-edge-body-min',
      date: at(670, 7, 40),
      bodyFatPercent: 8.0,
      muscleMassKg: 21.0,
      musclePct: 33.0,
      visceralFatLevel: 1,
      metabolicAge: 18,
      bmrKcal: 1200,
      bodyWaterPercent: 42.0,
      boneMassKg: 1.80,
      deviceName: demoDeviceName,
      createdAt: at(670, 7, 40),
      updatedAt: at(670, 7, 40),
      isSynced: true,
    ),
  ];

  return DemoDataset(
    anthropometric: anthropometric,
    vitalSigns: vitalSigns,
    lipids: lipids,
    bodyComposition: bodyComposition,
  );
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

  /// Notas para los registros extremos (ver `_buildEdgeCases`). Se eligen por
  /// índice, así que el orden importa: 0=crisis, 1=hipotensión, 2=obesidad,
  /// 3=analítica alta, 4=composición al tope.
  final List<String> edges;

  /// La nota del primer día del tramo de siete de automedición.
  final String monitoring;

  factory _DemoNotes(String language) =>
      language == 'es' ? _DemoNotes._spanish() : _DemoNotes._english();

  const _DemoNotes._({
    required this.weight,
    required this.vitals,
    required this.lipids,
    required this.body,
    required this.edges,
    required this.monitoring,
  });

  factory _DemoNotes._spanish() => const _DemoNotes._(
    monitoring: 'El médico me pidió medir la tensión siete días seguidos.',
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
    edges: [
      'Lectura en urgencias, tensión muy alta.',
      'Me levanté mareada, la tensión salió muy baja.',
      'Antes de empezar a cuidarme.',
      'Analítica de control, el médico ajustó la medicación.',
      'Primera bioimpedancia, punto de partida.',
    ],
  );

  factory _DemoNotes._english() => const _DemoNotes._(
    monitoring: 'Doctor asked me to measure my blood pressure seven days in a row.',
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
    edges: [
      'Reading at the ER, blood pressure very high.',
      'Woke up dizzy, blood pressure came out very low.',
      'Before I started taking care of myself.',
      'Follow-up panel, the doctor adjusted the medication.',
      'First bioimpedance reading, starting point.',
    ],
  );

  /// La nota que toca en el registro [i], o `null` si a ese no le toca. Sólo
  /// uno de cada [every] lleva comentario: si los llevaran todos, el historial
  /// se leería como una novela y dejaría de parecer el uso real de una app.
  String? pick(List<String> pool, int i, {required int every}) =>
      i % every == 0 ? pool[(i ~/ every) % pool.length] : null;
}
