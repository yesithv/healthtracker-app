import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_compliance_service.dart';

Appointment _toBook(String title, DateTime due) => Appointment(
      title: title,
      status: AppointmentStatus.toBook,
      dueToBookOn: due,
    );

Appointment _scheduled(String title, DateTime at) => Appointment(
      title: title,
      status: AppointmentStatus.scheduled,
      scheduledAt: at,
    );

Appointment _closed(String title, AppointmentStatus status) => Appointment(
      title: title,
      status: status,
      scheduledAt: DateTime(2026, 7, 1),
    );

void main() {
  final now = DateTime(2026, 8, 17, 10);

  group('overdueCount', () {
    test('cuenta las vencidas por sacar y agendadas', () {
      final list = [
        _toBook('a', DateTime(2026, 8, 10)), // vencida
        _toBook('b', DateTime(2026, 9, 1)), // futura
        _scheduled('c', DateTime(2026, 8, 17, 9)), // vencida
      ];
      expect(AppointmentComplianceService.overdueCount(list, now: now), 2);
    });
  });

  group('dueSoonCount', () {
    test('cuenta lo que cae en la ventana sin incluir vencidas', () {
      final list = [
        _toBook('vencida', DateTime(2026, 8, 10)),
        _toBook('pronto', DateTime(2026, 8, 20)),
        _scheduled('pronto2', DateTime(2026, 8, 22, 9)),
        _toBook('lejana', DateTime(2026, 10, 1)),
      ];
      expect(
        AppointmentComplianceService.dueSoonCount(list, now: now, withinDays: 7),
        2,
      );
    });
  });

  group('semaphore', () {
    test('rojo si hay algo vencido', () {
      final list = [_toBook('a', DateTime(2026, 8, 10))];
      expect(AppointmentComplianceService.semaphore(list, now: now),
          ComplianceLevel.red);
    });

    test('ámbar si hay algo inminente pero nada vencido', () {
      final list = [_toBook('a', DateTime(2026, 8, 20))];
      expect(AppointmentComplianceService.semaphore(list, now: now),
          ComplianceLevel.amber);
    });

    test('verde si no hay nada pendiente pronto', () {
      final list = [_toBook('a', DateTime(2026, 12, 1))];
      expect(AppointmentComplianceService.semaphore(list, now: now),
          ComplianceLevel.green);
    });

    test('verde con inventario vacío', () {
      expect(AppointmentComplianceService.semaphore(const [], now: now),
          ComplianceLevel.green);
    });
  });

  group('nextAction', () {
    test('prioriza las vencidas y, entre ellas, la más antigua', () {
      final list = [
        _scheduled('futura', DateTime(2026, 8, 25, 9)),
        _toBook('vencida-vieja', DateTime(2026, 8, 1)),
        _toBook('vencida-reciente', DateTime(2026, 8, 15)),
      ];
      final next = AppointmentComplianceService.nextAction(list, now: now);
      expect(next!.title, 'vencida-vieja');
    });

    test('null si no hay citas abiertas', () {
      final list = [
        _closed('ida', AppointmentStatus.attended),
        _closed('perdida', AppointmentStatus.missed),
      ];
      expect(AppointmentComplianceService.nextAction(list, now: now), isNull);
    });
  });

  group('attendanceRate', () {
    test('asistidas sobre asistidas + no asistidas', () {
      final list = [
        _closed('1', AppointmentStatus.attended),
        _closed('2', AppointmentStatus.attended),
        _closed('3', AppointmentStatus.missed),
        _toBook('abierta', DateTime(2026, 9, 1)), // no cuenta
      ];
      expect(AppointmentComplianceService.attendanceRate(list), closeTo(2 / 3, 1e-9));
    });

    test('null si no hay citas cerradas', () {
      final list = [_toBook('a', DateTime(2026, 9, 1))];
      expect(AppointmentComplianceService.attendanceRate(list), isNull);
    });
  });
}
