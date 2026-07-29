import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/validation/input_rules.dart';

/// Paso ÚNICO de identificación. El usuario ingresa un solo dato (documento del paciente
/// migrado, o email) y el backend decide el camino:
///   - existe  → pantalla de verificación (`/verify`) → entra y ve su historial.
///   - no existe → registro nuevo (onboarding en modo cuenta).
///
/// El usuario nunca elige "soy paciente / soy nuevo": eso lo resuelve el lookup. El framing
/// es de BENEFICIO ("traer tu historial"), no de trámite.
class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  final _auth = AuthApiClient();
  final _idController = TextEditingController();
  bool _busy = false;
  String? _error;

  /// true = el lookup encontró historial en el legacy para este documento:
  /// se muestra la oferta de alta self-service ("traer mi historial").
  bool _legacyFound = false;

  /// true mientras corre la activación (migración del historial).
  bool _activating = false;

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
      _legacyFound = false;
    });

    final router = GoRouter.of(context);
    try {
      final result = await _auth.lookup(identifier);
      if (!mounted) return;
      if (result.exists) {
        router.go('/verify', extra: identifier);
      } else if (result.inLegacy) {
        // Hay historial en el legacy: ofrecer el alta self-service (no autoclasificar).
        setState(() => _legacyFound = true);
      } else {
        // Paciente nuevo: al terminar el onboarding se crea la cuenta.
        router.go('/onboarding');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(
        () => _error = AppLocalizations.of(context)!.unexpectedError('$e'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Alta self-service: migra el historial (persona + atenciones + indicadores) y sigue
  /// al paso de verificación. Puede tardar unos segundos (backfill completo).
  Future<void> _activate() async {
    final identifier = _idController.text.trim();
    if (identifier.isEmpty || _activating) return;

    setState(() {
      _activating = true;
      _error = null;
    });

    final router = GoRouter.of(context);
    try {
      await _auth.activate(identifier);
      if (!mounted) return;
      router.go('/verify', extra: identifier);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(
        () => _error = AppLocalizations.of(context)!.unexpectedError('$e'),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    // Hallazgo positivo («encontramos tu historial») = estado óptimo del tema.
    final found = theme.clinical.optimal;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: surfaces.brand,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/intro'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.badge_outlined, size: 56, color: surfaces.brand),
              const SizedBox(height: 16),
              Text(
                l10n.identifyTitle,
                textAlign: TextAlign.center,
                style: theme.type.screenTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.identifyBody,
                textAlign: TextAlign.center,
                style: theme.type.body,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _idController,
                autofocus: true,
                textInputAction: TextInputAction.go,
                // Documento de identidad: cifras y letras, sin espacios ni
                // signos. Se admiten letras porque hay países que las usan
                // (la letra final del DNI español, por ejemplo).
                inputFormatters: InputRules.documentId(),
                decoration: InputDecoration(
                  labelText: l10n.identifyFieldLabel,
                  hintText: l10n.identifyFieldHint,
                  prefixIcon: Icon(Icons.person_outline, color: surfaces.brand),
                  filled: true,
                  fillColor: surfaces.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(surfaces.radiusControl),
                    borderSide: BorderSide.none,
                  ),
                ),
                // Si cambia el documento, la oferta de alta anterior deja de aplicar.
                onChanged: (_) {
                  if (_legacyFound) setState(() => _legacyFound = false);
                },
                onSubmitted: (_) => _continue(),
              ),
              if (_legacyFound) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: found.surface,
                    borderRadius: BorderRadius.circular(surfaces.radiusControl),
                    border: Border.all(color: found.accent, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.folder_shared_outlined,
                            color: found.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l10n.identifyFoundTitle,
                              style: theme.type.button.copyWith(
                                fontSize: 14,
                                color: found.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.identifyFoundBody,
                        style: theme.type.body.copyWith(
                          fontSize: 13,
                          color: found.accent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: found.accent,
                          foregroundColor: found.onAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              surfaces.radiusControl,
                            ),
                          ),
                        ),
                        onPressed: _activating ? null : _activate,
                        icon: _activating
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: found.onAccent,
                                ),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(
                          _activating
                              ? l10n.identifyBringingHistory
                              : l10n.identifyBringHistory,
                          style: theme.type.button.copyWith(
                            color: found.onAccent,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _activating
                            ? null
                            : () => context.go('/onboarding'),
                        child: Text(
                          l10n.identifyNotMe,
                          style: theme.type.body.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.clinical.alert.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.type.body.copyWith(
                          color: theme.clinical.alert.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (!_legacyFound)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: surfaces.brand,
                    foregroundColor: surfaces.onBrand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        surfaces.radiusControl,
                      ),
                    ),
                  ),
                  onPressed: _busy ? null : _continue,
                  child: _busy
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: surfaces.onBrand,
                          ),
                        )
                      : Text(
                          l10n.continueAction,
                          style: theme.type.button.copyWith(
                            fontSize: 16,
                            color: surfaces.onBrand,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
