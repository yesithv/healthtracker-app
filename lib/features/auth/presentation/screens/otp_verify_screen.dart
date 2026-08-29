import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/access_target.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_entry.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// El paso del código, que sirve a los dos caminos de entrada.
///
/// **Por correo** (lo normal): se acaba de escribir una dirección en la puerta y ahí ha
/// llegado un código. Al canjearlo, o se entra —si esa cuenta ya tiene ficha— o se va al alta,
/// que es donde se piden el documento y los términos.
///
/// **Con el código de la clínica**: a un paciente de NutryApp un agente le dictó seis dígitos
/// por teléfono después de verificar quién es. Ese canje pide además el documento, porque el
/// código viajó fuera del sistema; sin el documento, probar seis dígitos al azar acertaría el
/// de alguien. Al canjearlo, el servidor trae su historial y la app entra con sus datos.
class OtpVerifyScreen extends StatefulWidget {
  /// Cómo se llegó aquí: con un correo al que se mandó el código, o con el de la clínica.
  final AccessTarget target;

  const OtpVerifyScreen({super.key, required this.target});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _blue = Color(0xFF0D48A0);

  final _auth = AuthApiClient();
  final _codeController = TextEditingController();
  late final TextEditingController _documentController;

  bool get _isClinicCode => widget.target.isClinicCode;

  bool _busy = false;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _documentController = TextEditingController();
  }

  @override
  void dispose() {
    _auth.close();
    _codeController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    final document = _documentController.text.trim();
    final code = _codeController.text.trim();
    final l10n = AppLocalizations.of(context)!;
    if (_isClinicCode && document.isEmpty) {
      setState(() => _error = l10n.accessCodeMissingDocument);
      return;
    }
    if (code.length != 6) {
      setState(() => _error = l10n.accessCodeSixDigits);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      if (_isClinicCode) {
        // El canje abre la sesión y de paso trae el historial del legacy, así que puede
        // tardar: el aviso es para que no parezca que se ha quedado colgada.
        setState(() => _status = l10n.verifyBringingHistory);
        final session = await _auth.redeemAccessCode(
          documentNumber: document,
          code: code,
        );
        if (!mounted) return;
        await completeLoginAndEnter(
          context,
          session.account,
          sessionToken: session.token,
          sessionExpiresAt: session.expiresAt,
          identifier: document,
        );
        return;
      }

      final session = await _auth.verifyEmailCode(
        email: widget.target.email!,
        code: code,
      );
      if (!mounted) return;
      if (session.needsSignup) {
        // Correo verificado y todavía sin ficha: falta el alta, que es donde se piden el
        // documento y los términos.
        router.go('/signup', extra: session.token);
        return;
      }
      await completeLoginAndEnter(
        context,
        session.account!,
        sessionToken: session.token,
        sessionExpiresAt: session.expiresAt,
        identifier: widget.target.email,
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
              Icon(
                _isClinicCode
                    ? Icons.folder_shared_outlined
                    : Icons.mark_email_read_outlined,
                size: 56,
                color: _blue,
              ),
              const SizedBox(height: 16),
              Text(
                _isClinicCode
                    ? l10n.verifyAppBarTitle
                    : l10n.accessCodeSentTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isClinicCode
                    ? l10n.accessCodeClinicHint
                    : l10n.accessCodeSentSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              if (_isClinicCode) ...[
                _label(l10n.accessCodeDocumentLabel),
                TextField(
                  controller: _documentController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _decoration(
                    l10n.accessCodeDocumentHint,
                    Icons.badge_outlined,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _label(l10n.accessCodeLabel),
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
              Text(
                l10n.accessCodeHelp,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
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
