import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';

import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../profile/data/achievements_reader.dart';

/// Cabecera del inicio: avatar, nombre y —en vez del correo, que no aportaba
/// nada al día a día— el PROGRESO DE AUTOCUIDADO en versión compacta y lúdica:
/// rango, nivel y una barra hacia el siguiente nivel. Bebe del mismo cálculo
/// ([readAchievements] → [ProfileAchievements]) que la tarjeta de logros del
/// Perfil, así que ambos coinciden siempre. Toda la tarjeta abre el Perfil, que
/// es el detalle completo (medallas incluidas).
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final achievements = readAchievements(context);

    return Container(
      // Filete sólido y visible, igual que el resto de tarjetas del inicio.
      decoration: theme.surfaces.cardDecoration(
        borderColor: theme.surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(surfaces.radiusCard),
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                _buildAvatar(context, prefs.profileImageBase64),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              prefs.userName.isNotEmpty
                                  ? prefs.userName
                                  : l10n.newUserInfo,
                              style: theme.type.numeralSmall.copyWith(
                                fontSize: 18,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelChip(level: achievements.level),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rankName(l10n, achievements.rankTier),
                        style: theme.type.meta.copyWith(color: surfaces.brand),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: achievements.progressToNext,
                          minHeight: 7,
                          backgroundColor: surfaces.track,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            surfaces.brand,
                          ),
                        ),
                      ),
                      // Registros como «XP» hacia el siguiente nivel. En el nivel
                      // máximo no hay «siguiente», así que se omite.
                      if (achievements.recordsForNextLevel > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          l10n.xpForNextLevel(
                            achievements.recordsIntoLevel,
                            achievements.recordsIntoLevel +
                                achievements.recordsForNextLevel,
                          ),
                          style: theme.type.meta.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? base64String) {
    if (base64String != null && base64String.isNotEmpty) {
      try {
        return CircleAvatar(
          radius: 36,
          backgroundImage: MemoryImage(base64Decode(base64String)),
        );
      } catch (e) {
        // Fallback
      }
    }
    final surfaces = Theme.of(context).surfaces;
    return CircleAvatar(
      radius: 36,
      backgroundColor: surfaces.selection,
      // Mismo icono en todos los temas; sólo cambia cómo se viste.
      child: Icon(Icons.person, size: 40, color: surfaces.brand),
    );
  }
}

/// Pastilla «Nivel N» a la derecha del nombre, con el acento de marca. Réplica
/// compacta de la que muestra la tarjeta de logros del Perfil.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final surfaces = theme.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: surfaces.brand.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        l10n.level(level),
        style: theme.type.badge.copyWith(fontSize: 10, color: surfaces.brand),
      ),
    );
  }
}
