import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/access_target.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// La puerta: se escribe el correo y llega un código.
///
/// Es la MISMA para quien ya tiene cuenta y para quien no. La respuesta del servidor es
/// idéntica en los dos casos —y en el de un paciente de la clínica que aún no ha activado su
/// cuenta—, así que esta pantalla siempre hace lo mismo: mandar al paso del código. Lo que
/// cambia va en el correo, no aquí.
///
/// Antes esta pantalla preguntaba «documento o email» y el servidor respondía si esa persona
/// tenía historial en la clínica. Eso convertía la pantalla en una forma de averiguar quién es
/// paciente de una consulta de nutrición: un dato de salud a cambio de teclear un número.
///
/// El paciente al que un agente le dictó un código por teléfono entra por el enlace de abajo,
/// que pide documento y código.
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
  void initState() {
    super.initState();
    final prefilled = GoRouterState.of(context).extra;
    if (prefilled is String) _idController.text = prefilled;
  }

  @override
  void dispose() {
    _auth.close();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final email = _idController.text.trim();
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_looksLikeEmail(email)) {
      setState(() => _error = l10n.accessDoorInvalidEmail);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      await _auth.startAccess(email);
      if (!mounted) return;
      // Siempre al mismo sitio: aquí no se sabe —ni se puede saber— si esa dirección tenía
      // cuenta. Preguntarlo sería la fuga que este diseño evita.
      router.go('/verify-otp', extra: AccessTarget.email(email));
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Comprobación mínima: el servidor valida de verdad, esto solo evita el viaje.
  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

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
          onPressed: () => context.go('/welcome'),
        ),
        title: Text(l10n.welcomeLogIn),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.mark_email_read_outlined,
                size: 56,
                color: _blue,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.accessDoorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.accessDoorSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _idController,
                autofocus: true,
                textInputAction: TextInputAction.go,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                inputFormatters: InputRules.identifier(),
                decoration: InputDecoration(
                  labelText: l10n.accessDoorEmailLabel,
                  hintText: l10n.accessDoorEmailHint,
                  prefixIcon: const Icon(Icons.alternate_email, color: _blue),
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
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.accessDoorContinue,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // El paciente al que la clínica le dictó un código entra por aquí: ese canje pide
              // documento y código, porque el código viajó por teléfono y no por su buzón.
              TextButton(
                onPressed: _busy
                    ? null
                    : () => context.go(
                        '/verify-otp',
                        extra: const AccessTarget.clinicCode(),
                      ),
                child: Text(l10n.accessClinicCodeLink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
