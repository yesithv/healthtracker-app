import 'package:flutter/material.dart';

import 'appointments_card.dart';
import 'medications_summary_card.dart';

/// Fila del fondo del Dashboard con dos cuadros gemelos: Medicamentos a la
/// izquierda y Citas médicas a la derecha.
///
/// Ambos comparten el MISMO alto sin fijarlo a mano: [IntrinsicHeight] mide el
/// contenido más alto de los dos y estira el otro hasta igualarlo, y ese alto lo
/// manda el propio contenido. Antes se forzaba una proporción fija con
/// [AspectRatio] dentro del `ListView` (altura entrante no acotada): esa
/// combinación imponía un alto ajeno al contenido que —a anchos reales de
/// móvil— dejaba el texto desbordado FUERA del recuadro decorado (las tarjetas
/// se veían «sin borde», flotando sobre el lienzo) y añadía extensión de scroll
/// fantasma. Con el alto dirigido por el contenido, el `Container` decorado
/// siempre envuelve lo que pinta y el scroll cierra justo tras la fila.
class DashboardSummaryRow extends StatelessWidget {
  const DashboardSummaryRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: MedicationsSummaryCard()),
          SizedBox(width: 16),
          Expanded(child: AppointmentsCard()),
        ],
      ),
    );
  }
}
