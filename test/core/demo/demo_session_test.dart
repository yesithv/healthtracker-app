import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';

/// La promesa de la demo es que salir devuelve todo como estaba, y esa promesa
/// se apoya entera en un viaje por JSON: al entrar se serializan las
/// preferencias del usuario, al salir se vuelven a escribir.
///
/// Ahí hay una trampa concreta. `SharedPreferences` distingue `int` de `double`,
/// y JSON no del todo: si un `75.0` volviera como `int`, la vuelta atrás
/// escribiría el tipo equivocado y el objetivo de peso del usuario reaparecería
/// roto —o directamente lanzaría al leerse—. Estas pruebas fijan ese contrato.
void main() {
  group('la copia de seguridad de la demo va y vuelve ·', () {
    test('conserva el tipo de cada preferencia', () {
      final original = <String, Object>{
        'user_name': 'Ana Restrepo',
        'medical_goals_enabled': true,
        'target_visceral_fat': 8,
        'target_weight': 75.0,
        'user_language': 'pt',
      };

      final restored = DemoSession.decodeBackup(jsonEncode(original));

      expect(restored['user_name'], isA<String>());
      expect(restored['medical_goals_enabled'], isA<bool>());
      expect(
        restored['target_visceral_fat'],
        isA<int>(),
        reason: 'Un entero no puede volver como double',
      );
      expect(
        restored['target_weight'],
        isA<double>(),
        reason: 'Un 75.0 no puede volver como int: prefs lo rechazaría',
      );
      expect(restored, original);
    });

    test('un usuario sin nada guardado no rompe la vuelta', () {
      // Caso real y frecuente: alguien que abre la app por primera vez y toca
      // directamente «ver la demostración». No hay nada que rebobinar.
      expect(DemoSession.decodeBackup(jsonEncode(<String, Object>{})), isEmpty);
    });

    test('sobrevive a acentos y a listas de cadenas', () {
      final original = <String, Object>{
        'user_name': 'José Ibáñez',
        'algo_lista': <String>['uno', 'dos'],
      };
      final restored = DemoSession.decodeBackup(jsonEncode(original));

      expect(restored['user_name'], 'José Ibáñez');
      expect(restored['algo_lista'], isA<List<dynamic>>());
    });
  });

  test('la demo arranca apagada', () {
    // Si el interruptor viniera encendido de fábrica, la app entera se
    // comportaría como una demo: sin sincronizar, contra otra base de datos y
    // con un aviso permanente en pantalla.
    expect(DemoSession.instance.isActive, isFalse);
  });
}
