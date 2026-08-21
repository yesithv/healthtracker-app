import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../view_models/med_view_models.dart';
import 'med_icon.dart';

/// Fila de una toma: icono del medicamento, nombre, «cantidad · hora» y a la
/// derecha el marcador de estado (círculo vacío por tomar, ✓ tomado, ✕ omitido).
class MedicationDoseTile extends StatelessWidget {
  const MedicationDoseTile({super.key, required this.dose, this.onTap});

  final DoseVm dose;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: surfaces.cardBorder == null
            ? null
            : Border.all(color: surfaces.cardBorder!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                MedIcon(icon: dose.icon, color: dose.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dose.medName, style: theme.type.cardTitle),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(AppLocalizations.of(context)!),
                        style: theme.type.meta,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StateMark(state: dose.state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(AppLocalizations l10n) => switch (dose.state) {
    DoseState.taken => '${dose.time} · ${l10n.medicationTaken}',
    DoseState.skipped => '${dose.time} · ${l10n.medicationSkipped}',
    DoseState.pending => '${dose.amount} · ${dose.time}',
  };
}

class _StateMark extends StatelessWidget {
  const _StateMark({required this.state});

  final DoseState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    switch (state) {
      case DoseState.pending:
        return Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: surfaces.divider, width: 2),
          ),
        );
      case DoseState.taken:
        final tone = theme.clinical.tone(ClinicalStatus.optimal);
        return _FilledMark(
          color: tone.accent,
          on: tone.onAccent,
          icon: Icons.check,
        );
      case DoseState.skipped:
        final tone = theme.clinical.tone(ClinicalStatus.alert);
        return _FilledMark(
          color: tone.surface,
          on: tone.accent,
          icon: Icons.close,
        );
    }
  }
}

class _FilledMark extends StatelessWidget {
  const _FilledMark({
    required this.color,
    required this.on,
    required this.icon,
  });

  final Color color;
  final Color on;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, size: 16, color: on),
    );
  }
}
