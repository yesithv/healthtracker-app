import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/export/clinical_summary.dart';
import 'package:myvitals_healthtracker_app/core/export/medical_history_pdf.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Smoke test: el PDF consolidado se construye sin lanzar y produce un documento
/// PDF real. No renderiza ni comparte (eso es del sistema): solo comprueba que la
/// tubería `resumen -> pdf` funciona en varios idiomas y con series largas.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 8, 7, 9, 30);

  ClinicalSummary sampleSummary({int n = 60}) {
    // ~n mediciones a lo largo de dos años, con valores que mejoran, para que
    // haya tendencia real que graficar.
    final vitals = <VitalSignRecord>[];
    final anthro = <AnthropometricRecord>[];
    final lipids = <LipidRecord>[];
    final body = <BodyCompositionRecord>[];
    for (var i = 0; i < n; i++) {
      final d = now.subtract(Duration(days: (n - i) * 12));
      vitals.add(
        VitalSignRecord(
          date: d,
          systolic: 140 - i ~/ 2,
          diastolic: 90 - i ~/ 3,
          heartRate: 78 - i ~/ 5,
          comment: i.isEven ? 'medición en reposo' : null,
        ),
      );
      anthro.add(
        AnthropometricRecord(
          date: d,
          weight: 92 - i * 0.2,
          height: 176,
          bmi: 29.8 - i * 0.06,
        ),
      );
      if (i % 6 == 0) {
        lipids.add(
          LipidRecord(
            date: d,
            totalCholesterol: 236 - i.toDouble(),
            ldl: 158 - i.toDouble(),
            hdl: 38 + i / 4,
            triglycerides: 180 - i.toDouble(),
          ),
        );
      }
      body.add(
        BodyCompositionRecord(
          date: d,
          bodyFatPercent: 31.4 - i * 0.15,
          visceralFatLevel: 13 - i ~/ 12,
        ),
      );
    }
    return buildClinicalSummary(
      period: ExportPeriod.all,
      now: now,
      vitals: vitals,
      anthropometry: anthro,
      lipids: lipids,
      bodyComposition: body,
    );
  }

  const patient = MedicalHistoryPatient(
    name: 'Daniel Ospina',
    birthDate: null,
    gender: 'male',
  );

  Future<void> expectValidPdf(String locale) async {
    final l10n = await AppLocalizations.delegate.load(Locale(locale));
    final bytes = await buildMedicalHistoryPdf(
      summary: sampleSummary(),
      patient: MedicalHistoryPatient(
        name: patient.name,
        birthDate: DateTime(1983, 5, 12),
        gender: patient.gender,
      ),
      l10n: l10n,
      localeName: locale,
    );
    expect(bytes.length, greaterThan(1000));
    // Cabecera mágica de un PDF.
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  }

  test('genera un PDF válido en español', () => expectValidPdf('es'));
  test('genera un PDF válido en inglés', () => expectValidPdf('en'));

  test('no lanza con un resumen vacío (aunque la UI no lo permita)', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final empty = buildClinicalSummary(
      period: ExportPeriod.all,
      now: now,
      vitals: const [],
      anthropometry: const [],
      lipids: const [],
      bodyComposition: const [],
    );
    final bytes = await buildMedicalHistoryPdf(
      summary: empty,
      patient: patient,
      l10n: l10n,
      localeName: 'en',
    );
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}
