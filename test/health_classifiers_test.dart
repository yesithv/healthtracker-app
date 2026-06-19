import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:myvitals_healthtracker_app/core/utils/health_classifiers.dart';
import 'package:myvitals_healthtracker_app/features/history/data/models/lipid_record.dart';

/// Semantic colors the classifiers map to (must match health_classifiers.dart).
const _blue = Color(0xFF3B82F6);
const _green = Color(0xFF10B981);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);

void main() {
  group('BpCategory.of', () {
    test('low when systolic < 90 or diastolic < 60', () {
      expect(BpCategory.of(85, 70), BpCategory.low);
      expect(BpCategory.of(110, 55), BpCategory.low);
      expect(BpCategory.of(85, 55), BpCategory.low);
    });

    test('normal at and below 120/80 (and not low)', () {
      expect(BpCategory.of(120, 80), BpCategory.normal);
      expect(BpCategory.of(90, 60), BpCategory.normal); // just above the low cutoff
      expect(BpCategory.of(100, 70), BpCategory.normal);
    });

    test('elevated up to 139/89', () {
      expect(BpCategory.of(130, 85), BpCategory.elevated);
      expect(BpCategory.of(139, 89), BpCategory.elevated);
      expect(BpCategory.of(121, 80), BpCategory.elevated); // systolic over normal
      expect(BpCategory.of(120, 81), BpCategory.elevated); // diastolic over normal
    });

    test('high above 139/89', () {
      expect(BpCategory.of(140, 90), BpCategory.high);
      expect(BpCategory.of(160, 100), BpCategory.high);
    });

    test('color mapping', () {
      expect(BpCategory.low.color, _blue);
      expect(BpCategory.normal.color, _green);
      expect(BpCategory.elevated.color, _amber);
      expect(BpCategory.high.color, _red);
    });
  });

  group('HrCategory.of', () {
    test('boundaries', () {
      expect(HrCategory.of(59), HrCategory.low);
      expect(HrCategory.of(60), HrCategory.normal);
      expect(HrCategory.of(100), HrCategory.normal);
      expect(HrCategory.of(101), HrCategory.high);
    });

    test('color mapping', () {
      expect(HrCategory.low.color, _blue);
      expect(HrCategory.normal.color, _green);
      expect(HrCategory.high.color, _red);
    });
  });

  group('BmiCategory.of', () {
    test('boundaries', () {
      expect(BmiCategory.of(18.4), BmiCategory.low);
      expect(BmiCategory.of(18.5), BmiCategory.normal);
      expect(BmiCategory.of(24.9), BmiCategory.normal);
      expect(BmiCategory.of(25), BmiCategory.overweight);
      expect(BmiCategory.of(29.9), BmiCategory.overweight);
      expect(BmiCategory.of(30), BmiCategory.obesity);
    });

    test('color mapping', () {
      expect(BmiCategory.low.color, _blue);
      expect(BmiCategory.normal.color, _green);
      expect(BmiCategory.overweight.color, _amber);
      expect(BmiCategory.obesity.color, _red);
    });
  });

  group('FatCategory.of', () {
    test('boundaries', () {
      expect(FatCategory.of(4.9), FatCategory.veryLow);
      expect(FatCategory.of(5), FatCategory.low);
      expect(FatCategory.of(9.9), FatCategory.low);
      expect(FatCategory.of(10), FatCategory.normal);
      expect(FatCategory.of(24.9), FatCategory.normal);
      expect(FatCategory.of(25), FatCategory.elevated);
      expect(FatCategory.of(29.9), FatCategory.elevated);
      expect(FatCategory.of(30), FatCategory.high);
    });

    test('veryLow and low share the blue color', () {
      expect(FatCategory.veryLow.color, _blue);
      expect(FatCategory.low.color, _blue);
      expect(FatCategory.normal.color, _green);
      expect(FatCategory.elevated.color, _amber);
      expect(FatCategory.high.color, _red);
    });
  });

  group('VisceralCategory.of', () {
    test('boundaries', () {
      expect(VisceralCategory.of(9), VisceralCategory.normal);
      expect(VisceralCategory.of(10), VisceralCategory.elevated);
      expect(VisceralCategory.of(14), VisceralCategory.elevated);
      expect(VisceralCategory.of(15), VisceralCategory.high);
    });

    test('color mapping', () {
      expect(VisceralCategory.normal.color, _green);
      expect(VisceralCategory.elevated.color, _amber);
      expect(VisceralCategory.high.color, _red);
    });
  });

  group('LipidStatus per-field classifiers', () {
    test('totalCholesterol boundaries', () {
      expect(LipidStatus.totalCholesterol(199), LipidStatus.optimal);
      expect(LipidStatus.totalCholesterol(200), LipidStatus.borderline);
      expect(LipidStatus.totalCholesterol(239), LipidStatus.borderline);
      expect(LipidStatus.totalCholesterol(240), LipidStatus.high);
    });

    test('ldl boundaries (ATP III, four tiers)', () {
      expect(LipidStatus.ldl(99), LipidStatus.optimal);
      expect(LipidStatus.ldl(100), LipidStatus.nearOptimal);
      expect(LipidStatus.ldl(129), LipidStatus.nearOptimal);
      expect(LipidStatus.ldl(130), LipidStatus.borderline);
      expect(LipidStatus.ldl(159), LipidStatus.borderline);
      expect(LipidStatus.ldl(160), LipidStatus.high);
    });

    test('hdl boundaries (low value is the risky end)', () {
      expect(LipidStatus.hdl(60), LipidStatus.optimal);
      expect(LipidStatus.hdl(59), LipidStatus.nearOptimal);
      expect(LipidStatus.hdl(40), LipidStatus.nearOptimal);
      expect(LipidStatus.hdl(39), LipidStatus.high);
    });

    test('vldl is optimal only within 2–30', () {
      expect(LipidStatus.vldl(2), LipidStatus.optimal);
      expect(LipidStatus.vldl(30), LipidStatus.optimal);
      expect(LipidStatus.vldl(1), LipidStatus.high);
      expect(LipidStatus.vldl(31), LipidStatus.high);
    });

    test('triglycerides boundaries', () {
      expect(LipidStatus.triglycerides(149), LipidStatus.optimal);
      expect(LipidStatus.triglycerides(150), LipidStatus.borderline);
      expect(LipidStatus.triglycerides(199), LipidStatus.borderline);
      expect(LipidStatus.triglycerides(200), LipidStatus.high);
    });

    test('color mapping', () {
      expect(LipidStatus.optimal.color, _green);
      expect(LipidStatus.nearOptimal.color, _blue);
      expect(LipidStatus.borderline.color, _amber);
      expect(LipidStatus.high.color, _red);
    });
  });

  group('overallLipidStatus', () {
    LipidRecord rec({
      double? tc,
      double? ldl,
      double? hdl,
      double? vldl,
      double? trigs,
    }) => LipidRecord(
      date: DateTime(2024, 1, 1),
      totalCholesterol: tc,
      ldl: ldl,
      hdl: hdl,
      vldl: vldl,
      triglycerides: trigs,
    );

    test('empty record falls back to optimal', () {
      expect(overallLipidStatus(rec()), LipidStatus.optimal);
    });

    test('returns the worst status across fields', () {
      // tc optimal + ldl borderline -> borderline (worst).
      expect(
        overallLipidStatus(rec(tc: 180, ldl: 140)),
        LipidStatus.borderline,
      );
      // low hdl is high severity.
      expect(overallLipidStatus(rec(hdl: 35)), LipidStatus.high);
      // worst wins even with several fields.
      expect(
        overallLipidStatus(rec(tc: 180, ldl: 110, trigs: 250)),
        LipidStatus.high,
      );
    });

    test('a lone near-optimal field surfaces as nearOptimal', () {
      expect(overallLipidStatus(rec(ldl: 110)), LipidStatus.nearOptimal);
    });

    test('ignores vldl (not part of the overall panel)', () {
      // vldl 100 would be "high" as a field, but overall ignores it.
      expect(overallLipidStatus(rec(vldl: 100)), LipidStatus.optimal);
    });
  });
}
