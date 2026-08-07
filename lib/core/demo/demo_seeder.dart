import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_dataset.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_mode.dart';

/// El contenido de la demostración: qué perfil, qué ajustes y qué registros.
///
/// Aquí sólo se decide QUÉ se siembra. El CUÁNDO —y, sobre todo, cómo se
/// deshace— es de `DemoSession`, que envuelve todo esto en una copia de
/// seguridad y una base de datos aparte. Separarlo así deja este archivo
/// razonable de leer: es la descripción de un personaje, no una máquina de
/// estados.
class DemoSeeder {
  const DemoSeeder._();

  /// Identidad ficticia del personaje. `example.com` está reservado por la RFC
  /// 2606 justo para esto: no es —ni puede llegar a ser— el correo de nadie.
  static const String demoName = 'Camila Herrera';
  static const String demoEmail = 'camila.herrera@example.com';
  static const String demoPhone = '3128840719';
  static const String demoCountry = 'CO';

  /// El estado con el que arranca la demo, en forma de preferencias.
  ///
  /// Las CLAVES van escritas a mano porque cada provider guarda las suyas en
  /// constantes privadas, y eso es frágil: si alguien renombra una, la demo
  /// arrancaría medio vacía sin que nada se queje. Por eso este mapa se expone —
  /// `test/core/demo/demo_seeder_test.dart` levanta los providers de verdad
  /// sobre él y comprueba que cada uno encuentra lo suyo.
  ///
  /// [overrideAppearance] añade idioma, unidades y tema. Sólo lo pide el
  /// arranque guionizado de las capturas: al entrar desde la portada, la demo
  /// tiene que verse con el idioma y el tema que el visitante ya tenía.
  static Map<String, Object> demoPreferences({
    bool overrideAppearance = false,
  }) {
    final birthDate = DateTime(1990, 5, 22);

    return <String, Object>{
      // Perfil.
      'user_name': demoName,
      'user_email': demoEmail,
      'user_birth_date': birthDate.toIso8601String(),
      'user_gender': 'female',
      // Debe ser una de las claves que reconoce la pantalla de Información
      // personal (sedentary · lightly_active · moderately_active · very_active ·
      // extra_active). Un valor fuera de ese juego —como el antiguo 'moderate'—
      // no casa con ninguna opción, así que el nivel de actividad se enseñaba
      // como si no estuviera puesto.
      'user_activity_level': 'moderately_active',
      'user_phone': demoPhone,
      'user_country': demoCountry,
      // El bloqueo biométrico se deja APAGADO a propósito: pediría huella antes
      // de dejar ver el panel, justo a quien viene a echar un vistazo.
      'user_biometric_enabled': false,
      'default_device_name': demoDeviceName,

      // Báscula de bioimpedancia: elegida, y sin nada pendiente de subir.
      'measuring_device_code': 'OMRON_HBF514C',
      'measuring_device_name': demoDeviceName,
      'measuring_device_chosen': true,
      'measuring_device_pending_sync': false,

      // Objetivos de salud. Deliberadamente MIXTOS: el peso sigue en curso
      // (faltan ~1,5 kg) y la grasa corporal ya está cumplida, para que una sola
      // pantalla enseñe los dos estados de la interfaz de metas.
      'medical_goals_enabled': true,
      'target_weight': 62.0,
      'target_body_fat': 27.0,
      'target_muscle_mass': 19.0,
      'target_visceral_fat': 6,

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

      // Asistente de alta ya superado y sesión activa: la demo entra directa al
      // panel sin pasar por el registro.
      'onboarding_complete': true,
      'session_patient_public_id': 'demo-0000-0000-0000-000000000001',
      'session_patient_first_name': 'Camila',
      'session_patient_last_name': 'Herrera',
      'session_patient_source': 'APP',

      // Sólo para capturas guionizadas (ver `demo_mode.dart`).
      if (overrideAppearance && kDemoLanguage.isNotEmpty)
        'user_language': kDemoLanguage,
      if (overrideAppearance && kDemoUnits.isNotEmpty)
        'user_measurement_unit': kDemoUnits,
      if (overrideAppearance && kDemoTheme.isNotEmpty)
        'app_theme_id': kDemoTheme,
    };
  }

  /// Ruta del asset donde puede vivir una foto de perfil real para la demo.
  ///
  /// Si el archivo existe en el bundle, [demoAvatar] lo usa tal cual; si no,
  /// cae a un retrato ilustrado. Así, dejar caer un JPEG cuadrado en esa ruta
  /// —una foto de banco con licencia libre, por ejemplo— cambia el avatar de la
  /// demo sin tocar una línea de código.
  static const String avatarAssetPath = 'assets/demo/demo_avatar.jpg';

  /// El avatar con el que arranca la demo, en base64.
  ///
  /// Tres peldaños, de más a menos concreto, para que la demo tenga cara sin
  /// depender de la red ni caerse si algo falla:
  ///
  /// 1. **Una foto real** en [avatarAssetPath], si está versionada en el bundle.
  ///    Es lo que se enseña en cuanto haya una foto de banco con licencia libre.
  /// 2. **Un retrato ilustrado** dibujado aquí mismo: no es la cara de nadie
  ///    real, pesa unos pocos KB y sale idéntico en cada arranque.
  /// 3. **Un monograma** con las iniciales, como última red.
  ///
  /// Si los tres fallaran devuelve `null` y la tarjeta del panel cae a su icono
  /// de siempre: la demo no se cae por un avatar.
  static Future<String?> demoAvatar() async {
    final photo = await _assetAvatar();
    if (photo != null) return photo;

    final illustration = await illustratedAvatar();
    if (illustration != null) return illustration;

    return monogramAvatar();
  }

  /// Lee la foto de [avatarAssetPath] del bundle y la devuelve en base64, o
  /// `null` si no está versionada (el caso normal hasta que se añada una).
  static Future<String?> _assetAvatar() async {
    try {
      final data = await rootBundle.load(avatarAssetPath);
      if (data.lengthInBytes == 0) return null;
      return base64Encode(data.buffer.asUint8List());
    } catch (_) {
      // Sin foto en el bundle: es el camino esperado, no un error que reportar.
      return null;
    }
  }

  /// Dibuja un retrato ilustrado —cabello, rostro y hombros sobre un degradado
  /// de marca— y lo devuelve en base64 (PNG). No retrata a nadie real y, al
  /// generarse por código, sale exactamente igual en cada arranque. Devuelve
  /// `null` si el dibujo fallara.
  static Future<String?> illustratedAvatar() async {
    try {
      const size = 256.0;
      const rect = Rect.fromLTWH(0, 0, size, size);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Fondo de marca.
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D4C9F), Color(0xFFC65B8A)],
          ).createShader(rect),
      );

      const skin = Color(0xFFF3C9A8);
      const hair = Color(0xFF3A2A22);
      const shoulders = Color(0xFFEDE7F2);

      // Recorta al círculo del avatar para que nada asome por las esquinas.
      canvas.clipRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(size)),
      );

      // Hombros/busto: un arco ancho que ancla la figura abajo.
      canvas.drawOval(
        const Rect.fromLTWH(38, 196, 180, 150),
        Paint()..color = shoulders,
      );

      // Melena: por detrás de la cabeza, cae sobre los hombros (lo que hace que
      // el retrato se lea como una mujer sin depender de rasgos concretos).
      canvas.drawOval(
        const Rect.fromLTWH(70, 44, 116, 172),
        Paint()..color = hair,
      );

      // Cuello.
      canvas.drawRect(
        const Rect.fromLTWH(115, 150, 26, 44),
        Paint()..color = skin,
      );

      // Rostro.
      canvas.drawOval(
        const Rect.fromLTWH(86, 66, 84, 104),
        Paint()..color = skin,
      );

      // Flequillo: una tapa de cabello sobre la frente.
      final fringe = Path()
        ..moveTo(86, 112)
        ..quadraticBezierTo(88, 66, 128, 62)
        ..quadraticBezierTo(168, 66, 170, 112)
        ..quadraticBezierTo(150, 86, 128, 88)
        ..quadraticBezierTo(106, 86, 86, 112)
        ..close();
      canvas.drawPath(fringe, Paint()..color = hair);

      // Ojos y sonrisa: apenas insinuados, para no caer en lo caricaturesco.
      final feature = Paint()..color = const Color(0xFF3A2A22);
      canvas.drawOval(const Rect.fromLTWH(106, 116, 12, 8), feature);
      canvas.drawOval(const Rect.fromLTWH(138, 116, 12, 8), feature);
      final smile = Paint()
        ..color = const Color(0xFFB5615E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final mouth = Path()
        ..moveTo(116, 142)
        ..quadraticBezierTo(128, 152, 140, 142);
      canvas.drawPath(mouth, smile);

      final image = await recorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (bytes == null) return null;
      return base64Encode(bytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Demo: no se pudo generar el retrato ilustrado ($e).');
      return null;
    }
  }

  /// Dibuja un avatar de monograma y lo devuelve en base64 (PNG). Es la última
  /// red por debajo de la foto y del retrato ilustrado.
  static Future<String?> monogramAvatar([String initials = 'CH']) async {
    try {
      const size = 256.0;
      const rect = Rect.fromLTWH(0, 0, size, size);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6D4C9F), Color(0xFFC65B8A)],
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

  /// Llena la base de datos activa con los dos años de historia.
  ///
  /// Da por hecho que quien llama ya ha cambiado a la base desechable: sembrar
  /// sobre la real borraría el historial del usuario. Ese contrato lo cumple
  /// `DemoSession.enter()`, que es el único que debería llamar aquí.
  static Future<void> seedRecords({required String language}) async {
    final db = await DatabaseService.instance.database;
    final data = buildDemoDataset(language: language);

    // Vaciar y volver a llenar, en un solo lote. Sin el `batch` serían ~630
    // transacciones sueltas y entrar en la demo se notaría; con él, la siembra
    // entera es un parpadeo.
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

    debugPrint('Demo: sembrados ${data.totalRecords} registros.');
  }

  /// Vacía la base de la demo, incluido lo que el visitante haya registrado él
  /// mismo. Se llama al salir, con la base desechable todavía abierta.
  static Future<void> wipeRecords() async {
    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final table in _tables) {
      batch.delete(table);
    }
    await batch.commit(noResult: true);
  }
}
