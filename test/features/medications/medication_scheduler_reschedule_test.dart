import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_dose.dart';
import 'package:myvitals_healthtracker_app/features/medications/domain/medication_scheduler.dart';

/// Doble de prueba del servicio de notificaciones: registra los ids programados
/// y cancelados en lugar de llamar al plugin. Usa el constructor `forTesting`.
class _FakeNotificationService extends NotificationService {
  _FakeNotificationService() : super.forTesting();

  final List<int> scheduled = [];
  final List<int> canceled = [];

  @override
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    String channelId = NotificationService.medicationChannelId,
    String channelName = 'Recordatorios de medicamentos',
    String channelDescription =
        'Avisos de tomas de medicamentos y de recompra de inventario',
  }) async {
    scheduled.add(id);
  }

  @override
  Future<void> cancel(int id) async {
    canceled.add(id);
  }
}

/// Clave del libro de ids que persiste el planificador (privada en producción).
const String _ledgerKey = 'medication_notif_ids';

Medication _med(String id) => Medication(
      id: id,
      name: 'Med-$id',
      doseQuantity: 1,
      frequencyType: FrequencyType.daily,
      startDate: DateTime(2026, 1, 1),
    );

MedicationDose _dose(String medId, int hour) =>
    MedicationDose(medicationId: medId, hour: hour, minute: 0);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rescheduleAll schedules the plan and persists its ids', () async {
    final notif = _FakeNotificationService();
    final scheduler = MedicationScheduler(notificationService: notif);
    final med = _med('a');

    await scheduler.rescheduleAll(
      medications: [med],
      dosesByMedication: {
        'a': [_dose('a', 8), _dose('a', 20)],
      },
      now: DateTime(2026, 8, 17, 0, 0),
      horizonDays: 0, // solo el día 17 → 2 tomas
    );

    expect(notif.scheduled, [200000, 200001]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_ledgerKey), ['200000', '200001']);
  });

  test('a second run cancels the previous run by its persisted ledger', () async {
    final notif = _FakeNotificationService();
    final scheduler = MedicationScheduler(notificationService: notif);

    // Primera pasada: programa dos avisos y los guarda en el libro.
    await scheduler.rescheduleAll(
      medications: [_med('a')],
      dosesByMedication: {
        'a': [_dose('a', 8), _dose('a', 20)],
      },
      now: DateTime(2026, 8, 17, 0, 0),
      horizonDays: 0,
    );
    final firstRunIds = List<int>.from(notif.scheduled);
    notif.scheduled.clear();

    // Segunda pasada sin medicamentos: no programa nada nuevo y cancela los
    // anteriores por el libro, dejándolo vacío (sin avisos huérfanos).
    await scheduler.rescheduleAll(
      medications: const [],
      dosesByMedication: const {},
      now: DateTime(2026, 8, 17, 0, 0),
      horizonDays: 0,
    );

    expect(notif.canceled, containsAll(firstRunIds));
    expect(notif.scheduled, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_ledgerKey), isEmpty);
  });

  test('cancelAll cancels the ledger and clears it', () async {
    final notif = _FakeNotificationService();
    final scheduler = MedicationScheduler(notificationService: notif);

    await scheduler.rescheduleAll(
      medications: [_med('a')],
      dosesByMedication: {
        'a': [_dose('a', 8)],
      },
      now: DateTime(2026, 8, 17, 0, 0),
      horizonDays: 0,
    );
    final ids = List<int>.from(notif.scheduled);

    await scheduler.cancelAll();

    expect(notif.canceled, containsAll(ids));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_ledgerKey), isNull);
  });
}
