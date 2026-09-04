import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_entry.dart';
import 'package:myvitals_healthtracker_app/core/legal/legal_api_client.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// El alta, con el correo ya verificado.
///
/// Se llega aquí solo después de teclear el código que llegó al buzón, así que la dirección ya
/// está demostrada. Lo que falta es el **documento**, y no es un trámite: es lo que el servidor
/// contrasta contra NutryApp. Si esa persona ya es paciente de la clínica, la cuenta no se crea
/// y se le pide que llame —su historia clínica no se entrega por teclear un número—.
///
/// Los datos se prellenan con lo que el onboarding ya recogió, para no pedir dos veces lo mismo.
class SignupScreen extends StatefulWidget {
  /// El token de la sesión abierta al verificar el correo. Solo sirve para completar el alta.
  final String sessionToken;

  const SignupScreen({super.key, required this.sessionToken});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _blue = Color(0xFF0D48A0);

  final _auth = AuthApiClient();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  bool _terms = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>();
    _nameController.text = profile.userName.trim();
  }

  @override
  void dispose() {
    _auth.close();
    _nameController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final document = _documentController.text.trim();
    if (name.isEmpty || document.isEmpty) {
      setState(() => _error = l10n.validationRequiredFields);
      return;
    }
    if (!_terms) {
      setState(() => _error = l10n.signupMissingTerms);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    final profile = context.read<UserProfileProvider>();
    try {
      final account = await _auth.signup(
        sessionToken: widget.sessionToken,
        firstName: name,
        birthDate: profile.birthDate,
        sex: profile.userGender.isEmpty ? null : profile.userGender,
        documentType: 'CC',
        documentNumber: document,
        termsAccepted: true,
      );
      if (!mounted) return;
      await completeLoginAndEnter(
        context,
        account,
        sessionToken: widget.sessionToken,
        identifier: account.email,
      );
    } on CallClinicException {
      // No es un error del usuario: es que ya tiene historia clínica en la consulta.
      if (mounted) router.go('/call-clinic');
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
        title: Text(l10n.signupTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Icon(Icons.assignment_ind_outlined, size: 56, color: _blue),
              const SizedBox(height: 16),
              Text(
                l10n.signupSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  l10n.signupNameLabel,
                  Icons.person_outline,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _documentController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration(
                  l10n.signupDocumentLabel,
                  Icons.badge_outlined,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.signupDocumentHelp,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _terms,
                onChanged: (v) => setState(() => _terms = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.signupTermsAccept,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
              // La casilla pedía aceptar dos documentos que no enlazaban a
              // ninguna parte. Los textos los sirve la API y se leen sin cuenta,
              // que es justo lo que hace falta aquí: todavía no la hay.
              Wrap(
                spacing: 4,
                children: [
                  _documentLink(
                    l10n.legalReadTerms,
                    '/legal/${LegalApiClient.terms}',
                  ),
                  _documentLink(
                    l10n.legalReadPrivacy,
                    '/legal/${LegalApiClient.privacy}',
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _busy ? null : _submit,
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
                        l10n.signupSubmit,
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

  /// Un enlace a uno de los documentos, en modo lectura. Se abre encima del
  /// alta (`push`) para volver aquí con lo ya escrito intacto.
  Widget _documentLink(String label, String route) => TextButton(
    onPressed: () => context.push(route),
    style: TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: _blue,
        decoration: TextDecoration.underline,
      ),
    ),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _blue),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
