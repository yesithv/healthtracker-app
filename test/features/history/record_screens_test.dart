import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/ui_preferences_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_catalog.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/screens/record_anthropometric_screen.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/screens/record_body_composition_screen.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/screens/record_lipid_screen.dart';
import 'package:myvitals_healthtracker_app/features/history/presentation/screens/record_vital_signs_screen.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Las cuatro pantallas donde el paciente escribe: **registrar los cuatro indicadores
/// principales**, que es la funcionalidad central de la app y no tenía ni una prueba.
///
/// Lo que se comprueba es la cadena entera de un guardado: la pantalla se pinta, el
/// botón guarda, y **el registro aparece en su repositorio** —contra SQLite de verdad—.
/// Comprobar solo que se llama a `insert` diría que la pantalla hace lo que creemos;
/// esto dice que el dato queda.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-record-screens.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // La composición corporal lee el perfil, y el perfil busca la foto en el
    // directorio de documentos: en una prueba no hay plugin nativo que responda.
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async =>
          Directory.systemTemp.createTempSync('record_screens').path,
    );
    await AnthropometricRepository.instance.clearAll();
    await VitalSignsRepository.instance.clearAll();
    await LipidRepository.instance.clearAll();
    await BodyCompositionRepository.instance.clearAll();
  });

  /// Monta la pantalla con router propio y **encima de otra**.
  ///
  /// Las cuatro terminan en `context.pop()`, así que hacen falta las dos cosas: sin
  /// GoRouter el guardado revienta justo al final —que es lo que hay que probar—, y sin
  /// una pantalla debajo, cerrarse deja la pila vacía.
  Widget host(Widget screen) {
    final router = GoRouter(
      // Una ruta ANIDADA: al arrancar en ella, GoRouter construye la pila entera
      // («/» debajo, «/registro» encima), así que `context.pop()` tiene a dónde
      // volver. Es también como llega el usuario: desde el historial.
      initialLocation: '/registro',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(),
          routes: [GoRoute(path: 'registro', builder: (_, _) => screen)],
        ),
      ],
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => MeasuringDeviceProvider()),
        ChangeNotifierProvider(create: (_) => UIPreferencesProvider()),
      ],
      child: MaterialApp.router(
        theme: AppThemeCatalog.themeOf(AppThemeId.pulsoClinico),
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  /// El texto del botón de guardar, tal y como lo dice la app en español.
  const guardar = 'Guardar y ganar +10 XP';

  /// Pulsa el botón cuyo texto se indica, dejando que la escritura a SQLite —E/S real—
  /// ocurra fuera del reloj falso de `testWidgets`.
  Future<void> pulsar(WidgetTester tester, String texto) async {
    final boton = find.widgetWithText(ElevatedButton, texto);
    expect(boton, findsOneWidget, reason: 'no se encontró el botón «$texto»');
    await tester.ensureVisible(boton);
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(boton, warnIfMissed: false);
      // Deja correr el guardado real antes de volver al reloj del test.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('signos vitales: guardar deja la toma en su repositorio', (
    tester,
  ) async {
    await tester.pumpWidget(host(const RecordVitalSignsScreen()));
    await tester.pumpAndSettle();

    await pulsar(tester, guardar);

    final saved = await tester.runAsync(VitalSignsRepository.instance.getAll);
    expect(saved, hasLength(1));
    // Los valores por defecto de la pantalla, que es lo que se guardaría sin tocar
    // nada: una toma normal.
    expect(saved!.single.systolic, 120);
    expect(saved.single.diastolic, 80);
    expect(saved.single.heartRate, 72);
    // Nace pendiente de subir: es lo que hace que la sincronización lo recoja.
    expect(saved.single.isSynced, isFalse);
  });

  testWidgets('antropometría: guardar deja el registro con su IMC', (
    tester,
  ) async {
    await tester.pumpWidget(host(const RecordAnthropometricScreen()));
    await tester.pumpAndSettle();

    await pulsar(tester, guardar);

    final saved = await tester.runAsync(
      AnthropometricRepository.instance.getAll,
    );
    expect(saved, hasLength(1));
    expect(saved!.single.weight, greaterThan(0));
    expect(saved.single.height, greaterThan(0));
    // El IMC se calcula en la pantalla; si llegara en cero, el historial pintaría
    // una clasificación falsa.
    expect(saved.single.bmi, greaterThan(0));
  });

  testWidgets('composición corporal: guardar deja el registro', (tester) async {
    await tester.pumpWidget(host(const RecordBodyCompositionScreen()));
    await tester.pumpAndSettle();

    await pulsar(tester, guardar);

    final saved = await tester.runAsync(
      BodyCompositionRepository.instance.getAll,
    );
    expect(saved, hasLength(1));
  });

  testWidgets('lípidos: sin ningún valor no se guarda nada', (tester) async {
    // Un perfil lipídico vacío no es un resultado: guardarlo metería una fecha sin
    // datos en el historial y en la serie que se sube al servidor.
    await tester.pumpWidget(host(const RecordLipidScreen()));
    await tester.pumpAndSettle();

    await pulsar(tester, guardar);

    final saved = await tester.runAsync(LipidRepository.instance.getAll);
    expect(saved, isEmpty);
  });

  testWidgets('lípidos: con un solo valor sí se guarda', (tester) async {
    // Basta uno: un perfil incompleto sigue siendo un resultado de laboratorio.
    await tester.pumpWidget(host(const RecordLipidScreen()));
    await tester.pumpAndSettle();

    final campos = find.byType(TextField);
    expect(campos, findsWidgets);
    await tester.enterText(campos.first, '195');
    await tester.pump();

    await pulsar(tester, guardar);

    final saved = await tester.runAsync(LipidRepository.instance.getAll);
    expect(saved, hasLength(1));
  });
}
