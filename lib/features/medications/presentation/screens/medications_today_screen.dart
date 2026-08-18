import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/medication_inventory_service.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../widgets/low_inventory_banner.dart';
import '../widgets/medication_dose_tile.dart';
import '../widgets/register_dose_sheet.dart';
import '../widgets/register_multiple_sheet.dart';
import '../widgets/week_strip.dart';

/// Vista «Hoy»: tira semanal de adherencia, aviso de inventario y las tomas del
/// día (pendientes y registradas), leídas del [MedicationsController]. Registrar
/// una toma pasa por el controlador (inventario + reprogramación).
class MedicationsTodayScreen extends StatelessWidget {
  const MedicationsTodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final entries = controller.entriesForDay(now);
    final pending = entries.where((e) => e.isPending).toList();
    final logged = entries.where((e) => !e.isPending).toList();
    final done = logged.length;

    // Tomas pendientes agrupadas por hora, para la hoja de «varias tomas».
    final pendingByTime = <DateTime, List<MedicationDayEntry>>{};
    for (final e in pending) {
      pendingByTime.putIfAbsent(e.scheduledAt, () => []).add(e);
    }

    final week = controller
        .adherence()
        .weekStates(anchor: now)
        .map((d) => weekDayVm(d, locale))
        .toList();

    final lowMeds = controller.activeMedications
        .where((m) => MedicationInventoryService.shouldAlert(
              m,
              controller.dosesFor(m.id),
              today: now,
            ))
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
                  icon: Icons.today,
                  title: l10n.medTodayTitle,
                  description: l10n.medTodayDescription,
                  accent: theme.content.heart,
                ),
                const SizedBox(height: 28),
                WeekStrip(days: week),
                const SizedBox(height: 20),
                if (lowMeds.isNotEmpty) ...[
                  Builder(builder: (context) {
                    final med = lowMeds.first;
                    final days = MedicationInventoryService.daysRemaining(
                        med, controller.dosesFor(med.id));
                    return LowInventoryBanner(
                      title: l10n.medLowStockBannerTitle(
                          med.name, (med.stockQuantity ?? 0).round()),
                      subtitle: days != null ? l10n.medRunsOutInDays(days) : '',
                      actionLabel: l10n.medicationRefill,
                      onAction: () => context.push(
                          '/profile/medications/refill',
                          extra: med.id),
                    );
                  }),
                  const SizedBox(height: 24),
                ],
                _SectionHeader(
                  label: l10n.medSectionToTakeToday,
                  trailing: l10n.medDosesProgress(done, entries.length),
                ),
                const SizedBox(height: 12),
                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      entries.isEmpty
                          ? l10n.medEmptyBody
                          : l10n.medNoPendingToday,
                      style: theme.type.meta,
                    ),
                  ),
                for (final e in pending)
                  MedicationDoseTile(
                    dose: doseVm(e, l10n),
                    onTap: () {
                      final group = pendingByTime[e.scheduledAt]!;
                      if (group.length > 1) {
                        showRegisterMultipleSheet(context, group);
                      } else {
                        showRegisterDoseSheet(context, e);
                      }
                    },
                  ),
                if (logged.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionHeader(label: l10n.medSectionLogged),
                  const SizedBox(height: 12),
                  for (final e in logged)
                    MedicationDoseTile(
                      dose: doseVm(e, l10n),
                      onTap: () => showRegisterDoseSheet(context, e),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.trailing});

  final String label;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(label, style: theme.type.sectionLabel),
        const Spacer(),
        if (trailing != null) Text(trailing!, style: theme.type.meta),
      ],
    );
  }
}
