import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/medication.dart';
import '../../domain/medication_inventory_service.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../view_models/med_view_models.dart';
import '../widgets/stock_donut.dart';

/// Vista «Inventario»: una fila por medicamento con su rosca de existencias,
/// unidades restantes y fecha estimada de agotamiento. Leída del controlador.
class MedicationInventoryScreen extends StatelessWidget {
  const MedicationInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<MedicationsController>();

    // Solo los medicamentos que llevan inventario.
    final tracked = controller.activeMedications
        .where((m) => m.stockTrackingEnabled)
        .toList();

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          SecondaryAppBar(title: l10n.medicationsTitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                SettingsPageHeader(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.medInventoryTitle,
                  description: l10n.medInventoryDescription,
                  accent: theme.clinical.caution,
                ),
                const SizedBox(height: 28),
                if (tracked.isEmpty)
                  Text(l10n.medNoPendingToday, style: theme.type.meta)
                else
                  for (final m in tracked)
                    _InventoryRow(med: m, controller: controller),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.med, required this.controller});

  final Medication med;
  final MedicationsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final doses = controller.dosesFor(med.id);

    final tone = resolveMedTone(
      context,
      medColorFromKey(med.color, seed: med.name),
    );
    final low =
        med.refillThreshold != null &&
        (med.stockQuantity ?? 0) <= med.refillThreshold!;
    final ringColor = low ? theme.clinical.caution.accent : tone.accent;

    final stock = (med.stockQuantity ?? 0).round();
    final pack = (med.packSize ?? 0).round();
    final runOut = MedicationInventoryService.runOutDate(med, doses);
    final subtitle = runOut != null
        ? '${l10n.medStockLeftUnits(stock)} · ${l10n.medRunsOutOn(shortDateLabel(runOut, locale))}'
        : l10n.medStockLeftUnits(stock);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: surfaces.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: () =>
              context.push('/profile/medications/refill', extra: med.id),
          child: Row(
            children: [
              StockDonut(
                value: stock,
                total: pack,
                color: ringColor,
                size: 60,
                stroke: 7,
                centerBottom: l10n.medStockDonutOf(pack),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: theme.type.cardTitle),
                    const SizedBox(height: 3),
                    Text(subtitle, style: theme.type.meta),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: surfaces.inkMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
