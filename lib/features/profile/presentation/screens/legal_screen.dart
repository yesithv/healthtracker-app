import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _LegalSection(
        icon: Icons.apps_rounded,
        title: l10n.helpLegalPurposeTitle,
        body: l10n.helpLegalPurposeBody,
        color: const Color(0xFF0D48A0),
      ),
      _LegalSection(
        icon: Icons.medical_services_outlined,
        title: l10n.helpLegalNotMedicalTitle,
        body: l10n.helpLegalNotMedicalBody,
        color: const Color(0xFFEF4444),
      ),
      _LegalSection(
        icon: Icons.person_outline,
        title: l10n.helpLegalResponsibilityTitle,
        body: l10n.helpLegalResponsibilityBody,
        color: const Color(0xFFF59E0B),
      ),
      _LegalSection(
        icon: Icons.lock_outline,
        title: l10n.helpLegalPrivacyTitle,
        body: l10n.helpLegalPrivacyBody,
        color: const Color(0xFF10B981),
      ),
      _LegalSection(
        icon: Icons.mail_outline_rounded,
        title: l10n.helpLegalContactTitle,
        body: l10n.helpLegalContactBody,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Shield banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF8B5CF6),
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.helpLegalDescription,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal sections
                ...sections.map((s) => _buildLegalTile(context, s)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile(BuildContext context, _LegalSection s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 18),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(s.icon, color: s.color, size: 18),
          ),
          title: Text(
            s.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          iconColor: const Color(0xFF8B5CF6),
          collapsedIconColor: const Color(0xFFCBD5E1),
          children: [
            Text(
              s.body,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}
