import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../medications/domain/medication_inventory_service.dart';
import '../../../medications/domain/medication_schedule_service.dart';
import '../../../medications/presentation/controllers/medications_controller.dart';
import '../../../medications/presentation/view_models/med_view_mapper.dart';
import '../../../medications/presentation/view_models/med_view_models.dart';
import '../../../medications/presentation/widgets/med_icon.dart';

/// Tarjeta de entrada al módulo Medicamentos en el Dashboard: la próxima toma y
/// un aviso de inventario, con acceso al módulo ya reubicado en Perfil. Se
/// oculta cuando el usuario aún no tiene medicamentos.
class MedicationsTodayCard extends StatelessWidget {
  const MedicationsTodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final meds = controller.activeMedications;
    if (meds.isEmpty) return const SizedBox.shrink();

    // Próxima toma entre todos los medicamentos activos.
    ExpectedDose? next;
    for (final m in meds) {
      final candidate =
          MedicationScheduleService.nextDose(m, controller.dosesFor(m.id), now);
      if (candidate == null) continue;
      if (next == null || candidate.scheduledAt.isBefore(next.scheduledAt)) {
        next = candidate;
      }
    }

    final lowMeds = meds
        .where((m) => MedicationInventoryService.shouldAlert(
              m,
              controller.dosesFor(m.id),
              today: now,
            ))
        .toList();

    final caution = theme.clinical.tone(ClinicalStatus.caution);

    return Container(
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.brand.withValues(alpha: 0.5)),
        boxShadow: surfaces.glow(surfaces.brand, alpha: 0.10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: () => context.push('/profile/medications'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, size: 18, color: surfaces.brand),
                    const SizedBox(width: 8),
                    Text(
                      l10n.medDashTodayLabel,
                      style:
                          theme.type.sectionLabel.copyWith(color: surfaces.brand),
                    ),
                    const Spacer(),
                    Text(
                      l10n.medDashSeeModule,
                      style:
                          theme.type.meta.copyWith(color: surfaces.inkSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (next == null)
                  Text(l10n.medDashNoDoses, style: theme.type.meta)
                else
                  Row(
                    children: [
                      MedIcon(
                        icon: medIconFor(next.medication.shape),
                        color: medColorFromKey(next.medication.color,
                            seed: next.medication.name),
                        size: 52,
                        iconSize: 26,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.medDashNextDose, style: theme.type.meta),
                            const SizedBox(height: 2),
                            Text(
                              '${next.medication.name} · ${timeLabelHM(next.scheduledAt.hour, next.scheduledAt.minute)}',
                              style: theme.type.cardTitle.copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doseAmountLabel(
                                  next.quantity, next.medication.form, l10n),
                              style: theme.type.meta,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (lowMeds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _LowRow(
                    caution: caution,
                    text: l10n.medLowStockBannerTitle(
                        lowMeds.first.name,
                        (lowMeds.first.stockQuantity ?? 0).round()),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LowRow extends StatelessWidget {
  const _LowRow({required this.caution, required this.text});

  final Tone caution;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: caution.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 18, color: caution.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.type.meta.copyWith(color: caution.accent),
            ),
          ),
        ],
      ),
    );
  }
}
