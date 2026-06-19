import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/app_theme.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

class ProfileSettingsLayout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final VoidCallback onConfirm;
  final bool showConfirmButton;

  const ProfileSettingsLayout({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    required this.onConfirm,
    this.showConfirmButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Icon Header
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 32, color: AppTheme.primaryColor),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Content
          child,
          const SizedBox(height: 40),
          // Confirmation Button
          if (showConfirmButton) ...[
            ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              label: Text(
                l10n.savePreferences,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
