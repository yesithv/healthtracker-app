import 'package:flutter/material.dart';

import 'appointments_card.dart';
import 'medications_summary_card.dart';

/// Fila del fondo del Dashboard con dos cuadros del mismo tamaño: Medicamentos
/// a la izquierda y Citas médicas a la derecha. Cada uno se fuerza a la misma
/// proporción con [AspectRatio] para que sean gemelos. Se usa una relación
/// ligeramente más alta que ancha ([_cardAspectRatio]) para darle aire al
/// contenido —antes eran cuadrados 1:1 y las tarjetas quedaban a medio pintar—.
class DashboardSummaryRow extends StatelessWidget {
  const DashboardSummaryRow({super.key});

  /// Un poco más altos que anchos: el contenido (próxima toma / próxima cita +
  /// semáforo) llena mejor el espacio.
  static const double _cardAspectRatio = 0.82;

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: _cardAspectRatio,
            child: MedicationsSummaryCard(),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: _cardAspectRatio,
            child: AppointmentsCard(),
          ),
        ),
      ],
    );
  }
}
