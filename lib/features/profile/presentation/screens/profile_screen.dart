import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/auth/patient_session.dart';
import '../../../../core/auth/local_data_reset.dart';
import '../../../../core/sync/sync_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Pide confirmación, sube lo pendiente (best-effort), CIERRA la sesión y BORRA
  /// los datos locales del paciente para que el siguiente usuario del dispositivo no
  /// los vea, y devuelve a la portada de bienvenida.
  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final sync = context.read<SyncService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.logOut,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 1) Best-effort: subir lo pendiente antes de borrar (si hay red).
    try {
      await sync.syncNow().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Sin red o timeout: se continúa; los no sincronizados se perderán.
    }

    // 2) Cerrar sesión ANTES de vaciar los repos: así el notify del vaciado no
    //    re-dispara el auto-sync (que corta cuando no hay sesión).
    await PatientSession.instance.clear();

    // 3) Borrar los datos locales del paciente.
    if (context.mounted) await wipeLocalUserData(context);

    router.go('/welcome');
  }

  void _showImageSourceSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    final pickerService = ImagePickerService();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.profileImageTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSourceOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: l10n.gallery,
                  color: const Color(0xFF0D48A0),
                  onTap: () async {
                    Navigator.pop(context);
                    final base64 = await pickerService.pickImageAsBase64(
                      ImageSource.gallery,
                    );
                    if (base64 != null) prefs.setProfileImage(base64);
                  },
                ),
                _buildSourceOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: l10n.camera,
                  color: const Color(0xFF0D48A0),
                  onTap: () async {
                    Navigator.pop(context);
                    final base64 = await pickerService.pickImageAsBase64(
                      ImageSource.camera,
                    );
                    if (base64 != null) prefs.setProfileImage(base64);
                  },
                ),
                if (prefs.profileImageBase64 != null)
                  _buildSourceOption(
                    context,
                    icon: Icons.delete_outline,
                    label: l10n.deletePhoto,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.pop(context);
                      prefs.setProfileImage(null);
                    },
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF334155),
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          MainAppBar(title: l10n.profile.toUpperCase()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              children: [
                // --- AVATAR SECTION ---
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showImageSourceSheet(context),
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: _buildAvatar(prefs.profileImageBase64),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D48A0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        prefs.userName.isNotEmpty
                            ? prefs.userName
                            : l10n.newUserInfo,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prefs.userEmail.isNotEmpty
                            ? prefs.userEmail
                            : 'email@ejemplo.com',
                        style: TextStyle(
                          fontSize: 14,
                          color: prefs.userEmail.isNotEmpty
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- ACHIEVEMENTS & XP CARD ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.selfCareProgress,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D48A0),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.level(1),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D48A0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Observador Vital',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: 0.15,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0D48A0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.myHealthAchievements,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // BADGES GRID
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                        children: [
                          _BadgeItem(
                            icon: Icons.start,
                            label: l10n.badgeFirstStep,
                            description: l10n.badgeFirstStepDesc,
                            color: const Color(0xFF0D48A0),
                            isLocked: false,
                          ),
                          _BadgeItem(
                            icon: Icons.favorite,
                            label: l10n.badgeStrongHeart,
                            description: l10n.badgeStrongHeartDesc,
                            color: const Color(0xFFEF4444),
                            isLocked: false,
                          ),
                          _BadgeItem(
                            icon: Icons.calendar_month,
                            label: l10n.badgeVitalHabit,
                            description: l10n.badgeVitalHabitDesc,
                            color: const Color(0xFFF59E0B),
                            isLocked: true,
                          ),
                          _BadgeItem(
                            icon: Icons.visibility,
                            label: l10n.badgeAwareness,
                            description: l10n.badgeAwarenessDesc,
                            color: const Color(0xFF8B5CF6),
                            isLocked: false,
                          ),
                          _BadgeItem(
                            icon: Icons.fitness_center,
                            label: l10n.badgeBalance,
                            description: l10n.badgeBalanceDesc,
                            color: const Color(0xFF10B981),
                            isLocked: true,
                          ),
                          _BadgeItem(
                            icon: Icons.verified_user,
                            label: l10n.badgeGuardian,
                            description: l10n.badgeGuardianDesc,
                            color: const Color(0xFF0D48A0),
                            isLocked: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- MENU ITEMS ---
                _MenuTile(
                  icon: Icons.sync,
                  title: 'Cuenta y sincronización',
                  iconColor: const Color(0xFF0D48A0),
                  onTap: () => context.push('/profile/account'),
                ),
                _MenuTile(
                  icon: Icons.badge_outlined,
                  title: l10n.personalInfo,
                  iconColor: const Color(0xFF0D48A0),
                  onTap: () => context.push('/profile/info'),
                ),
                _MenuTile(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Mi dispositivo de medición',
                  iconColor: const Color(0xFF0D48A0),
                  onTap: () => context.push('/profile/device'),
                ),
                _MenuTile(
                  icon: Icons.flag_circle_outlined,
                  title: l10n.healthGoalsTitle,
                  iconColor: const Color(0xFFEF4444),
                  onTap: () => context.push('/profile/goals'),
                ),
                _MenuTile(
                  icon: Icons.language,
                  title: l10n.language,
                  iconColor: const Color(0xFF10B981),
                  onTap: () => context.push('/profile/language'),
                ),
                _MenuTile(
                  icon: Icons.straighten,
                  title: l10n.measurementUnits,
                  iconColor: const Color(0xFFF59E0B),
                  onTap: () => context.push('/profile/units'),
                ),
                _MenuTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.remindersTitle,
                  iconColor: const Color(0xFF14B8A6), // Teal
                  onTap: () => context.push('/profile/reminders'),
                ),
                _MenuTile(
                  icon: Icons.security_outlined,
                  title: l10n.privacySecurity,
                  iconColor: const Color(0xFF8B5CF6),
                  onTap: () => context.push('/profile/privacy'),
                ),
                _MenuTile(
                  icon: Icons.cloud_sync,
                  title: l10n.myDataBackup,
                  iconColor: const Color(0xFF0891B2), // Cyan
                  onTap: () => context.push('/profile/backup'),
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  iconColor: const Color(0xFF64748B),
                  onTap: () => context.push('/profile/help'),
                ),
                const SizedBox(height: 24),

                // --- LOG OUT BUTTON ---
                GestureDetector(
                  onTap: () => _confirmLogout(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFFFB2B2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFEF4444,
                          ).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.logOut,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // --- MEDICAL DISCLAIMER ---
                Text(
                  l10n.medicalDisclaimerTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.medicalDisclaimerText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '© 2026 My Vitals Health Inc. v1.1.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 40),
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
          radius: 50,
          backgroundImage: MemoryImage(base64Decode(base64String)),
        );
      } catch (e) {
        // Fallback
      }
    }
    return const CircleAvatar(
      radius: 50,
      backgroundColor: Color(0xFFE2E8F0),
      child: Icon(Icons.person, size: 60, color: Color(0xFF64748B)),
    );
  }

}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final bool isLocked;

  const _BadgeItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLocked
                    ? const Color(0xFFF1F5F9)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isLocked
                      ? const Color(0xFFE2E8F0)
                      : color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: isLocked
                  ? const ColorFiltered(
                      colorFilter: ColorFilter.matrix([
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: Icon(
                        Icons.lock_outline,
                        color: Color(0xFF94A3B8),
                        size: 24,
                      ),
                    )
                  : Icon(icon, color: color, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: const Color(0xFF94A3B8),
            fontWeight: isLocked ? FontWeight.normal : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D48A0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D48A0),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF0D48A0),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
