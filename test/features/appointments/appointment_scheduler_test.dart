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

  test('por sacar sin leadDays: aviso a las 9:00 de la propia fecha objetivo',
      () {
    final appt = Appointment(
      id: 'f1',
      title: 'Laboratorio',
      status: AppointmentStatus.toBook,
      dueToBookOn: DateTime(2026, 9, 1),
    );
    final plan = AppointmentScheduler.buildPlan(appointments: [appt], from: from);
    expect(plan.single.scheduledAt, DateTime(2026, 9, 1, 9));
  });

  test('por sacar fuera del horizonte no genera aviso', () {
    final appt = Appointment(
      id: 'g1',
      title: 'Control lejano',
      status: AppointmentStatus.toBook,
      dueToBookOn: DateTime(2026, 12, 1), // > 60 días desde `from`
    );
    expect(
      AppointmentScheduler.buildPlan(appointments: [appt], from: from),
      isEmpty,
    );
  });

  test('agendada: los offsets que caen antes de la ventana se descartan', () {
    final appt = Appointment(
      id: 'h1',
      title: 'Cardiología',
      status: AppointmentStatus.scheduled,
      scheduledAt: DateTime(2026, 8, 17, 12), // hoy, aún futura (from 08:00)
      reminderOffsets: const [1440, 60], // 24 h antes queda antes de `from`.
    );
    final plan = AppointmentScheduler.buildPlan(appointments: [appt], from: from);
    expect(plan.length, 1);
    expect(plan.single.scheduledAt, DateTime(2026, 8, 17, 11)); // solo 1 h antes
  });

  test('agendada en el pasado sin confirmar genera re-empuje de vencida', () {
    final appt = Appointment(
      id: 'i1',
      title: 'Cardiología',
      status: AppointmentStatus.scheduled,
      scheduledAt: DateTime(2026, 8, 10, 9), // antes de `from`
      reminderOffsets: const [1440, 60],
    );
    final plan = AppointmentScheduler.buildPlan(appointments: [appt], from: from);
    expect(plan.single.kind, AppointmentNotificationKind.overdue);
    expect(plan.single.payload, 'appointment|i1|overdue');
  });

  test('varias citas: ids únicos por tipo dentro de su rango', () {
    final plan = AppointmentScheduler.buildPlan(
      appointments: [
        Appointment(
          id: 'a1',
          title: 'Uno',
          status: AppointmentStatus.scheduled,
          scheduledAt: DateTime(2026, 8, 20, 10),
          reminderOffsets: const [60],
        ),
        Appointment(
          id: 'a2',
          title: 'Dos',
          status: AppointmentStatus.scheduled,
          scheduledAt: DateTime(2026, 8, 21, 10),
          reminderOffsets: const [60],
        ),
      ],
      from: from,
    );
    final ids = plan.map((p) => p.id).toSet();
    expect(ids, {
      AppointmentScheduler.scheduledIdBase,
      AppointmentScheduler.scheduledIdBase + 1,
    });
  });
}
