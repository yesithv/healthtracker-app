import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_entry.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Verificación de identidad para una cuenta EXISTENTE (el lookup ya confirmó que el
/// identificador existe). Solo aquí se personaliza: antes de verificar no se muestra ni el
/// nombre ni el historial (no se filtra PII a quien solo teclea un documento).
///
/// <b>Fase 0:</b> la verificación es la contraseña de desarrollo (`1234`). Este es el HUECO
/// donde en Fase 1 entra el OTP de Firebase (SMS/email): mismo paso del flujo, distinto
/// mecanismo — la UI no cambia.
///
/// Al verificar: guarda la sesión, marca el onboarding como completo, hidrata el nombre del
/// servidor y entra al dashboard con su historial ya visible.
class VerifyScreen extends StatefulWidget {
  /// Documento o email confirmado en el paso de identificación.
  final String identifier;

  const VerifyScreen({super.key, required this.identifier});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  static const _blue = Color(0xFF0D48A0);

  final _auth = AuthApiClient();
  final _passController = TextEditingController(text: '1234');

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _auth.close();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final account = await _auth.login(
        identifier: widget.identifier,
        password: _passController.text,
      );

      if (!mounted) return;
      await completeLoginAndEnter(
        context,
        account,
        identifier: widget.identifier,
      );
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/login'),
        ),
        title: Text(l10n.verifyAppBarTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.verified_user_outlined, size: 56, color: _blue),
              const SizedBox(height: 16),
              const Text(
                'Encontramos tu cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verifica tu identidad para continuar con\n${widget.identifier}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              _label('Contraseña'),
              TextField(
                controller: _passController,
                autofocus: true,
                obscureText: true,
                decoration: _decoration('••••', Icons.lock_outline),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 6),
              const Text(
                'Fase de pruebas: la contraseña es 1234. (Aquí irá el código OTP en producción.)',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Ingresar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF64748B),
      ),
    ),
  );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: _blue, size: 20),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
