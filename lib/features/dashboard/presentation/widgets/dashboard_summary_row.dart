import 'package:flutter/material.dart';

import 'appointments_card.dart';
import 'medications_summary_card.dart';

/// Fila del fondo del Dashboard con dos cuadrados del mismo tamaño: Medicamentos
/// a la izquierda y Citas médicas (placeholder) a la derecha. Cada uno se fuerza
/// a proporción 1:1 con [AspectRatio] para que sean cuadrados, no rectángulos.
class DashboardSummaryRow extends StatelessWidget {
  const DashboardSummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: MedicationsSummaryCard(),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: AppointmentsCard(),
          ),
        ),
      ],
    );
  }
}
