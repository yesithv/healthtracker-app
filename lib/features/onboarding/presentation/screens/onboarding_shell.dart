import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/auth/auth_api_client.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/constants/countries.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/measurement_units_screen.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'onboarding_avatar_page.dart';

/// The 3-step onboarding wizard shell (datos → unidades → avatar).
/// La portada de bienvenida vive en /welcome; el idioma se autodetecta del
/// dispositivo (LocaleUnitsProvider) y se cambia desde Preferencias, no aquí.
/// Wraps a [PageView] with step indicators, Next/Finish buttons,
/// and embeds shared profile screens via their `onNext` / `showAppBar` params.
class OnboardingShell extends StatefulWidget {
  /// When true, finishing the wizard creates the patient account (register,
  /// source=APP) with the collected profile. When false the wizard is local-only
  /// ("usar sin cuenta"): the account can be linked later from Profile.
  final bool createAccount;

  const OnboardingShell({super.key, this.createAccount = false});

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
        break;
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

  Future<void> _finishOnboarding() async {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (widget.createAccount) {
      await _tryRegister();
    }
    await onboarding.setComplete();
    if (mounted) context.go('/dashboard');
  }

  /// Crea la cuenta del paciente nuevo (source=APP) con el perfil recogido. No
  /// bloquea: si no hay email o el registro falla (offline, email duplicado), el
  /// usuario entra en modo local y puede vincular la cuenta luego desde Perfil.
  Future<void> _tryRegister() async {
    final profile = Provider.of<UserProfileProvider>(context, listen: false);
    final email = profile.userEmail.trim();
    if (email.isEmpty) return; // sin identificador no se puede crear la cuenta

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
    } catch (e) {
      debugPrint('Registro al terminar onboarding falló: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo crear la cuenta ahora; puedes vincularla luego en Perfil.',
            ),
          ),
        );
      }
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
                  PersonalInfoScreen(
                    key: _personalInfoKey,
                    showAppBar: false,
                    onNext: _nextPage,
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
                        onTap: _nextPage,
                      ),
                    ],
                  ),

                  // Skip text (only on the last step —avatar—, fully optional)
                  if (isLastPage) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        l10n.onboardingSkip,
                        style: theme.type.meta.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
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
  final VoidCallback onTap;

  const _NextButton({
    required this.label,
    required this.isLight,
    required this.onTap,
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
            boxShadow: surfaces.cardShadow.isEmpty
                ? const []
                : [
                    BoxShadow(
                      color: fill.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.type.button.copyWith(color: onFill)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: onFill),
            ],
          ),
        ),
      ),
    );
  }
}
