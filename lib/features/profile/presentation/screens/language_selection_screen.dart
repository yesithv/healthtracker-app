import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_layout.dart';
import 'package:myvitals_healthtracker_app/core/theme/settings_accent.dart';

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
    final surfaces = Theme.of(context).surfaces;
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<LocaleUnitsProvider>(context, listen: false);

    final content = SingleChildScrollView(
      child: SettingsPageLayout(
        icon: Icons.language_rounded,
        title: l10n.languageTitle,
        description: l10n.languageDescription,
        accent: SettingsSection.language.tone(Theme.of(context)),
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
                    setState(() => _tempSelectedCode = lang['code']);
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
      backgroundColor: surfaces.canvas,
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
    final surfaces = Theme.of(context).surfaces;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? surfaces.selection : surfaces.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? surfaces.brand : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: surfaces.cardShadow,
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
                    color: isSelected ? surfaces.brand : surfaces.ink,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? surfaces.brand : surfaces.inkMuted,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: surfaces.brand,
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
