import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/user_profile_provider.dart';
import 'core/providers/reminders_provider.dart';
import 'core/providers/health_goals_provider.dart';
import 'core/providers/onboarding_provider.dart';
import 'core/providers/ui_preferences_provider.dart';
import 'core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:myvitals_healthtracker_app/core/database/record_repositories.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';

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

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => RemindersProvider()),
            ChangeNotifierProvider(create: (_) => HealthGoalsProvider()),
            ChangeNotifierProvider(create: (_) => OnboardingProvider()),
            ChangeNotifierProvider(create: (_) => UIPreferencesProvider()),
            ChangeNotifierProvider(create: (_) => LocaleUnitsProvider()),
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

    return MaterialApp.router(
      title: 'My Vitals',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
