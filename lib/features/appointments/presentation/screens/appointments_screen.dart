import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myvitals_healthtracker_app/core/theme/settings_accent.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_header.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_compliance_service.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_status_service.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/widgets/appointment_add_sheet.dart';

/// Pantalla-inventario de «Mis citas»: el hogar estable de la función de citas
/// (abre desde la fila de Perfil y desde el deep-link de las notificaciones).
///
/// De arriba a abajo: encabezado común + tres secciones —Por sacar, Agendadas e
/// Historial—. Cada sección se pinta solo con su lista; si el inventario entero
/// está vacío, un estado vacío amable invita a añadir la primera cita. El botón
/// flotante abre la hoja de alta en dos modos.
class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<AppointmentsController>();
    final accent = SettingsSection.appointments.tone(theme);

    final toBook = controller.toBook;
    final scheduled = controller.scheduled;
    final history = controller.history;
    final isEmpty = toBook.isEmpty && scheduled.isEmpty && history.isEmpty;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context),
        backgroundColor: accent.accent,
        foregroundColor: accent.onAccent,
        icon: const Icon(Icons.add),
        label: Text(l10n.appointmentsAddCta),
      ),
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
              children: [
                SettingsPageHeader(
                  icon: Icons.event_available_outlined,
                  title: l10n.appointmentsTitle,
                  description: l10n.appointmentsDescription,
                  accent: accent,
                ),
                const SizedBox(height: 28),
                if (!isEmpty) ...[
                  _ComplianceBanner(
                    level: controller.semaphore(),
                    next: controller.nextAction(),
                  ),
                  const SizedBox(height: 24),
                ],
                if (isEmpty)
                  _EmptyAll(l10n: l10n)
                else ...[
                  if (toBook.isNotEmpty) ...[
                    _SectionLabel(text: l10n.appointmentsSectionToBook),
                    ...toBook.map((a) => _AppointmentCard(appointment: a)),
                    const SizedBox(height: 20),
                  ],
                  if (scheduled.isNotEmpty) ...[
                    _SectionLabel(text: l10n.appointmentsSectionScheduled),
                    ...scheduled.map((a) => _AppointmentCard(appointment: a)),
                    const SizedBox(height: 20),
                  ],
                  if (history.isNotEmpty) ...[
                    _SectionLabel(text: l10n.appointmentsSectionHistory),
                    ...history.map((a) => _AppointmentCard(appointment: a)),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre la hoja de alta ([existing] == null) o de edición de una cita.
Future<void> _openAddSheet(BuildContext context, {Appointment? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppointmentAddSheet(existing: existing),
  );
}

/// Tarjetita del índice de cumplimiento (semáforo): color según [level] y una
/// línea de «próxima acción» derivada de [next]. Discreta —una tarjeta, no un
/// dashboard—, arriba del inventario. La lógica ya vive en
/// [AppointmentComplianceService]; aquí sólo se pinta.
class _ComplianceBanner extends StatelessWidget {
  const _ComplianceBanner({required this.level, required this.next});

  final ComplianceLevel level;
  final Appointment? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);

    final (tone, icon, title) = switch (level) {
      ComplianceLevel.red => (
        theme.clinical.alert,
        Icons.warning_amber_rounded,
        l10n.appointmentComplianceRedTitle,
      ),
      ComplianceLevel.amber => (
        theme.clinical.caution,
        Icons.schedule_outlined,
        l10n.appointmentComplianceAmberTitle,
      ),
      ComplianceLevel.green => (
        theme.clinical.optimal,
        Icons.check_circle_outline,
        l10n.appointmentComplianceGreenTitle,
      ),
    };

    String subtitle;
    if (level == ComplianceLevel.green || next == null) {
      subtitle = l10n.appointmentComplianceGreenBody;
    } else if (AppointmentStatusService.isOverdue(next!)) {
      subtitle = l10n.appointmentNextActionOverdue(next!.title);
    } else {
      final date = next!.status == AppointmentStatus.scheduled
          ? next!.scheduledAt
          : next!.dueToBookOn;
      final dateText = date == null ? '—' : material.formatMediumDate(date);
      subtitle = l10n.appointmentNextActionUpcoming(next!.title, dateText);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.surface,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: tone.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: tone.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.type.cardTitle.copyWith(
                    fontSize: 15,
                    color: tone.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: theme.type.sectionLabel.copyWith(
          color: theme.surfaces.inkSecondary,
        ),
      ),
    );
  }
}

/// Estado vacío del inventario entero: nada por sacar, nada agendado, sin
/// historial. Invita a añadir la primera cita.
class _EmptyAll extends StatelessWidget {
  const _EmptyAll({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(color: surfaces.divider),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 40,
            color: surfaces.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.appointmentsEmptyTitle,
            textAlign: TextAlign.center,
            style: theme.type.cardTitle.copyWith(color: surfaces.ink),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.appointmentsEmptyBody,
            textAlign: TextAlign.center,
            style: theme.type.meta.copyWith(color: surfaces.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de una cita en el inventario: identidad, fecha relevante, chip de
/// estado/vencida y las acciones que correspondan a su estado.
class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final l10n = AppLocalizations.of(context)!;
    final a = appointment;
    final overdue = AppointmentStatusService.isOverdue(a);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(surfaces.radiusCard),
        border: Border.all(
          color: overdue
              ? theme.clinical.alert.accent.withValues(alpha: 0.5)
              : surfaces.divider,
        ),
        boxShadow: surfaces.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.title,
                        style: theme.type.cardTitle.copyWith(
                          fontSize: 16,
                          color: surfaces.ink,
                        ),
                      ),
                      if (a.specialty != null && a.specialty!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          a.specialty!,
                          style: theme.type.meta.copyWith(
                            color: surfaces.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (overdue)
                  _Chip(
                    text: l10n.appointmentsOverdueChip,
                    color: theme.clinical.alert.accent,
                    surface: theme.clinical.alert.surface,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _DateLine(appointment: a, l10n: l10n),
            if (a.location != null && a.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              _MetaLine(icon: Icons.place_outlined, text: a.location!),
            ],
            if (a.isRecurring && (a.intervalMonths ?? 0) > 0) ...[
              const SizedBox(height: 4),
              _MetaLine(
                icon: Icons.event_repeat_outlined,
                text: l10n.appointmentEveryNMonths(a.intervalMonths!),
              ),
            ],
            const SizedBox(height: 12),
            _Actions(appointment: a),
          ],
        ),
      ),
    );
  }
}

/// Línea de fecha relevante según el estado: objetivo (por sacar), fecha/hora
/// (agendada) o el desenlace (historial).
class _DateLine extends StatelessWidget {
  const _DateLine({required this.appointment, required this.l10n});

  final Appointment appointment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final a = appointment;
    final material = MaterialLocalizations.of(context);

    IconData icon;
    String text;
    switch (a.status) {
      case AppointmentStatus.toBook:
        icon = Icons.event_repeat_outlined;
        text = a.dueToBookOn != null
            ? l10n.appointmentDueOn(material.formatMediumDate(a.dueToBookOn!))
            : l10n.appointmentNoDate;
      case AppointmentStatus.scheduled:
        icon = Icons.event_outlined;
        if (a.scheduledAt != null) {
          final date = material.formatMediumDate(a.scheduledAt!);
          final time = TimeOfDay.fromDateTime(a.scheduledAt!).format(context);
          text = l10n.appointmentScheduledOn(date, time);
        } else {
          text = l10n.appointmentNoDate;
        }
      case AppointmentStatus.attended:
        icon = Icons.check_circle_outline;
        text = l10n.appointmentStatusAttended;
      case AppointmentStatus.missed:
        icon = Icons.cancel_outlined;
        text = l10n.appointmentStatusMissed;
      case AppointmentStatus.cancelled:
        icon = Icons.block_outlined;
        text = l10n.appointmentStatusCancelled;
    }

    return Row(
      children: [
        Icon(icon, size: 15, color: surfaces.inkMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
          ),
        ),
      ],
    );
  }
}

/// Línea secundaria (icono + texto tenue) para datos informativos de la cita,
/// como el lugar o la periodicidad. Mismo estilo que [_DateLine].
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    return Row(
      children: [
        Icon(icon, size: 15, color: surfaces.inkMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.type.meta.copyWith(color: surfaces.inkSecondary),
          ),
        ),
      ],
    );
  }
}

/// Acciones por estado: por sacar → «Ya la saqué» / «Posponer»; agendada → «Ya
/// asistí» / «No asistí»; cerradas → sin acciones (solo eliminar).
class _Actions extends StatelessWidget {
  const _Actions({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.read<AppointmentsController>();
    final a = appointment;

    final buttons = <Widget>[];
    switch (a.status) {
      case AppointmentStatus.toBook:
        buttons.add(
          _PrimaryAction(
            label: l10n.appointmentActionBook,
            onTap: () => _book(context, controller, a),
          ),
        );
        buttons.add(
          _SecondaryAction(
            label: l10n.appointmentActionPostpone,
            onTap: () => _postpone(context, controller, a),
          ),
        );
        buttons.add(
          _SecondaryAction(
            label: l10n.appointmentActionEdit,
            onTap: () => _openAddSheet(context, existing: a),
          ),
        );
      case AppointmentStatus.scheduled:
        buttons.add(
          _PrimaryAction(
            label: l10n.appointmentActionAttended,
            onTap: () =>
                _confirmAttendance(context, controller, a, attended: true),
          ),
        );
        buttons.add(
          _SecondaryAction(
            label: l10n.appointmentActionMissed,
            onTap: () =>
                _confirmAttendance(context, controller, a, attended: false),
          ),
        );
        buttons.add(
          _SecondaryAction(
            label: l10n.appointmentActionEdit,
            onTap: () => _openAddSheet(context, existing: a),
          ),
        );
      case AppointmentStatus.attended:
      case AppointmentStatus.missed:
      case AppointmentStatus.cancelled:
        break;
    }
    buttons.add(
      _DeleteAction(onTap: () => _confirmDelete(context, controller, a)),
    );

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  /// Confirma asistencia/inasistencia y, si la cita era un control periódico,
  /// avisa de que ya se anotó la siguiente «por sacar» (reflejo visual de la
  /// recurrencia automática).
  Future<void> _confirmAttendance(
    BuildContext context,
    AppointmentsController controller,
    Appointment a, {
    required bool attended,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (attended) {
      await controller.markAttended(a);
    } else {
      await controller.markMissed(a);
    }
    if (a.isRecurring && (a.intervalMonths ?? 0) > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.appointmentNextSpawned)),
      );
    }
  }

  Future<void> _book(
    BuildContext context,
    AppointmentsController controller,
    Appointment a,
  ) async {
    final when = await _pickDateTime(context);
    if (when == null) return;
    await controller.book(a, when);
  }

  Future<void> _postpone(
    BuildContext context,
    AppointmentsController controller,
    Appointment a,
  ) async {
    final date = await _pickDate(context, initial: a.dueToBookOn);
    if (date == null) return;
    await controller.postpone(a, date);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AppointmentsController controller,
    Appointment a,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.appointmentDeleteTitle),
        content: Text(l10n.deleteRecordBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteRecordConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.delete(a.id);
  }
}

/// Selector de fecha (día) con el tema de la app.
Future<DateTime?> _pickDate(BuildContext context, {DateTime? initial}) {
  final now = DateTime.now();
  return showDatePicker(
    context: context,
    initialDate: initial ?? now,
    firstDate: DateTime(now.year - 1),
    lastDate: DateTime(now.year + 5),
  );
}

/// Selector de fecha + hora, para agendar una cita concreta.
Future<DateTime?> _pickDateTime(BuildContext context) async {
  final date = await _pickDate(context);
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.now(),
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: surfaces.brand,
        foregroundColor: surfaces.onBrand,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 38),
        textStyle: Theme.of(context).type.button,
      ),
      child: Text(label),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: surfaces.ink,
        side: BorderSide(color: surfaces.divider),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 38),
        textStyle: Theme.of(context).type.button,
      ),
      child: Text(label),
    );
  }
}

class _DeleteAction extends StatelessWidget {
  const _DeleteAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaces = Theme.of(context).surfaces;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: surfaces.inkMuted,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(0, 38),
        textStyle: Theme.of(context).type.button,
      ),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: Text(l10n.appointmentActionDelete),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color, required this.surface});

  final String text;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: theme.type.badge.copyWith(color: color)),
    );
  }
}
