import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';

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
  static const _blue = Color(0xFF0D48A0);

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
      setState(() => _error = 'Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _activating = false);
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
                'Traigamos tu historial',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ingresa tu documento (o email). Si ya eres paciente, cargamos tus datos; '
                'si no, creamos tu cuenta.',
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.folder_shared_outlined, color: Color(0xFF047857)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Encontramos un historial clínico asociado a este documento.',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Podemos traerlo y activar tu cuenta para que veas tus datos desde el primer día.',
                        style: TextStyle(color: Color(0xFF047857), fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _activating ? null : _activate,
                        icon: _activating
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cloud_download_outlined),
                        label: Text(
                          _activating ? 'Trayendo tu historial…' : 'Traer mi historial y continuar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _activating
                            ? null
                            : () => context.go('/onboarding?mode=account'),
                        child: const Text('No soy yo — registrarme como nuevo',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
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
              if (!_legacyFound)
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
                      : const Text('Continuar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : () => context.go('/onboarding?mode=offline'),
                child: const Text('Explorar sin cuenta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
