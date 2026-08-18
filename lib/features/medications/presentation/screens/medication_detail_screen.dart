import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/dashed_border_container.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../view_models/med_view_models.dart';
import '../widgets/adherence_squares.dart';
import '../widgets/med_icon.dart';
import '../widgets/stock_donut.dart';

/// Detalle de un medicamento: pauta, inventario, adherencia e información, con
/// acciones reales (editar, eliminar, recargar). Lee del [MedicationsController]
/// por id, así que se refresca solo tras cualquier cambio.
class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final String medicationId;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = context.read<MedicationsController>();
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.surfaces.radiusCard),
        ),
        title: Text(l10n.medDeleteTitle, style: theme.type.cardTitle),
        content: Text(l10n.medDeleteBody, style: theme.type.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: theme.type.button
                  .copyWith(color: theme.surfaces.inkSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.medDelete,
              style: theme.type.button
                  .copyWith(color: theme.clinical.alert.accent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await controller.deleteMedication(medicationId);
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final med = controller.medicationById(medicationId);
    if (med == null) {
      // El medicamento se eliminó o no existe: cerramos.
      return Scaffold(
        backgroundColor: surfaces.canvas,
        body: Column(
          children: [
            SecondaryAppBar(title: l10n.medicationsTitle),
            const Spacer(),
          ],
        ),
      );
    }

    final vm = medVmForMedication(controller, med, l10n, locale, today: now);
    final ringColor = vm.lowStock
        ? theme.clinical.caution.accent
        : resolveMedTone(context, vm.color).accent;
    final headerParts =
        [vm.form, vm.strength, vm.reason].where((s) => s.isNotEmpty).join(' · ');

    // Últimos 8 días de estado para la tira de cuadros.
    final recent = controller
        .adherence(only: med)
        .weekStates(anchor: now, length: 8)
        .map((d) => doseStateFromDayStatus(d.status))
        .toList();

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          SecondaryAppBar(title: l10n.medicationsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  children: [
                    MedIcon(
                        icon: vm.icon, color: vm.color, size: 60, iconSize: 30),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vm.name,
                              style:
                                  theme.type.screenTitle.copyWith(fontSize: 28)),
                          if (headerParts.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(headerParts, style: theme.type.meta),
                          ],
                          if (!med.isActive) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.clinical.caution.surface,
                                borderRadius: BorderRadius.circular(
                                    surfaces.radiusControl),
                              ),
                              child: Text(
                                l10n.medPausedBadge,
                                style: theme.type.meta.copyWith(
                                    color: theme.clinical.caution.accent),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _Card(
                  label: l10n.medSectionSchedule,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vm.schedule,
                          style: theme.type.cardTitle.copyWith(fontSize: 18)),
                      if (vm.doseSummary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(vm.doseSummary, style: theme.type.meta),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (vm.trackInventory) ...[
                  _Card(
                    label: l10n.medSectionInventory,
                    action: _CardAction(
                      label: l10n.medicationRefill,
                      onTap: () => context.push(
                          '/profile/medications/refill', extra: med.id),
                    ),
                    child: Row(
                      children: [
                        StockDonut(
                          value: vm.stock,
                          total: vm.packSize,
                          color: ringColor,
                          size: 92,
                          stroke: 9,
                          centerBottom: l10n.medStockDonutOf(vm.packSize),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.medRemainingUnits(vm.stock),
                                style:
                                    theme.type.cardTitle.copyWith(fontSize: 16),
                              ),
                              if (vm.runOut.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(l10n.medRunsOutOn(vm.runOut),
                                    style: theme.type.meta),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                l10n.medPackAndThreshold(
                                    vm.packSize, vm.refillThreshold),
                                style: theme.type.meta,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _Card(
                  label: l10n.medSectionAdherence,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${vm.adherencePct}%',
                              style: theme.type.numeral.copyWith(fontSize: 34)),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child:
                                Text(l10n.medThisMonth, style: theme.type.meta),
                          ),
                          const Spacer(),
                          Text('${vm.streak}',
                              style: theme.type.numeral.copyWith(
                                fontSize: 34,
                                color: theme.clinical.optimal.accent,
                              )),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child:
                                Text(l10n.medStreakDays, style: theme.type.meta),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AdherenceSquares(days: recent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                DashedBorderContainer(
                  color: surfaces.divider,
                  borderRadius: surfaces.radiusCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(l10n.medSectionInformation,
                              style: theme.type.sectionLabel),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: surfaces.inset,
                              borderRadius:
                                  BorderRadius.circular(surfaces.radiusControl),
                            ),
                            child:
                                Text(l10n.medInfoSoon, style: theme.type.meta),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(l10n.medInfoSoonBody,
                          style: theme.type.body
                              .copyWith(color: surfaces.inkMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pausar/reanudar: un medicamento pausado deja de generar tomas
                // y avisos pero conserva su historial (a diferencia de eliminar).
                ActionButton(
                  text: med.isActive ? l10n.medPause : l10n.medResume,
                  color: med.isActive
                      ? theme.clinical.caution.accent
                      : theme.clinical.optimal.accent,
                  solid: false,
                  onPressed: () => controller.setActive(med, !med.isActive),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: l10n.medEdit,
                        color: surfaces.brand,
                        solid: false,
                        onPressed: () => context.push(
                            '/profile/medications/add', extra: med.id),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: l10n.medDelete,
                        color: theme.clinical.alert.accent,
                        solid: false,
                        onPressed: () => _confirmDelete(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.label, required this.child, this.action});

  final String label;
  final Widget child;
  final _CardAction? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: surfaces.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.type.sectionLabel),
              const Spacer(),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Material(
      color: surfaces.selection,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style:
                theme.type.button.copyWith(fontSize: 14, color: surfaces.brand),
          ),
        ),
      ),
    );
  }
}
