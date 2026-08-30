import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myvitals_healthtracker_app/core/legal/legal_api_client.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../../../../core/widgets/secondary_app_bar.dart';

import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

/// El resumen legal de Ajustes.
///
/// <h3>Lo que decía antes</h3>
///
/// «Todos los datos se almacenan localmente en el dispositivo. My Vitals no
/// recopila, transmite ni comparte información personal con terceros. **No
/// existen cuentas de usuario ni servidores de datos**.» Era cierto cuando la
/// app era local; hoy hay cuenta, sesión, servidor, subida de todas las
/// mediciones y el staff de la clínica viendo la historia desde el panel. Cada
/// fase lo fue haciendo menos cierto y nadie tocó el texto.
///
/// <h3>Qué es esta pantalla ahora</h3>
///
/// Un **resumen** de lo que el sistema hace de verdad, con enlace a los
/// documentos completos —que sirve la API y son los que rigen—. El resumen vive
/// en la app porque tiene que poder leerse sin conexión; los documentos no,
/// porque cambiarlos no puede exigir publicar en las tiendas.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final content = Theme.of(context).content;
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _LegalSection(
        icon: Icons.apps_rounded,
        title: l10n.helpLegalPurposeTitle,
        body: l10n.helpLegalPurposeBody,
        color: surfaces.brand,
      ),
      _LegalSection(
        icon: Icons.medical_services_outlined,
        title: l10n.helpLegalNotMedicalTitle,
        body: l10n.helpLegalNotMedicalBody,
        color: clinical.alert.accent,
      ),
      _LegalSection(
        icon: Icons.person_outline,
        title: l10n.helpLegalResponsibilityTitle,
        body: l10n.helpLegalResponsibilityBody,
        color: clinical.caution.accent,
      ),
      _LegalSection(
        icon: Icons.lock_outline,
        title: l10n.helpLegalPrivacyTitle,
        body: l10n.helpLegalPrivacyBody,
        color: clinical.optimal.accent,
      ),
      _LegalSection(
        icon: Icons.groups_outlined,
        title: l10n.helpLegalWhoSeesTitle,
        body: l10n.helpLegalWhoSeesBody,
        color: surfaces.brand,
      ),
      _LegalSection(
        icon: Icons.mail_outline_rounded,
        title: l10n.helpLegalContactTitle,
        body: l10n.helpLegalContactBody,
        color: content.tone(ContentCategory.emotional).accent,
      ),
    ];

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                // Shield banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: content
                        .tone(ContentCategory.emotional)
                        .accent
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: content
                          .tone(ContentCategory.emotional)
                          .accent
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: content.tone(ContentCategory.emotional).accent,
                        size: 28,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.helpLegalDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: surfaces.inkSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Legal sections
                ...sections.map((s) => _buildLegalTile(context, s)),
                const SizedBox(height: 8),

                // Los documentos completos. El resumen de arriba no los
                // sustituye: lo que rige es lo que sirve el servidor, con su
                // número de versión.
                _documentLink(
                  context,
                  icon: Icons.description_outlined,
                  label: l10n.legalReadTerms,
                  document: LegalApiClient.terms,
                ),
                _documentLink(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: l10n.legalReadPrivacy,
                  document: LegalApiClient.privacy,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String document,
  }) {
    final surfaces = Theme.of(context).surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/legal/$document'),
        icon: Icon(icon, size: 18),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: surfaces.ink,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalTile(BuildContext context, _LegalSection s) {
    final surfaces = Theme.of(context).surfaces;
    final content = Theme.of(context).content;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: surfaces.cardShadow,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 18,
          ),
          leading: IconBadge(
            s.icon,
            color: s.color,
            background: s.color.withValues(alpha: 0.10),
            padding: 9,
            iconSize: 18,
          ),
          title: Text(
            s.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: surfaces.ink,
            ),
          ),
          iconColor: content.tone(ContentCategory.emotional).accent,
          collapsedIconColor: surfaces.inkMuted,
          children: [
            Text(
              s.body,
              style: TextStyle(
                fontSize: 13,
                color: surfaces.inkSecondary,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalSection {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _LegalSection({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });
}
