import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_status_service.dart';

Appointment _toBook({DateTime? due, bool recurring = false, int? months}) =>
    Appointment(
      title: 'Endocrino',
      status: AppointmentStatus.toBook,
      dueToBookOn: due,
      isRecurring: recurring,
      intervalMonths: months,
    );

Appointment _scheduled({DateTime? at}) => Appointment(
      title: 'Cardiología',
      status: AppointmentStatus.scheduled,
      scheduledAt: at,
    );

void main() {
  group('addMonths', () {
    test('suma meses conservando el día', () {
      expect(
        AppointmentStatusService.addMonths(DateTime(2026, 1, 15), 3),
        DateTime(2026, 4, 15),
      );
    });

    test('cruza el año', () {
      expect(
        AppointmentStatusService.addMonths(DateTime(2026, 11, 10), 3),
        DateTime(2027, 2, 10),
      );
    });

    test('recorta el día al último válido del mes destino', () {
      // 31-ene + 1 mes -> 28-feb (2026 no bisiesto), sin desbordar a marzo.
      expect(
        AppointmentStatusService.addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
    });
  });

  group('isOverdue', () {
    final now = DateTime(2026, 8, 17, 10);

    test('toBook con fecha objetivo pasada está vencida', () {
      expect(
        AppointmentStatusService.isOverdue(
          _toBook(due: DateTime(2026, 8, 10)),
          now: now,
        ),
        isTrue,
      );
    });

    test('toBook con fecha objetivo futura no está vencida', () {
      expect(
        AppointmentStatusService.isOverdue(
          _toBook(due: DateTime(2026, 9, 1)),
          now: now,
        ),
        isFalse,
      );
    });

    test('scheduled en el pasado está vencida', () {
      expect(
        AppointmentStatusService.isOverdue(
          _scheduled(at: DateTime(2026, 8, 17, 9)),
          now: now,
        ),
        isTrue,
      );
    });

    test('attended nunca está vencida', () {
      final a = Appointment(
        title: 'x',
        status: AppointmentStatus.attended,
        scheduledAt: DateTime(2020, 1, 1),
      );
      expect(AppointmentStatusService.isOverdue(a, now: now), isFalse);
    });
  });

  group('book', () {
    test('pasa de toBook a scheduled y limpia la fecha objetivo', () {
      final booked = AppointmentStatusService.book(
        _toBook(due: DateTime(2026, 9, 1)),
        DateTime(2026, 9, 5, 8, 30),
      );
      expect(booked.status, AppointmentStatus.scheduled);
      expect(booked.scheduledAt, DateTime(2026, 9, 5, 8, 30));
      expect(booked.dueToBookOn, isNull);
    });

    test('no cambia una cita que no está por sacar', () {
      final s = _scheduled(at: DateTime(2026, 9, 5));
      expect(identical(AppointmentStatusService.book(s, DateTime(2026, 9, 6)), s),
          isTrue);
    });
  });

  group('nextRecurringOccurrence', () {
    test('null si no es recurrente', () {
      final closed = AppointmentStatusService.markAttended(
        _toBook(due: DateTime(2026, 8, 1)),
      );
      expect(AppointmentStatusService.nextRecurringOccurrence(closed), isNull);
    });

    test('genera la siguiente por sacar a +N meses, heredando la serie', () {
      final recurring = Appointment(
        title: 'Endocrino',
        specialty: 'Endocrinología',
        status: AppointmentStatus.scheduled,
        scheduledAt: DateTime(2026, 8, 17, 9),
        isRecurring: true,
        intervalMonths: 3,
        seriesId: 'serie-1',
      );
      final next = AppointmentStatusService.nextRecurringOccurrence(
        recurring,
        completedOn: DateTime(2026, 8, 17),
      );
      expect(next, isNotNull);
      expect(next!.status, AppointmentStatus.toBook);
      expect(next.dueToBookOn, DateTime(2026, 11, 17));
      expect(next.isRecurring, isTrue);
      expect(next.intervalMonths, 3);
      expect(next.seriesId, 'serie-1');
      expect(next.title, 'Endocrino');
      expect(next.specialty, 'Endocrinología');
    });

    test('crea un series_id si la ocurrencia cerrada no tenía', () {
      final recurring = _toBook(
        due: DateTime(2026, 8, 1),
        recurring: true,
        months: 6,
      );
      final closed = AppointmentStatusService.markMissed(recurring);
      final next = AppointmentStatusService.nextRecurringOccurrence(
        closed,
        completedOn: DateTime(2026, 8, 17),
      );
      expect(next!.seriesId, isNotNull);
      expect(next.dueToBookOn, DateTime(2027, 2, 17));
    });
  });
}
