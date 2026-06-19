import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/services/biometric_service.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/features/profile/presentation/widgets/profile_settings_layout.dart';
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
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const SecondaryAppBar(),
      body: SingleChildScrollView(
        child: ProfileSettingsLayout(
          icon: Icons.security_outlined,
          title: l10n.privacySecurity,
          description: l10n.privacySecurityDescription,
          onConfirm: () {
            Navigator.pop(context);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fingerprint,
                            color: Color(0xFF8B5CF6),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                l10n.biometricLockSubtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: prefs.isBiometricEnabled,
                          activeThumbColor: const Color(0xFF8B5CF6),
                          onChanged: _isBiometricSupported
                              ? (value) async {
                                  if (value) {
                                    final authenticated = await _biometricService.authenticate(
                                      localizedReason: l10n.unlockAppToContinue,
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
                          const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.biometricNotAvailable,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF0284C7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF0369A1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
