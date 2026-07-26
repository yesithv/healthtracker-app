import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/services/biometric_service.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _ecgController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ECG Animation Controller
    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

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
      context.go('/welcome');
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
    _ecgController.dispose();
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
            _EcgPanel(
              controller: _ecgController,
              stroke: surfaces.dataStroke,
              strokeWidth: surfaces.chartLineWidth,
              bezel: surfaces.monitorBezel,
              radius: surfaces.radiusCard,
              onBrand: surfaces.onBrand,
            ),
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

/// El electro del arranque, en los dos acabados que admite el sistema.
class _EcgPanel extends StatelessWidget {
  const _EcgPanel({
    required this.controller,
    required this.stroke,
    required this.strokeWidth,
    required this.bezel,
    required this.radius,
    required this.onBrand,
  });

  final AnimationController controller;
  final Color stroke;
  final double strokeWidth;
  final bool bezel;
  final double radius;
  final Color onBrand;

  @override
  Widget build(BuildContext context) {
    final trace = AnimatedBuilder(
      animation: controller,
      builder: (context, child) => CustomPaint(
        painter: EcgPainter(
          progress: controller.value,
          color: stroke,
          strokeWidth: strokeWidth,
          // La rejilla y el resplandor son cromo de instrumental: sólo
          // acompañan al bisel.
          showGrid: bezel,
          glow: bezel,
        ),
        child: const SizedBox.expand(),
      ),
    );

    if (!bezel) {
      // «Consulta Serena»: el trazo respira sobre el lienzo de marca.
      return SizedBox(width: 240, height: 60, child: trace);
    }

    // «Pulso Clínico»: pantalla de monitor con marco y halo.
    return Container(
      width: 240,
      height: 140,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // Interior de la pantalla del monitor. Es una constante del PROPIO
        // idioma de instrumental, no de la paleta del tema: un monitor apagado
        // es negro en cualquier tema. Sólo se dibuja si `monitorBezel` es true.
        color: const Color(0xFF020617),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: onBrand.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: onBrand.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 4),
        child: trace,
      ),
    );
  }
}

class EcgPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  /// Rejilla de fondo estilo papel de electro. Sólo con bisel de instrumental.
  final bool showGrid;

  /// Halo alrededor del trazo, como el fósforo de un monitor. Ídem.
  final bool glow;

  EcgPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 2.5,
    this.showGrid = true,
    this.glow = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (showGrid) _drawGrid(canvas, size);

    final path = Path();
    final double midY = size.height / 2;
    final double width = size.width;

    for (double x = 0; x <= width; x++) {
      double relativeX = (x / width + (1 - progress)) % 1.0;
      // La amplitud escala con la altura disponible: el mismo trazo sirve para
      // el monitor de 140 px y para la línea desnuda de 60 px.
      double y = midY + _getEcgHeight(relativeX * 10) * (size.height * 0.29);

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = strokeWidth * 2.4
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawPath(path, glowPaint);
    }
  }

  double _getEcgHeight(double t) {
    t = t % 10;
    if (t < 0.5) return 0;
    if (t < 1.0) return -0.2 * math.sin((t - 0.5) * 2 * math.pi);
    if (t < 1.5) return 0;
    if (t < 1.6) return 0.2 * (t - 1.5) * 10;
    if (t < 1.8) return -1.5 * math.sin((t - 1.6) * 5 * math.pi / 2);
    if (t < 2.0) return 0.5 * math.sin((t - 1.8) * 5 * math.pi / 2);
    if (t < 2.5) return 0;
    if (t < 3.5) return -0.4 * math.sin((t - 2.5) * math.pi);
    return 0;
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..strokeWidth = 0.5;
    const double spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(EcgPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.showGrid != showGrid ||
      oldDelegate.glow != glow;
}
