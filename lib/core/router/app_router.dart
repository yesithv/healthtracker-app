import 'package:go_router/go_router.dart';
import '../demo/demo_session.dart';
import '../shell/app_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/history/presentation/screens/history_category_screen.dart';
import '../../features/history/presentation/widgets/anthropometry_history_tab.dart';
import '../../features/history/presentation/widgets/vital_signs_history_tab.dart';
import '../../features/history/presentation/widgets/lipid_history_tab.dart';
import '../../features/history/presentation/widgets/body_composition_history_tab.dart';
import '../../features/discover/presentation/screens/discover_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/language_selection_screen.dart';
import '../../features/profile/presentation/screens/measurement_units_screen.dart';
import '../../features/profile/presentation/screens/personal_info_screen.dart';
import '../../features/profile/presentation/screens/measuring_device_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/history/presentation/screens/record_anthropometric_screen.dart';
import '../../features/history/presentation/screens/record_vital_signs_screen.dart';
import '../../features/history/presentation/screens/record_lipid_screen.dart';
import '../../features/history/presentation/screens/record_body_composition_screen.dart';
import '../../features/profile/presentation/screens/privacy_security_screen.dart';
import '../../features/profile/presentation/screens/health_goals_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/faq_screen.dart';
import '../../features/profile/presentation/screens/glossary_screen.dart';
import '../../features/profile/presentation/screens/legal_screen.dart';
import '../../features/profile/presentation/screens/contact_screen.dart';
import '../../features/profile/presentation/screens/data_backup_screen.dart';
import '../../features/profile/presentation/screens/reminders_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_shell.dart';
import '../../features/account/presentation/screens/account_sync_screen.dart';
import '../../features/welcome/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/verify_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/theming/presentation/screens/theme_picker_screen.dart';
import '../../features/medications/presentation/screens/medications_menu_screen.dart';
import '../../features/medications/presentation/screens/medications_today_screen.dart';
import '../../features/medications/presentation/screens/medication_inventory_screen.dart';
import '../../features/medications/presentation/screens/medication_adherence_screen.dart';
import '../../features/medications/presentation/screens/medication_detail_screen.dart';
import '../../features/medications/presentation/screens/medication_wizard_screen.dart';
import '../../features/medications/presentation/screens/refill_inventory_screen.dart';
import '../../features/history/data/models/anthropometric_record.dart';
import '../../features/history/data/models/vital_sign_record.dart';
import '../../features/history/data/models/lipid_record.dart';
import '../../features/history/data/models/body_composition_record.dart';

class AppRouter {
  static final router = GoRouter(
    // Arrancar con la demo ya activa (porque el visitante recargó la página sin
    // salir de ella) entra directo al panel: la portada y el selector de tema le
    // harían repetir un camino que ya recorrió. El arranque normal no se mueve
    // de la raíz.
    initialLocation: DemoSession.instance.isActive ? '/dashboard' : '/',
    routes: [
      // PANTALLA 0 — selector de tema (temporal, ver ThemePickerScreen).
      // Es la raíz para poder recorrer el flujo entero con cualquiera de los
      // temas. Al reubicarla en Perfil, basta devolver '/' a SplashScreen.
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const ThemePickerScreen(mode: ThemePickerMode.onboarding),
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Portada del flujo real: logotipo, las tres características y los dos
      // caminos de entrada. Es a donde manda el arranque a quien no tiene
      // sesión ni perfil local.
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) {
          // El identificador llega del paso de login; sin él, volver a iniciar sesión.
          final id = state.extra as String?;
          return (id == null || id.isEmpty)
              ? const LoginScreen()
              : VerifyScreen(identifier: id);
        },
      ),
      // Alta de paciente nuevo. Ya no admite parámetro `mode`: el asistente
      // siempre crea la cuenta, porque el modo local se ha eliminado.
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          // Verificación OTP del paciente legacy; sin identificador, volver a login.
          final id = state.extra as String?;
          return (id == null || id.isEmpty)
              ? const LoginScreen()
              : OtpVerifyScreen(identifier: id);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingShell(),
      ),
      // Mismo selector que la pantalla 0, en modo ajuste: con vuelta atrás y
      // sin CTA, porque la elección ya se guarda al tocar la ficha.
      GoRoute(
        path: '/profile/theme',
        builder: (context, state) =>
            const ThemePickerScreen(mode: ThemePickerMode.settings),
      ),
      GoRoute(
        path: '/profile/language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: '/profile/units',
        builder: (context, state) => const MeasurementUnitsScreen(),
      ),
      GoRoute(
        path: '/profile/info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/device',
        builder: (context, state) => const MeasuringDeviceScreen(),
      ),
      GoRoute(
        path: '/profile/account',
        builder: (context, state) => const AccountSyncScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      GoRoute(
        path: '/profile/backup',
        builder: (context, state) => const DataBackupScreen(),
      ),
      GoRoute(
        path: '/profile/reminders',
        builder: (context, state) => const RemindersScreen(),
      ),
      GoRoute(
        path: '/profile/goals',
        builder: (context, state) => const HealthGoalsScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/profile/help/faq',
        builder: (context, state) => const FaqScreen(),
      ),
      GoRoute(
        path: '/profile/help/glossary',
        builder: (context, state) => const GlossaryScreen(),
      ),
      GoRoute(
        path: '/profile/help/legal',
        builder: (context, state) => const LegalScreen(),
      ),
      GoRoute(
        path: '/profile/help/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/record-anthropometric',
        builder: (context, state) => RecordAnthropometricScreen(
          recordToEdit: state.extra as AnthropometricRecord?,
        ),
      ),
      GoRoute(
        path: '/record-vital-signs',
        builder: (context, state) => RecordVitalSignsScreen(
          recordToEdit: state.extra as VitalSignRecord?,
        ),
      ),
      GoRoute(
        path: '/record-lipid',
        builder: (context, state) =>
            RecordLipidScreen(recordToEdit: state.extra as LipidRecord?),
      ),
      GoRoute(
        path: '/record-body-composition',
        builder: (context, state) => RecordBodyCompositionScreen(
          recordToEdit: state.extra as BodyCompositionRecord?,
        ),
      ),

      GoRoute(
        path: '/history/anthropometry',
        builder: (context, state) =>
            const HistoryCategoryScreen(child: AnthropometryHistoryTab()),
      ),
      GoRoute(
        path: '/history/vital-signs',
        builder: (context, state) =>
            const HistoryCategoryScreen(child: VitalSignsHistoryTab()),
      ),
      GoRoute(
        path: '/history/lipid',
        builder: (context, state) =>
            const HistoryCategoryScreen(child: LipidHistoryTab()),
      ),
      GoRoute(
        path: '/history/body-composition',
        builder: (context, state) =>
            const HistoryCategoryScreen(child: BodyCompositionHistoryTab()),
      ),
      // Módulo Medicamentos (prototipo navegable), ya dentro de Perfil.
      // Rutas de pantalla completa fuera del shell, como el resto de
      // subpantallas de Perfil: el menú y sus vistas usan la cabecera azul y
      // vuelven atrás con el botón estándar.
      GoRoute(
        path: '/profile/medications',
        builder: (context, state) => const MedicationsMenuScreen(),
      ),
      GoRoute(
        path: '/profile/medications/today',
        builder: (context, state) => const MedicationsTodayScreen(),
      ),
      GoRoute(
        path: '/profile/medications/inventory',
        builder: (context, state) => const MedicationInventoryScreen(),
      ),
      GoRoute(
        path: '/profile/medications/adherence',
        builder: (context, state) => const MedicationAdherenceScreen(),
      ),
      GoRoute(
        path: '/profile/medications/detail',
        builder: (context, state) => MedicationDetailScreen(
          medicationId: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/profile/medications/add',
        builder: (context, state) =>
            MedicationWizardScreen(medicationId: state.extra as String?),
      ),
      GoRoute(
        path: '/profile/medications/refill',
        builder: (context, state) => RefillInventoryScreen(
          medicationId: state.extra as String? ?? '',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
          GoRoute(
            path: '/discover',
            builder: (context, state) => const DiscoverScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
