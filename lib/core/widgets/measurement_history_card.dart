import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/theme_context.dart';

/// Tarjeta de una medición en el historial.
///
/// Antes cada pantalla de historial (antropometría, composición, lípidos, signos
/// vitales) copiaba el mismo `Container` + `Row` a mano. En todas, la columna de
/// la izquierda no se envolvía en `Expanded`, así que una línea de descripción
/// larga («MUSCLE 30.9% · VISCERAL 5 · …») crecía hasta ocupar todo el ancho y
/// empujaba el chip de estado fuera de la pantalla. Este widget centraliza el
/// contenedor, la fecha y —lo importante— el layout correcto: la columna cede
/// espacio al chip en vez de expulsarlo.
///
/// Cada indicador solo inyecta lo que varía: la fila de valor ([value]), la línea
/// de descripción opcional ([detail]) y su insignia de estado ([trailing]).
class MeasurementHistoryCard extends StatelessWidget {
  const MeasurementHistoryCard({
    super.key,
    required this.date,
    required this.value,
    this.detail,
    this.trailing,
  });

  /// Fecha de la toma. Se formatea aquí para que las cuatro pantallas muestren la
  /// misma cabecera («10 AUG 2026») sin repetir el formateo.
  final DateTime date;

  /// Fila de valor + unidad. La construye cada llamante porque cambia por
  /// indicador (p. ej. «63.4 kg (BMI 23.3)», «26 % FAT», «120/80 mmHg ♥ 72 bpm»).
  final Widget value;

  /// Línea de descripción opcional (perímetros, composición…). Se recorta con «…»
  /// para no volver a desbordar la tarjeta.
  final String? detail;

  /// Insignia de estado a la derecha (`StatusChip` / `BmiStatusBadge`). Opcional:
  /// algunos registros no tienen estado clínico que mostrar.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final dateLabel = DateFormat('dd MMM yyyy').format(date).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: surfaces.cardDecoration().copyWith(
        border: Border.all(color: surfaces.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: theme.type.sectionLabel.copyWith(
                    fontSize: 10,
                    color: surfaces.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                value,
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail!,
                    style: theme.type.meta.copyWith(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
