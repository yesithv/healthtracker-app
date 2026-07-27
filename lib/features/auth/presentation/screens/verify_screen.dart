import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/constants/measurement_unit.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';

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

    // Capturados antes de los await para no usar el context tras un gap async.
    final profile = context.read<UserProfileProvider>();
    final onboarding = context.read<OnboardingProvider>();
    final localeUnits = context.read<LocaleUnitsProvider>();
    final router = GoRouter.of(context);

    try {
      final account = await _auth.login(
        identifier: widget.identifier,
        password: _passController.text,
      );

      await PatientSession.instance.save(
        publicId: account.publicId,
        firstName: account.firstName,
        lastName: account.lastName,
        source: account.source,
      );

      // Hidrata el perfil local con lo que el servidor ya sabe (solo campos vacíos).
      final fullName = [account.firstName, account.lastName]
          .where((s) => s != null && s.trim().isNotEmpty)
          .join(' ');
      await profile.hydrateIdentity(
        name: fullName,
        email: account.email ??
            (widget.identifier.contains('@') ? widget.identifier : null),
        birthDate: account.birthDate,
        gender: account.genderForApp,
      );

      // Defaults del paciente migrado del legacy: español, sistema métrico y
      // báscula Omron (la de la consulta). Solo si el usuario no eligió antes.
      if (account.migrated) {
        await localeUnits.ensureDefaults(
            languageCode: 'es', unit: MeasurementUnit.metric);
        await profile.setDefaultDeviceIfUnset('Omron');
      }

      await onboarding.setComplete();

      if (!mounted) return;
      router.go('/dashboard');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.unexpectedError('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: surfaces.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/identify'),
        ),
        title: Text(l10n.verifyAppBarTitle, style: theme.type.cardTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.verified_user_outlined,
                  size: 56, color: surfaces.brand),
              const SizedBox(height: 16),
              Text(
                l10n.verifyTitle,
                textAlign: TextAlign.center,
                style: theme.type.screenTitle.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.verifyBody(widget.identifier),
                textAlign: TextAlign.center,
                style: theme.type.body,
              ),
              const SizedBox(height: 28),
              _label(l10n.verifyPasswordLabel),
              TextField(
                controller: _passController,
                autofocus: true,
                obscureText: true,
                decoration: _decoration('••••', Icons.lock_outline),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.verifyTestNotice,
                style: theme.type.meta,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.clinical.alert.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: theme.clinical.alert.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: theme.type.body.copyWith(
                                color: theme.clinical.alert.accent)),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: surfaces.brand,
                  foregroundColor: surfaces.onBrand,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(surfaces.radiusControl),
                  ),
                ),
                onPressed: _busy ? null : _verify,
                child: _busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: surfaces.onBrand))
                    : Text(l10n.verifySubmit,
                        style: theme.type.button.copyWith(
                            fontSize: 16, color: surfaces.onBrand)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(text, style: Theme.of(context).type.fieldLabel),
      );

  InputDecoration _decoration(String hint, IconData icon) {
    final surfaces = Theme.of(context).surfaces;
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: surfaces.brand, size: 20),
      filled: true,
      fillColor: surfaces.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        borderSide: BorderSide.none,
      ),
    );
  }
}
