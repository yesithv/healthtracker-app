import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

class OnboardingWelcomePage extends StatefulWidget {
  const OnboardingWelcomePage({super.key});

  @override
  State<OnboardingWelcomePage> createState() => _OnboardingWelcomePageState();
}

class _OnboardingWelcomePageState extends State<OnboardingWelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _ecgController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _ecgController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D48A0), Color(0xFF1565C0), Color(0xFF0D48A0)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // --- APP TITLE (encima del logo) ---
                  Text(
                    'MY VITALS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.width < 360 ? 28 : 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- ECG MONITOR (reducido) ---
                  Container(
                    width: 170,
                    height: 100,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF020617),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedBuilder(
                        animation: _ecgController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _EcgPainter(
                              progress: _ecgController.value,
                              color: const Color(0xFF22C55E),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    l10n.onboardingWelcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- FEATURE CARDS ---
                  _FeatureCard(
                    icon: Icons.monitor_heart_outlined,
                    color: const Color(0xFFEF4444),
                    text: l10n.onboardingWelcomeFeature1,
                    delay: 0,
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.show_chart_rounded,
                    color: const Color(0xFF22C55E),
                    text: l10n.onboardingWelcomeFeature2,
                    delay: 100,
                  ),
                  const SizedBox(height: 12),
                  _FeatureCard(
                    icon: Icons.cloud_sync_outlined,
                    color: const Color(0xFF60A5FA),
                    text: l10n.onboardingWelcomeFeature3,
                    delay: 200,
                  ),

                  // Espacio para los CTAs fijos de WelcomeScreen (no tapan la última tarjeta).
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String text;
  final int delay;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.text,
    required this.delay,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);

    Future.delayed(Duration(milliseconds: 400 + widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            IconBadge(
              widget.icon,
              color: widget.color,
              background: widget.color.withValues(alpha: 0.2),
              padding: 10,
              iconSize: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ECG painter (same style as SplashScreen).
class _EcgPainter extends CustomPainter {
  final double progress;
  final Color color;

  _EcgPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double midY = size.height / 2;

    for (double x = 0; x <= size.width; x++) {
      final double relX = (x / size.width + (1 - progress)) % 1.0;
      final double y = midY + _ecgHeight(relX * 10) * 35;
      if (x == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawPath(path, glowPaint);
  }

  double _ecgHeight(double t) {
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
    const double spacing = 18.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.progress != progress;
}
