import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bienvenida: un ÚNICO CTA protagonista, sin pedirle al usuario que se autoclasifique
/// (paciente/nuevo/invitado). Al pulsar "Comenzar" se le pide un solo dato (documento o
/// email) y el backend decide si ya es paciente o es nuevo — el usuario nunca elige categoría.
/// El modo sin cuenta queda como enlace secundario, sin robar protagonismo al flujo principal.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D48A0), Color(0xFF1565C0), Color(0xFF0D48A0)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Icon(Icons.monitor_heart_outlined, size: 76, color: Colors.white),
                const SizedBox(height: 22),
                const Text(
                  'MY VITALS',
                  style: TextStyle(
                    color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 6),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tu salud, en tus manos',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 15, letterSpacing: 1),
                ),
                const Spacer(flex: 3),

                // Único CTA protagonista.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0D48A0),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => context.go('/identify'),
                    child: const Text('Comenzar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),

                // Escape secundario: sin cuenta (local-first). No compite con el CTA.
                TextButton(
                  onPressed: () => context.go('/onboarding?mode=offline'),
                  child: Text(
                    'Explorar sin cuenta',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
