import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class ActionButton extends StatelessWidget {
  final String text;

  /// Color de acento del botón. Lo pasa quien lo usa porque suele ser el de la
  /// FAMILIA de indicador («registrar signos vitales» va en el rojo de vitales),
  /// y ese color ya sale del tema: `Theme.of(context).metrics.tone(...).accent`.
  final Color color;

  final bool solid;
  final VoidCallback? onPressed;

  const ActionButton({
    super.key,
    required this.text,
    required this.color,
    required this.solid,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final radius = BorderRadius.circular(surfaces.radiusControl);

    // En variante hueca el relleno se MEZCLA con la tarjeta del tema en lugar de
    // apoyarse en una transparencia: así el botón descansa sobre el material real
    // del tema y no sobre la suposición de que el fondo es blanco.
    final Color background = solid
        ? color
        : Color.lerp(surfaces.card, color, 0.06)!;

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: radius,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: solid
                ? null
                : Border.all(
                    color: Color.lerp(surfaces.card, color, 0.30)!,
                    width: 1.5,
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: theme.type.button.copyWith(
              color: solid ? surfaces.onBrand : color,
            ),
          ),
        ),
      ),
    );
  }
}
