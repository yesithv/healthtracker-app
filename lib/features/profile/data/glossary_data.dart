import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

class GlossaryTerm {
  final String name;
  final String definition;
  final String? normalRange;

  const GlossaryTerm({
    required this.name,
    required this.definition,
    this.normalRange,
  });
}

class GlossaryGroup {
  final String titleKey; // resolved externally via l10n
  final IconData icon;
  final Color color;
  final List<GlossaryTerm> terms;

  const GlossaryGroup({
    required this.titleKey,
    required this.icon,
    required this.color,
    required this.terms,
  });
}

class GlossaryData {
  /// Builds the glossary groups for the active locale. All term text comes from
  /// the ARB files via [l10n], so there is a single locale-independent
  /// structure here instead of one hardcoded copy per language.
  static List<GlossaryGroup> getGroups(AppLocalizations l10n) {
    return [
      GlossaryGroup(
        titleKey: 'helpGlossaryGroupAnthropo',
        icon: Icons.straighten,
        color: const Color(0xFF0D48A0),
        terms: [
          GlossaryTerm(
            name: l10n.glossaryImcName,
            definition: l10n.glossaryImcDefinition,
            normalRange: l10n.glossaryImcRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryPesoName,
            definition: l10n.glossaryPesoDefinition,
            normalRange: l10n.glossaryPesoRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryTallaName,
            definition: l10n.glossaryTallaDefinition,
          ),
        ],
      ),
      GlossaryGroup(
        titleKey: 'helpGlossaryGroupVitals',
        icon: Icons.favorite_border,
        color: const Color(0xFFEF4444),
        terms: [
          GlossaryTerm(
            name: l10n.glossarySistolicaName,
            definition: l10n.glossarySistolicaDefinition,
            normalRange: l10n.glossarySistolicaRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryDiastolicaName,
            definition: l10n.glossaryDiastolicaDefinition,
            normalRange: l10n.glossaryDiastolicaRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryFcName,
            definition: l10n.glossaryFcDefinition,
            normalRange: l10n.glossaryFcRange,
          ),
        ],
      ),
      GlossaryGroup(
        titleKey: 'helpGlossaryGroupLipid',
        icon: Icons.bloodtype_outlined,
        color: const Color(0xFFF59E0B),
        terms: [
          GlossaryTerm(
            name: l10n.glossaryColesterolTotalName,
            definition: l10n.glossaryColesterolTotalDefinition,
            normalRange: l10n.glossaryColesterolTotalRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryLdlName,
            definition: l10n.glossaryLdlDefinition,
            normalRange: l10n.glossaryLdlRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryHdlName,
            definition: l10n.glossaryHdlDefinition,
            normalRange: l10n.glossaryHdlRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryVldlName,
            definition: l10n.glossaryVldlDefinition,
            normalRange: l10n.glossaryVldlRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryTrigliceridosName,
            definition: l10n.glossaryTrigliceridosDefinition,
            normalRange: l10n.glossaryTrigliceridosRange,
          ),
        ],
      ),
      GlossaryGroup(
        titleKey: 'helpGlossaryGroupBody',
        icon: Icons.accessibility_new,
        color: const Color(0xFF10B981),
        terms: [
          GlossaryTerm(
            name: l10n.glossaryGrasaName,
            definition: l10n.glossaryGrasaDefinition,
            normalRange: l10n.glossaryGrasaRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryMusculoName,
            definition: l10n.glossaryMusculoDefinition,
          ),
          GlossaryTerm(
            name: l10n.glossaryGrasaVisceralName,
            definition: l10n.glossaryGrasaVisceralDefinition,
            normalRange: l10n.glossaryGrasaVisceralRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryEdadMetabolicaName,
            definition: l10n.glossaryEdadMetabolicaDefinition,
          ),
          GlossaryTerm(
            name: l10n.glossaryBmrName,
            definition: l10n.glossaryBmrDefinition,
          ),
          GlossaryTerm(
            name: l10n.glossaryAguaName,
            definition: l10n.glossaryAguaDefinition,
            normalRange: l10n.glossaryAguaRange,
          ),
          GlossaryTerm(
            name: l10n.glossaryHuesoName,
            definition: l10n.glossaryHuesoDefinition,
            normalRange: l10n.glossaryHuesoRange,
          ),
        ],
      ),
    ];
  }
}
