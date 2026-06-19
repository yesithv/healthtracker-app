import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/services/biometric_service.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

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

    // ── ONBOARDING CHECK ──────────────────────────────────────────────
    // Show wizard if: first launch OR user has not completed their profile.
    final needsOnboarding =
        !onboarding.isComplete || prefs.userName.trim().isEmpty;

    if (needsOnboarding) {
      context.go('/onboarding');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D48A0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ECG MONITOR FRAME ---
            Container(
              width: 240,
              height: 140,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF020617),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _ecgController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: EcgPainter(
                        progress: _ecgController.value,
                        color: const Color(0xFF22C55E),
                      ),
                      child: Container(),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 48),
            // --- TEXT SECTION ---
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: const [
                  Text(
                    'MY VITALS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Health Tracker',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
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

class EcgPainter extends CustomPainter {
  final double progress;
  final Color color;

  EcgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    _drawGrid(canvas, size);

    final path = Path();
    final double midY = size.height / 2;
    final double width = size.width;

    for (double x = 0; x <= width; x++) {
      double relativeX = (x / width + (1 - progress)) % 1.0;
      double y = midY + _getEcgHeight(relativeX * 10) * 40;

      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawPath(path, glowPaint);
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
      oldDelegate.progress != progress;
}
