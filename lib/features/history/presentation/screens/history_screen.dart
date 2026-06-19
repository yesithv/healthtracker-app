import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/main_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          MainAppBar(title: l10n.history.toUpperCase()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // Menu items matching Profile _MenuTile style
                _HistoryMenuTile(
                  icon: Icons.straighten,
                  title: l10n.anthropometry,
                  iconColor: const Color(0xFFF57C00),
                  onTap: () => context.push('/history/anthropometry'),
                ),
                _HistoryMenuTile(
                  icon: Icons.favorite,
                  title: l10n.vitalSigns,
                  iconColor: const Color(0xFFE53935),
                  onTap: () => context.push('/history/vital-signs'),
                ),
                _HistoryMenuTile(
                  icon: Icons.bloodtype,
                  title: l10n.lipidProfile,
                  iconColor: const Color(0xFF00897B),
                  onTap: () => context.push('/history/lipid'),
                ),
                _HistoryMenuTile(
                  icon: Icons.accessibility_new,
                  title: l10n.bodyComposition,
                  iconColor: const Color(0xFF5C6BC0),
                  onTap: () => context.push('/history/body-composition'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback? onTap;

  const _HistoryMenuTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D48A0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D48A0),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF0D48A0),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
