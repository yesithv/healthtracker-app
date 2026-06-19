import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import '../../../../core/providers/user_profile_provider.dart';

/// Dashboard header card: avatar, name and email from [UserProfileProvider].
class UserProfileCard extends StatelessWidget {
  const UserProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(prefs.profileImageBase64),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefs.userName.isNotEmpty
                      ? prefs.userName
                      : l10n.newUserInfo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (prefs.userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    prefs.userEmail,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? base64String) {
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
    return const CircleAvatar(
      radius: 36,
      backgroundColor: Color(0xFFE3F2FD),
      child: Icon(Icons.person, size: 40, color: Color(0xFF0D48A0)),
    );
  }
}
