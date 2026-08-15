import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';

/// Paso 1 de "Iniciar sesión". El usuario que YA es paciente ingresa un solo dato
/// (documento del paciente migrado, o email de la cuenta) y el backend decide el camino:
///   - existe cuenta   → verificación por contraseña (`/verify`) → entra.
///   - existe en legacy → verificación por OTP (`/verify-otp`) → trae su historial y entra.
///   - no existe        → es alguien nuevo: se le envía al onboarding de registro.
///
/// Los usuarios nuevos NO pasan por aquí: entran por "Comenzar" (onboarding directo). Este
/// es el punto de reciclaje de los dos flujos de retorno en una sola pantalla de acceso.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _blue = Color(0xFF0D48A0);

  final _auth = AuthApiClient();
  final _idController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _auth.close();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final identifier = _idController.text.trim();
    if (identifier.isEmpty || _busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      final result = await _auth.lookup(identifier);
      if (!mounted) return;
      if (result.exists) {
        // Cuenta activa → verificación por contraseña.
        router.go('/verify', extra: identifier);
      } else if (result.inLegacy) {
        // Historial en el legacy → verificación por OTP + migración.
        router.go('/verify-otp', extra: identifier);
      } else {
        // No es paciente todavía: lo tratamos como nuevo (registro).
        router.go('/onboarding?mode=account');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/welcome'),
        ),
        title: const Text('Iniciar sesión'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.badge_outlined, size: 56, color: _blue),
              const SizedBox(height: 16),
              const Text(
                'Bienvenido de vuelta',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu documento o email. Reconocemos tu cuenta y te pedimos '
                'la verificación que corresponda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _idController,
                autofocus: true,
                textInputAction: TextInputAction.go,
                decoration: InputDecoration(
                  labelText: 'Documento o email',
                  hintText: 'Ej. 1032456789',
                  prefixIcon: const Icon(Icons.person_outline, color: _blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _continue(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C)))),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _continue,
                child: _busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Siguiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
