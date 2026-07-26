import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
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

    // ── AUTH / ONBOARDING GATE ────────────────────────────────────────
    // Priority: an active patient session (migrated/created) goes straight in.
    // Otherwise, a locally-configured profile (onboarding done) also goes in.
    // A fresh install with neither lands on the Welcome gate to choose between
    // logging in (migrated patient), creating an account, or using it offline.
    final hasSession = PatientSession.instance.isAuthenticated;
    final hasLocalProfile =
        onboarding.isComplete && prefs.userName.trim().isNotEmpty;

    if (!hasSession && !hasLocalProfile) {
      context.go('/intro');
      return;
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

