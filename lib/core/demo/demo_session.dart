import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_mode.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_seeder.dart';

/// ¿Está la app dentro de la demostración, ahora mismo?
///
/// Es el interruptor de verdad del modo demo. Se entra desde la portada y se
/// sale desde dentro, así que no puede ser una constante de compilación: tiene
/// que ser estado vivo que la interfaz pueda observar. Por eso es un
/// [ChangeNotifier] y a la vez un singleton — igual que `PatientSession`, el
/// código que no vive en el árbol de widgets (base de datos, sincronización,
/// clasificadores) necesita consultarlo sin un `BuildContext`.
///
/// ## El trato
///
/// Entrar en la demo no puede destruir nada de quien la abre, y salir tiene que
/// devolverlo todo como estaba. Se sostiene sobre dos garantías:
///
/// 1. **Las preferencias se copian antes de sembrar.** Lo que hubiera —el tema
///    que eligió, su idioma, una alta a medias— se guarda en un único blob y se
///    restaura íntegro al salir. La demo no «limpia» al terminar: rebobina.
/// 2. **Los registros van a otra base de datos.** `my-vitals-demo.db` es un
///    archivo distinto del de producción (ver [DatabaseService]). Entrar cambia
///    de archivo, salir vuelve al de siempre. El historial real no se abre
///    siquiera mientras dura la demo.
///
/// De ahí que el visitante pueda registrar y editar libremente: escribe en una
/// base desechable, y al salir se vacía.
class DemoSession extends ChangeNotifier {
  DemoSession._();
  static final DemoSession instance = DemoSession._();

  /// Que la demo siga activa tiene que sobrevivir a recargar la página: en web
  /// un F5 accidental echaría al visitante de la demo sin haberla dejado.
  static const _kActive = 'demo_active';

  /// Las preferencias de antes de entrar, en JSON. Es la vuelta atrás.
  static const _kBackup = 'demo_prefs_backup';

  bool _active = false;
  bool _pendingNotice = false;

  bool get isActive => _active;

  /// Prepara el estado del demo ANTES de que nadie abra la base de datos.
  ///
  /// El orden importa: [DatabaseService] pregunta qué archivo abrir la primera
  /// vez que alguien le pide la conexión, así que si esto corriera después, la
  /// app abriría la base real y la demo escribiría encima.
  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _active = prefs.getBool(_kActive) ?? false;
    DatabaseService.useDemoDatabase(_active);

    // Arranque guionizado (`--dart-define=DEMO_MODE=true`) sobre una app que no
    // estaba en demo: se entra ahora, con las imposiciones de apariencia que
    // traigan las banderas.
    if (!_active && kDemoAutoStart) {
      await enter(
        languageCode: kDemoLanguage.isEmpty ? null : kDemoLanguage,
        overrideAppearance: kDemoOverridesAppearance,
      );
    }
  }

  /// Entra en la demo: copia lo que había, siembra perfil y ajustes, cambia de
  /// base de datos y la llena con los dos años de historia.
  ///
  /// [languageCode] es el idioma en el que se escriben los comentarios de los
  /// registros, para que la historia se lea en el idioma del visitante. La
  /// interfaz ya se traduce sola; esto es sólo el contenido.
  Future<void> enter({
    String? languageCode,
    bool overrideAppearance = false,
  }) async {
    if (_active) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. La vuelta atrás, ANTES de tocar nada.
    final backup = <String, Object>{};
    for (final key in prefs.getKeys()) {
      final value = prefs.get(key);
      if (value != null) backup[key] = value;
    }
    await prefs.setString(_kBackup, jsonEncode(backup));

    // 2. Perfil, ajustes, objetivos, recordatorios y sesión.
    final seed = DemoSeeder.demoPreferences(
      overrideAppearance: overrideAppearance,
    );
    final avatar = await DemoSeeder.monogramAvatar();
    if (avatar != null) seed['user_profile_image'] = avatar;
    await _writeAll(prefs, seed);
    await prefs.setBool(_kActive, true);

    // 3. La base de datos desechable, sembrada.
    DatabaseService.useDemoDatabase(true);
    await DatabaseService.instance.reopen();
    await DemoSeeder.seedRecords(language: languageCode ?? 'es');
    await _refreshRepositories();

    _active = true;
    // El aviso se enseña una vez, al llegar al panel. No se persiste a
    // propósito: recargar la página no debe volver a interrumpir.
    _pendingNotice = true;
    notifyListeners();
  }

  /// Sale de la demo: vacía lo sembrado, restaura las preferencias de antes y
  /// vuelve a la base de datos real.
  Future<void> exit() async {
    if (!_active) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBackup);

    // 1. Vaciar la base desechable mientras todavía es la que está abierta.
    // Incluye lo que el visitante haya registrado él mismo.
    await DemoSeeder.wipeRecords();

    // 2. Rebobinar las preferencias. Un `clear()` a secas dejaría al usuario sin
    // el tema ni el idioma que tenía antes de curiosear.
    await prefs.clear();
    if (raw != null && raw.isNotEmpty) {
      await _writeAll(prefs, decodeBackup(raw));
    }

    // 3. Volver al archivo de siempre y releer: los repositorios tienen en
    // memoria los registros de la demo y hay que sacárselos.
    DatabaseService.useDemoDatabase(false);
    await DatabaseService.instance.reopen();
    await _refreshRepositories();

    _active = false;
    _pendingNotice = false;
    notifyListeners();
  }

  /// ¿Toca enseñar el aviso de «esto son datos de prueba»? Devuelve `true` una
  /// sola vez por entrada.
  bool consumeNotice() {
    if (!_pendingNotice) return false;
    _pendingNotice = false;
    return true;
  }

  Future<void> _refreshRepositories() async {
    await AnthropometricRepository.instance.refresh();
    await VitalSignsRepository.instance.refresh();
    await LipidRepository.instance.refresh();
    await BodyCompositionRepository.instance.refresh();
  }

  /// Escribe un mapa de preferencias respetando el tipo de cada valor.
  static Future<void> _writeAll(
    SharedPreferences prefs,
    Map<String, Object> values,
  ) async {
    for (final entry in values.entries) {
      switch (entry.value) {
        case final String v:
          await prefs.setString(entry.key, v);
        case final bool v:
          await prefs.setBool(entry.key, v);
        case final int v:
          await prefs.setInt(entry.key, v);
        case final double v:
          await prefs.setDouble(entry.key, v);
        case final List<dynamic> v:
          await prefs.setStringList(entry.key, v.cast<String>());
        default:
          debugPrint('Demo: preferencia de tipo inesperado: ${entry.key}');
      }
    }
  }

  /// Reconstruye la copia de seguridad desde su JSON.
  ///
  /// Es público para las pruebas porque aquí está el único punto donde la vuelta
  /// atrás puede perder algo: JSON no distingue un `int` de un `double` entero, y
  /// `SharedPreferences` sí. Se conserva lo que Dart devuelve —un `75.0` vuelve
  /// como `double` y un `8` como `int`—, que es exactamente lo que se guardó.
  @visibleForTesting
  static Map<String, Object> decodeBackup(String raw) {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      for (final entry in decoded.entries)
        if (entry.value case final Object value) entry.key: value,
    };
  }
}
