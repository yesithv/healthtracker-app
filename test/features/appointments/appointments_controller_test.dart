import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_scheduler.dart';
import 'package:myvitals_healthtracker_app/features/appointments/presentation/controllers/appointments_controller.dart';

/// Planificador que no hace nada: evita tocar el plugin de notificaciones y
/// SharedPreferences en un test de VM, dejando ver el efecto real sobre el
/// repositorio (persistencia + transiciones de estado + recurrencia).
class _NoopScheduler extends AppointmentScheduler {
  @override
  Future<void> rescheduleAll({
    required List<Appointment> appointments,
    DateTime? now,
    int horizonDays = AppointmentScheduler.defaultHorizonDays,
    AppointmentTextBuilder? scheduledText,
    AppointmentTextBuilder? toBookText,
    AppointmentTextBuilder? overdueText,
  }) async {}
}

void main() {
  setUpAll(() {
    // La base real corre sobre sqflite ffi en el test.
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-appointments-controller.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Aísla cada prueba: vacía la tabla (crea la base si hace falta).
    await AppointmentRepository.instance.clearAll();
  });

  AppointmentsController buildController() =>
      AppointmentsController(scheduler: _NoopScheduler());

  test('addScheduled crea una cita agendada con avisos por defecto', () async {
    final c = buildController();
    final appt = await c.addScheduled(
      title: 'Cardiología',
      scheduledAt: DateTime(2026, 9, 10, 10),
      specialty: 'Cardiología',
    );

    expect(c.scheduled.map((a) => a.id), contains(appt.id));
    expect(c.toBook, isEmpty);
    expect(appt.reminderOffsets, Appointment.defaultReminderOffsets);
    expect(appt.specialty, 'Cardiología');
  });

  test('addToBook crea una cita por sacar', () async {
    final c = buildController();
    final appt = await c.addToBook(
      title: 'Neuropsicología',
      dueToBookOn: DateTime(2026, 9, 1),
    );

    expect(c.toBook.map((a) => a.id), contains(appt.id));
    expect(c.scheduled, isEmpty);
  });

  test(
    'book pasa una cita por sacar a agendada y limpia la fecha objetivo',
    () async {
      final c = buildController();
      final appt = await c.addToBook(
        title: 'Endocrino',
        dueToBookOn: DateTime(2026, 9, 1),
      );

      await c.book(appt, DateTime(2026, 9, 5, 8, 30));

      expect(c.toBook, isEmpty);
      final booked = c.scheduled.single;
      expect(booked.scheduledAt, DateTime(2026, 9, 5, 8, 30));
      expect(booked.dueToBookOn, isNull);
    },
  );

  test(
    'markAttended de una cita no recurrente la cierra sin generar otra',
    () async {
      final c = buildController();
      final appt = await c.addScheduled(
        title: 'Laboratorio',
        scheduledAt: DateTime(2026, 8, 1, 9),
      );

      await c.markAttended(appt);

      expect(c.scheduled, isEmpty);
      expect(c.toBook, isEmpty);
      expect(c.history.single.status, AppointmentStatus.attended);
    },
  );

  test(
    'markAttended de una recurrente genera la siguiente por sacar',
    () async {
      final c = buildController();
      final appt = await c.addScheduled(
        title: 'Endocrino',
        scheduledAt: DateTime(2026, 8, 17, 9),
        specialty: 'Endocrinología',
        isRecurring: true,
        intervalMonths: 3,
      );

      await c.markAttended(appt);

      // La ocurrencia cerrada queda en el historial…
      expect(c.history.single.status, AppointmentStatus.attended);
      // …y aparece la siguiente por sacar a +3 meses.
      final next = c.toBook.single;
      expect(next.dueToBookOn, DateTime(2026, 11, 17));
      expect(next.isRecurring, isTrue);
      expect(next.intervalMonths, 3);
      expect(next.specialty, 'Endocrinología');
      expect(next.seriesId, isNotNull);
    },
  );

  test('markMissed de una recurrente también genera la siguiente', () async {
    final c = buildController();
    final appt = await c.addScheduled(
      title: 'Endocrino',
      scheduledAt: DateTime(2026, 8, 17, 9),
      isRecurring: true,
      intervalMonths: 6,
    );

    await c.markMissed(appt);

    expect(c.history.single.status, AppointmentStatus.missed);
    expect(c.toBook.single.dueToBookOn, DateTime(2027, 2, 17));
  });

  test('postpone mueve la fecha objetivo de una cita por sacar', () async {
    final c = buildController();
    final appt = await c.addToBook(
      title: 'Neuropsicología',
      dueToBookOn: DateTime(2026, 9, 1),
    );

    await c.postpone(appt, DateTime(2026, 10, 1));

    expect(c.toBook.single.dueToBookOn, DateTime(2026, 10, 1));
  });

  test('delete elimina la cita del inventario', () async {
    final c = buildController();
    final appt = await c.addToBook(
      title: 'Temporal',
      dueToBookOn: DateTime(2026, 9, 1),
    );
    expect(c.all, isNotEmpty);

    await c.delete(appt.id);

    expect(c.all, isEmpty);
  });

  test('overdueCount cuenta una cita por sacar pasada de fecha', () async {
    final c = buildController();
    await c.addToBook(title: 'Vencida', dueToBookOn: DateTime(2026, 8, 1));
    await c.addToBook(title: 'Futura', dueToBookOn: DateTime(2027, 1, 1));

    expect(c.overdueCount(now: DateTime(2026, 8, 17, 10)), 1);
  });

  test('addToBook recurrente persiste isRecurring e intervalMonths', () async {
    final c = buildController();
    final appt = await c.addToBook(
      title: 'Control endocrino',
      dueToBookOn: DateTime(2026, 9, 1),
      isRecurring: true,
      intervalMonths: 6,
      leadDays: 7,
    );

    final stored = c.toBook.single;
    expect(stored.id, appt.id);
    expect(stored.isRecurring, isTrue);
    expect(stored.intervalMonths, 6);
    expect(stored.leadDays, 7);
  });

  test('save edita una cita existente y la mantiene en su sección', () async {
    final c = buildController();
    final appt = await c.addToBook(
      title: 'Neuropsicología',
      dueToBookOn: DateTime(2026, 9, 1),
    );

    await c.save(
      appt.copyWith(
        title: 'Neuropsicología (adultos)',
        specialty: 'Neuropsicología',
        location: 'Sede norte',
      ),
    );

    final edited = c.toBook.single;
    expect(edited.id, appt.id);
    expect(edited.title, 'Neuropsicología (adultos)');
    expect(edited.specialty, 'Neuropsicología');
    expect(edited.location, 'Sede norte');
  });

  test(
    'save puede convertir una por sacar en agendada limpiando la objetivo',
    () async {
      final c = buildController();
      final appt = await c.addToBook(
        title: 'Endocrino',
        dueToBookOn: DateTime(2026, 9, 1),
      );

      await c.save(
        appt.copyWith(
          status: AppointmentStatus.scheduled,
          scheduledAt: DateTime(2026, 9, 5, 8, 30),
          clearDueToBookOn: true,
        ),
      );

      expect(c.toBook, isEmpty);
      final scheduled = c.scheduled.single;
      expect(scheduled.scheduledAt, DateTime(2026, 9, 5, 8, 30));
      expect(scheduled.dueToBookOn, isNull);
    },
  );
}
