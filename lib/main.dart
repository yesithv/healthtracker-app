import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'core/theme/theme_catalog.dart';
import 'core/router/app_router.dart';
import 'core/providers/user_profile_provider.dart';
import 'core/providers/measuring_device_provider.dart';
import 'core/providers/reminders_provider.dart';
import 'core/providers/health_goals_provider.dart';
import 'core/providers/onboarding_provider.dart';
import 'core/providers/ui_preferences_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/locale_units_provider.dart';
import 'core/providers/discover_provider.dart';
import 'package:myvitals_healthtracker_app/features/discover/data/repositories/discover_repository.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Capture and log all Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('=== FLUTTER ERROR ===');
        debugPrint(details.toString());
      };

      // 1. SQLite / sqflite database initialization
      try {
        await DatabaseService.instance.database;
      } catch (e, st) {
        debugPrint('=== DATABASE INIT ERROR: $e\n$st');
        // Non-fatal on web – app continues without pre-warmed DB
      }

      // 2. Notifications (already guarded with kIsWeb inside)
      try {
        await NotificationService().init();
      } catch (e, st) {
        debugPrint('=== NOTIFICATION INIT ERROR: $e\n$st');
      }

      // 3. Restore the patient session (identity used to sync with the API).
      try {
        await PatientSession.instance.load();
      } catch (e, st) {
        debugPrint('=== SESSION LOAD ERROR: $e\n$st');
      }

      // 4. Rangos de referencia del servidor (fuente de verdad de los semáforos):
      // carga el caché local y se refresca con la sesión. Sin red, los
      // clasificadores usan su fallback de fábrica.
      try {
        await ReferenceRangesStore.instance.init();
      } catch (e, st) {
        debugPrint('=== REFERENCE RANGES INIT ERROR: $e\n$st');
      }

      // 4. Warm the Discover feed cache for the device language so the tab
      // renders instantly (no spinner) the first time the user opens it.
      try {
        final lang =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        await DiscoverRepository.instance.load(lang);
      } catch (e, st) {
        debugPrint('=== DISCOVER WARM ERROR: $e\n$st');
      }

      // 5. Preferencia de tema. Se lee ANTES de `runApp` para que el primer
      // frame ya salga con el tema elegido: cargarla después provocaría un
      // destello del tema por defecto en cada arranque.
      final themeProvider = await ThemeProvider.load();

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => MeasuringDeviceProvider()),
            ChangeNotifierProvider(create: (_) => RemindersProvider()),
            ChangeNotifierProvider(create: (_) => HealthGoalsProvider()),
            ChangeNotifierProvider(create: (_) => OnboardingProvider()),
            ChangeNotifierProvider(create: (_) => UIPreferencesProvider()),
            // Tema activo. `.value` porque ya viene cargado de disco.
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider(create: (_) => LocaleUnitsProvider()),
            // Discover feed: warmed eagerly (lazy:false) so content is ready in
            // memory before the user ever opens the Discover tab.
            ChangeNotifierProvider(
              create: (_) => DiscoverProvider(),
              lazy: false,
            ),
            // Record repositories are app-lifetime singletons; expose them with
            // `.value` so screens can `watch` their cached, reactive lists.
            ChangeNotifierProvider<AnthropometricRepository>.value(
              value: AnthropometricRepository.instance,
            ),
            ChangeNotifierProvider<VitalSignsRepository>.value(
              value: VitalSignsRepository.instance,
            ),
            ChangeNotifierProvider<LipidRepository>.value(
              value: LipidRepository.instance,
            ),
            ChangeNotifierProvider<BodyCompositionRepository>.value(
              value: BodyCompositionRepository.instance,
            ),
            // Sesión del paciente (identidad para sincronizar con la API).
            ChangeNotifierProvider<PatientSession>.value(
              value: PatientSession.instance,
            ),
            // Sincronización bidireccional (app ↔ API). `lazy: false` es OBLIGATORIO:
            // el servicio escucha la sesión y los repositorios para auto-sincronizar
            // (subida tras guardar, bajada tras login); si Provider lo creara perezoso,
            // no existiría hasta abrir la pantalla de cuenta y nada se dispararía.
            ChangeNotifierProvider<SyncService>(
              lazy: false,
              create: (_) => SyncService(
                anthropometric: AnthropometricRepository.instance,
                vitals: VitalSignsRepository.instance,
                lipid: LipidRepository.instance,
                body: BodyCompositionRepository.instance,
              ),
            ),
          ],
          child: const MyVitalsApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      // Catches ALL unhandled async errors that would silently crash the app
      debugPrint('=== UNHANDLED ASYNC ERROR ===');
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class MyVitalsApp extends StatelessWidget {
  const MyVitalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeUnits = Provider.of<LocaleUnitsProvider>(context);
    // Éste es el ÚNICO widget que escucha al tema: al cambiar, sólo se
    // reconstruye desde aquí, y el resto del árbol se repinta por el
    // InheritedWidget de Theme. Ninguna pantalla se suscribe al provider.
    final themeId = context.select<ThemeProvider, AppThemeId>((p) => p.themeId);

    return MaterialApp.router(
      title: 'My Vitals',
      debugShowCheckedModeBanner: false,
      theme: AppThemeCatalog.themeOf(themeId),
      routerConfig: AppRouter.router,
      locale: localeUnits.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
