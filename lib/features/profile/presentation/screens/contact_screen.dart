import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _launchEmail(String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'yesithvalencia@gmail.com',
      queryParameters: {'subject': 'My Vitals — $subject'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Contact cards row
                Row(
                  children: [
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.bug_report_outlined,
                        title: l10n.helpContactReportBug,
                        description: l10n.helpContactReportBugDesc,
                        color: clinical.alert.accent,
                        onTap: () => _launchEmail('Bug Report'),
                        buttonLabel: l10n.helpContactSendEmail,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ContactCard(
                        icon: Icons.lightbulb_outline,
                        title: l10n.helpContactSuggest,
                        description: l10n.helpContactSuggestDesc,
                        color: clinical.caution.accent,
                        onTap: () => _launchEmail('Sugerencia'),
                        buttonLabel: l10n.helpContactSendEmail,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // App version section
                _SectionHeader(label: l10n.helpContactAppVersion),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surfaces.card,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: surfaces.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaces.selection,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.system_update_alt,
                          color: surfaces.brand,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Vitals — Health Tracker',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: surfaces.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'v1.1.0  •  © 2026 My Vitals Health Inc.',
                            style: TextStyle(
                              fontSize: 12,
                              color: surfaces.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // What's new
                _SectionHeader(label: l10n.helpContactWhatsNew),
                _ChangelogCard(
                  version: l10n.helpContactV110,
                  changes: l10n.helpContactV110Changes,
                  isCurrent: true,
                ),
                const SizedBox(height: 10),
                _ChangelogCard(
                  version: l10n.helpContactV100,
                  changes: l10n.helpContactV100Changes,
                  isCurrent: false,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: surfaces.inkMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final String buttonLabel;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: surfaces.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: surfaces.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.send_outlined, size: 14),
              label: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: surfaces.onBrand,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final String version;
  final String changes;
  final bool isCurrent;

  const _ChangelogCard({
    required this.version,
    required this.changes,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCurrent ? surfaces.selection : surfaces.card,
        borderRadius: BorderRadius.circular(16),
        border: isCurrent
            ? Border.all(color: surfaces.brand.withValues(alpha: 0.2))
            : Border.all(color: surfaces.inset),
        boxShadow: surfaces.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCurrent ? Icons.new_releases_outlined : Icons.history,
                size: 16,
                color: isCurrent ? surfaces.brand : surfaces.inkMuted,
              ),
              const SizedBox(width: 8),
              Text(
                version,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCurrent ? surfaces.brand : surfaces.inkSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            changes,
            style: TextStyle(
              fontSize: 12,
              color: surfaces.inkSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
