import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_entry.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Verificación por OTP para un paciente que existe en el LEGACY (el lookup marcó
/// `inLegacy`). Valida la identidad con un código y, al confirmar, TRAE su historial
/// (persona + atenciones + indicadores) y entra al dashboard con los datos ya visibles.
///
/// <b>Fase 0:</b> no hay OTP real todavía; el código es un placeholder y por dentro se
/// recicla el `activate` (migración) + `login` con la clave dev para obtener la sesión.
/// Este es el HUECO donde en Fase 1 entra el OTP de Firebase (SMS/email): mismo paso del
/// flujo, distinto mecanismo — la UI no cambia.
class OtpVerifyScreen extends StatefulWidget {
  /// Documento o email confirmado en el paso de identificación.
  final String identifier;

  const OtpVerifyScreen({super.key, required this.identifier});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _blue = Color(0xFF0D48A0);

  final _auth = AuthApiClient();
  final _codeController = TextEditingController();

  bool _busy = false;
  String? _status;
  String? _error;

  @override
  void dispose() {
    _auth.close();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa el código para continuar.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // El OTP (placeholder) solo valida identidad; luego migramos y entramos.
      setState(() => _status = 'Trayendo tu historial…');
      await _auth.activate(widget.identifier);
      final account = await _auth.login(
        identifier: widget.identifier,
        password: '1234',
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
      if (mounted) {
        setState(() {
          _busy = false;
          _status = null;
        });
      }
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
              const Icon(Icons.folder_shared_outlined, size: 56, color: _blue),
              const SizedBox(height: 16),
              const Text(
                'Encontramos tu historial',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verifica tu identidad para traer tus datos asociados a\n${widget.identifier}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              _label('Código de verificación'),
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: _decoration('••••••', Icons.password_outlined),
                onSubmitted: (_) => _verify(),
              ),
              const Text(
                'Fase de pruebas: ingresa cualquier código (p. ej. 123456). '
                'Aquí irá el OTP por SMS/email en producción.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              if (_status != null) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _status!,
                      style: const TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
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
                    : Text(
                        l10n.identifyBringHistory,
                        style: const TextStyle(
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
    counterText: '',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
