import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../appointments/data/models/appointment.dart';
import '../../../appointments/domain/appointment_compliance_service.dart';
import '../../../appointments/domain/appointment_status_service.dart';
import '../../../appointments/presentation/controllers/appointments_controller.dart';

/// Cuadrado de «Citas médicas» en el fondo del Dashboard. Igual que el de
/// Medicamentos, muestra en la mitad del espacio lo más accionable ahora,
/// reutilizando los servicios de dominio del inventario de citas (sin lógica
/// nueva):
///
/// - Con una cita vencida (por sacar pasada de fecha, o agendada pasada sin
///   confirmar) → gana el chip rojo «Vencida».
/// - Con una cita agendada próxima → su fecha y el título.
/// - Con una cita por sacar → su fecha objetivo y el título.
/// - Sin nada abierto pero con historial → «Todo al día».
/// - Sin citas → un CTA compacto para añadir la primera.
///
/// Todo el cuadrado abre el inventario en Perfil (`/profile/appointments`).
class AppointmentsCard extends StatelessWidget {
  const AppointmentsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<AppointmentsController>();

    final hasAny = controller.all.isNotEmpty;
    final next = AppointmentComplianceService.nextAction(controller.all);
    final level = AppointmentComplianceService.semaphore(controller.all);

    // El semáforo se expresa como ACENTO FINO —el punto de color del encabezado
    // y el chip «Vencida»—, no tiñendo todo el marco: el board es neutro e igual
    // al de las tarjetas principales. Este color alimenta ese punto: verde
    // conserva el acento de marca, ámbar y rojo pasan a sus tonos clínicos.
    final Color borderColor = switch (level) {
      ComplianceLevel.red => theme.clinical.alert.accent,
      ComplianceLevel.amber => theme.clinical.caution.accent,
      ComplianceLevel.green => surfaces.brand,
    };

    return Container(
      // Mismo board que las tarjetas principales del inicio (DashboardCard):
      // relleno, filete neutro y la elevación estándar del tema. El semáforo se
      // mantiene como acento fino (punto del encabezado + chip «Vencida»).
      decoration: surfaces.cardDecoration(
        borderColor: surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: () => context.push('/profile/appointments'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            // El alto lo manda el contenido (mainAxisSize.min): la fila lo iguala
            // con su gemela vía IntrinsicHeight, sin hijos flexibles —un `Expanded`
            // hace inestable la medición intrínseca y dejaba el texto fuera del
            // recuadro decorado—.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_outlined, size: 18, color: surfaces.brand),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.medDashApptsTitle,
                        style: theme.type.sectionLabel
                            .copyWith(color: surfaces.brand),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Punto de semáforo: hace visible «próximamente» (ámbar), no
                    // sólo «vencida» (rojo), sin robar espacio.
                    if (hasAny && level != ComplianceLevel.green)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: borderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                !hasAny
                    ? _AddContent(label: l10n.apptDashAdd)
                    : next == null
                        ? _AllClear(l10n: l10n)
                        : _NextHero(appointment: next, l10n: l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Héroe de la cita abierta más urgente: etiqueta (próxima / por sacar), su
/// fecha en grande y el título; con chip «Vencida» si se pasó de fecha.
class _NextHero extends StatelessWidget {
  const _NextHero({required this.appointment, required this.l10n});

  final Appointment appointment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final material = MaterialLocalizations.of(context);
    final a = appointment;
    final overdue = AppointmentStatusService.isOverdue(a);

    final isScheduled = a.status == AppointmentStatus.scheduled;
    final label =
        isScheduled ? l10n.apptDashNextTitle : l10n.apptDashToBookTitle;
    final date = isScheduled ? a.scheduledAt : a.dueToBookOn;
    final dateText = date == null ? '—' : material.formatMediumDate(date);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.type.meta),
        const SizedBox(height: 2),
        Text(
          dateText,
          style: theme.type.cardTitle.copyWith(fontSize: 17),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          a.title,
          style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (overdue) ...[
          const SizedBox(height: 10),
          _Chip(
            icon: Icons.warning_amber_rounded,
            text: l10n.apptDashOverdue,
            tone: theme.clinical.alert,
          ),
        ],
      ],
    );
  }
}

/// Estado «todo al día»: hay citas en el historial pero nada abierto.
class _AllClear extends StatelessWidget {
  const _AllClear({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final optimal = theme.clinical.optimal;
    return Row(
      children: [
        Icon(Icons.check_circle, size: 20, color: optimal.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.apptDashAllClear,
            style:
                theme.type.cardTitle.copyWith(fontSize: 15, color: surfaces.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// CTA compacto cuando aún no hay citas, para no dejar el cuadrado vacío.
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
            style:
                theme.type.cardTitle.copyWith(fontSize: 15, color: surfaces.brand),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Chip pequeño con icono + texto, teñido con un [Tone].
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
