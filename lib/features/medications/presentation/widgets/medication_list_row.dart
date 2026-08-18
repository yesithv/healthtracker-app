import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../view_models/med_view_models.dart';
import 'med_icon.dart';

/// Fila de «Tus medicamentos»: icono, nombre, pauta abreviada y chevron. Abre
/// el detalle del medicamento.
class MedicationListRow extends StatelessWidget {
  const MedicationListRow({super.key, required this.med, this.onTap});

  final MedVm med;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaces.selection,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                MedIcon(icon: med.icon, color: med.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: theme.type.cardTitle),
                      const SizedBox(height: 3),
                      Text(
                        '${med.form} · ${med.strength} · ${med.schedule}',
                        style: theme.type.meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: surfaces.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
