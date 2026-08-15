import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';

/// Cubre los índices derivados (WHtR/WHR) que la gráfica del historial dibuja a
/// partir de los perímetros opcionales. Son Dart puro, sin base de datos.
void main() {
  AnthropometricRecord rec({double? waist, double? hip, double height = 175}) {
    return AnthropometricRecord(
      date: DateTime(2024, 1, 1),
      weight: 70,
      height: height,
      bmi: 22.9,
      waistCm: waist,
      hipCm: hip,
    );
  }

  group('AnthropometricRecord.whtr', () {
    test('es cintura ÷ altura cuando hay cintura', () {
      expect(rec(waist: 87.5, height: 175).whtr, closeTo(0.5, 1e-9));
    });

    test('null sin cintura', () {
      expect(rec(waist: null).whtr, isNull);
    });

    test('null con altura inválida', () {
      expect(rec(waist: 80, height: 0).whtr, isNull);
    });
  });

  group('AnthropometricRecord.whr', () {
    test('es cintura ÷ cadera cuando hay ambas', () {
      expect(rec(waist: 90, hip: 100).whr, closeTo(0.9, 1e-9));
    });

    test('null si falta la cadera', () {
      expect(rec(waist: 90, hip: null).whr, isNull);
    });

    test('null si falta la cintura', () {
      expect(rec(waist: null, hip: 100).whr, isNull);
    });
  });
}
