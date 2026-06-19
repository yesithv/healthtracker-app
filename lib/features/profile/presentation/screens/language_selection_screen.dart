import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import '../widgets/profile_settings_layout.dart';

/// Mixin that exposes a [validate] method for wizard-embedded screens.
mixin WizardValidatable {
  /// Returns a list of localized error strings for required fields.
  /// An empty list means all required fields are valid.
  List<String> validate(BuildContext context);
}

class LanguageSelectionScreen extends StatefulWidget {
  /// When set, called instead of Navigator.pop() on confirm.
  /// Used by the onboarding wizard to advance to the next step.
  final VoidCallback? onNext;

  /// Whether to show the SecondaryAppBar. Defaults to true (Profile mode).
  final bool showAppBar;

  const LanguageSelectionScreen({
    super.key,
    this.onNext,
    this.showAppBar = true,
  });

  @override
  State<LanguageSelectionScreen> createState() =>
      LanguageSelectionScreenState();
}

class LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with WizardValidatable {
  String? _tempSelectedCode;

  final List<Map<String, String>> languages = [
    {'label': 'Español', 'code': 'es', 'flag': '🇪🇸'},
    {'label': 'English', 'code': 'en', 'flag': '🇺🇸'},
    {'label': 'Deutsch', 'code': 'de', 'flag': '🇩🇪'},
    {'label': 'Português', 'code': 'pt', 'flag': '🇧🇷'},
    {'label': 'Italiano', 'code': 'it', 'flag': '🇮🇹'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentLocale = Provider.of<LocaleUnitsProvider>(
        context,
        listen: false,
      ).locale;
      setState(() {
        _tempSelectedCode = currentLocale.languageCode;
      });
    });
  }

  /// Returns a list of localized error strings for required fields.
  @override
  List<String> validate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errors = <String>[];
    if (_tempSelectedCode == null || _tempSelectedCode!.isEmpty) {
      errors.add(l10n.validationSelectLanguage);
    }
    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<LocaleUnitsProvider>(context, listen: false);

    final content = SingleChildScrollView(
      child: ProfileSettingsLayout(
        icon: Icons.language_rounded,
        title: l10n.languageTitle,
        description: l10n.languageDescription,
        showConfirmButton: widget.showAppBar,
        onConfirm: () {
          if (_tempSelectedCode != null) {
            prefs.setLocale(Locale(_tempSelectedCode!));
          }
          if (widget.onNext != null) {
            widget.onNext!();
          } else {
            Navigator.pop(context);
          }
        },
        child: Column(
          children: languages
              .map(
                (lang) => _LanguageTile(
                  label: lang['label']!,
                  flag: lang['flag']!,
                  isSelected: _tempSelectedCode == lang['code'],
                  onTap: () {
                    setState(() => _tempSelectedCode = lang['code']!);
                    prefs.setLocale(Locale(lang['code']!));
                  },
                ),
              )
              .toList(),
        ),
      ),
    );

    if (!widget.showAppBar) {
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0D48A0).withValues(alpha: 0.05)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF0D48A0) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF0D48A0)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0D48A0)
                        : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D48A0),
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
