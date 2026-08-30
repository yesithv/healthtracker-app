import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/profile/profile_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/widgets/contact_consents_card.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Los canales de contacto, en manos del paciente.
///
/// Hasta ahora los decidía el staff desde el panel: `app.patient_consent`
/// admitía `source = 'APP'` desde la V14 y nadie lo escribía nunca. La persona a
/// la que se llama no tenía dónde decir que no.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.save(publicId: 'p-1', token: 'tok-123');
  });

  /// Devuelve un perfil con los canales pedidos y anota lo que se escribe.
  ({http.Client client, List<Map<String, dynamic>> written}) server({
    bool? phone,
    bool? messages,
    bool? email,
    int saveStatus = 200,
  }) {
    final written = <Map<String, dynamic>>[];
    String perfil() => jsonEncode({
      'identity': {'email': 'maria@example.com'},
      'personal': {'firstName': 'María'},
      'preferences': {'locale': 'es'},
      'consents': {'phone': phone, 'messages': messages, 'email': email},
    });

    final client = MockClient((request) async {
      if (request.method == 'PUT') {
        written.add(jsonDecode(request.body) as Map<String, dynamic>);
        if (saveStatus >= 300) return http.Response('', saveStatus);
      }
      return http.Response(
        perfil(),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    return (client: client, written: written);
  }

  Future<void> pump(WidgetTester tester, http.Client client) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: ContactConsentsCard(
            client: ProfileApiClient(httpClient: client),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un canal que nunca se respondió no se pinta como un «no»', (
    tester,
  ) async {
    await pump(tester, server(phone: true).client);

    // Teléfono contestado; los otros dos, no. Quien no respondió no ha revocado
    // nada, y decir «no consta» evita que crea que ya dijo que sí.
    expect(find.text('Todavía no lo has respondido'), findsNWidgets(2));
  });

  testWidgets('revocar un canal manda ese canal y ninguno más', (tester) async {
    final s = server(phone: true, messages: true, email: true);
    await pump(tester, s.client);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Mandar los tres convertiría abrir esta pantalla en una respuesta que
    // nadie dio; y un canal ausente el servidor lo deja como estaba.
    expect(s.written, hasLength(1));
    expect(s.written.first['consents'], {'phone': false});
  });

  testWidgets('si el servidor no lo guarda, el interruptor vuelve atrás', (
    tester,
  ) async {
    // Dejarlo donde lo puso la persona diría que su revocación quedó guardada.
    final s = server(phone: true, saveStatus: 500);
    await pump(tester, s.client);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final phoneSwitch = tester.widget<Switch>(find.byType(Switch).first);
    expect(phoneSwitch.value, isTrue);
    expect(find.textContaining('No se pudo guardar'), findsOneWidget);
  });
}
