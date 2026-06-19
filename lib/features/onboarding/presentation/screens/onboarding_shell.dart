import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/onboarding_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/app_theme.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/language_selection_screen.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/screens/measurement_units_screen.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'onboarding_welcome_page.dart';
import 'onboarding_avatar_page.dart';

/// The 5-step onboarding wizard shell.
/// Wraps a [PageView] with step indicators, Next/Finish buttons,
/// and embeds shared profile screens via their `onNext` / `showAppBar` params.
class OnboardingShell extends StatefulWidget {
  const OnboardingShell({super.key});

  @override
  State<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends State<OnboardingShell> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;

  // GlobalKeys to access embedded screen states and call validate()
  final GlobalKey<LanguageSelectionScreenState> _languageKey =
      GlobalKey<LanguageSelectionScreenState>();
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
      case 1: // Language — required
        errors = _languageKey.currentState?.validate(context) ?? [];
        break;
      case 2: // Personal Info — name, dob, gender required
        errors = _personalInfoKey.currentState?.validate(context) ?? [];
        break;
      // Step 3 (Measurement Units): always has a default → no validation needed
      // Step 4 (Avatar): fully optional → no validation
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
    await onboarding.setComplete();
    if (mounted) context.go('/dashboard');
  }

  // ── UI HELPERS ───────────────────────────────────────────────────────────────

  /// Returns the background color for the bottom action area based on step.
  Color _bottomBgColor() {
    if (_currentPage == 0) return const Color(0xFF0D48A0); // Welcome (blue)
    return const Color(0xFFF4F6F9); // Light for other steps
  }

  bool get _isWelcomeStep => _currentPage == 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  // Step 1 — Welcome
                  const OnboardingWelcomePage(),

                  // Step 2 — Language (shared with Profile)
                  LanguageSelectionScreen(
                    key: _languageKey,
                    showAppBar: false,
                    onNext: _nextPage,
                  ),

                  // Step 3 — Personal Info (shared with Profile)
                  PersonalInfoScreen(
                    key: _personalInfoKey,
                    showAppBar: false,
                    onNext: _nextPage,
                  ),

                  // Step 4 — Measurement Units (shared with Profile)
                  // No validation needed: always has a default value
                  MeasurementUnitsScreen(
                    showAppBar: false,
                    onNext: _nextPage,
                  ),

                  // Step 5 — Avatar (fully optional)
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
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Step counter text
                      Text(
                        l10n.onboardingStep(_currentPage + 1, _totalPages),
                        style: TextStyle(
                          fontSize: 13,
                          color: _isWelcomeStep
                              ? Colors.white60
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
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

                  // Skip text (only on avatar step, since it is fully optional)
                  if (_currentPage == 4) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: Text(
                        l10n.onboardingSkip,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
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
        final Color activeColor =
            isLight ? Colors.white : AppTheme.primaryColor;
        final Color inactiveColor = isLight
            ? Colors.white.withValues(alpha: 0.3)
            : const Color(0xFFCBD5E1);

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.3)
                    : AppTheme.primaryColor.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isLight ? AppTheme.primaryColor : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isLight ? AppTheme.primaryColor : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
