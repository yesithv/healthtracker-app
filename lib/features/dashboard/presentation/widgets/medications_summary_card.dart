import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../medications/domain/medication_inventory_service.dart';
import '../../../medications/domain/medication_schedule_service.dart';
import '../../../medications/presentation/controllers/medications_controller.dart';
import '../../../medications/presentation/view_models/med_view_mapper.dart';

/// Cuadrado de Medicamentos en el fondo del Dashboard. Sustituye a la antigua
/// tarjeta rectangular de ancho completo: en la mitad del espacio muestra lo
/// más accionable ahora (composición ADAPTATIVA), reutilizando por completo los
/// servicios de dominio del módulo (nada de lógica nueva).
///
/// - Con tomas pendientes hoy → próxima toma (hora + nombre) y progreso «X/Y».
/// - Con todo tomado → la racha de días, como refuerzo del hábito.
/// - Con stock bajo → gana el chip de aviso ámbar.
/// - Sin medicamentos → un CTA compacto para añadir el primero.
///
/// Todo el cuadrado abre el módulo en Perfil (`/profile/medications`).
class MedicationsSummaryCard extends StatelessWidget {
  const MedicationsSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<MedicationsController>();
    final now = DateTime.now();

    final meds = controller.activeMedications;

    return Container(
      // Mismo board que las tarjetas principales del inicio (DashboardCard):
      // relleno, filete neutro y la elevación estándar del tema. Así la minicard
      // «tiene su espacio» y se lee igual que las cuatro de arriba, en lugar de
      // flotar sobre el lienzo.
      decoration: surfaces.cardDecoration(
        borderColor: surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: () => context.push('/profile/medications'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            // El alto lo manda el contenido (mainAxisSize.min): la fila lo iguala
            // con su gemela vía IntrinsicHeight, sin `Spacer` —un hijo flexible
            // hace inestable la medición intrínseca—.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.medication, size: 18, color: surfaces.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.medDashMedsTitle,
                        style: theme.type.sectionLabel
                            .copyWith(color: surfaces.brand),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (meds.isEmpty)
                  _AddContent(label: l10n.medDashAddMed)
                else
                  _Body(controller: controller, now: now, l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuerpo adaptativo cuando hay medicamentos: elige el héroe y el chip.
class _Body extends StatelessWidget {
  const _Body({
    required this.controller,
    required this.now,
    required this.l10n,
  });

  final MedicationsController controller;
  final DateTime now;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final entries = controller.entriesForDay(now);
    final pending = entries.where((e) => e.isPending).toList();
    final done = entries.length - pending.length;

    // Próxima toma entre todos los medicamentos activos (misma lógica que la
    // antigua tarjeta del dashboard).
    ExpectedDose? next;
    for (final m in controller.activeMedications) {
      final candidate =
          MedicationScheduleService.nextDose(m, controller.dosesFor(m.id), now);
      if (candidate == null) continue;
      if (next == null || candidate.scheduledAt.isBefore(next.scheduledAt)) {
        next = candidate;
      }
    }

    final streak = controller.adherence().currentStreak(today: now);

    final lowMeds = controller.activeMedications
        .where((m) => MedicationInventoryService.shouldAlert(
              m,
              controller.dosesFor(m.id),
              today: now,
            ))
        .toList();

    final hasPending = pending.isNotEmpty && next != null;

    // Un único chip bajo el héroe (para no desbordar el cuadrado). Prioridad: el
    // aviso de stock bajo manda; si no, con próxima toma se muestra la racha
    // (motivación) o, en su defecto, el progreso «X/Y» del día.
    final Widget? chip;
    if (lowMeds.isNotEmpty) {
      chip = _Chip(
        icon: Icons.warning_amber_rounded,
        text: l10n.medDashLowShort((lowMeds.first.stockQuantity ?? 0).round()),
        tone: theme.clinical.caution,
      );
    } else if (hasPending && streak > 0) {
      chip = _Chip(
        icon: Icons.local_fire_department,
        text: l10n.medDashStreakShort(streak),
        tone: theme.clinical.optimal,
      );
    } else if (hasPending) {
      chip = _Chip(
        icon: Icons.check_circle_outline,
        text: l10n.medDashTodayProgress(done, entries.length),
        tone: theme.clinical.info,
      );
    } else {
      chip = null;
    }

    final Widget hero;
    if (hasPending) {
      hero = _NextDoseHero(next: next, l10n: l10n);
    } else {
      hero = _StreakHero(streak: streak, l10n: l10n);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        if (chip != null) ...[
          const SizedBox(height: 10),
          chip,
        ],
      ],
    );
  }
}

/// Héroe «próxima toma»: hora en grande y nombre del medicamento.
class _NextDoseHero extends StatelessWidget {
  const _NextDoseHero({required this.next, required this.l10n});

  final ExpectedDose next;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.medDashNextDose, style: theme.type.meta),
        const SizedBox(height: 2),
        Text(
          timeLabelHM(next.scheduledAt.hour, next.scheduledAt.minute),
          style: theme.type.cardTitle.copyWith(fontSize: 22),
        ),
        Text(
          next.medication.name,
          style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Héroe «racha»: los días seguidos en grande, o «todo al día» si aún no hay
/// racha (pero tampoco tomas pendientes).
class _StreakHero extends StatelessWidget {
  const _StreakHero({required this.streak, required this.l10n});

  final int streak;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final optimal = theme.clinical.optimal;

    if (streak <= 0) {
      return Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: optimal.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.medDashAllDone,
              style: theme.type.cardTitle
                  .copyWith(fontSize: 15, color: surfaces.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Icon(Icons.local_fire_department, size: 20, color: optimal.accent),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: theme.type.numeral.copyWith(fontSize: 30),
            ),
          ],
        ),
        Text(l10n.medStreakDays, style: theme.type.meta),
      ],
    );
  }
}

/// CTA compacto cuando aún no hay medicamentos, para no dejar el cuadrado vacío.
class _AddContent extends StatelessWidget {
  const _AddContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Row(
      children: [
        Icon(Icons.add_circle_outline, size: 20, color: surfaces.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: theme.type.cardTitle
                .copyWith(fontSize: 15, color: surfaces.brand),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Chip pequeño con icono + texto, teñido con un [Tone] (racha o aviso).
class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusControl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone.accent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: theme.type.meta.copyWith(color: tone.accent),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
