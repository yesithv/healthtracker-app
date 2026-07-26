import 'package:flutter/material.dart';

import '../utils/health_classifiers.dart';
import 'status_chip.dart';

/// Insignia del estado de IMC.
///
/// Antes derivaba color, fondo e icono de sus propios cortes (`bmi < 18.5`…),
/// duplicando los umbrales que ya viven en [BmiCategory] —con el riesgo de que
/// la insignia dijera «normal» mientras el resto de la app decía «sobrepeso»
/// porque el backoffice había movido un rango—. Ahora delega: [BmiCategory]
/// decide el estado y [StatusChip] lo pinta según el tema activo.
class BmiStatusBadge extends StatelessWidget {
  final double bmi;

  /// Texto ya localizado (p. ej. `l10n.bmiNormal`).
  final String label;

  const BmiStatusBadge({super.key, required this.bmi, required this.label});

  @override
  Widget build(BuildContext context) {
    final status = BmiCategory.of(bmi).status;
    return StatusChip(
      status: status,
      label: label,
      icon: iconForStatus(status),
    );
  }
}
