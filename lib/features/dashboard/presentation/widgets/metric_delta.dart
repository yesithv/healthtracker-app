import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';

/// Variación de una lectura respecto a la ANTERIOR: una flecha ▲/▼ (o «—» si no
/// cambió) y la magnitud del cambio.
///
/// Se pinta en tinta APAGADA a propósito. Un cambio no es un hallazgo clínico
/// —subir de 118 a 121 de sistólica no es «malo»—, así que no gasta el rojo ni
/// el verde de la paleta clínica; sigue el mismo criterio que las flechas de
/// meta de las tarjetas. La dirección la da la flecha, no el color.
///
/// Si falta el valor previo (primera medición, o el campo no venía en el
/// registro anterior) no dibuja nada: no hay variación que contar.
class MetricDelta extends StatelessWidget {
  const MetricDelta({
    super.key,
    required this.current,
    required this.previous,
    this.decimals = 0,
    this.unit,
  });

  final double? current;
  final double? previous;

  /// Decimales de la magnitud (0 para vitales/IMC, 1 para grasa/músculo…).
  final int decimals;

  /// Sufijo opcional tras la magnitud (p. ej. «%», « kg»).
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final c = current;
    final p = previous;
    if (c == null || p == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final color = theme.surfaces.inkMuted;
    final diff = c - p;

    // Umbral por debajo del cual se considera «sin cambio», acorde a los
    // decimales que se muestran (así 0.04 con 1 decimal no aparece como ▲0.0).
    final eps = 0.5 / (decimals == 0 ? 1 : 10 * decimals);
    final IconData icon;
    if (diff > eps) {
      icon = Icons.arrow_upward_rounded;
    } else if (diff < -eps) {
      icon = Icons.arrow_downward_rounded;
    } else {
      icon = Icons.remove_rounded;
    }

    final magnitude = diff.abs().toStringAsFixed(decimals);
    final label = icon == Icons.remove_rounded
        ? magnitude // «—» + 0: solo el guion basta, pero mantenemos alineación
        : '$magnitude${unit ?? ''}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(label, style: theme.type.meta.copyWith(color: color)),
      ],
    );
  }
}
