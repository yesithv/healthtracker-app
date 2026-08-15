import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/onboarding/presentation/screens/onboarding_welcome_page.dart';

/// Pantalla de entrada (sin sesión): muestra la reseña de funcionalidades y los dos
/// caminos:
///   - "Comenzar" (CTA principal): usuario NUEVO → onboarding de registro.
///   - "Iniciar sesión" (enlace secundario): usuario que YA es paciente (cuenta o legacy).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // Reseña de funcionalidades animada, a pantalla completa (gradiente + tarjetas).
          const Positioned.fill(child: OnboardingWelcomePage()),

          // CTAs fijos abajo sobre el gradiente.
          Positioned(
            left: 28,
            right: 28,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // CTA principal: usuario nuevo → onboarding de registro.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D48A0),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => context.go('/onboarding?mode=account'),
                    child: Text(
                      l10n.welcomeGetStarted,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Secundario, de menor peso: usuario que ya es paciente.
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(text: '${l10n.welcomeAlreadyHaveAccount} '),
                        TextSpan(
                          text: l10n.welcomeLogIn,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
