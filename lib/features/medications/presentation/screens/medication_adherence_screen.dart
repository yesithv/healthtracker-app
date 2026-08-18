import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/widgets/secondary_app_bar.dart';
import '../../../../core/widgets/settings_page_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/medications_controller.dart';
import '../view_models/med_view_mapper.dart';
import '../widgets/adherence_calendar.dart';

/// Vista «Adherencia»: cumplimiento del mes, racha y calendario, calculados por
/// el [MedicationAdherenceService] a partir de las tomas reales.
class MedicationAdherenceScreen extends StatelessWidget {
  const MedicationAdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final locale = l10n.localeName;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final adherence = controller.adherence();
    final pct = adherence.monthlyAdherence(now, today: now);
    final streak = adherence.currentStreak(today: now);
    final grid = adherence
        .monthGrid(now, today: now)
        .map(adherenceDayVm)
        .toList();

    final weekdayInitials = [
      for (var wd = 1; wd <= 7; wd++) weekdayShort(wd, locale)[0].toUpperCase(),
    ];

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
                  icon: Icons.insights,
                  title: l10n.medAdherenceTitle,
                  description: l10n.medAdherenceDescription,
                  accent: theme.clinical.optimal,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        value: '$pct%',
                        label: l10n.medComplianceMonth(monthLabel(now, locale)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        value: '$streak',
                        label: l10n.medStreakDays,
                        valueColor: theme.clinical.optimal.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AdherenceCalendar(
                  monthLabel: monthLabel(now, locale),
                  days: grid,
                  weekdayInitials: weekdayInitials,
                  takenLabel: l10n.medLegendTaken,
                  skippedLabel: l10n.medLegendSkipped,
                  noDataLabel: l10n.medLegendNoData,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

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
          Text(
            value,
            style: theme.type.numeral.copyWith(
              fontSize: 34,
              color: valueColor ?? surfaces.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.type.meta),
        ],
      ),
    );
  }
}
