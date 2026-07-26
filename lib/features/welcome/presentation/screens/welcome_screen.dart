import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

/// Bienvenida: un ÚNICO CTA protagonista, sin pedirle al usuario que se autoclasifique
/// (paciente/nuevo/invitado). Al pulsar "Comenzar" se le pide un solo dato (documento o
/// email) y el backend decide si ya es paciente o es nuevo — el usuario nunca elige categoría.
/// El modo sin cuenta queda como enlace secundario, sin robar protagonismo al flujo principal.
///
/// ALCANCE: aquí solo se ha aplicado el tema. Los textos, los botones y las rutas
/// son exactamente los que ya tenía. El rediseño del sistema (lámina A2, con el
/// párrafo de beneficios y el descargo médico) queda pendiente de decidir aparte.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    // Mismo gesto de degradado que antes (marca → más claro → marca), pero
    // derivado del color de marca del tema en vez de tres azules fijos.
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        surfaces.brand,
        Color.lerp(surfaces.brand, surfaces.onBrand, 0.14)!,
        surfaces.brand,
      ],
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                // El icono no cambia entre temas: solo su color se adapta.
                Icon(
                  Icons.monitor_heart_outlined,
                  size: 76,
                  color: surfaces.onBrand,
                ),
                const SizedBox(height: 22),
                Text(
                  'MY VITALS',
                  textAlign: TextAlign.center,
                  style: theme.type.display.copyWith(
                    color: surfaces.onBrand,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu salud, en tus manos',
                  textAlign: TextAlign.center,
                  style: theme.type.displayMeta.copyWith(
                    color: surfaces.onBrand.withValues(alpha: 0.85),
                    fontSize: 15,
                  ),
                ),
                const Spacer(flex: 3),

                // Único CTA protagonista.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: surfaces.onBrand,
                      foregroundColor: surfaces.brand,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          surfaces.radiusControl,
                        ),
                      ),
                    ),
                    onPressed: () => context.go('/identify'),
                    child: Text(
                      'Comenzar',
                      style: theme.type.button.copyWith(
                        fontSize: 17,
                        color: surfaces.brand,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Escape secundario: sin cuenta (local-first). No compite con el CTA.
                TextButton(
                  onPressed: () => context.go('/onboarding?mode=offline'),
                  child: Text(
                    'Explorar sin cuenta',
                    style: theme.type.button.copyWith(
                      fontSize: 15,
                      color: surfaces.onBrand.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
