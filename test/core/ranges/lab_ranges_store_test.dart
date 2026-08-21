import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/ranges/lab_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';

ServerBand _b(String code, double min, double max) => ServerBand(
  bandCode: code,
  bandLabel: code,
  minValue: min,
  maxValue: max,
  sortOrder: 0,
);

void main() {
  final store = LabRangesStore.instance;

  tearDown(() => store.setForTesting({}));

  test('clasifica por (lab, indicador) y clampa fuera de escala', () {
    store.setForTesting({
      'SURA': {
        'TRIGLYCERIDES': [_b('NORMAL', 0, 149.99), _b('HIGH', 200, 499.99)],
      },
    });

    expect(store.classify('SURA', 'TRIGLYCERIDES', 100)!.bandCode, 'NORMAL');
    expect(store.classify('SURA', 'TRIGLYCERIDES', 900)!.bandCode, 'HIGH');
    expect(store.classify('IDIME', 'TRIGLYCERIDES', 100), isNull);
  });

  group('LipidStatus con rangos del laboratorio', () {
    test('el corte del LAB gana sobre ATP III', () {
      // Este lab marca "alto" desde 220 (ATP III lo haría desde 240).
      store.setForTesting({
        'SURA': {
          'CHOLESTEROL_TOTAL': [
            _b('DESIRABLE', 0, 199.99),
            _b('BORDERLINE', 200, 219.99),
            _b('HIGH', 220, 1000),
          ],
        },
      });

      expect(
        LipidStatus.totalCholesterol(230, labCode: 'SURA'),
        LipidStatus.high,
      );
      // Sin lab, mismo valor: fallback ATP III → borderline.
      expect(LipidStatus.totalCholesterol(230), LipidStatus.borderline);
    });

    test('HDL invierte la semántica con las bandas del lab', () {
      store.setForTesting({
        'SURA': {
          'CHOLESTEROL_HDL': [
            _b('LOW', 0, 39.99),
            _b('NORMAL', 40, 59.99),
            _b('PROTECTIVE', 60, 200),
          ],
        },
      });

      expect(
        LipidStatus.hdl(35, labCode: 'SURA'),
        LipidStatus.high,
      ); // bajo = riesgo
      expect(LipidStatus.hdl(65, labCode: 'SURA'), LipidStatus.optimal);
    });

    test('lab sin datos cacheados cae al fallback', () {
      expect(
        LipidStatus.triglycerides(160, labCode: 'HIGUERA_ESCALANTE'),
        LipidStatus.borderline,
      );
    });
  });
}
