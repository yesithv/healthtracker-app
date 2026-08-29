import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// El final del camino para quien ya es paciente de la clínica.
///
/// No es un error ni un rechazo: es que esa persona tiene una historia clínica, y esa no se
/// entrega por teclear un número. La activa un agente después de verificar por teléfono quién
/// es, y entonces le dicta el código con el que entra.
class CallClinicScreen extends StatelessWidget {
  const CallClinicScreen({super.key});

  static const _blue = Color(0xFF0D48A0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _blue,
        title: Text(l10n.callClinicTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.support_agent_outlined, size: 64, color: _blue),
              const SizedBox(height: 20),
              Text(
                l10n.callClinicBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF334155)),
              ),
              const Spacer(),
              // Quien ya tenga su código llega al canje desde la puerta, sin salir de la app.
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => context.go('/login'),
                child: Text(l10n.callClinicBack),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
