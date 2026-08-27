import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verifica el ALTA DIFERIDA: qué pasa cuando el usuario se registra sin red.
///
/// Lo que se prueba no es «se llama a register», sino la decisión que sostiene la
/// función: **un corte de red no es lo mismo que un dato rechazado**. Si esa
/// distinción se rompe, o el alta quedaría pendiente para siempre con un correo
/// duplicado, o un simple corte de red echaría al usuario con sus datos ya
/// escritos.
void main() {
  // Sin el binding, el canal de plataforma de SharedPreferences no responde y
  // `UserProfileProvider.ready` no se completa nunca.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.clear();
    await PendingAccountStore.instance.clear();
  });

  /// Borrador con lo mínimo para poder registrar.
  AccountDraft draftWithEmail(String email) => AccountDraft(
    firstName: 'Lucía Márquez',
    email: email,
    birthDate: DateTime(1987, 3, 14),
    sex: 'female',
    countryIso: 'ES',
  );

  /// Cliente que responde siempre lo mismo, sin tocar la red.
  AuthApiClient clientThat({int? status, String body = '{}', Object? throws}) {
    return AuthApiClient(
      httpClient: MockClient((_) async {
        if (throws != null) throw throws;
        return http.Response(body, status!);
      }),
    );
  }

  group('sin nada pendiente ·', () {
    test('no intenta nada', () async {
      final draft = draftWithEmail('lucia@correo.com');
      final r = await flushPendingAccount(draft);
      expect(r.outcome, PendingAccountOutcome.nothingToDo);
    });
  });

  group('con el alta pendiente ·', () {
    setUp(PendingAccountStore.instance.markPending);

    test('sin conexión: sigue pendiente y NO crea sesión', () async {
      final draft = draftWithEmail('lucia@correo.com');

      final r = await flushPendingAccount(
        draft,
        client: clientThat(throws: const SocketExceptionStub()),
      );

      expect(r.outcome, PendingAccountOutcome.stillOffline);
      expect(
        PendingAccountStore.instance.isPending,
        isTrue,
        reason: 'Un corte de red no debe descartar el alta',
      );
      expect(PatientSession.instance.isAuthenticated, isFalse);
    });

    test('servidor caído (5xx): también se considera reintentable', () async {
      final draft = draftWithEmail('lucia@correo.com');

      final r = await flushPendingAccount(
        draft,
        client: clientThat(status: 503, body: '{"detail":"Service down"}'),
      );

      expect(
        r.outcome,
        PendingAccountOutcome.stillOffline,
        reason: 'Con los servicios caídos hay que reintentar, no rechazar',
      );
      expect(PendingAccountStore.instance.isPending, isTrue);
    });

    test('servidor rechaza el dato (4xx): NO es reintentable', () async {
      final draft = draftWithEmail('duplicado@correo.com');

      final r = await flushPendingAccount(
        draft,
        client: clientThat(
          status: 409,
          body: '{"detail":"Ese correo ya tiene cuenta."}',
        ),
      );

      expect(r.outcome, PendingAccountOutcome.rejected);
      expect(r.message, contains('ya tiene cuenta'));
      expect(
        PendingAccountStore.instance.isPending,
        isTrue,
        reason:
            'Sigue pendiente para que el usuario no quede fuera, pero marcado '
            'como rechazado para que corrija el dato',
      );
      expect(PatientSession.instance.isAuthenticated, isFalse);
    });

    test('éxito: crea la sesión y deja de estar pendiente', () async {
      final draft = draftWithEmail('lucia@correo.com');

      final r = await flushPendingAccount(
        draft,
        client: clientThat(
          status: 201,
          body: jsonEncode({
            'publicId': 'pub-123',
            'firstName': 'Lucía',
            'source': 'APP',
          }),
        ),
      );

      expect(r.outcome, PendingAccountOutcome.created);
      expect(PendingAccountStore.instance.isPending, isFalse);
      expect(PatientSession.instance.publicId, 'pub-123');
      // El alta crea la cuenta, pero NO abre sesión: quien autentica es el código que la
      // clínica dicta por teléfono, y el registro no lo emite. Hasta que exista un
      // autorregistro con verificación propia, un paciente nuevo queda con su ficha
      // creada y sin poder sincronizar.
      expect(PatientSession.instance.isAuthenticated, isFalse);
    });

    test('sin correo: no se puede registrar y se avisa', () async {
      final draft = draftWithEmail('');

      final r = await flushPendingAccount(
        draft,
        client: clientThat(status: 201),
      );

      expect(r.outcome, PendingAccountOutcome.rejected);
      expect(PendingAccountStore.instance.isPending, isTrue);
    });
  });

  group('el estado sobrevive al reinicio ·', () {
    test('load() recupera el alta pendiente y su motivo', () async {
      await PendingAccountStore.instance.markPending(reason: 'Sin conexión');
      // Simula un arranque limpio releyendo del almacén persistido.
      await PendingAccountStore.instance.load();

      expect(PendingAccountStore.instance.isPending, isTrue);
      expect(PendingAccountStore.instance.lastError, 'Sin conexión');
    });
  });
}

/// Sustituto de `SocketException` sin importar `dart:io`, para que la prueba
/// corra igual en cualquier plataforma.
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketException: sin conexión';
}
