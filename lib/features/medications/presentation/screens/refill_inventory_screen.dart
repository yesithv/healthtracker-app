import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/action_button.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/medication.dart';
import '../../domain/medication_inventory_service.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../widgets/stock_donut.dart';

/// Recargar inventario: estado actual, cuánto añadir y proyección. «Ya lo compré»
/// suma la caja al stock (y silencia la alerta); «Recuérdame en 1 día» aplaza el
/// aviso. Ambos pasan por el [MedicationsController].
class RefillInventoryScreen extends StatefulWidget {
  const RefillInventoryScreen({super.key, required this.medicationId});

  final String medicationId;

  @override
  State<RefillInventoryScreen> createState() => _RefillInventoryScreenState();
}

class _RefillInventoryScreenState extends State<RefillInventoryScreen> {
  int? _add;

  Future<void> _buy(Medication med) async {
    final controller = context.read<MedicationsController>();
    final router = GoRouter.of(context);
    await controller.refill(med, amount: (_add ?? 0).toDouble());
    router.pop();
  }

  Future<void> _remindTomorrow(Medication med) async {
    final controller = context.read<MedicationsController>();
    final router = GoRouter.of(context);
    await controller.snoozeRefill(
        med, DateTime.now().add(const Duration(days: 1)));
    router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final controller = context.watch<MedicationsController>();

    final med = controller.medicationById(widget.medicationId);
    if (med == null) {
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

    final doses = controller.dosesFor(med.id);
    final caution = theme.clinical.caution;
    final stock = (med.stockQuantity ?? 0).round();
    final pack = (med.packSize ?? 0).round();
    _add ??= pack > 0 ? pack : 30;

    final low = med.refillThreshold != null &&
        (med.stockQuantity ?? 0) <= med.refillThreshold!;
    final ringColor = low ? caution.accent : surfaces.brand;
    final daysLeft = MedicationInventoryService.daysRemaining(med, doses);
    final buyBy = MedicationInventoryService.buyByDate(med, doses);
    final perDay = MedicationInventoryService.dailyConsumption(med, doses);
    final projected = stock + _add!;
    final projectedDays = perDay > 0 ? (projected / perDay).round() : null;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          SecondaryAppBar(title: med.name),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(l10n.medRefillTitle,
                    style: theme.type.screenTitle.copyWith(fontSize: 26)),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: surfaces.cardDecoration(),
                  child: Column(
                    children: [
                      StockDonut(
                        value: stock,
                        total: pack,
                        color: ringColor,
                        size: 132,
                        stroke: 12,
                        centerTop: '$stock',
                        centerBottom: l10n.medStockDonutOf(pack),
                      ),
                      const SizedBox(height: 16),
                      if (daysLeft != null)
                        Text(
                          l10n.medRunsOutInDays(daysLeft),
                          style: theme.type.cardTitle.copyWith(
                            fontSize: 18,
                            color: low ? caution.accent : surfaces.ink,
                          ),
                        ),
                      if (buyBy != null) ...[
                        const SizedBox(height: 4),
                        Text(l10n.medBuyBefore(shortDateLabel(buyBy, locale)),
                            style: theme.type.meta),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: surfaces.cardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.medAddABox,
                                    style: theme.type.cardTitle
                                        .copyWith(fontSize: 16)),
                                const SizedBox(height: 2),
                                Text(l10n.medAddABoxSub, style: theme.type.meta),
                              ],
                            ),
                          ),
                          _Stepper(
                            value: _add!,
                            onMinus: () =>
                                setState(() => _add = (_add! - 1).clamp(1, 999)),
                            onPlus: () =>
                                setState(() => _add = (_add! + 1).clamp(1, 999)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: surfaces.selection,
                          borderRadius:
                              BorderRadius.circular(surfaces.radiusControl),
                        ),
                        child: Text(
                          l10n.medWillRemain(projected, projectedDays ?? 0),
                          style: theme.type.body.copyWith(color: surfaces.brand),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: l10n.medRemindOneDay,
                        color: surfaces.brand,
                        solid: false,
                        onPressed: () => _remindTomorrow(med),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionButton(
                        text: l10n.medBought,
                        color: surfaces.brand,
                        solid: true,
                        onPressed: () => _buy(med),
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

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onMinus, required this.onPlus});

  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _Btn(icon: Icons.remove, onTap: onMinus),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value', style: theme.type.numeral.copyWith(fontSize: 24)),
        ),
        _Btn(icon: Icons.add, onTap: onPlus),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return Material(
      color: surfaces.inset,
      borderRadius: BorderRadius.circular(surfaces.radiusControl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: surfaces.brand),
        ),
      ),
    );
  }
}
