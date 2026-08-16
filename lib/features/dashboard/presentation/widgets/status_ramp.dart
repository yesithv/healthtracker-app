import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';

/// Barra de ZONA CLÍNICA: cuatro segmentos —bajo · óptimo · atención · alto—
/// que dibujan la rampa de severidad del tema y resaltan aquel en el que cae la
/// lectura actual.
///
/// A diferencia de una barra posicional (que necesita los límites numéricos del
/// rango), esta se alimenta SOLO del [ClinicalStatus] que ya produce el
/// clasificador, así que sirve para cualquier indicador sin conocer sus cortes.
/// El color sale de `clinical.severityRamp`; el segmento activo va a tinta plena
/// y algo más alto, el resto atenuados: se lee «en qué zona estoy» de un vistazo.
///
/// No pinta nada para [ClinicalStatus.neutral]: un valor sin lectura clínica no
/// tiene zona que señalar.
class StatusRamp extends StatelessWidget {
  const StatusRamp({super.key, required this.status, this.width});

  final ClinicalStatus status;

  /// Ancho opcional. Sin él ocupa el ancho disponible (los segmentos son
  /// `Expanded`); con él, la barra se acota (útil en las casillas pequeñas).
  final double? width;

  @override
  Widget build(BuildContext context) {
    if (status == ClinicalStatus.neutral) return const SizedBox.shrink();

    final clinical = Theme.of(context).clinical;
    final ramp = clinical.severityRamp; // info · optimal · caution · alert
    // El orden de `severityRamp` coincide con `kDiagnosticStatuses`, así que el
    // índice del estado en esa lista es el segmento que hay que resaltar.
    final activeIndex = kDiagnosticStatuses.indexOf(status);

    final bar = Row(
      mainAxisSize: width == null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (var i = 0; i < ramp.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          _segment(color: ramp[i], active: i == activeIndex),
        ],
      ],
    );

    if (width == null) return bar;
    return SizedBox(width: width, child: bar);
  }

  Widget _segment({required Color color, required bool active}) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: active ? 7 : 5,
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(4),
      ),
    );
    // Con ancho fijo cada segmento reparte por igual dentro del SizedBox; sin
    // él, los `Expanded` reparten el ancho del padre.
    return Expanded(child: child);
  }
}
