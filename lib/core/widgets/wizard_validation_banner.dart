import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

/// A premium animated validation banner that slides up between the page
/// content and the bottom navigation bar of the onboarding wizard.
///
/// Usage:
/// ```dart
/// WizardValidationBanner(
///   errors: ['Select a language'],
///   onDismiss: () {},
/// )
/// ```
class WizardValidationBanner extends StatefulWidget {
  final List<String> errors;
  final VoidCallback onDismiss;

  const WizardValidationBanner({
    super.key,
    required this.errors,
    required this.onDismiss,
  });

  @override
  State<WizardValidationBanner> createState() => _WizardValidationBannerState();
}

class _WizardValidationBannerState extends State<WizardValidationBanner>
    with TickerProviderStateMixin {
  // Slide + fade animation
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Icon shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();

    // --- Slide / Fade ---
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // --- Shake ---
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: -4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );

    // Start entrance
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _shakeController.forward();
    });

    // Auto-dismiss after 4 seconds
    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted) return;
    await _slideController.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Faltan campos obligatorios: es la ALERTA de la paleta clínica, el mismo
    // rojo que un valor fuera de rango. Eran seis rojos y un ámbar sueltos.
    final alert = theme.clinical.alert;

    return GestureDetector(
      onTap: _dismiss,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            decoration: BoxDecoration(
              color: alert.surface,
              borderRadius: BorderRadius.circular(surfaces.radiusCard),
              border: Border.all(
                color: alert.accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: surfaces.glow(
                alert.accent,
                alpha: 0.12,
                blur: 20,
                offset: const Offset(0, 4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shaking warning icon
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: IconBadge(
                      Icons.warning_amber_rounded,
                      color: alert.accent,
                      background: alert.accent.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.validationRequiredFields,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: alert.accent,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.validationCompleteBeforeContinue,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.clinical.caution.accent,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Error list
                        ...widget.errors.map(
                          (error) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: alert.accent,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    error,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: alert.accent,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Dismiss X button
                  GestureDetector(
                    onTap: _dismiss,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: alert.accent.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
