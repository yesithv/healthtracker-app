import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class AppBrandHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double iconSize;
  final double titleFontSize;
  final double subtitleFontSize;

  const AppBrandHeader({
    super.key,
    this.title = 'MY VITALS',
    this.subtitle = 'Health Tracker',
    this.iconSize = 28,
    this.titleFontSize = 16,
    this.subtitleFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = theme.surfaces.onBrand;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // El ICONO no cambia entre temas: sólo su color se adapta al fondo.
        Icon(Icons.monitor_heart, color: onBrand, size: iconSize),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.type.display.copyWith(
                color: onBrand,
                fontSize: titleFontSize,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: theme.type.displayMeta.copyWith(
                  color: onBrand.withValues(alpha: 0.78),
                  fontSize: subtitleFontSize,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
