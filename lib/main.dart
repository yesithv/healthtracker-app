import 'dart:async';

import 'package:flutter/gestures.dart';
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
import 'package:myvitals_healthtracker_app/features/medications/data/repositories/medication_repositories.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/sync/sync_service.dart';
import 'package:myvitals_healthtracker_app/core/demo/demo_session.dart';

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

      // 0. MODO DEMOSTRACIÓN. Va PRIMERO, y no por capricho: decide QUÉ base de
      // datos hay que abrir, y el paso 1 ya la abre. Si el visitante dejó la
      // demo activa y recargó la página, esto la restituye.
      try {
        await DemoSession.instance.bootstrap();
      } catch (e, st) {
        debugPrint('=== DEMO BOOTSTRAP ERROR: $e\n$st');
      }

      // 1. SQLite / sqflite database initialization
      try {
        await DatabaseService.instance.database;
      } catch (e, st) {
        debugPrint('=== DATABASE INIT ERROR: $e\n$st');
        // Non-fatal on web – app continues without pre-warmed DB
      }

      // 2. Notifications (already guarded with kIsWeb inside)
      String? notificationLaunchPayload;
      try {
        await NotificationService().init();
        // Deep-link: enruta el toque de una notificación a su pantalla según el
        // prefijo del payload (`dose`/`inventory` → medicamentos; `appointment`
        // → citas). Lo fijan MedicationScheduler y AppointmentScheduler.
        NotificationService.onNotificationTap = _handleNotificationTap;
        // Si la app se abrió tocando una notificación (arranque en frío), el
        // `initialize` no dispara el callback para ese toque; se recupera aquí
        // y se enruta tras el primer frame (cuando el router ya está montado).
        notificationLaunchPayload = await NotificationService().launchPayload();
      } catch (e, st) {
        debugPrint('=== NOTIFICATION INIT ERROR: $e\n$st');
      }

      // 3. Restore the patient session (identity used to sync with the API).
      try {
        await PatientSession.instance.load();
      } catch (e, st) {
        debugPrint('=== SESSION LOAD ERROR: $e\n$st');
      }

      // 3b. Alta que quedó pendiente de crear por falta de red. Se lee junto a
      // la sesión porque la puerta de arranque necesita las dos cosas.
      try {
        await PendingAccountStore.instance.load();
      } catch (e, st) {
        debugPrint('=== PENDING ACCOUNT LOAD ERROR: $e\n$st');
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
            // Módulo de medicamentos: maestro + pauta/inventario, horas de toma
            // y eventos de toma. Mismos singletons de por vida que el resto de
            // repositorios; las pantallas los `watch` para refrescarse.
            ChangeNotifierProvider<MedicationRepository>.value(
              value: MedicationRepository.instance,
            ),
            ChangeNotifierProvider<MedicationDoseRepository>.value(
              value: MedicationDoseRepository.instance,
            ),
            ChangeNotifierProvider<MedicationLogRepository>.value(
              value: MedicationLogRepository.instance,
            ),
            // Orquestador del módulo: las pantallas registran tomas, editan la
            // pauta y recargan inventario a través de él (descuento de stock y
            // reprogramación de avisos incluidos).
            ChangeNotifierProvider<MedicationsController>(
              create: (_) => MedicationsController(),
            ),
            // Inventario de citas médicas: mismo singleton de por vida que el
            // resto de repositorios; las pantallas lo `watch` para refrescarse.
            ChangeNotifierProvider<AppointmentRepository>.value(
              value: AppointmentRepository.instance,
            ),
            // Orquestador del inventario de citas: las pantallas crean, agendan y
            // confirman citas a través de él (reprogramación de avisos incluida).
            ChangeNotifierProvider<AppointmentsController>(
              create: (_) => AppointmentsController(),
            ),
            // Sesión del paciente (identidad para sincronizar con la API).
            ChangeNotifierProvider<PatientSession>.value(
              value: PatientSession.instance,
            ),
            // Demostración: la cáscara observa esto para pintar (o quitar) el
            // aviso permanente y la salida.
            ChangeNotifierProvider<DemoSession>.value(
              value: DemoSession.instance,
            ),
            // Alta diferida: la UI reacciona para avisar de que la cuenta aún
            // no existe en el servidor.
            ChangeNotifierProvider<PendingAccountStore>.value(
              value: PendingAccountStore.instance,
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

      // Arranque en frío desde una notificación: una vez montado el primer
      // frame (y con él el router), hace el deep-link al payload recuperado.
      if (notificationLaunchPayload != null) {
        final payload = notificationLaunchPayload;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _handleNotificationTap(payload),
        );
      }
    },
    (Object error, StackTrace stack) {
      // Catches ALL unhandled async errors that would silently crash the app
      debugPrint('=== UNHANDLED ASYNC ERROR ===');
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

/// Enruta el toque de CUALQUIER notificación a su pantalla según el prefijo del
/// payload. Lo fijan [MedicationScheduler] (`dose|medId|iso` / `inventory|medId`)
/// y [AppointmentScheduler] (`appointment|id|kind`). Usa el router global
/// directamente porque el toque llega fuera del árbol de widgets (callback del
/// plugin de notificaciones), sin `BuildContext`.
void _handleNotificationTap(String payload) {
  final parts = payload.split('|');
  if (parts.isEmpty) return;
  switch (parts.first) {
    case 'dose':
      // La toma: a la vista «Hoy», que ya muestra la dosis pendiente lista para
      // registrar (no hace falta transportar la dosis concreta por la ruta).
      AppRouter.router.push('/profile/medications/today');
    case 'inventory':
      final medId = parts.length > 1 ? parts[1] : '';
      AppRouter.router.push('/profile/medications/refill?med=$medId');
    case 'appointment':
      // Cualquier aviso de cita (agendada, por sacar o vencida) abre el
      // inventario, donde el usuario confirma o agenda desde la propia lista.
      AppRouter.router.push('/profile/appointments');
  }
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
      // En web/escritorio Flutter deshabilita el arrastre con mouse en los
      // scrollables por defecto; lo habilitamos para que las listas horizontales
      // (p. ej. Nivel de actividad) se puedan desplazar con el mouse. En móvil el
      // gesto táctil ya funcionaba.
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: AppRouter.router,
      // Envuelve todas las rutas para gobernar el ciclo de vida de los avisos de
      // medicamentos: se ejecuta por debajo de Localizations (tiene idioma) y de
      // los Provider (tiene el controlador).
      builder: (context, child) =>
          _NotificationsLifecycle(child: child ?? const SizedBox.shrink()),
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

/// Gobierna el ciclo de vida de las notificaciones de medicamentos Y de citas:
/// fija los textos localizados y reprograma la ventana móvil de avisos **al
/// arrancar** y **al volver del segundo plano**. Es necesario porque los
/// planificadores solo materializan una ventana finita por delante: sin esta
/// pasada, si el usuario no toca los módulos durante ese tiempo, los avisos se
/// agotarían. Vive por debajo de `MaterialApp` para tener idioma (Localizations)
/// y controladores (Provider).
class _NotificationsLifecycle extends StatefulWidget {
  const _NotificationsLifecycle({required this.child});

  final Widget child;

  @override
  State<_NotificationsLifecycle> createState() =>
      _NotificationsLifecycleState();
}

class _NotificationsLifecycleState extends State<_NotificationsLifecycle>
    with WidgetsBindingObserver {
  bool _didInitialReschedule = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didInitialReschedule) return;
      _didInitialReschedule = true;
      _syncNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver del segundo plano se rellena la ventana móvil de avisos.
    if (state == AppLifecycleState.resumed && _didInitialReschedule) {
      _syncNotifications();
    }
  }

  /// Fija los textos localizados (con el idioma activo) y reprograma. Se hace en
  /// este orden para que un reschedule de arranque no salga con los textos por
  /// defecto en español. No-op efectivo en web (el planificador se protege solo).
  void _syncNotifications() {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return;
    context.read<MedicationsController>()
      ..setNotificationTextBuilders(
        doseText: (med, dose) => (
          title: l10n.medicationDoseNotifTitle(med.name),
          body: l10n.medicationDoseNotifBody,
        ),
        inventoryText: (med) => (
          title: l10n.medicationRefillNotifTitle(med.name),
          body: l10n.medicationRefillNotifBody,
        ),
      )
      // Asegura que los repositorios están cargados antes de reprogramar: hacerlo
      // con la caché vacía cancelaría los avisos existentes sin volver a crearlos.
      ..refreshAndReschedule();

    // Mismo ciclo para el inventario de citas: textos localizados + reprograma.
    context.read<AppointmentsController>()
      ..setNotificationTextBuilders(
        scheduledText: (a) => (
          title: l10n.apptScheduledNotifTitle(a.title),
          body: l10n.apptScheduledNotifBody,
        ),
        toBookText: (a) => (
          title: l10n.apptToBookNotifTitle(a.title),
          body: l10n.apptToBookNotifBody,
        ),
        overdueText: (a) => (
          title: l10n.apptOverdueNotifTitle(a.title),
          body: l10n.apptOverdueNotifBody,
        ),
      )
      ..refreshAndReschedule();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Permite arrastrar los scrollables con mouse y trackpad (además del táctil), para
/// que en la web/escritorio se puedan desplazar las listas —notablemente las filas
/// horizontales— igual que en el móvil.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
