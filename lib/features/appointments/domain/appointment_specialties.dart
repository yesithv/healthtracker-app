import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

/// Catálogo curado de especialidades médicas para el desplegable de citas.
///
/// La especialidad se guarda como texto (`Appointment.specialty`), pero el
/// usuario NO la escribe: elige de esta lista cerrada para reducir tecleo y
/// evitar variantes sueltas. Las etiquetas se localizan con las claves
/// `specialty*` de los `.arb`; el orden es el de esta función.
List<String> appointmentSpecialties(AppLocalizations l10n) => [
  l10n.specialtyGeneralMedicine,
  l10n.specialtyCardiology,
  l10n.specialtyEndocrinology,
  l10n.specialtyDermatology,
  l10n.specialtyGynecology,
  l10n.specialtyDentistry,
  l10n.specialtyOphthalmology,
  l10n.specialtyOtolaryngology,
  l10n.specialtyNeurology,
  l10n.specialtyNeuropsychology,
  l10n.specialtyPsychiatry,
  l10n.specialtyOrthopedics,
  l10n.specialtyUrology,
  l10n.specialtyGastroenterology,
  l10n.specialtyNutrition,
  l10n.specialtyPediatrics,
  l10n.specialtyPhysiotherapy,
  l10n.specialtyClinicalLaboratory,
];
