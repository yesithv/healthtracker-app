import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/services/biometric_service.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_layout.dart';
import 'package:myvitals_healthtracker_app/core/theme/settings_accent.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final isSupported = await _biometricService.isBiometricAvailable();
    setState(() {
      _isBiometricSupported = isSupported;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final content = Theme.of(context).content;
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: SingleChildScrollView(
        child: SettingsPageLayout(
          icon: Icons.security_outlined,
          title: l10n.privacySecurity,
          description: l10n.privacySecurityDescription,
          accent: SettingsSection.privacy.tone(Theme.of(context)),
          onConfirm: () {
            Navigator.pop(context);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaces.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: surfaces.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: content
                                .tone(ContentCategory.emotional)
                                .accent
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fingerprint,
                            color: content
                                .tone(ContentCategory.emotional)
                                .accent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.biometricLockTitle,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: surfaces.ink,
                                ),
                              ),
                              Text(
                                l10n.biometricLockSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: surfaces.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: prefs.isBiometricEnabled,
                          activeThumbColor: content
                              .tone(ContentCategory.emotional)
                              .accent,
                          onChanged: _isBiometricSupported
                              ? (value) async {
                                  if (value) {
                                    final authenticated =
                                        await _biometricService.authenticate(
                                          localizedReason:
                                              l10n.unlockAppToContinue,
                                        );
                                    if (authenticated) {
                                      prefs.setBiometricEnabled(true);
                                    }
                                  } else {
                                    prefs.setBiometricEnabled(false);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                    if (!_isBiometricSupported) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: clinical.alert.accent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.biometricNotAvailable,
                              style: TextStyle(
                                fontSize: 12,
                                color: clinical.alert.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoBanner(l10n.biometricReasoning),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner(String text) {
    final clinical = Theme.of(context).clinical;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: clinical.info.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clinical.info.surface),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: clinical.info.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: clinical.info.accent,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
