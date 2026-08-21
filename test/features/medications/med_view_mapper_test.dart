import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myvitals_healthtracker_app/features/medications/data/models/medication.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/view_models/med_view_mapper.dart';
import 'package:myvitals_healthtracker_app/features/medications/presentation/view_models/med_view_models.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

void main() {
  late AppLocalizations es;
  late AppLocalizations en;

  setUpAll(() async {
    await initializeDateFormatting();
    es = await AppLocalizations.delegate.load(const Locale('es'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('doseAmountLabel — plural + form + locale', () {
    test('singular vs plural in Spanish', () {
      expect(doseAmountLabel(1, MedicationForm.capsule, es), '1 cápsula');
      expect(doseAmountLabel(2, MedicationForm.capsule, es), '2 cápsulas');
    });

    test('tablet form and English locale', () {
      expect(doseAmountLabel(1, MedicationForm.tablet, es), '1 tableta');
      expect(doseAmountLabel(2, MedicationForm.tablet, en), '2 tablets');
    });

    test('drops plural', () {
      expect(doseAmountLabel(3, MedicationForm.drops, es), '3 gotas');
    });
  });

  group('scheduleLabel — three frequency types', () {
    Medication med({
      required FrequencyType freq,
      int? daysOfWeek,
      int? intervalDays,
    }) => Medication(
      name: 'X',
      doseQuantity: 1,
      frequencyType: freq,
      daysOfWeek: daysOfWeek,
      intervalDays: intervalDays,
      anchorDate: DateTime(2026, 1, 1),
    );

    test('daily', () {
      final m = med(freq: FrequencyType.daily);
      expect(scheduleLabel(m, es, 'es'), 'Todos los días');
      expect(scheduleLabel(m, en, 'en'), 'Every day');
    });

    test('every N days', () {
      final m = med(freq: FrequencyType.intervalDays, intervalDays: 8);
      expect(scheduleLabel(m, es, 'es'), 'Cada 8 días');
      expect(scheduleLabel(m, en, 'en'), 'Every 8 days');
    });

    test('specific weekdays join three names with a middot', () {
      // Lunes, miércoles, viernes → bits 0, 2, 4.
      final m = med(
        freq: FrequencyType.daysOfWeek,
        daysOfWeek: (1 << 0) | (1 << 2) | (1 << 4),
      );
      final label = scheduleLabel(m, es, 'es');
      expect(label.split(' · ').length, 3);
      expect(label, isNot('Todos los días'));
    });

    test('all seven weekdays collapse to daily', () {
      final m = med(freq: FrequencyType.daysOfWeek, daysOfWeek: 0x7F);
      expect(scheduleLabel(m, es, 'es'), 'Todos los días');
    });
  });

  group('strengthLabel', () {
    test('value + unit, integer without decimals', () {
      final m = Medication(
        name: 'X',
        doseQuantity: 1,
        strengthValue: 10,
        strengthUnit: 'mg',
      );
      expect(strengthLabel(m), '10 mg');
    });

    test('empty when no strength', () {
      final m = Medication(name: 'X', doseQuantity: 1);
      expect(strengthLabel(m), '');
    });
  });

  group('color mapping', () {
    test('known keys map to their role', () {
      expect(medColorFromKey('teal'), MedColor.teal);
      expect(medColorFromKey('amber'), MedColor.amber);
    });

    test('unknown key falls back stably by seed', () {
      final a = medColorFromKey('unknown', seed: 'Vytorin');
      final b = medColorFromKey('unknown', seed: 'Vytorin');
      expect(a, b);
    });
  });

  group('runOutLabel', () {
    test('prefixes a tilde and is empty for null', () {
      expect(runOutLabel(null, 'es'), '');
      expect(runOutLabel(DateTime(2026, 8, 13), 'es').startsWith('~'), isTrue);
    });
  });
}
