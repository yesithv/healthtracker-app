import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';

/// Centralized, single-source-of-truth classification of health metrics.
///
/// Each metric is an enhanced enum: `Category.of(...)` performs the pure
/// classification (no UI dependency, easy to unit-test), while `.color` and
/// `.label(l10n)` map a category to its presentation. All medical thresholds
/// live here and nowhere else — screens must not re-derive them.
///
/// The semantic colors below match the hex values previously hardcoded across
/// the screens. Phase 6 will fold them into the app-wide design system.
const Color _blue = Color(0xFF3B82F6); // low / near-optimal
const Color _green = Color(0xFF10B981); // normal / optimal
const Color _amber = Color(0xFFF59E0B); // elevated / borderline
const Color _red = Color(0xFFEF4444); // high / out-of-range

/// Blood pressure category from a systolic/diastolic reading (mmHg).
enum BpCategory {
  low,
  normal,
  elevated,
  high;

  static BpCategory of(int systolic, int diastolic) {
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
    if (heartRate < 60) return HrCategory.low;
    if (heartRate <= 100) return HrCategory.normal;
    return HrCategory.high;
  }

  Color get color => switch (this) {
    HrCategory.low => _blue,
    HrCategory.normal => _green,
    HrCategory.high => _red,
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
    if (level <= 9) return VisceralCategory.normal;
    if (level <= 14) return VisceralCategory.elevated;
    return VisceralCategory.high;
  }

  Color get color => switch (this) {
    VisceralCategory.normal => _green,
    VisceralCategory.elevated => _amber,
    VisceralCategory.high => _red,
  };

  /// Reuses the generic NORMAL / ELEVATED / HIGH fat labels.
  String label(AppLocalizations l10n) => switch (this) {
    VisceralCategory.normal => l10n.fatNormal,
    VisceralCategory.elevated => l10n.fatElevated,
    VisceralCategory.high => l10n.fatHigh,
  };
}

/// Lipid panel status, shared by every cholesterol/triglyceride field
/// (ATP III style cut-offs). Use the named constructors per field.
enum LipidStatus {
  optimal,
  nearOptimal,
  borderline,
  high;

  static LipidStatus totalCholesterol(double v) {
    if (v < 200) return LipidStatus.optimal;
    if (v < 240) return LipidStatus.borderline;
    return LipidStatus.high;
  }

  static LipidStatus ldl(double v) {
    if (v < 100) return LipidStatus.optimal;
    if (v < 130) return LipidStatus.nearOptimal;
    if (v < 160) return LipidStatus.borderline;
    return LipidStatus.high;
  }

  static LipidStatus hdl(double v) {
    if (v >= 60) return LipidStatus.optimal;
    if (v >= 40) return LipidStatus.nearOptimal;
    return LipidStatus.high; // low HDL is the risky end
  }

  static LipidStatus vldl(double v) {
    if (v >= 2 && v <= 30) return LipidStatus.optimal;
    return LipidStatus.high;
  }

  static LipidStatus triglycerides(double v) {
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
/// when the record has no values.
LipidStatus overallLipidStatus(LipidRecord record) {
  final statuses = <LipidStatus>[
    if (record.totalCholesterol != null)
      LipidStatus.totalCholesterol(record.totalCholesterol!),
    if (record.ldl != null) LipidStatus.ldl(record.ldl!),
    if (record.hdl != null) LipidStatus.hdl(record.hdl!),
    if (record.triglycerides != null)
      LipidStatus.triglycerides(record.triglycerides!),
  ];
  if (statuses.isEmpty) return LipidStatus.optimal;
  // Severity grows with the enum index: optimal < nearOptimal < borderline < high.
  return statuses.reduce((a, b) => a.index >= b.index ? a : b);
}
