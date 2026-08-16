import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_header.dart';
import '../../../../core/theme/settings_accent.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final content = Theme.of(context).content;
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _HelpSection(
        icon: Icons.help_outline_rounded,
        title: l10n.helpFaqTitle,
        description: l10n.helpFaqDescription,
        color: surfaces.brand,
        route: '/profile/help/faq',
      ),
      _HelpSection(
        icon: Icons.menu_book_outlined,
        title: l10n.helpGlossaryTitle,
        description: l10n.helpGlossaryDescription,
        color: clinical.optimal.accent,
        route: '/profile/help/glossary',
      ),
      _HelpSection(
        icon: Icons.shield_outlined,
        title: l10n.helpLegalTitle,
        description: l10n.helpLegalDescription,
        color: content.tone(ContentCategory.emotional).accent,
        route: '/profile/help/legal',
      ),
      _HelpSection(
        icon: Icons.mail_outline_rounded,
        title: l10n.helpContactTitle,
        description: l10n.helpContactDescription,
        color: clinical.caution.accent,
        route: '/profile/help/contact',
      ),
    ];

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Encabezado común: ícono + título + descripción centrados.
                SettingsPageHeader(
                  icon: Icons.support_agent,
                  title: l10n.helpSupportPageTitle,
                  description: l10n.helpSupportPageDescription,
                  accent: SettingsSection.help.tone(Theme.of(context)),
                ),
                const SizedBox(height: 32),

                // Section cards
                ...sections.map((s) => _buildSectionCard(context, s)),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, _HelpSection s) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: surfaces.cardShadow,
      ),
      child: Material(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push(s.route),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: s.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(s.icon, color: s.color, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: s.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: surfaces.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: s.color.withValues(alpha: 0.6),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ), // Closed Material
    );
  }
}

class _HelpSection {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String route;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.route,
  });
}
