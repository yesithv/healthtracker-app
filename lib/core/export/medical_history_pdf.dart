import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:myvitals_healthtracker_app/core/config/app_info.dart';
import 'package:myvitals_healthtracker_app/core/export/clinical_summary.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/clinical_palette.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/anthropometric_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/body_composition_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/vital_sign_record.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Construcción del PDF CONSOLIDADO de historia clínica (los cuatro indicadores
/// en un solo documento que el paciente enseña al médico).
///
/// Sigue la estructura de un *Patient Summary* (ISO 27269 / HL7 FHIR IPS): una
/// cabecera del paciente con la app como FUENTE, un aviso de que son datos
/// autoreportados, un resumen ejecutivo de últimos valores marcados dentro/fuera
/// de rango, y una sección por indicador con su tendencia (gráfica vectorial
/// nativa), estadísticas del periodo y los últimos registros con sus
/// comentarios. Cierra con los disclaimers completos.
///
/// La aritmética vive en `clinical_summary.dart` (puro y testeado). Aquí solo
/// se DIBUJA: se toma un [ClinicalSummary] ya recortado y se pinta. Todo el
/// texto visible entra por [AppLocalizations]; los únicos literales son cifras,
/// unidades (UCUM), códigos LOINC y la marca de la app, iguales en todo idioma.

/// Datos identificatorios del paciente para la cabecera del documento,
/// desacoplados del `UserProfileProvider` para que la construcción del PDF no
/// dependa de Flutter y se pueda testear.
class MedicalHistoryPatient {
  final String name;
  final DateTime? birthDate;

  /// Valor crudo guardado ('male' / 'female' / ''); se traduce al pintar.
  final String gender;

  const MedicalHistoryPatient({
    required this.name,
    required this.birthDate,
    required this.gender,
  });
}

// ── Paleta de estado clínico dentro del PDF ─────────────────────────────────
// El documento no es una pantalla de la app: no pasa por el sistema de temas
// (que gobierna widgets Flutter), así que aquí se usan colores fijos `PdfColors`,
// igual que los cuatro `_exportPdf` por-indicador ya existentes.
const PdfColor _ink = PdfColors.blueGrey900;
const PdfColor _muted = PdfColors.blueGrey500;
const PdfColor _hairline = PdfColors.blueGrey100;
// `PdfColor.fromInt` es factory (no const), así que este token es `final`, no
// `const`. Solo se usa en `TextStyle` no-const, de modo que no rompe nada.
final PdfColor _brand = PdfColor.fromInt(0xFF1E5A8A);

PdfColor _statusColor(ClinicalStatus s) => switch (s) {
  ClinicalStatus.info => PdfColors.blue600,
  ClinicalStatus.optimal => PdfColors.green700,
  ClinicalStatus.caution => PdfColors.orange700,
  ClinicalStatus.alert => PdfColors.red700,
  // Sin valoración clínica: gris neutro, sin cargar la lectura.
  ClinicalStatus.neutral => _muted,
};

/// Rangos de referencia ORIENTATIVOS mostrados junto a cada valor. Son cifras y
/// unidades (no texto traducible). Coinciden con el fallback offline de
/// `health_classifiers.dart`; la interpretación real la da el médico.
class _Ref {
  static const bp = '90-120 / 60-80';
  static const heartRate = '60-100';
  static const bmi = '18.5-24.9';
  static const totalCholesterol = '< 200';
  static const ldl = '< 100';
  static const hdl = '>= 40';
  static const triglycerides = '< 150';
  static const visceralFat = '<= 9';
  static const none = '-';
}

/// Códigos LOINC por métrica para el pie técnico de cada sección.
class _Loinc {
  static const bpPanel = '85354-9';
  static const heartRate = '8867-4';
  static const weight = '29463-7';
  static const bmi = '39156-5';
  static const bodyFat = '41982-0';
  static const lipidPanel = '24331-1';
}

/// Genera los bytes del PDF consolidado. No comparte ni toca disco: devolver los
/// bytes lo hace testeable (un smoke test comprueba que no está vacío).
Future<Uint8List> buildMedicalHistoryPdf({
  required ClinicalSummary summary,
  required MedicalHistoryPatient patient,
  required AppLocalizations l10n,
  required String localeName,
}) async {
  // La app no inicializa los símbolos de fecha de intl (usa el `en_US` por
  // defecto en las pestañas). Para que los meses del documento salgan en el
  // idioma del paciente hay que cargar el locale antes de formatear; sin esto,
  // un `DateFormat(..., 'es')` lanzaría `LocaleDataException`. Es idempotente.
  await initializeDateFormatting(localeName);
  final dateFmt = DateFormat('dd MMM yyyy', localeName);
  final doc = pw.Document(
    title: l10n.mhxDocTitle,
    author: '${AppInfo.appName} ${AppInfo.version}',
  );

  final sections = <pw.Widget>[
    _patientHeader(summary, patient, l10n, dateFmt),
    pw.SizedBox(height: 14),
    _disclaimerBox(l10n),
    pw.SizedBox(height: 18),
    _executiveSummary(summary, l10n, dateFmt),
  ];

  final vitals = _vitalsSection(summary, l10n, localeName, dateFmt);
  if (vitals != null) sections.addAll([pw.SizedBox(height: 20), vitals]);
  final anthro = _anthropometrySection(summary, l10n, localeName, dateFmt);
  if (anthro != null) sections.addAll([pw.SizedBox(height: 20), anthro]);
  final lipids = _lipidsSection(summary, l10n, localeName, dateFmt);
  if (lipids != null) sections.addAll([pw.SizedBox(height: 20), lipids]);
  final body = _bodyCompositionSection(summary, l10n, localeName, dateFmt);
  if (body != null) sections.addAll([pw.SizedBox(height: 20), body]);

  sections.addAll([pw.SizedBox(height: 24), _fullDisclaimer(l10n)]);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
      header: (context) => _runningHeader(context, patient, l10n),
      footer: (context) => _footer(context, l10n),
      build: (context) => sections,
    ),
  );

  return doc.save();
}

// ── Sello de marca ──────────────────────────────────────────────────────────

/// El sello de la app en el documento: un latido de ECG vectorial —el mismo
/// gesto que `EcgTrace` en la pantalla de arranque— seguido del wordmark
/// «MY VITALS». Se dibuja con `pw.CustomPaint` en vez de incrustar un PNG: sale
/// nítido a cualquier tamaño y no arrastra un asset al bundle. [scale] lo hace
/// grande en la portada y pequeño en la cabecera corriente.
pw.Widget _brandMark({double scale = 1.0}) {
  final markW = 30.0 * scale;
  final markH = 15.0 * scale;
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.CustomPaint(
        size: PdfPoint(markW, markH),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final w = size.x;
          final h = size.y;
          final mid = h / 2;
          // Línea base, pequeña subida, pico R (arriba), valle S (abajo) y
          // vuelta a la base. En PDF el eje Y crece hacia arriba, así que el
          // pico es el valor alto. Fracciones del ancho para que escale limpio.
          final pts = <List<double>>[
            [0.00, mid],
            [0.30, mid],
            [0.37, mid + h * 0.12],
            [0.45, h * 0.96],
            [0.54, h * 0.04],
            [0.62, mid + h * 0.08],
            [0.70, mid],
            [1.00, mid],
          ];
          canvas
            ..setStrokeColor(_brand)
            ..setLineWidth(1.3 * scale)
            ..moveTo(pts.first[0] * w, pts.first[1]);
          for (final p in pts.skip(1)) {
            canvas.lineTo(p[0] * w, p[1]);
          }
          canvas.strokePath();
        },
      ),
      pw.SizedBox(width: 6 * scale),
      pw.Text(
        AppInfo.appName,
        style: pw.TextStyle(
          fontSize: 13 * scale,
          fontWeight: pw.FontWeight.bold,
          color: _brand,
          letterSpacing: 1.1 * scale,
        ),
      ),
    ],
  );
}

/// Folio determinista del informe, derivado del instante de generación:
/// `MV-AAAAMMDD-HHMM`. Da al documento un identificador estable —dos
/// generaciones en el mismo minuto dan el mismo folio— con aire de informe
/// formal, sin depender de red ni de un contador persistente.
String _reportRef(DateTime at) {
  String two(int v) => v.toString().padLeft(2, '0');
  return 'MV-${at.year}${two(at.month)}${two(at.day)}-${two(at.hour)}${two(at.minute)}';
}

// ── Cabecera corriente (páginas 2+) ─────────────────────────────────────────

/// Cabecera que se repite en cada página SALVO la primera (que ya lleva la
/// portada grande). Ata cada hoja suelta a su origen: sello de la marca a la
/// izquierda, documento + paciente a la derecha, con una fina línea inferior.
pw.Widget _runningHeader(
  pw.Context context,
  MedicalHistoryPatient patient,
  AppLocalizations l10n,
) {
  if (context.pageNumber == 1) return pw.SizedBox();
  final name = patient.name.trim().isEmpty ? '-' : patient.name.trim();
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _hairline)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        _brandMark(scale: 0.7),
        pw.Text(
          '${l10n.mhxDocTitle}  ·  $name',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    ),
  );
}

// ── Portada / cabecera del paciente (página 1) ──────────────────────────────

pw.Widget _patientHeader(
  ClinicalSummary summary,
  MedicalHistoryPatient patient,
  AppLocalizations l10n,
  DateFormat dateFmt,
) {
  final name = patient.name.trim().isEmpty ? '-' : patient.name.trim();
  final dob = patient.birthDate;
  final age = dob == null ? null : _ageInYears(dob, summary.generatedAt);

  final periodText = (summary.periodStart != null && summary.periodEnd != null)
      ? '${dateFmt.format(summary.periodStart!)} - ${dateFmt.format(summary.periodEnd!)}'
      : '-';
  final generatedText = DateFormat(
    'dd MMM yyyy · HH:mm',
    dateFmt.locale,
  ).format(summary.generatedAt);

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Lockup de marca (izquierda) + folio y fecha de generación (derecha).
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _brandMark(scale: 1.15),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '${l10n.mhxReportRef} ${_reportRef(summary.generatedAt)}',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _brand,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${l10n.mhxGeneratedOn} $generatedText',
                style: const pw.TextStyle(fontSize: 7.5, color: _muted),
              ),
            ],
          ),
        ],
      ),
      pw.Divider(color: _hairline, thickness: 1, height: 18),
      // Título del documento.
      pw.Text(
        l10n.mhxDocTitle,
        style: pw.TextStyle(
          fontSize: 23,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 3),
      pw.Text(
        l10n.mhxDocSubtitle,
        style: const pw.TextStyle(fontSize: 10.5, color: _muted),
      ),
      pw.SizedBox(height: 14),
      // Tarjeta de identidad del paciente, con cinta de título.
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: _hairline),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: _brand,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(7),
                  topRight: pw.Radius.circular(7),
                ),
              ),
              child: pw.Text(
                l10n.mhxPatient.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Wrap(
                spacing: 28,
                runSpacing: 12,
                children: [
                  _headerField(l10n.mhxPatient, name),
                  _headerField(
                    l10n.mhxBirthDate,
                    dob == null
                        ? '-'
                        : '${dateFmt.format(dob)}'
                              '${age == null ? '' : '  (${l10n.mhxAgeYears(age)})'}',
                  ),
                  _headerField(l10n.gender, _genderLabel(patient.gender, l10n)),
                  _headerField(l10n.mhxPeriodCovered, periodText),
                  _headerField(
                    l10n.mhxStatsMeasurements,
                    '${summary.totalRecords}',
                  ),
                  _headerField(l10n.mhxGeneratedBy, name),
                  _headerField(
                    l10n.mhxSource,
                    '${AppInfo.appName} v${AppInfo.version} · ${l10n.mhxSelfReported}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _headerField(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        label.toUpperCase(),
        style: const pw.TextStyle(fontSize: 7, color: _muted),
      ),
      pw.SizedBox(height: 1),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 10,
          color: _ink,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    ],
  );
}

// ── Aviso destacado ─────────────────────────────────────────────────────────

pw.Widget _disclaimerBox(AppLocalizations l10n) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: PdfColors.orange50,
      border: pw.Border.all(color: PdfColors.orange200),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          l10n.mhxDisclaimerTitle,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange900,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          l10n.mhxDisclaimerBody,
          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.orange900),
        ),
      ],
    ),
  );
}

// ── Resumen ejecutivo ───────────────────────────────────────────────────────

pw.Widget _executiveSummary(
  ClinicalSummary summary,
  AppLocalizations l10n,
  DateFormat dateFmt,
) {
  final rows = <_SummaryRow>[];

  final vital = summary.vitals.isEmpty ? null : summary.vitals.last;
  if (vital != null) {
    final bp = BpCategory.of(vital.systolic, vital.diastolic);
    rows.add(
      _SummaryRow(
        l10n.mhxBloodPressure,
        '${vital.systolic}/${vital.diastolic} mmHg',
        dateFmt.format(vital.date),
        _Ref.bp,
        bp.label(l10n),
        bp.status,
      ),
    );
    final hr = HrCategory.of(vital.heartRate);
    rows.add(
      _SummaryRow(
        l10n.mhxHeartRate,
        '${vital.heartRate} bpm',
        dateFmt.format(vital.date),
        _Ref.heartRate,
        hr.label(l10n),
        hr.status,
      ),
    );
  }

  final anthro = summary.anthropometry.isEmpty
      ? null
      : summary.anthropometry.last;
  if (anthro != null) {
    rows.add(
      _SummaryRow(
        l10n.mhxWeight,
        '${_fmt1(anthro.weight)} kg',
        dateFmt.format(anthro.date),
        _Ref.none,
        null,
        null,
      ),
    );
    final bmi = BmiCategory.of(anthro.bmi);
    rows.add(
      _SummaryRow(
        l10n.mhxBmi,
        _fmt1(anthro.bmi),
        dateFmt.format(anthro.date),
        _Ref.bmi,
        bmi.label(l10n),
        bmi.status,
      ),
    );
  }

  final body = summary.bodyComposition.isEmpty
      ? null
      : summary.bodyComposition.last;
  if (body != null && body.bodyFatPercent != null) {
    final fat = FatCategory.of(body.bodyFatPercent!);
    rows.add(
      _SummaryRow(
        l10n.mhxBodyFat,
        '${_fmt1(body.bodyFatPercent!)} %',
        dateFmt.format(body.date),
        _Ref.none,
        fat.label(l10n),
        fat.status,
      ),
    );
  }
  if (body != null && body.visceralFatLevel != null) {
    final vf = VisceralCategory.of(body.visceralFatLevel!);
    rows.add(
      _SummaryRow(
        l10n.mhxVisceralFat,
        '${body.visceralFatLevel}',
        dateFmt.format(body.date),
        _Ref.visceralFat,
        vf.label(l10n),
        vf.status,
      ),
    );
  }

  final lipid = summary.lipids.isEmpty ? null : summary.lipids.last;
  if (lipid != null) {
    final lab = lipid.labCode;
    if (lipid.totalCholesterol != null) {
      final s = LipidStatus.totalCholesterol(
        lipid.totalCholesterol!,
        labCode: lab,
      );
      rows.add(
        _SummaryRow(
          l10n.mhxTotalCholesterol,
          '${_fmt0(lipid.totalCholesterol!)} mg/dL',
          dateFmt.format(lipid.date),
          _Ref.totalCholesterol,
          s.label(l10n),
          s.status,
        ),
      );
    }
    if (lipid.ldl != null) {
      final s = LipidStatus.ldl(lipid.ldl!, labCode: lab);
      rows.add(
        _SummaryRow(
          l10n.mhxLdl,
          '${_fmt0(lipid.ldl!)} mg/dL',
          dateFmt.format(lipid.date),
          _Ref.ldl,
          s.label(l10n),
          s.status,
        ),
      );
    }
    if (lipid.hdl != null) {
      final s = LipidStatus.hdl(lipid.hdl!, labCode: lab);
      rows.add(
        _SummaryRow(
          l10n.mhxHdl,
          '${_fmt0(lipid.hdl!)} mg/dL',
          dateFmt.format(lipid.date),
          _Ref.hdl,
          s.label(l10n, hdlInverted: true),
          s.status,
        ),
      );
    }
    if (lipid.triglycerides != null) {
      final s = LipidStatus.triglycerides(lipid.triglycerides!, labCode: lab);
      rows.add(
        _SummaryRow(
          l10n.mhxTriglycerides,
          '${_fmt0(lipid.triglycerides!)} mg/dL',
          dateFmt.format(lipid.date),
          _Ref.triglycerides,
          s.label(l10n),
          s.status,
        ),
      );
    }
  }

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle(l10n.mhxSummaryTitle),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _hairline),
          bottom: pw.BorderSide(color: _hairline),
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(2.4),
          1: pw.FlexColumnWidth(1.9),
          2: pw.FlexColumnWidth(1.7),
          3: pw.FlexColumnWidth(1.6),
          4: pw.FlexColumnWidth(1.8),
        },
        children: [
          _summaryHeaderRow(l10n),
          ...rows.map(_summaryDataRow),
        ],
      ),
    ],
  );
}

pw.TableRow _summaryHeaderRow(AppLocalizations l10n) {
  pw.Widget h(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Text(
      t.toUpperCase(),
      style: const pw.TextStyle(fontSize: 7.5, color: _muted),
    ),
  );
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
    children: [
      h(l10n.mhxColIndicator),
      h(l10n.mhxColLatest),
      h(l10n.historyColDate),
      h(l10n.mhxColReference),
      h(l10n.mhxColStatus),
    ],
  );
}

pw.TableRow _summaryDataRow(_SummaryRow r) {
  pw.Widget c(String t, {PdfColor color = _ink, bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
        child: pw.Text(
          t,
          style: pw.TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
  return pw.TableRow(
    children: [
      c(r.indicator, bold: true),
      c(r.value),
      c(r.date, color: _muted),
      c(r.reference, color: _muted),
      r.statusLabel == null
          ? c('-', color: _muted)
          : c(r.statusLabel!, color: _statusColor(r.status!), bold: true),
    ],
  );
}

class _SummaryRow {
  final String indicator;
  final String value;
  final String date;
  final String reference;
  final String? statusLabel;
  final ClinicalStatus? status;
  _SummaryRow(
    this.indicator,
    this.value,
    this.date,
    this.reference,
    this.statusLabel,
    this.status,
  );
}

// ── Secciones por indicador ─────────────────────────────────────────────────

pw.Widget? _vitalsSection(
  ClinicalSummary summary,
  AppLocalizations l10n,
  String localeName,
  DateFormat dateFmt,
) {
  final records = summary.vitals;
  if (records.isEmpty) return null;

  final sys = summary.systolicSeries.sampled();
  final dia = summary.diastolicSeries.sampled();
  final chart = _trendChart(
    lines: [
      _ChartLine(l10n.mhxSystolic, PdfColors.red600, sys),
      _ChartLine(l10n.mhxDiastolic, PdfColors.blue600, dia),
    ],
    dateFmt: dateFmt,
  );

  final stats = <pw.Widget>[
    _statBlock(l10n.mhxStatsMeasurements, '${records.length}'),
    if (summary.heartRateSeries.stats != null)
      _statBlock(
        l10n.mhxHeartRate,
        '${_fmt0(summary.heartRateSeries.stats!.average)} bpm',
        caption: l10n.mhxStatsAverage,
      ),
  ];

  // Últimos registros (más reciente primero), tabla con comentarios.
  final table = _recordsTable(
    l10n: l10n,
    dateFmt: dateFmt,
    valueHeader: l10n.mhxBloodPressure,
    records: records.reversed.take(12).toList(),
    valueOf: (r) {
      final v = r as VitalSignRecord;
      return '${v.systolic}/${v.diastolic} · ${v.heartRate} bpm';
    },
    commentOf: (r) => (r as VitalSignRecord).comment,
  );

  return _indicatorSection(
    title: l10n.vitalSigns,
    accent: PdfColors.red600,
    chart: chart,
    stats: stats,
    table: table,
    coding: '${l10n.mhxColReference}: ${_Ref.bp} mmHg · '
        'LOINC ${_Loinc.bpPanel}, ${_Loinc.heartRate} · UCUM mm[Hg], /min',
  );
}

pw.Widget? _anthropometrySection(
  ClinicalSummary summary,
  AppLocalizations l10n,
  String localeName,
  DateFormat dateFmt,
) {
  final records = summary.anthropometry;
  if (records.isEmpty) return null;

  final weight = summary.weightSeries.sampled();
  final chart = _trendChart(
    lines: [_ChartLine(l10n.mhxWeight, PdfColors.blue700, weight)],
    dateFmt: dateFmt,
  );

  final wStats = summary.weightSeries.stats;
  final bmiStats = summary.bmiSeries.stats;
  final stats = <pw.Widget>[
    if (wStats != null)
      _statBlock(
        l10n.mhxWeight,
        '${_fmt1(wStats.average)} kg',
        caption: l10n.mhxStatsAverage,
      ),
    if (wStats != null)
      _statBlock(
        l10n.mhxStatsRange,
        '${_fmt1(wStats.min)}-${_fmt1(wStats.max)} kg',
      ),
    if (bmiStats != null)
      _statBlock(l10n.mhxBmi, _fmt1(bmiStats.latest), caption: l10n.mhxStatsLatest),
  ];

  final table = _recordsTable(
    l10n: l10n,
    dateFmt: dateFmt,
    valueHeader: '${l10n.mhxWeight} · ${l10n.mhxBmi}',
    records: records.reversed.take(12).toList(),
    valueOf: (r) {
      final a = r as AnthropometricRecord;
      return '${_fmt1(a.weight)} kg · ${_fmt1(a.bmi)}';
    },
    commentOf: (r) => (r as AnthropometricRecord).comment,
  );

  return _indicatorSection(
    title: l10n.anthropometry,
    accent: PdfColors.blue700,
    chart: chart,
    stats: stats,
    table: table,
    coding: 'LOINC ${_Loinc.weight}, ${_Loinc.bmi} · UCUM kg, kg/m2',
  );
}

pw.Widget? _lipidsSection(
  ClinicalSummary summary,
  AppLocalizations l10n,
  String localeName,
  DateFormat dateFmt,
) {
  final records = summary.lipids;
  if (records.isEmpty) return null;

  // Solo el colesterol total se grafica: LDL/HDL/triglicéridos son campos
  // OPCIONALES, con fechas propias, y una gráfica multilínea exige que todas las
  // series compartan el eje X (como sí ocurre con sistólica/diastólica). Sus
  // valores van igualmente en la tabla y en el resumen ejecutivo.
  final total = summary.totalCholesterolSeries.sampled();
  final chart = total.length >= 2
      ? _trendChart(
          lines: [
            _ChartLine(l10n.mhxTotalCholesterol, PdfColors.pink600, total),
          ],
          dateFmt: dateFmt,
        )
      : null;

  final table = _recordsTable(
    l10n: l10n,
    dateFmt: dateFmt,
    valueHeader: 'Col · LDL · HDL · Trig (mg/dL)',
    records: records.reversed.take(12).toList(),
    valueOf: (r) {
      final l = r as LipidRecord;
      return [
        _fmtOrDash(l.totalCholesterol),
        _fmtOrDash(l.ldl),
        _fmtOrDash(l.hdl),
        _fmtOrDash(l.triglycerides),
      ].join(' · ');
    },
    commentOf: (r) => (r as LipidRecord).comment,
  );

  return _indicatorSection(
    title: l10n.lipidProfile,
    accent: PdfColors.pink600,
    chart: chart,
    stats: const [],
    table: table,
    coding: '${l10n.mhxColReference}: ${_Ref.totalCholesterol} · '
        'LDL ${_Ref.ldl} · HDL ${_Ref.hdl} · Trig ${_Ref.triglycerides} mg/dL · '
        'LOINC ${_Loinc.lipidPanel}',
  );
}

pw.Widget? _bodyCompositionSection(
  ClinicalSummary summary,
  AppLocalizations l10n,
  String localeName,
  DateFormat dateFmt,
) {
  final records = summary.bodyComposition;
  if (records.isEmpty) return null;

  final fat = summary.bodyFatSeries.sampled();
  final chart = fat.length >= 2
      ? _trendChart(
          lines: [_ChartLine(l10n.mhxBodyFat, PdfColors.deepOrange400, fat)],
          dateFmt: dateFmt,
        )
      : null;

  final fatStats = summary.bodyFatSeries.stats;
  final stats = <pw.Widget>[
    if (fatStats != null)
      _statBlock(
        l10n.mhxBodyFat,
        '${_fmt1(fatStats.average)} %',
        caption: l10n.mhxStatsAverage,
      ),
    if (fatStats != null)
      _statBlock(
        l10n.mhxStatsRange,
        '${_fmt1(fatStats.min)}-${_fmt1(fatStats.max)} %',
      ),
  ];

  final table = _recordsTable(
    l10n: l10n,
    dateFmt: dateFmt,
    valueHeader: l10n.mhxBodyFat,
    records: records.reversed.take(12).toList(),
    valueOf: (r) {
      final b = r as BodyCompositionRecord;
      final parts = <String>[
        if (b.bodyFatPercent != null) '${_fmt1(b.bodyFatPercent!)} %',
        if (b.visceralFatLevel != null)
          '${l10n.mhxVisceralFat}: ${b.visceralFatLevel}',
      ];
      return parts.isEmpty ? '-' : parts.join(' · ');
    },
    commentOf: (r) => (r as BodyCompositionRecord).comment,
  );

  return _indicatorSection(
    title: l10n.bodyComposition,
    accent: PdfColors.deepOrange400,
    chart: chart,
    stats: stats,
    table: table,
    coding: 'LOINC ${_Loinc.bodyFat} · UCUM %',
  );
}

/// Envoltorio común de una sección de indicador: título con acento, gráfica de
/// tendencia (si hay ≥2 puntos), tira de estadísticas, tabla de registros y pie
/// técnico con la codificación LOINC/UCUM.
pw.Widget _indicatorSection({
  required String title,
  required PdfColor accent,
  required pw.Widget? chart,
  required List<pw.Widget> stats,
  required pw.Widget table,
  required String coding,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Row(
        children: [
          pw.Container(width: 4, height: 14, color: accent),
          pw.SizedBox(width: 6),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      if (chart != null) ...[chart, pw.SizedBox(height: 10)],
      if (stats.isNotEmpty) ...[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            for (final s in stats) ...[s, pw.SizedBox(width: 20)],
          ],
        ),
        pw.SizedBox(height: 10),
      ],
      table,
      pw.SizedBox(height: 4),
      pw.Text(coding, style: const pw.TextStyle(fontSize: 6.5, color: _muted)),
    ],
  );
}

pw.Widget _statBlock(String label, String value, {String? caption}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        (caption ?? label).toUpperCase(),
        style: const pw.TextStyle(fontSize: 6.5, color: _muted),
      ),
      pw.SizedBox(height: 1),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      if (caption != null)
        pw.Text(label, style: const pw.TextStyle(fontSize: 6.5, color: _muted)),
    ],
  );
}

/// Tabla de los últimos registros de un indicador: fecha, valor(es) y el
/// comentario del registro (la «observación» que pidió el usuario).
pw.Widget _recordsTable({
  required AppLocalizations l10n,
  required DateFormat dateFmt,
  required String valueHeader,
  required List<Object> records,
  required String Function(Object) valueOf,
  required String? Function(Object) commentOf,
}) {
  pw.Widget headerCell(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: pw.Text(
      t.toUpperCase(),
      style: const pw.TextStyle(fontSize: 7, color: _muted),
    ),
  );
  pw.Widget dataCell(String t, {PdfColor color = _ink}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
    child: pw.Text(t, style: pw.TextStyle(fontSize: 8.5, color: color)),
  );

  return pw.Table(
    border: pw.TableBorder(horizontalInside: pw.BorderSide(color: _hairline)),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4),
      1: pw.FlexColumnWidth(2.2),
      2: pw.FlexColumnWidth(2.6),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          headerCell(l10n.historyColDate),
          headerCell(valueHeader),
          headerCell(l10n.mhxColNotes),
        ],
      ),
      for (final r in records)
        pw.TableRow(
          children: [
            dataCell(dateFmt.format((r as dynamic).date as DateTime)),
            dataCell(valueOf(r)),
            dataCell(commentOf(r) ?? '-', color: _muted),
          ],
        ),
    ],
  );
}

// ── Gráfica de tendencia vectorial ──────────────────────────────────────────

class _ChartLine {
  final String label;
  final PdfColor color;
  final List<SeriesPoint> points; // ya muestreados
  _ChartLine(this.label, this.color, this.points);
}

/// Dibuja una o más series sobre los mismos ejes. Las series de una misma
/// gráfica comparten fechas (vienen de la misma lista de registros), así que su
/// eje X se indexa por posición y las etiquetas salen de la primera serie.
pw.Widget _trendChart({
  required List<_ChartLine> lines,
  required DateFormat dateFmt,
}) {
  final ref = lines.first.points;
  final n = ref.length;
  // Con menos de dos puntos no hay tendencia que dibujar y el eje X degeneraría
  // (min == max). El valor sigue estando en el resumen y en la tabla.
  if (n < 2) return pw.SizedBox();

  double minY = double.infinity;
  double maxY = -double.infinity;
  for (final l in lines) {
    for (final p in l.points) {
      if (p.value < minY) minY = p.value;
      if (p.value > maxY) maxY = p.value;
    }
  }
  if (minY == maxY) {
    minY -= 1;
    maxY += 1;
  }
  final pad = (maxY - minY) * 0.12;
  final lo = minY - pad;
  final hi = maxY + pad;
  final yTicks = List<double>.generate(5, (i) => lo + (hi - lo) * i / 4);

  final step = _labelStep(n);
  final xTickSet = <int>{0, n - 1};
  for (var i = 0; i < n; i += step) {
    xTickSet.add(i);
  }
  final xTicks = xTickSet.toList()..sort();

  return pw.Container(
    height: 150,
    width: double.infinity,
    padding: const pw.EdgeInsets.only(top: 4, right: 6),
    child: pw.Chart(
      right: lines.length > 1
          ? pw.ChartLegend(
              textStyle: const pw.TextStyle(fontSize: 7, color: _muted),
              decoration: const pw.BoxDecoration(),
            )
          : null,
      grid: pw.CartesianGrid(
        xAxis: pw.FixedAxis(
          xTicks,
          format: (v) {
            final i = v.toInt();
            if (i < 0 || i >= n) return '';
            return dateFmt.format(ref[i].date);
          },
          textStyle: const pw.TextStyle(fontSize: 6.5, color: _muted),
          color: _hairline,
          divisions: false,
        ),
        yAxis: pw.FixedAxis(
          yTicks,
          format: (v) => v.toStringAsFixed(0),
          textStyle: const pw.TextStyle(fontSize: 6.5, color: _muted),
          color: _hairline,
          divisions: true,
          divisionsColor: _hairline,
        ),
      ),
      datasets: [
        for (final l in lines)
          pw.LineDataSet(
            legend: l.label,
            drawSurface: false,
            isCurved: false,
            drawPoints: true,
            pointSize: 2.2,
            lineWidth: 1.6,
            color: l.color,
            data: [
              for (var i = 0; i < l.points.length; i++)
                pw.PointChartValue(i.toDouble(), l.points[i].value),
            ],
          ),
      ],
    ),
  );
}

int _labelStep(int count, {int maxLabels = 6}) {
  if (count <= maxLabels) return 1;
  return (count / maxLabels).ceil();
}

// ── Pie y disclaimers ───────────────────────────────────────────────────────

pw.Widget _fullDisclaimer(AppLocalizations l10n) {
  return pw.Container(
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _hairline)),
    ),
    child: pw.Text(
      l10n.mhxFooterDisclaimer,
      style: const pw.TextStyle(fontSize: 7, color: _muted),
    ),
  );
}

pw.Widget _footer(pw.Context context, AppLocalizations l10n) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 8),
    padding: const pw.EdgeInsets.only(top: 6),
    decoration: const pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _hairline)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${AppInfo.appName} v${AppInfo.version} · ${l10n.mhxSelfReported}',
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
        pw.Text(
          l10n.mhxPageOf(context.pageNumber, context.pagesCount),
          style: const pw.TextStyle(fontSize: 7, color: _muted),
        ),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String t) => pw.Text(
  t,
  style: pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: _ink,
  ),
);

// ── Utilidades de formato ───────────────────────────────────────────────────

String _fmt0(double v) => v.toStringAsFixed(0);
String _fmt1(double v) => v.toStringAsFixed(1);
String _fmtOrDash(double? v) => v == null ? '-' : _fmt0(v);

int _ageInYears(DateTime dob, DateTime at) {
  var age = at.year - dob.year;
  if (at.month < dob.month || (at.month == dob.month && at.day < dob.day)) {
    age--;
  }
  return age;
}

String _genderLabel(String raw, AppLocalizations l10n) => switch (raw) {
  'male' => l10n.male,
  'female' => l10n.female,
  'other' => l10n.other,
  _ => '-',
};
