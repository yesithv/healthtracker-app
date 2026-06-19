import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/secondary_app_bar.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _HelpSection(
        icon: Icons.help_outline_rounded,
        title: l10n.helpFaqTitle,
        description: l10n.helpFaqDescription,
        color: const Color(0xFF0D48A0),
        route: '/profile/help/faq',
      ),
      _HelpSection(
        icon: Icons.menu_book_outlined,
        title: l10n.helpGlossaryTitle,
        description: l10n.helpGlossaryDescription,
        color: const Color(0xFF10B981),
        route: '/profile/help/glossary',
      ),
      _HelpSection(
        icon: Icons.shield_outlined,
        title: l10n.helpLegalTitle,
        description: l10n.helpLegalDescription,
        color: const Color(0xFF8B5CF6),
        route: '/profile/help/legal',
      ),
      _HelpSection(
        icon: Icons.mail_outline_rounded,
        title: l10n.helpContactTitle,
        description: l10n.helpContactDescription,
        color: const Color(0xFFF59E0B),
        route: '/profile/help/contact',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                // Header description
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D48A0), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0D48A0).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.helpSupportPageTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.helpSupportPageDescription,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
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
