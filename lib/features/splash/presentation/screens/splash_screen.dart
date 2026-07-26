import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:myvitals_healthtracker_app/core/services/biometric_service.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/ecg_trace.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in animation for text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _fadeController.forward();

    // Start Smart Initialization
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Minimum duration to show the animation (2.2 seconds for a fast feel)
    final minimumWait = Future.delayed(const Duration(milliseconds: 2200));

    // 2. Simulated real initialization (e.g., loading local DB, Auth state, etc.)
    final initializationTasks = Future.delayed(
      const Duration(milliseconds: 500),
    );

    // Wait for BOTH the tasks and the minimum duration
    await Future.wait([minimumWait, initializationTasks]);

    if (!mounted) return;

    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);

    // Ensure both stores are loaded from SharedPreferences before checking.
    await prefs.ready;
    await onboarding.ready;
    if (!mounted) return;

    // ── PUERTA DE ACCESO ──────────────────────────────────────────────
    // La cuenta es OBLIGATORIA, pero su CREACIÓN puede quedar diferida: si el
    // alta no pudo salir al servidor por falta de red, el usuario entra igual y
    // la cuenta se crea en el primer intento que funcione. Exigir servidor
    // disponible en ese instante convertiría un corte de red en un muro.
    //
    // Da paso, por tanto, una sesión activa O un alta pendiente.
    final pending = PendingAccountStore.instance;
    if (!PatientSession.instance.isAuthenticated && !pending.isPending) {
      context.go('/intro');
      return;
    }

    // Con un alta pendiente se reintenta AQUÍ, en cada arranque: es el momento
    // natural de «apenas haya internet» sin añadir un vigilante de conectividad.
    // No se espera el resultado —entrar no debe depender de la red— y si sale
    // bien, guardar la sesión despierta a SyncService, que sube lo acumulado.
    if (pending.isPending) {
      final profile = Provider.of<UserProfileProvider>(context, listen: false);
      // ignore: discarded_futures
      flushPendingAccount(AccountDraft.fromProfile(profile));
    }

    // ── BIOMETRIC AUTH ────────────────────────────────────────────────
    if (prefs.isBiometricEnabled) {
      final biometricService = BiometricService();
      // ignore: use_build_context_synchronously
      final l10n = AppLocalizations.of(context)!;
      bool isAuth = false;

      while (!isAuth) {
        isAuth = await biometricService.authenticate(
          localizedReason: l10n.unlockAppToContinue,
        );
        if (!isAuth) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (!mounted) return;

    // Navigate to dashboard
    context.go('/dashboard');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Scaffold(
      backgroundColor: surfaces.brand,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── ELECTRO ─────────────────────────────────────────────────────
            // El trazo es el mismo en los dos temas. Lo que cambia es si va
            // dentro de un bisel de instrumental o desnudo sobre el fondo, y
            // eso lo dice el tema (`monitorBezel`), no esta pantalla.
            const EcgTrace(),
            const SizedBox(height: 48),
            // ── MARCA ───────────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'My Vitals',
                    textAlign: TextAlign.center,
                    style: theme.type.display.copyWith(color: surfaces.onBrand),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Health Tracker',
                    textAlign: TextAlign.center,
                    style: theme.type.displayMeta.copyWith(
                      color: surfaces.onBrand.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

