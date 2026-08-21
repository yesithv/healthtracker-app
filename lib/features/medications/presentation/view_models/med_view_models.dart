import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens/clinical_palette.dart';
import '../../../../core/theme/tokens/metric_palette.dart';
import '../../../../core/theme/tokens/tone.dart';

/// VIEW-MODELS DE PRESENTACIÓN del módulo de Medicamentos.
///
/// Los widgets del módulo son presentacionales: reciben estos VM con las cadenas
/// ya formateadas y localizadas (las produce `med_view_mapper.dart` a partir del
/// dominio). Así los widgets no conocen `Medication` ni `AppLocalizations` y se
/// pueden probar y reutilizar sin la capa de datos.
///
/// El color de cada medicamento NO es un literal: se elige un rol de [MedColor]
/// y el tema lo resuelve con [resolveMedTone], para verse coherente en «Pulso
/// Clínico» y «Consulta Serena» sin código condicional.

/// Rol de color decorativo del medicamento. Lo resuelve el tema.
enum MedColor { brand, teal, violet, green, amber }

/// Estado de una toma o de un día de adherencia, tal como lo pintan los widgets.
enum DoseState { pending, taken, skipped }

/// Resuelve el color decorativo de un medicamento contra el tema activo, para
/// no escribir un solo literal de color en las pantallas.
Tone resolveMedTone(BuildContext context, MedColor color) {
  final theme = Theme.of(context);
  return switch (color) {
    MedColor.brand => Tone(
      accent: theme.surfaces.brand,
      surface: Color.lerp(theme.surfaces.card, theme.surfaces.brand, 0.14)!,
      onAccent: theme.surfaces.onBrand,
    ),
    MedColor.teal => theme.metrics.tone(MetricFamily.lipids),
    MedColor.violet => theme.metrics.tone(MetricFamily.bodyComposition),
    MedColor.green => theme.clinical.tone(ClinicalStatus.optimal),
    MedColor.amber => theme.clinical.tone(ClinicalStatus.caution),
  };
}

/// Icono de píldora estable a partir de un identificador guardado (`shape`) o del
/// nombre. Decorativo: si no se reconoce, cae en la píldora genérica.
IconData medIconFor(String? shapeKey) {
  switch (shapeKey) {
    case 'round':
      return Icons.blur_circular;
    case 'capsule':
      return Icons.medication;
    case 'liquid':
      return Icons.medication_liquid;
    case 'drops':
      return Icons.water_drop;
    default:
      return Icons.medication;
  }
}

/// Una toma del día con su estado: lo que pinta [MedicationDoseTile]. Lleva los
/// identificadores para que la pantalla que la creó pueda registrar la toma.
class DoseVm {
  const DoseVm({
    required this.medId,
    required this.doseId,
    required this.scheduledAt,
    required this.medName,
    required this.amount,
    required this.time,
    required this.color,
    required this.icon,
    this.state = DoseState.pending,
  });

  final String medId;
  final String? doseId;
  final DateTime scheduledAt;
  final String medName;
  final String amount; // "2 cápsulas"
  final String time; // "20:30"
  final MedColor color;
  final IconData icon;
  final DoseState state;
}

/// Ficha de un medicamento para la lista y el detalle. Todos los textos vienen
/// ya formateados y localizados.
class MedVm {
  const MedVm({
    required this.id,
    required this.name,
    required this.form,
    required this.strength,
    required this.reason,
    required this.color,
    required this.icon,
    required this.schedule,
    required this.doseSummary,
    required this.trackInventory,
    required this.stock,
    required this.packSize,
    required this.refillThreshold,
    required this.daysLeft,
    required this.runOut,
    required this.adherencePct,
    required this.streak,
    required this.lowStock,
  });

  final String id;
  final String name;
  final String form; // "Cápsula"
  final String strength; // "10 mg"
  final String reason; // notas / motivo (puede ir vacío)
  final MedColor color;
  final IconData icon;
  final String schedule; // "Todos los días"
  final String doseSummary; // "2 cápsulas · 08:00, 20:30"

  final bool trackInventory;
  final int stock;
  final int packSize;
  final int refillThreshold;
  final int? daysLeft;
  final String runOut; // "~13 ago" (vacío si no proyectable)

  final int adherencePct;
  final int streak;
  final bool lowStock;
}

/// Un día de la tira semanal.
class WeekDayVm {
  const WeekDayVm({
    required this.weekday,
    required this.number,
    required this.state,
    this.isToday = false,
  });

  final String weekday; // "MIÉ"
  final int number;
  final DoseState state;
  final bool isToday;
}

/// Un día del calendario de adherencia (estado o vacío).
class AdherenceDayVm {
  const AdherenceDayVm({
    required this.number,
    required this.state,
    this.isToday = false,
    this.outOfMonth = false,
  });

  final int number;
  final DoseState? state; // null = sin dato
  final bool isToday;
  final bool outOfMonth;
}
