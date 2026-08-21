import 'dart:convert';
import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/user_profile_provider.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/settings_accent.dart';
import '../../../../core/theme/tokens/content_palette.dart';
import '../../../../core/theme/tokens/tone.dart';
import '../../../../core/widgets/main_app_bar.dart';
import '../../../../core/services/image_picker_service.dart';
import '../../../../core/auth/patient_session.dart';
import '../../../../core/auth/local_data_reset.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/demo/demo_actions.dart';
import '../../../../core/demo/demo_session.dart';
import '../../../../core/database/record_repositories.dart';
import '../../../../core/providers/health_goals_provider.dart';
import '../../data/profile_achievements.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

part 'profile_screen.parts.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// ACENTOS DE ORIENTACIÓN de las filas de ajustes.
  ///
  /// Son doce filas seguidas: el cuadradito de color es lo que permite volver a
  /// encontrar «Idioma» sin leer las doce. No es semántica —un ajuste no está
  /// «óptimo» ni pertenece a una familia de indicador— así que no puede salir de
  /// la paleta clínica ni de la de métricas.
  ///
  /// Salen de la paleta de CONTENIDO porque es el único juego de acentos que la
  /// app ya garantiza mutuamente distinguibles en matiz y legibles en cualquier
  /// tema (lo verifica el contrato semántico). Cada fila conserva exactamente la
  /// familia de matiz que tenía escrita a mano, así que la pantalla se reconoce
  /// igual; lo que gana es que en «Consulta Serena» ya no aparecen un violeta y
  /// un cian eléctricos sobre un lienzo cálido.
  static Tone _wayfinding(ThemeData theme, ContentCategory c) =>
      theme.content.tone(c);

  /// Reúne lo que los registros dicen sobre los logros del usuario. Observa los
  /// cuatro repositorios y las metas (todos provistos en `main.dart`), reduce
  /// todo a números y deja el cálculo a [ProfileAchievements], que es puro y
  /// testeable. Si algún repositorio aún no cargó, su conteo es 0: nunca se
  /// enseña más de lo que hay.
  static ProfileAchievements _readAchievements(BuildContext context) {
    final anthro = context.watch<AnthropometricRepository>();
    final vitals = context.watch<VitalSignsRepository>();
    final lipid = context.watch<LipidRepository>();
    final body = context.watch<BodyCompositionRepository>();
    final goals = context.watch<HealthGoalsProvider>();

    // Meta corporal cumplida: mismo criterio que las tarjetas del panel
    // (`AnthropometricHistoryCard` y `BodyCompositionCard`), para no tener dos
    // definiciones que puedan discrepar. Basta con que se cumpla una.
    var bodyGoalMet = false;
    if (goals.medicalGoalsEnabled) {
      final weight = anthro.items.isNotEmpty ? anthro.items.first.weight : null;
      if (goals.targetWeight != null && weight != null) {
        bodyGoalMet = (weight - goals.targetWeight!).abs() <= 0.5;
      }
      final fat = body.items.isNotEmpty
          ? body.items.first.bodyFatPercent
          : null;
      if (!bodyGoalMet && goals.targetBodyFat != null && fat != null) {
        bodyGoalMet = fat <= goals.targetBodyFat!;
      }
    }

    // Ventana de historia: del registro más antiguo al más nuevo, sea de la
    // familia que sea. Cada lista viene ordenada por fecha descendente, así que
    // basta mirar sus extremos (primero = más nuevo, último = más antiguo). Se
    // recogen sólo los extremos y no todas las fechas: esto corre en cada
    // reconstrucción del Perfil.
    final endpoints = <DateTime>[
      if (anthro.items.isNotEmpty) anthro.items.first.date,
      if (anthro.items.isNotEmpty) anthro.items.last.date,
      if (vitals.items.isNotEmpty) vitals.items.first.date,
      if (vitals.items.isNotEmpty) vitals.items.last.date,
      if (lipid.items.isNotEmpty) lipid.items.first.date,
      if (lipid.items.isNotEmpty) lipid.items.last.date,
      if (body.items.isNotEmpty) body.items.first.date,
      if (body.items.isNotEmpty) body.items.last.date,
    ];
    final spanDays = endpoints.isEmpty
        ? 0
        : endpoints
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .difference(endpoints.reduce((a, b) => a.isBefore(b) ? a : b))
              .inDays;

    return ProfileAchievements.from(
      AchievementInput(
        anthroCount: anthro.isLoaded ? anthro.items.length : 0,
        vitalsCount: vitals.isLoaded ? vitals.items.length : 0,
        lipidCount: lipid.isLoaded ? lipid.items.length : 0,
        bodyCount: body.isLoaded ? body.items.length : 0,
        longestVitalsDayStreak: longestConsecutiveDayStreak(
          vitals.items.map((r) => r.date),
        ),
        historySpanDays: spanDays,
        bodyGoalMet: bodyGoalMet,
      ),
    );
  }

  /// Nombre del rango para el tramo calculado. El tramo 1 reutiliza el rango que
  /// ya existía; los otros dos se añadieron con este cambio.
  static String _rankName(AppLocalizations l10n, int tier) => switch (tier) {
    3 => l10n.profileRankTier3,
    2 => l10n.profileRankTier2,
    _ => l10n.profileRankObserver,
  };

  void _showImageSourceSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    final pickerService = ImagePickerService();

    final theme = Theme.of(context);
    final surfaces = theme.surfaces;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: surfaces.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(surfaces.radiusCard + 8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.profileImageTitle,
                  style: theme.type.cardTitle.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 24),
                _buildSourceOption(
                  context,
                  icon: Icons.photo_library_outlined,
                  label: l10n.gallery,
                  color: surfaces.brand,
                  onTap: () async {
                    Navigator.pop(context);
                    final base64 = await pickerService.pickImageAsBase64(
                      ImageSource.gallery,
                    );
                    if (base64 != null) await prefs.setProfileImage(base64);
                  },
                ),
                _buildSourceOption(
                  context,
                  icon: Icons.camera_alt_outlined,
                  label: l10n.camera,
                  color: surfaces.brand,
                  onTap: () async {
                    Navigator.pop(context);
                    final base64 = await pickerService.pickImageAsBase64(
                      ImageSource.camera,
                    );
                    if (base64 != null) await prefs.setProfileImage(base64);
                  },
                ),
                if (prefs.profileImageBase64 != null)
                  _buildSourceOption(
                    context,
                    icon: Icons.delete_outline,
                    label: l10n.deletePhoto,
                    // Borrar la foto es la acción destructiva del diálogo.
                    color: theme.clinical.alert.accent,
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
                    style: theme.type.button.copyWith(
                      color: surfaces.inkSecondary,
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

  /// Cierra la sesión y devuelve al usuario a la portada.
  ///
  /// La cuenta es obligatoria para usar la app, así que cerrar sesión es salir
  /// del todo: por eso se confirma antes. NO borra los registros locales —siguen
  /// en la base del dispositivo y vuelven a subir al reentrar—, y el diálogo lo
  /// dice para que nadie crea que está perdiendo sus datos.
  Future<void> _confirmLogOut(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final router = GoRouter.of(context);
    final sync = context.read<SyncService>();

    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.surfaces.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.surfaces.radiusCard),
        ),
        title: Text(l10n.logOut, style: theme.type.cardTitle),
        content: Text(l10n.logOutConfirm, style: theme.type.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              l10n.cancel,
              style: theme.type.button.copyWith(
                color: theme.surfaces.inkSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.logOut,
              style: theme.type.button.copyWith(
                color: theme.clinical.alert.accent,
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
    } catch (e) {
      debugLogError('Profile.syncBeforeReset', e);
      // Sin red o timeout: se continúa; los no sincronizados se perderán.
    }

    // 2) Cerrar sesión ANTES de vaciar los repos: así el notify del vaciado no
    //    re-dispara el auto-sync (que corta cuando no hay sesión).
    await PatientSession.instance.clear();

    // 3) Borrar los datos locales del paciente para que el siguiente usuario del
    //    dispositivo no los vea.
    if (context.mounted) await wipeLocalUserData(context);

    router.go('/welcome');
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
      leading: IconBadge(
        icon,
        color: color,
        background: color.withValues(alpha: 0.1),
        iconSize: 22,
      ),
      title: Text(
        label,
        style: Theme.of(context).type.body.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).surfaces.ink,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final prefs = Provider.of<UserProfileProvider>(context);
    final theme = Theme.of(context);
    final surfaces = theme.surfaces;
    final achievements = _readAchievements(context);

    return Scaffold(
      backgroundColor: surfaces.canvas,
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
                                  color: surfaces.card,
                                  width: 2,
                                ),
                                boxShadow: surfaces.cardShadow,
                              ),
                              child: _buildAvatar(
                                context,
                                prefs.profileImageBase64,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: surfaces.brand,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: surfaces.card,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: surfaces.onBrand,
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
                        style: theme.type.screenTitle.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prefs.userEmail.isNotEmpty
                            ? prefs.userEmail
                            : 'email@ejemplo.com',
                        style: theme.type.body.copyWith(
                          fontSize: 14,
                          color: prefs.userEmail.isNotEmpty
                              ? surfaces.ink
                              : surfaces.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- ACHIEVEMENTS & XP CARD ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: surfaces.cardDecoration(
                    radius: surfaces.radiusCard + 4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.selfCareProgress,
                            style: theme.type.sectionLabel.copyWith(
                              fontSize: 11,
                              color: surfaces.brand,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: surfaces.brand.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.level(achievements.level),
                              style: theme.type.badge.copyWith(
                                fontSize: 10,
                                color: surfaces.brand,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _rankName(l10n, achievements.rankTier),
                        style: theme.type.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: achievements.progressToNext,
                          minHeight: 8,
                          backgroundColor: surfaces.track,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            surfaces.brand,
                          ),
                        ),
                      ),
                      // Registros como «XP» hacia el siguiente nivel. En el nivel
                      // máximo no hay «siguiente», así que se omite.
                      if (achievements.recordsForNextLevel > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.xpForNextLevel(
                            achievements.recordsIntoLevel,
                            achievements.recordsIntoLevel +
                                achievements.recordsForNextLevel,
                          ),
                          style: theme.type.meta.copyWith(fontSize: 11),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        l10n.myHealthAchievements,
                        style: theme.type.sectionLabel.copyWith(
                          fontSize: 11,
                          color: surfaces.inkMuted,
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
                            tone: Tone.from(
                              surfaces.brand,
                              canvas: surfaces.card,
                            ),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.firstStep,
                            ),
                          ),
                          _BadgeItem(
                            icon: Icons.favorite,
                            label: l10n.badgeStrongHeart,
                            description: l10n.badgeStrongHeartDesc,
                            tone: _wayfinding(theme, ContentCategory.heart),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.strongHeart,
                            ),
                          ),
                          _BadgeItem(
                            icon: Icons.calendar_month,
                            label: l10n.badgeVitalHabit,
                            description: l10n.badgeVitalHabitDesc,
                            tone: _wayfinding(theme, ContentCategory.sports),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.vitalHabit,
                            ),
                          ),
                          _BadgeItem(
                            icon: Icons.visibility,
                            label: l10n.badgeAwareness,
                            description: l10n.badgeAwarenessDesc,
                            tone: _wayfinding(theme, ContentCategory.emotional),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.awareness,
                            ),
                          ),
                          _BadgeItem(
                            icon: Icons.fitness_center,
                            label: l10n.badgeBalance,
                            description: l10n.badgeBalanceDesc,
                            tone: _wayfinding(theme, ContentCategory.nutrition),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.balance,
                            ),
                          ),
                          _BadgeItem(
                            icon: Icons.verified_user,
                            label: l10n.badgeGuardian,
                            description: l10n.badgeGuardianDesc,
                            tone: Tone.from(
                              surfaces.brand,
                              canvas: surfaces.card,
                            ),
                            isLocked: !achievements.isUnlocked(
                              ProfileBadge.guardian,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // --- MENU ITEMS ---
                // El acento DE ORIENTACIÓN de cada fila sale de [SettingsSection]
                // —la misma fuente que lee el encabezado de cada pantalla de
                // detalle—, así que abrir una fila lleva su color adentro.
                _MenuTile(
                  icon: Icons.sync,
                  title: l10n.accountSyncTitle,
                  tone: SettingsSection.accountSync.tone(theme),
                  onTap: () => context.push('/profile/account'),
                ),
                _MenuTile(
                  icon: Icons.badge_outlined,
                  title: l10n.personalInfo,
                  tone: SettingsSection.personalInfo.tone(theme),
                  onTap: () => context.push('/profile/info'),
                ),
                _MenuTile(
                  icon: Icons.monitor_heart_outlined,
                  title: l10n.deviceScreenTitle,
                  tone: SettingsSection.device.tone(theme),
                  onTap: () => context.push('/profile/device'),
                ),
                _MenuTile(
                  icon: Icons.flag_circle_outlined,
                  title: l10n.healthGoalsTitle,
                  tone: SettingsSection.healthGoals.tone(theme),
                  onTap: () => context.push('/profile/goals'),
                ),
                _MenuTile(
                  icon: Icons.medication_outlined,
                  title: l10n.medicationsTitle,
                  tone: SettingsSection.medications.tone(theme),
                  onTap: () => context.push('/profile/medications'),
                ),
                _MenuTile(
                  icon: Icons.event_available_outlined,
                  title: l10n.appointmentsTitle,
                  tone: SettingsSection.appointments.tone(theme),
                  onTap: () => context.push('/profile/appointments'),
                ),
                // Selector de tema. Reutiliza la pantalla 0 en modo ajuste.
                _MenuTile(
                  icon: Icons.palette_outlined,
                  title: l10n.profileAppTheme,
                  tone: SettingsSection.appTheme.tone(theme),
                  onTap: () => context.push('/profile/theme'),
                ),
                _MenuTile(
                  icon: Icons.language,
                  title: l10n.language,
                  tone: SettingsSection.language.tone(theme),
                  onTap: () => context.push('/profile/language'),
                ),
                _MenuTile(
                  icon: Icons.straighten,
                  title: l10n.measurementUnits,
                  tone: SettingsSection.measurementUnits.tone(theme),
                  onTap: () => context.push('/profile/units'),
                ),
                _MenuTile(
                  icon: Icons.notifications_active_outlined,
                  title: l10n.remindersTitle,
                  tone: SettingsSection.reminders.tone(theme),
                  onTap: () => context.push('/profile/reminders'),
                ),
                _MenuTile(
                  icon: Icons.security_outlined,
                  title: l10n.privacySecurity,
                  tone: SettingsSection.privacy.tone(theme),
                  onTap: () => context.push('/profile/privacy'),
                ),
                _MenuTile(
                  icon: Icons.cloud_sync,
                  title: l10n.myDataBackup,
                  tone: SettingsSection.backup.tone(theme),
                  onTap: () => context.push('/profile/backup'),
                ),
                _MenuTile(
                  icon: Icons.help_outline,
                  title: l10n.helpSupport,
                  tone: SettingsSection.help.tone(theme),
                  onTap: () => context.push('/profile/help'),
                ),
                const SizedBox(height: 24),

                // --- SALIR ---
                // En la demostración, cerrar sesión no significa nada: no hay
                // cuenta que cerrar. La acción de salida de la pantalla pasa a
                // ser abandonar la demo, que es lo único que el visitante puede
                // querer hacer aquí, y así no quedan dos salidas compitiendo.
                if (context.watch<DemoSession>().isActive)
                  const _ExitDemoButton()
                else
                  GestureDetector(
                    onTap: () => _confirmLogOut(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: surfaces.card,
                        borderRadius: BorderRadius.circular(
                          surfaces.radiusCard,
                        ),
                        // Salir es la acción destructiva de la pantalla: va en el
                        // rojo de ALERTA, igual que borrar un registro.
                        border: Border.all(
                          color: theme.clinical.alert.accent.withValues(
                            alpha: 0.35,
                          ),
                          width: 1.5,
                        ),
                        boxShadow: surfaces.glow(
                          theme.clinical.alert.accent,
                          alpha: 0.05,
                          blur: 10,
                          offset: const Offset(0, 4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: theme.clinical.alert.accent,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.logOut,
                            style: theme.type.button.copyWith(
                              color: theme.clinical.alert.accent,
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
                  style: theme.type.sectionLabel.copyWith(
                    fontSize: 10,
                    color: surfaces.inkMuted,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.medicalDisclaimerText,
                  textAlign: TextAlign.center,
                  style: theme.type.meta.copyWith(fontSize: 10, height: 1.6),
                ),
                const SizedBox(height: 24),
                Text(
                  '© 2026 My Vitals Health Inc. v1.1.0',
                  textAlign: TextAlign.center,
                  style: theme.type.meta.copyWith(
                    fontSize: 10,
                    color: surfaces.inkMuted,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? base64String) {
    final surfaces = Theme.of(context).surfaces;
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
    return CircleAvatar(
      radius: 50,
      backgroundColor: surfaces.track,
      child: Icon(Icons.person, size: 60, color: surfaces.inkSecondary),
    );
  }
}
