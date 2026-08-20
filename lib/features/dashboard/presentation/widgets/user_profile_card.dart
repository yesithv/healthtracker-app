import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/theme/theme_context.dart';

/// Dashboard header card: avatar, name and email from [UserProfileProvider].
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      // Filete sólido y visible, igual que el resto de tarjetas del inicio.
      decoration: theme.surfaces.cardDecoration(
        borderColor: theme.surfaces.divider,
        borderWidth: 1.5,
      ),
      child: Row(
        children: [
          _buildAvatar(context, prefs.profileImageBase64),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefs.userName.isNotEmpty ? prefs.userName : l10n.newUserInfo,
                  style: theme.type.numeralSmall.copyWith(fontSize: 18),
                ),
                if (prefs.userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(prefs.userEmail, style: theme.type.meta),
                ],
              ],
            ),
          ),
        ],
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
