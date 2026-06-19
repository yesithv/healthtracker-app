import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../constants/metric_colors.dart';

/// Shows the register modal with a blurred background.
void showRegisterModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    enableDrag: true,
    builder: (context) => const _RegisterModalContent(),
  );
}

class _RegisterModalContent extends StatelessWidget {
  const _RegisterModalContent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.registerIndicators,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.8,
                      color: Color(0xFF0D48A0),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 2x2 Grid — smaller cards, more gap
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 2.0, // wide cards → shorter height
                children: [
                  _RegisterOption(
                    icon: Icons.straighten,
                    label: l10n.anthropometry,
                    iconColor: MetricColors.anthropoColor,
                    bgColor: MetricColors.anthropoBg,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/record-anthropometric');
                    },
                  ),
                  _RegisterOption(
                    icon: Icons.favorite,
                    label: l10n.vitalSigns,
                    iconColor: MetricColors.vitalsColor,
                    bgColor: MetricColors.vitalsBg,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _RegisterOption(
                    icon: Icons.bloodtype,
                    label: l10n.lipidProfile,
                    iconColor: MetricColors.lipidColor,
                    bgColor: MetricColors.lipidBg,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _RegisterOption(
                    icon: Icons.accessibility_new,
                    label: l10n.bodyComposition,
                    iconColor: MetricColors.compositionColor,
                    bgColor: MetricColors.compositionBg,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _RegisterOption({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
