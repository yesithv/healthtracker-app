import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_dataset.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_mode.dart';

/// Deja la app lista para que la fotografíen: preferencias, perfil, ajustes y
/// dos años de mediciones, todo puesto antes del primer frame.
///
/// **Qué escribe y dónde.** Nada aterriza en la instalación real:
///
/// - Las preferencias van a un almacén EN MEMORIA
///   ([SharedPreferences.setMockInitialValues]). Al cerrar la app se evaporan,
///   y mientras tanto se comportan como las de verdad: los ajustes que se
///   toquen durante la demo funcionan y se ven, simplemente no sobreviven.
/// - Las mediciones van a `my-vitals-demo.db`, un archivo aparte del de
///   producción (ver [DatabaseService]), que se vacía y se vuelve a llenar en
///   cada arranque.
///
/// De ahí que la demo sea idempotente y desechable: arrancarla diez veces deja
/// el mismo estado diez veces, y desinstalarla no deja rastro.
class DemoSeeder {
  const DemoSeeder._();

  /// Identidad ficticia del personaje. `example.com` está reservado por la RFC
  /// 2606 justo para esto: no es —ni puede llegar a ser— el correo de nadie.
  static const String demoName = 'Daniel Ospina';
  static const String demoEmail = 'daniel.ospina@example.com';
  static const String demoPhone = '3128840719';
  static const String demoCountry = 'CO';

  /// Siembra todo. Llamar en `main()` ANTES de tocar nada más: las preferencias
  /// tienen que estar en su sitio antes de que cualquier provider o store las
  /// lea, o cada uno se quedará con lo que hubiera en disco.
  static Future<void> install() async {
    if (!kDemoMode) return;
    await _seedPreferences();
    await _seedRecords();
  }

  // ── Preferencias, perfil y ajustes ───────────────────────────────────────

  static Future<void> _seedPreferences() async {
    final values = demoPreferences();

    final avatar = await _monogramAvatar('DO');
    if (avatar != null) values['user_profile_image'] = avatar;

    // A partir de aquí, `SharedPreferences.getInstance()` devuelve este mapa y
    // toda escritura se queda en RAM. Es una utilidad marcada para pruebas y se
    // usa a propósito: es exactamente el «que no persista nada» que pide la
    // demo, y el compilador ya ha borrado esta rama en una build normal.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues(values);
  }

  /// El estado con el que arranca la demo, en forma de preferencias.
  ///
  /// Las CLAVES van escritas a mano porque cada provider guarda las suyas en
  /// constantes privadas, y eso es frágil: si alguien renombra una, la demo
  /// arrancaría medio vacía sin que nada se queje. Por eso este mapa se expone —
  /// `test/core/demo/demo_seeder_test.dart` levanta los providers de verdad
  /// sobre él y comprueba que cada uno encuentra lo suyo.
  @visibleForTesting
  static Map<String, Object> demoPreferences() {
    final birthDate = DateTime(1984, 3, 12);

    return <String, Object>{
      // Perfil.
      'user_name': demoName,
      'user_email': demoEmail,
      'user_birth_date': birthDate.toIso8601String(),
      'user_gender': 'male',
      'user_activity_level': 'moderate',
      'user_phone': demoPhone,
      'user_country': demoCountry,
      'user_biometric_enabled': false,
      'default_device_name': demoDeviceName,

      // Idioma, unidades y tema, todos gobernados por `--dart-define` para
      // poder repetir la misma captura en otro idioma o con el otro tema.
      'user_language': kDemoLanguage,
      'user_measurement_unit': kDemoUnits,
      'app_theme_id': kDemoTheme,

      // Báscula de bioimpedancia: elegida, y sin nada pendiente de subir.
      'measuring_device_code': 'OMRON_HBF514C',
      'measuring_device_name': demoDeviceName,
      'measuring_device_chosen': true,
      'measuring_device_pending_sync': false,

      // Objetivos de salud. Deliberadamente MIXTOS: el peso sigue en curso
      // (faltan ~1,8 kg) y la grasa corporal ya está cumplida, para que una
      // sola captura del panel enseñe los dos estados de la interfaz de metas.
      'medical_goals_enabled': true,
      'target_weight': 75.0,
      'target_body_fat': 22.0,
      'target_muscle_mass': 27.0,
      'target_visceral_fat': 8,

      // Recordatorios: dos encendidos y dos apagados, que es como se ve una
      // pantalla de ajustes usada de verdad.
      'user_reminders': jsonEncode([
        {
          'id': 'r1',
          'translationKey': 'reminderVitals',
          'hour': 7,
          'minute': 0,
          'isEnabled': true,
        },
        {
          'id': 'r2',
          'translationKey': 'reminderMeds',
          'hour': 13,
          'minute': 30,
          'isEnabled': true,
        },
        {
          'id': 'r3',
          'translationKey': 'reminderWorkout',
          'hour': 18,
          'minute': 15,
          'isEnabled': false,
        },
        {
          'id': 'r4',
          'translationKey': 'reminderWater',
          'hour': 10,
          'minute': 0,
          'isEnabled': true,
        },
      ]),

      // Asistente de alta ya superado y sesión activa: la app entra directa al
      // panel sin pasar por la portada ni por el registro.
      'onboarding_complete': true,
      'session_patient_public_id': 'demo-0000-0000-0000-000000000001',
      'session_patient_first_name': 'Daniel',
      'session_patient_last_name': 'Ospina',
      'session_patient_source': 'APP',
    };
  }

  /// Dibuja un avatar de monograma y lo devuelve en base64 (PNG).
  ///
  /// La alternativa era versionar una foto de archivo, que en una web de
  /// portafolio plantea de quién es esa cara. Un monograma no retrata a nadie
  /// y pesa unos 2 KB. Si el dibujo fallara, se devuelve `null` y la tarjeta
  /// del panel cae a su icono de siempre: la demo no se cae por un avatar.
  static Future<String?> _monogramAvatar(String initials) async {
    try {
      const size = 256.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Degradado diagonal en el azul de la marca.
      final rect = const Rect.fromLTWH(0, 0, size, size);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A5F), Color(0xFF2E7D9A)],
          ).createShader(rect),
      );

      final painter = TextPainter(
        text: TextSpan(
          text: initials,
          style: const TextStyle(
            color: Color(0xFFF2F6F9),
            fontSize: 112,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset((size - painter.width) / 2, (size - painter.height) / 2),
      );

      final image = await recorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return null;
      return base64Encode(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Demo: no se pudo generar el avatar ($e).');
      return null;
    }
  }

  // ── Mediciones ───────────────────────────────────────────────────────────

  static const List<String> _tables = [
    'anthropometric_records',
    'vital_sign_records',
    'lipid_records',
    'body_composition_records',
  ];

  static Future<void> _seedRecords() async {
    final db = await DatabaseService.instance.database;
    final data = buildDemoDataset(language: kDemoLanguage);

    // Vaciar y volver a llenar, en un solo lote. Sin el `batch` serían ~630
    // transacciones sueltas y el arranque de la demo se notaría; con él, la
    // siembra entera es un parpadeo.
    final batch = db.batch();
    for (final table in _tables) {
      batch.delete(table);
    }
    for (final r in data.anthropometric) {
      batch.insert('anthropometric_records', r.toMap());
    }
    for (final r in data.vitalSigns) {
      batch.insert('vital_sign_records', r.toMap());
    }
    for (final r in data.lipids) {
      batch.insert('lipid_records', r.toMap());
    }
    for (final r in data.bodyComposition) {
      batch.insert('body_composition_records', r.toMap());
    }
    await batch.commit(noResult: true);

    debugPrint(
      'Demo: sembrados ${data.totalRecords} registros '
      '(${data.anthropometric.length} antropometría, '
      '${data.vitalSigns.length} signos vitales, '
      '${data.lipids.length} lípidos, '
      '${data.bodyComposition.length} composición corporal).',
    );
  }
}
