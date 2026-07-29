import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class DismissibleInfoBanner extends StatelessWidget {
  final String text;

  /// Color de acento del aviso. Lo decide quien lo coloca (normalmente la
  /// identidad de la familia de indicador), no este widget.
  final Color baseColor;
  final VoidCallback onDismiss;

  const DismissibleInfoBanner({
    super.key,
    required this.text,
    required this.baseColor,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: baseColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                text,
                // El texto va en tinta, no en el acento: el color del aviso lo
                // lleva el icono y el borde, y así se lee igual de bien en los
                // cuatro acentos de familia.
                style: theme.type.body.copyWith(fontSize: 12, height: 1.4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: baseColor.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
