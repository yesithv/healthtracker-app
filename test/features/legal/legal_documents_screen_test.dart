import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/legal/legal_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/features/legal/presentation/screens/legal_documents_screen.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// La pantalla de los términos, en su modo difícil: el de puerta.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientSession.instance.save(publicId: 'p-1', token: 'tok-123');
  });

  /// Sirve los documentos y anota los POST de aceptación.
  ({http.Client client, List<String> accepted}) server({
    bool translated = true,
    int acceptStatus = 204,
  }) {
    final accepted = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        final enviado = jsonDecode(request.body) as Map<String, dynamic>;
        accepted.add(enviado['version'] as String);
        return http.Response('', acceptStatus);
      }
      final document = request.url.pathSegments.last;
      return http.Response(
        jsonEncode({
          'document': document,
          'version': '2026-08',
          'locale': translated ? 'es' : 'es',
          'translated': translated,
          'body': '# Título de $document\n\nUn párrafo con **negrita**.',
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    return (client: client, accepted: accepted);
  }

  Future<GoRouter> pumpGate(
    WidgetTester tester,
    http.Client client, {
    bool mustAccept = true,
  }) async {
    final router = GoRouter(
      initialLocation: '/terminos',
      routes: [
        GoRoute(
          path: '/terminos',
          builder: (_, _) => LegalDocumentsScreen(
            mustAccept: mustAccept,
            client: LegalApiClient(httpClient: client),
          ),
        ),
        GoRoute(path: '/dashboard', builder: (_, _) => const Text('DASHBOARD')),
        GoRoute(path: '/welcome', builder: (_, _) => const Text('WELCOME')),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('enseña el documento que sirve el servidor', (tester) async {
    await pumpGate(tester, server().client);

    expect(find.textContaining('Título de terms'), findsOneWidget);
    expect(find.textContaining('negrita'), findsOneWidget);
  });

  testWidgets('aceptar manda la versión del texto leído y entra', (
    tester,
  ) async {
    final s = server();
    final router = await pumpGate(tester, s.client);

    await tester.tap(find.text('Acepto'));
    await tester.pumpAndSettle();

    // La versión NO es una constante de la app: es la del documento servido.
    expect(s.accepted, ['2026-08']);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/dashboard');
  });

  testWidgets('si el servidor rechaza la aceptación, no se entra', (
    tester,
  ) async {
    // Entrar de todos modos dejaría al paciente dentro creyendo que aceptó algo
    // que no quedó escrito en ninguna parte.
    final s = server(acceptStatus: 409);
    final router = await pumpGate(tester, s.client);

    await tester.tap(find.text('Acepto'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/terminos');
    expect(find.text('DASHBOARD'), findsNothing);
  });

  testWidgets('el botón atrás del sistema no es una puerta trasera', (
    tester,
  ) async {
    // Sin esto bastaría pulsar atrás para entrar sin aceptar nada.
    final router = await pumpGate(tester, server().client);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/terminos');
  });

  testWidgets('en modo lectura no se pide aceptar nada', (tester) async {
    // Desde Ajustes o desde la casilla del alta: se lee y se sale.
    await pumpGate(tester, server().client, mustAccept: false);

    expect(find.text('Acepto'), findsNothing);
  });

  testWidgets('un documento sin traducir lo dice antes del texto', (
    tester,
  ) async {
    await pumpGate(tester, server(translated: false).client);

    expect(find.textContaining('Todavía no hay traducción'), findsOneWidget);
  });

  testWidgets('sin poder leer el texto no hay nada que aceptar', (
    tester,
  ) async {
    await pumpGate(tester, MockClient((_) async => http.Response('', 503)));

    expect(find.text('Reintentar'), findsOneWidget);
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
  });
}
