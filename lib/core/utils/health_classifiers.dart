import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/ranges/lab_ranges_store.dart';
import 'package:myvitals_healthtracker_app/core/ranges/reference_ranges_store.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/clinical_palette.dart';

/// Centralized classification of health metrics.
///
/// La FUENTE DE VERDAD de los umbrales son los rangos administrados en el
/// backoffice y servidos por `GET /me/reference-ranges` (ya resueltos por
/// dispositivo/sexo/edad del paciente): cada `Category.of(...)` consulta
/// primero [ReferenceRangesStore]. Los cortes literales que quedan abajo son
/// SOLO el fallback offline (invitado sin sesión o primer arranque sin red) —
/// no editarlos para "ajustar" la interpretación: eso se hace en el backoffice.
///
/// Los lípidos usan su propia fuente: los rangos del LABORATORIO donde se tomó
/// cada examen ([LabRangesStore], por el `labCode` del registro), con ATP III
/// como fallback.
/// Colores de FÁBRICA. Son el último recurso, para código que todavía llama a
/// `.color` sin `BuildContext`. La interfaz migrada NO los usa: pide
/// `.status` y deja que el tema activo resuelva el acabado
/// (`Theme.of(context).clinical.tone(cat.status)`).
///
/// Lo que NO cambia con el tema es este archivo: qué cuenta como «elevada» o
/// «alta» lo deciden los rangos del backoffice, no la paleta.
const Color _blue = Color(0xFF3B82F6); // low / near-optimal
const Color _green = Color(0xFF10B981); // normal / optimal
const Color _amber = Color(0xFFF59E0B); // elevated / borderline
const Color _red = Color(0xFFEF4444); // high / out-of-range

/// Clasifica [value] contra las bandas del servidor y las traduce al enum del
/// clasificador vía [byBandCode]. Devuelve null si no hay banda aplicable o el
/// código no está mapeado (el llamador usa su fallback de fábrica).
T? _serverCategory<T>(
  String indicatorCode,
  num value,
  Map<String, T> byBandCode,
) {
  final band = ReferenceRangesStore.instance.classify(indicatorCode, value);
  if (band == null) return null;
  return byBandCode[band.bandCode.toUpperCase()];
}

/// Blood pressure category from a systolic/diastolic reading (mmHg).
enum BpCategory {
  low,
  normal,
  elevated,
  high;

  static const _bandMap = {
    'LOW': BpCategory.low,
    'NORMAL': BpCategory.normal,
    'ELEVATED': BpCategory.elevated,
    'BORDERLINE': BpCategory.elevated,
    'HIGH': BpCategory.high,
    'VERY_HIGH': BpCategory.high,
  };

  static BpCategory of(int systolic, int diastolic) {
    // Servidor primero: se clasifica cada componente y gana el más severo.
    final s = _serverCategory('BP_SYSTOLIC', systolic, _bandMap);
    final d = _serverCategory('BP_DIASTOLIC', diastolic, _bandMap);
    if (s != null || d != null) {
      final cats = [?s, ?d];
      if (cats.contains(BpCategory.high)) return BpCategory.high;
      if (cats.contains(BpCategory.elevated)) return BpCategory.elevated;
      if (cats.contains(BpCategory.low)) return BpCategory.low;
      return BpCategory.normal;
    }
    // Fallback offline.
    if (systolic < 90 || diastolic < 60) return BpCategory.low;
    if (systolic <= 120 && diastolic <= 80) return BpCategory.normal;
    if (systolic <= 139 || diastolic <= 89) return BpCategory.elevated;
    return BpCategory.high;
  }

  Color get color => switch (this) {
    BpCategory.low => _blue,
    BpCategory.normal => _green,
    BpCategory.elevated => _amber,
    BpCategory.high => _red,
  };

  /// Severidad clínica de esta categoría. Criterio fijo: no lo altera el tema.
  ClinicalStatus get status => switch (this) {
    BpCategory.low => ClinicalStatus.info,
    BpCategory.normal => ClinicalStatus.optimal,
    BpCategory.elevated => ClinicalStatus.caution,
    BpCategory.high => ClinicalStatus.alert,
  };

  String label(AppLocalizations l10n) => switch (this) {
    BpCategory.low => l10n.bpLow,
    BpCategory.normal => l10n.bpNormal,
    BpCategory.elevated => l10n.bpElevated,
    BpCategory.high => l10n.bpHigh,
  };
}

/// Resting heart rate category (bpm).
enum HrCategory {
  low,
  normal,
  high;

  static HrCategory of(int heartRate) {
    final s = _serverCategory('HEART_RATE', heartRate, const {
      'LOW': HrCategory.low,
      'NORMAL': HrCategory.normal,
      'ELEVATED': HrCategory.high,
      'HIGH': HrCategory.high,
      'VERY_HIGH': HrCategory.high,
    });
    if (s != null) return s;
    // Fallback offline.
    if (heartRate < 60) return HrCategory.low;
    if (heartRate <= 100) return HrCategory.normal;
    return HrCategory.high;
  }

  Color get color => switch (this) {
    HrCategory.low => _blue,
    HrCategory.normal => _green,
    HrCategory.high => _red,
  };

  ClinicalStatus get status => switch (this) {
    HrCategory.low => ClinicalStatus.info,
    HrCategory.normal => ClinicalStatus.optimal,
    HrCategory.high => ClinicalStatus.alert,
  };

  String label(AppLocalizations l10n) => switch (this) {
    HrCategory.low => l10n.hrLow,
    HrCategory.normal => l10n.hrNormal,
    HrCategory.high => l10n.hrHigh,
  };
}

/// Body Mass Index category (WHO cut-offs).
enum BmiCategory {
  low,
  normal,
  overweight,
  obesity;

  static BmiCategory of(double bmi) {
    final s = _serverCategory('BMI', bmi, const {
      'UNDERWEIGHT': BmiCategory.low,
      'LOW': BmiCategory.low,
      'NORMAL': BmiCategory.normal,
      'OVERWEIGHT': BmiCategory.overweight,
      'BORDERLINE': BmiCategory.overweight,
      'OBESE': BmiCategory.obesity,
      'HIGH': BmiCategory.obesity,
      'VERY_HIGH': BmiCategory.obesity,
    });
    if (s != null) return s;
    // Fallback offline (cortes OMS).
    if (bmi < 18.5) return BmiCategory.low;
    if (bmi < 25) return BmiCategory.normal;
    if (bmi < 30) return BmiCategory.overweight;
    return BmiCategory.obesity;
  }

  Color get color => switch (this) {
    BmiCategory.low => _blue,
    BmiCategory.normal => _green,
    BmiCategory.overweight => _amber,
    BmiCategory.obesity => _red,
  };

  ClinicalStatus get status => switch (this) {
    BmiCategory.low => ClinicalStatus.info,
    BmiCategory.normal => ClinicalStatus.optimal,
    BmiCategory.overweight => ClinicalStatus.caution,
    BmiCategory.obesity => ClinicalStatus.alert,
  };

  String label(AppLocalizations l10n) => switch (this) {
    BmiCategory.low => l10n.bmiLow,
    BmiCategory.normal => l10n.bmiNormal,
    BmiCategory.overweight => l10n.bmiOverweight,
    BmiCategory.obesity => l10n.bmiObesity,
  };
}

/// Body-fat-percentage category.
enum FatCategory {
  veryLow,
  low,
  normal,
  elevated,
  high;

  static FatCategory of(double bodyFatPercent) {
    // Servidor primero: bandas por sexo/edad del paciente (tabla OMRON del backoffice).
    final s = _serverCategory('BODY_FAT', bodyFatPercent, const {
      'VERY_LOW': FatCategory.veryLow,
      'LOW': FatCategory.low,
      'NORMAL': FatCategory.normal,
      'ELEVATED': FatCategory.elevated,
      'HIGH': FatCategory.elevated,
      'VERY_HIGH': FatCategory.high,
    });
    if (s != null) return s;
    // Fallback offline.
    if (bodyFatPercent < 5) return FatCategory.veryLow;
    if (bodyFatPercent < 10) return FatCategory.low;
    if (bodyFatPercent < 25) return FatCategory.normal;
    if (bodyFatPercent < 30) return FatCategory.elevated;
    return FatCategory.high;
  }

  Color get color => switch (this) {
    FatCategory.veryLow || FatCategory.low => _blue,
    FatCategory.normal => _green,
    FatCategory.elevated => _amber,
    FatCategory.high => _red,
  };

  ClinicalStatus get status => switch (this) {
    FatCategory.veryLow || FatCategory.low => ClinicalStatus.info,
    FatCategory.normal => ClinicalStatus.optimal,
    FatCategory.elevated => ClinicalStatus.caution,
    FatCategory.high => ClinicalStatus.alert,
  };

  String label(AppLocalizations l10n) => switch (this) {
    FatCategory.veryLow => l10n.fatVeryLow,
    FatCategory.low => l10n.fatLow,
    FatCategory.normal => l10n.fatNormal,
    FatCategory.elevated => l10n.fatElevated,
    FatCategory.high => l10n.fatHigh,
  };
}

/// Visceral-fat-level category (bioimpedance scale level).
enum VisceralCategory {
  normal,
  elevated,
  high;

  static VisceralCategory of(int level) {
    final s = _serverCategory('VISCERAL_FAT_LEVEL', level, const {
      'LOW': VisceralCategory.normal,
      'NORMAL': VisceralCategory.normal,
      'ELEVATED': VisceralCategory.elevated,
      'HIGH': VisceralCategory.elevated,
      'VERY_HIGH': VisceralCategory.high,
    });
    if (s != null) return s;
    // Fallback offline (escala OMRON).
    if (level <= 9) return VisceralCategory.normal;
    if (level <= 14) return VisceralCategory.elevated;
    return VisceralCategory.high;
  }

  Color get color => switch (this) {
    VisceralCategory.normal => _green,
    VisceralCategory.elevated => _amber,
    VisceralCategory.high => _red,
  };

  ClinicalStatus get status => switch (this) {
    VisceralCategory.normal => ClinicalStatus.optimal,
    VisceralCategory.elevated => ClinicalStatus.caution,
    VisceralCategory.high => ClinicalStatus.alert,
  };

  /// Reuses the generic NORMAL / ELEVATED / HIGH fat labels.
  String label(AppLocalizations l10n) => switch (this) {
    VisceralCategory.normal => l10n.fatNormal,
    VisceralCategory.elevated => l10n.fatElevated,
    VisceralCategory.high => l10n.fatHigh,
  };
}

/// Lipid panel status, shared by every cholesterol/triglyceride field.
///
/// Fuente de verdad: los rangos del LABORATORIO donde se tomó el examen
/// ([LabRangesStore], según el `labCode` del registro). Sin lab o sin datos
/// cacheados, caen a los cortes ATP III de fábrica.
enum LipidStatus {
  optimal,
  nearOptimal,
  borderline,
  high;

  /// Mapeo genérico banda→estado para los campos donde "alto es malo".
  static const _map = {
    'DESIRABLE': LipidStatus.optimal,
    'OPTIMAL': LipidStatus.optimal,
    'NORMAL': LipidStatus.optimal,
    'NEAR_OPTIMAL': LipidStatus.nearOptimal,
    'BORDERLINE': LipidStatus.borderline,
    'PREDIABETES': LipidStatus.borderline,
    'HIGH': LipidStatus.high,
    'VERY_HIGH': LipidStatus.high,
    'LOW':
        LipidStatus.borderline, // p. ej. glucosa baja: anómalo sin ser "alto"
  };

  static LipidStatus? _fromLab(
    String? labCode,
    String indicator,
    double v, [
    Map<String, LipidStatus> byBand = _map,
  ]) {
    if (labCode == null || labCode.isEmpty) return null;
    final band = LabRangesStore.instance.classify(labCode, indicator, v);
    if (band == null) return null;
    return byBand[band.bandCode.toUpperCase()];
  }

  static LipidStatus totalCholesterol(double v, {String? labCode}) {
    final s = _fromLab(labCode, 'CHOLESTEROL_TOTAL', v);
    if (s != null) return s;
    if (v < 200) return LipidStatus.optimal;
    if (v < 240) return LipidStatus.borderline;
    return LipidStatus.high;
  }

  static LipidStatus ldl(double v, {String? labCode}) {
    final s = _fromLab(labCode, 'CHOLESTEROL_LDL', v);
    if (s != null) return s;
    if (v < 100) return LipidStatus.optimal;
    if (v < 130) return LipidStatus.nearOptimal;
    if (v < 160) return LipidStatus.borderline;
    return LipidStatus.high;
  }

  static LipidStatus hdl(double v, {String? labCode}) {
    // HDL invierte la semántica: bajo es lo riesgoso, alto protege.
    final s = _fromLab(labCode, 'CHOLESTEROL_HDL', v, const {
      'LOW': LipidStatus.high,
      'NORMAL': LipidStatus.nearOptimal,
      'PROTECTIVE': LipidStatus.optimal,
      'HIGH': LipidStatus.optimal,
    });
    if (s != null) return s;
    if (v >= 60) return LipidStatus.optimal;
    if (v >= 40) return LipidStatus.nearOptimal;
    return LipidStatus.high; // low HDL is the risky end
  }

  static LipidStatus vldl(double v, {String? labCode}) {
    final s = _fromLab(labCode, 'CHOLESTEROL_VLDL', v);
    if (s != null) return s;
    if (v >= 2 && v <= 30) return LipidStatus.optimal;
    return LipidStatus.high;
  }

  static LipidStatus triglycerides(double v, {String? labCode}) {
    final s = _fromLab(labCode, 'TRIGLYCERIDES', v);
    if (s != null) return s;
    if (v < 150) return LipidStatus.optimal;
    if (v < 200) return LipidStatus.borderline;
    return LipidStatus.high;
  }

  Color get color => switch (this) {
    LipidStatus.optimal => _green,
    LipidStatus.nearOptimal => _blue,
    LipidStatus.borderline => _amber,
    LipidStatus.high => _red,
  };

  /// Severidad clínica. `nearOptimal` cae en `info` (frío): aceptable, sin ser
  /// lo deseable — la misma lectura que «por debajo de rango» en el resto.
  ClinicalStatus get status => switch (this) {
    LipidStatus.optimal => ClinicalStatus.optimal,
    LipidStatus.nearOptimal => ClinicalStatus.info,
    LipidStatus.borderline => ClinicalStatus.caution,
    LipidStatus.high => ClinicalStatus.alert,
  };

  /// When [hdlInverted] is true the wording switches to HDL semantics, where a
  /// high reading is protective and a low reading is the concern. Colors are
  /// unaffected, matching the prior behavior.
  String label(AppLocalizations l10n, {bool hdlInverted = false}) {
    if (hdlInverted) {
      return switch (this) {
        LipidStatus.optimal => l10n.lipidStatusProtective,
        LipidStatus.nearOptimal => l10n.lipidStatusAcceptable,
        LipidStatus.borderline => l10n.lipidStatusBorderline,
        LipidStatus.high => l10n.lipidStatusLow,
      };
    }
    return switch (this) {
      LipidStatus.optimal => l10n.lipidStatusOptimal,
      LipidStatus.nearOptimal => l10n.lipidStatusNearOptimal,
      LipidStatus.borderline => l10n.lipidStatusBorderline,
      LipidStatus.high => l10n.lipidStatusHigh,
    };
  }
}

/// Worst-case lipid status across the populated fields of [record], used for
/// the dashboard/history "overall" indicator. Falls back to [LipidStatus.optimal]
/// when the record has no values. Usa los rangos del laboratorio del registro
/// ([LipidRecord.labCode]) cuando están cacheados.
LipidStatus overallLipidStatus(LipidRecord record) {
  final lab = record.labCode;
  final statuses = <LipidStatus>[
    if (record.totalCholesterol != null)
      LipidStatus.totalCholesterol(record.totalCholesterol!, labCode: lab),
    if (record.ldl != null) LipidStatus.ldl(record.ldl!, labCode: lab),
    if (record.hdl != null) LipidStatus.hdl(record.hdl!, labCode: lab),
    if (record.triglycerides != null)
      LipidStatus.triglycerides(record.triglycerides!, labCode: lab),
  ];
  if (statuses.isEmpty) return LipidStatus.optimal;
  // Severity grows with the enum index: optimal < nearOptimal < borderline < high.
  return statuses.reduce((a, b) => a.index >= b.index ? a : b);
}
