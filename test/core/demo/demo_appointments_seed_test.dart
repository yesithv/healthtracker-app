import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/database/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:myvitals_healthtracker_app/core/demo/demo_appointments_seed.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';
import 'package:myvitals_healthtracker_app/features/appointments/domain/appointment_compliance_service.dart';

/// La siembra de citas de la demo debe poblar el inventario con un juego que
/// enseñe todos los estados, y ser idempotente (no duplicar si ya hay datos).
void main() {
  setUpAll(() {
    // Base propia para este fichero: `flutter test` corre los ficheros en paralelo
    // y compartir el archivo los bloquea entre sí («database is locked»).
    DatabaseService.useDatabaseFile('test-demo-appointments-seed.db');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await AppointmentRepository.instance.clearAll();
  });

  test('siembra un juego con todos los estados', () async {
    final repo = AppointmentRepository.instance;
    await seedDemoAppointmentsIfEmpty();
    await repo.refresh();

    // Una agendada, tres por sacar, tres de historial.
    expect(repo.scheduled.length, 1);
    expect(repo.toBook.length, 3);
    expect(repo.history.length, 3);

    // Hay exactamente una vencida (la de laboratorio, con fecha objetivo pasada).
    expect(AppointmentComplianceService.overdueCount(repo.items), 1);

    // Hay una serie recurrente (control endocrino) representada por su próxima
    // «por sacar».
    final recurring = repo.toBook.where((a) => a.isRecurring).toList();
    expect(recurring, hasLength(1));
    expect(recurring.single.intervalMonths, 3);
    expect(recurring.single.seriesId, isNotNull);

    // Tasa de asistencia calculable (2 asistidas, 1 no asistida).
    expect(AppointmentComplianceService.attendanceRate(repo.items), isNotNull);
  });

  test('es idempotente: una segunda llamada no duplica', () async {
    await seedDemoAppointmentsIfEmpty();
    await AppointmentRepository.instance.refresh();
    final firstCount = AppointmentRepository.instance.items.length;

    await seedDemoAppointmentsIfEmpty();
    await AppointmentRepository.instance.refresh();

    expect(AppointmentRepository.instance.items.length, firstCount);
  });

  test('las citas sembradas persisten con su estado', () async {
    await seedDemoAppointmentsIfEmpty();
    await AppointmentRepository.instance.refresh();

    final byStatus = <AppointmentStatus, int>{};
    for (final a in AppointmentRepository.instance.items) {
      byStatus[a.status] = (byStatus[a.status] ?? 0) + 1;
    }
    expect(byStatus[AppointmentStatus.scheduled], 1);
    expect(byStatus[AppointmentStatus.toBook], 3);
    expect(byStatus[AppointmentStatus.attended], 2);
    expect(byStatus[AppointmentStatus.missed], 1);
  });
}
