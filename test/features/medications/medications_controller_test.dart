import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication_log.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/controllers/medications_controller.dart';

/// The full controller writes through SQLite-backed repositories (exercised via
/// widget/integration tests in the UI phase); here we lock down the pure
/// inventory-transition rule, which is the part that could silently
/// double-count or lose stock.
void main() {
  group('inventoryEffectOf', () {
    test('pending -> taken consumes stock', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: null,
          next: MedicationLogStatus.taken,
        ),
        InventoryEffect.consume,
      );
    });

    test('pending -> skipped has no inventory effect', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: null,
          next: MedicationLogStatus.skipped,
        ),
        InventoryEffect.none,
      );
    });

    test('taken -> skipped restores stock', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: MedicationLogStatus.taken,
          next: MedicationLogStatus.skipped,
        ),
        InventoryEffect.restore,
      );
    });

    test('skipped -> taken consumes stock', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: MedicationLogStatus.skipped,
          next: MedicationLogStatus.taken,
        ),
        InventoryEffect.consume,
      );
    });

    test('taken -> taken does not double-count', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: MedicationLogStatus.taken,
          next: MedicationLogStatus.taken,
        ),
        InventoryEffect.none,
      );
    });

    test('skipped -> skipped is a no-op', () {
      expect(
        MedicationsController.inventoryEffectOf(
          previous: MedicationLogStatus.skipped,
          next: MedicationLogStatus.skipped,
        ),
        InventoryEffect.none,
      );
    });
  });
}
