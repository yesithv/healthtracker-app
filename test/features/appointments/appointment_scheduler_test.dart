import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_scheduler.dart';

void main() {
  final from = DateTime(2026, 8, 17, 8, 0);

  test('cita agendada: un aviso por cada offset, dentro de la ventana', () {
    final appt = Appointment(
      id: 'a1',
      title: 'Cardiología',
      status: AppointmentStatus.scheduled,
      scheduledAt: DateTime(2026, 8, 20, 10, 0),
      reminderOffsets: const [1440, 60], // 24 h y 1 h antes.
    );

    final plan = AppointmentScheduler.buildPlan(
      appointments: [appt],
      from: from,
    );

    expect(plan.length, 2);
    expect(
      plan.every((p) => p.kind == AppointmentNotificationKind.scheduled),
      isTrue,
    );
    final times = plan.map((p) => p.scheduledAt).toSet();
    expect(times, {
      DateTime(2026, 8, 19, 10, 0), // 24 h antes
      DateTime(2026, 8, 20, 9, 0), // 1 h antes
    });
    expect(plan.every((p) => p.payload == 'appointment|a1|scheduled'), isTrue);
    expect(plan.every((p) => p.id >= AppointmentScheduler.scheduledIdBase), isTrue);
  });

  test('cita por sacar: aviso a las 9:00 de la fecha objetivo menos leadDays', () {
    final appt = Appointment(
      id: 'b1',
      title: 'Endocrino',
      status: AppointmentStatus.toBook,
      dueToBookOn: DateTime(2026, 9, 1),
      leadDays: 3,
    );

    final plan = AppointmentScheduler.buildPlan(
      appointments: [appt],
      from: from,
    );

    expect(plan.length, 1);
    expect(plan.single.kind, AppointmentNotificationKind.toBook);
    expect(plan.single.scheduledAt, DateTime(2026, 8, 29, 9)); // 01-sep - 3 días
    expect(plan.single.id >= AppointmentScheduler.toBookIdBase, isTrue);
  });

  test('cita vencida: un solo re-empuje al inicio de la ventana', () {
    final appt = Appointment(
      id: 'c1',
      title: 'Neuropsicología',
      status: AppointmentStatus.toBook,
      dueToBookOn: DateTime(2026, 8, 10), // ya pasada
    );

    final plan = AppointmentScheduler.buildPlan(
      appointments: [appt],
      from: from,
    );

    expect(plan.length, 1);
    expect(plan.single.kind, AppointmentNotificationKind.overdue);
    expect(plan.single.scheduledAt, from.add(const Duration(minutes: 1)));
    expect(plan.single.id >= AppointmentScheduler.overdueIdBase, isTrue);
  });

  test('una cita silenciada no genera avisos', () {
    final appt = Appointment(
      id: 'd1',
      title: 'Cardiología',
      status: AppointmentStatus.scheduled,
      scheduledAt: DateTime(2026, 8, 20, 10, 0),
      reminderOffsets: const [1440, 60],
      snoozedUntil: DateTime(2026, 9, 1),
    );

    final plan = AppointmentScheduler.buildPlan(
      appointments: [appt],
      from: from,
    );

    expect(plan, isEmpty);
  });

  test('las citas cerradas no generan avisos', () {
    final plan = AppointmentScheduler.buildPlan(
      appointments: [
        Appointment(
          id: 'e1',
          title: 'x',
          status: AppointmentStatus.attended,
          scheduledAt: DateTime(2026, 8, 20),
        ),
      ],
      from: from,
    );
    expect(plan, isEmpty);
  });
}
