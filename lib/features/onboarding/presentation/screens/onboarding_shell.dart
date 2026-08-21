import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/local_data_reset.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/auth/pending_account.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/measurement_units_screen.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import 'onboarding_avatar_page.dart';

/// Cómo terminó el intento de crear la cuenta al cerrar el asistente.
enum _RegisterOutcome {
  /// Cuenta creada y sesión guardada.
  created,

  /// No se pudo hablar con el servidor: queda pendiente y el usuario entra.
  deferred,

  /// El servidor rechazó los datos: el usuario tiene que corregir algo.
  rejected,
}

/// Asistente de alta en 3 pasos (datos → unidades → avatar).
///
/// La portada vive en /welcome; el idioma se autodetecta del dispositivo
/// (LocaleUnitsProvider) y se cambia desde Preferencias, no aquí.
/// Envuelve un [PageView] con indicadores de paso y botones Siguiente/Finalizar,
/// y reutiliza pantallas de Perfil vía sus parámetros `onNext` / `showAppBar`.
///
/// La cuenta es OBLIGATORIA, pero su CREACIÓN puede diferirse:
///
///   · El servidor acepta  → cuenta creada, sesión guardada, al panel.
///   · Falla la RED        → los datos quedan en el dispositivo, el alta se marca
///                           pendiente y el usuario entra igual. La cuenta se
///                           crea en el primer intento que funcione (al arrancar
///                           la app o al pulsar «Sincronizar»).
///   · El servidor RECHAZA → correo duplicado, dato inválido… Reintentar no
///                           ayuda: se muestra el motivo y se queda en el paso.
///
/// La diferencia entre los dos fallos la da [AuthNetworkException]; sin ella,
/// un corte de red y un correo duplicado serían indistinguibles y habría que
/// tratarlos igual.
class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  // GlobalKey to access the embedded Personal Info screen state and call validate()
  final GlobalKey<PersonalInfoScreenState> _personalInfoKey =
      GlobalKey<PersonalInfoScreenState>();

  /// Registro en curso: bloquea el botón para no crear dos cuentas.
  bool _registering = false;

  /// Motivo por el que falló el último intento de registro, si falló.
  String? _registerError;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── VALIDATION ──────────────────────────────────────────────────────────────

  /// Validates the current step.
  /// Returns true if valid and the wizard may advance, false otherwise.
  bool _validateCurrentStep() {
    List<String> errors = [];

    switch (_currentPage) {
      case 0: // Personal Info — name, dob, gender required
        errors = _personalInfoKey.currentState?.validate(context) ?? [];
      // Step 1 (Measurement Units): always has a default → no validation needed
      // Step 2 (Avatar): fully optional → no validation
      default:
        break;
    }

    if (errors.isNotEmpty) {
      return false;
    }
    return true;
  }

  // ── NAVIGATION ──────────────────────────────────────────────────────────────

  void _nextPage() {
    if (!_validateCurrentStep()) return;

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  /// Cierra el asistente creando la cuenta.
  ///
  /// Solo se queda en el paso cuando el servidor RECHAZA los datos, porque eso
  /// el usuario sí puede arreglarlo. Si lo que falla es la red, entra: sus datos
  /// están en el dispositivo y la cuenta se creará luego.
  Future<void> _finishOnboarding() async {
    if (_registering) return;
    setState(() {
      _registering = true;
      _registerError = null;
    });

    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    final outcome = await _register();
    if (!mounted) return;

    if (outcome == _RegisterOutcome.rejected) {
      setState(() => _registering = false);
      return;
    }

    await onboarding.setComplete();
    if (mounted) context.go('/dashboard');
  }

  /// Crea la cuenta del paciente nuevo (source=APP) con el perfil recogido.
  Future<_RegisterOutcome> _register() async {
    final l10n = AppLocalizations.of(context)!;
    final profile = Provider.of<UserProfileProvider>(context, listen: false);
    final email = profile.userEmail.trim();
    if (email.isEmpty) {
      // Red de seguridad: el paso 1 ya exige el correo, pero si llegara vacío
      // no hay identificador con el que crear la cuenta.
      setState(() => _registerError = l10n.validationEnterEmail);
      return _RegisterOutcome.rejected;
    }

    // País: el elegido en el picker de prefijo o, si nunca lo tocó, el del
    // locale del dispositivo (captura silenciosa; el backend valida el código).
    final country =
        Countries.byIso(profile.userCountryCode) ?? Countries.deviceDefault();
    // Teléfono en formato internacional (prefijo + número): listo para WhatsApp.
    final localPhone = profile.userPhone.replaceAll(RegExp(r'[^0-9]'), '');

    final auth = AuthApiClient();
    try {
      final account = await auth.register(
        firstName: profile.userName.trim().isEmpty
            ? 'Paciente'
            : profile.userName.trim(),
        email: email,
        birthDate: profile.birthDate,
        sex: profile.userGender.isEmpty ? null : profile.userGender,
        phone: localPhone.isEmpty ? null : '${country.dialCode}$localPhone',
        country: country.iso,
      );
      await PatientSession.instance.save(
        publicId: account.publicId,
        firstName: account.firstName,
        source: account.source,
      );
      // El paciente recién creado es el dueño de los datos locales de este device.
      await setDataOwner(account.publicId);
      // Cuenta creada: nada queda pendiente.
      await PendingAccountStore.instance.clear();
      return _RegisterOutcome.created;
    } on AuthNetworkException catch (e) {
      // Sin red o servidor caído: los datos ya están guardados en el perfil
      // local, así que basta con recordar que el alta sigue pendiente.
      await PendingAccountStore.instance.markPending(reason: e.message);
      return _RegisterOutcome.deferred;
    } on AuthException catch (e) {
      // El servidor rechaza el dato (correo duplicado, formato inválido…):
      // reintentar no arregla nada, hay que decírselo al usuario.
      if (mounted) setState(() => _registerError = e.message);
      return _RegisterOutcome.rejected;
    } catch (e) {
      debugPrint('Registro al terminar onboarding falló: $e');
      // Causa desconocida: se trata como diferible en lugar de dejar al usuario
      // fuera con sus datos ya escritos.
      await PendingAccountStore.instance.markPending(
        reason: l10n.commonRegisterFailed,
      );
      return _RegisterOutcome.deferred;
    } finally {
      auth.close();
    }
  }

  // ── UI HELPERS ───────────────────────────────────────────────────────────────

  /// Fondo de la barra de acciones: el lienzo del tema activo.
  Color _bottomBgColor() => Theme.of(context).surfaces.canvas;

  // Ya no hay un paso "welcome" oscuro dentro del wizard; la barra siempre es clara.
  bool get _isWelcomeStep => false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final isLastPage = _currentPage == _totalPages - 1;

    return PopScope(
      // Prevent back navigation on first step; allow going back on others
      canPop: _currentPage > 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentPage > 0) _prevPage();
      },
      child: Scaffold(
        body: Column(
          children: [
            // ── PAGE CONTENT ─────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  // Step 1 — Personal Info (shared with Profile)
                  // En modo cuenta el email es obligatorio: es el identificador con el
                  // que se crea la cuenta (register), así el alta no queda en modo local.
                  PersonalInfoScreen(
                    key: _personalInfoKey,
                    showAppBar: false,
                    onNext: _nextPage,
                    // La cuenta es obligatoria y el registro necesita un
                    // identificador: aquí el correo deja de ser opcional.
                    requireEmail: true,
                  ),

                  // Step 2 — Measurement Units (shared with Profile)
                  // No validation needed: always has a default value
                  MeasurementUnitsScreen(showAppBar: false, onNext: _nextPage),

                  // Step 3 — Avatar (fully optional)
                  const OnboardingAvatarPage(),
                ],
              ),
            ),

            // ── BOTTOM NAVIGATION BAR ─────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: _bottomBgColor(),
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Motivo del fallo de registro, si lo hubo. Va aquí y no en
                  // un SnackBar porque es un error bloqueante: el usuario tiene
                  // que verlo y reintentar, no verlo pasar.
                  if (_registerError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.clinical.alert.surface,
                        borderRadius: BorderRadius.circular(
                          surfaces.radiusControl,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.clinical.alert.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _registerError!,
                              style: theme.type.body.copyWith(
                                fontSize: 13,
                                color: theme.clinical.alert.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Step indicator dots
                  _StepIndicators(
                    total: _totalPages,
                    current: _currentPage,
                    isLight: _isWelcomeStep,
                  ),
                  const SizedBox(height: 20),

                  // Step label + action row
                  Row(
                    children: [
                      // Back button (hidden on step 0)
                      AnimatedOpacity(
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          onPressed: _currentPage > 0 ? _prevPage : null,
                          icon: Icon(
                            Icons.arrow_back_ios_rounded,
                            color: _isWelcomeStep
                                ? surfaces.onBrand.withValues(alpha: 0.7)
                                : surfaces.inkSecondary,
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Step counter text
                      // «PASO 1 DE 3»: rótulo de sección, en versalitas
                      // monoespaciadas cuando el tema lo pide.
                      Text(
                        l10n
                            .onboardingStep(_currentPage + 1, _totalPages)
                            .toUpperCase(),
                        style: theme.type.sectionLabel.copyWith(
                          color: _isWelcomeStep
                              ? surfaces.onBrand.withValues(alpha: 0.6)
                              : surfaces.inkMuted,
                        ),
                      ),

                      const Spacer(),

                      // Next / Finish button
                      _NextButton(
                        label: isLastPage
                            ? l10n.onboardingFinish
                            : l10n.onboardingNext,
                        isLight: _isWelcomeStep,
                        busy: _registering,
                        onTap: _registering ? null : _nextPage,
                      ),
                    ],
                  ),

                  // Antes había aquí un enlace de «omitir» en el paso del avatar.
                  // Se retira: hacía exactamente lo mismo que «Finalizar» —la
                  // foto siempre fue opcional y sigue siéndolo—, así que eran dos
                  // botones para la misma acción, uno de ellos insinuando que el
                  // otro obligaba a poner foto.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── STEP INDICATORS ──────────────────────────────────────────────────────────

/// Animated step indicator dots.
class _StepIndicators extends StatelessWidget {
  final int total;
  final int current;
  final bool isLight;

  const _StepIndicators({
    required this.total,
    required this.current,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        final surfaces = Theme.of(context).surfaces;
        final Color activeColor = isLight ? surfaces.onBrand : surfaces.brand;
        final Color inactiveColor = isLight
            ? surfaces.onBrand.withValues(alpha: 0.3)
            : surfaces.track;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── NEXT BUTTON ──────────────────────────────────────────────────────────────

/// Primary action button for Next/Finish.
class _NextButton extends StatelessWidget {
  final String label;
  final bool isLight;
  final bool busy;
  final VoidCallback? onTap;

  const _NextButton({
    required this.label,
    required this.isLight,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);

    final Color fill = isLight ? surfaces.onBrand : surfaces.brand;
    final Color onFill = isLight ? surfaces.brand : surfaces.onBrand;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            // El halo del botón lo hereda del tema: en «Consulta Serena» las
            // superficies son planas y aquí no se dibuja sombra ninguna.
            boxShadow: surfaces.glow(
              fill,
              alpha: 0.35,
              blur: 12,
              offset: const Offset(0, 4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.type.button.copyWith(color: onFill)),
              const SizedBox(width: 6),
              if (busy)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onFill,
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: onFill),
            ],
          ),
        ),
      ),
    );
  }
}
