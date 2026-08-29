import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/core/widgets/settings_page_header.dart';
import 'package:myvitals_healthtracker_app/core/theme/settings_accent.dart';
import 'package:myvitals_healthtracker_app/core/auth/patient_session.dart';
import 'package:myvitals_healthtracker_app/core/export/data_export_service.dart';
import 'package:myvitals_healthtracker_app/core/services/backup_service.dart';
import 'package:myvitals_healthtracker_app/core/services/share_feedback.dart';
import 'package:myvitals_healthtracker_app/core/providers/user_profile_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/health_goals_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/locale_units_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/theme_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/measuring_device_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

class DataBackupScreen extends StatefulWidget {
  const DataBackupScreen({super.key});

  @override
  State<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends State<DataBackupScreen> {
  bool _isLoading = false;

  Future<void> _exportBackup() async {
    setState(() => _isLoading = true);

    final prefs = Provider.of<UserProfileProvider>(context, listen: false);
    final backupService = BackupService();

    final outcome = await backupService.exportBackup(prefs.userName);

    if (mounted) {
      setState(() => _isLoading = false);
      // El helper distingue éxito (verde), cancelar (silencio) y fallo (rojo), así
      // cancelar el diálogo ya no cuenta como «backup creado».
      showShareFeedback(
        ScaffoldMessenger.of(context),
        Theme.of(context),
        AppLocalizations.of(context)!,
        outcome,
        successMessage: AppLocalizations.of(context)!.backupSuccess,
      );
    }
  }

  /// Descarga del servidor todo lo que guarda sobre el paciente.
  ///
  /// No es la copia de seguridad de al lado: aquella es local y se puede reimportar;
  /// esta trae lo que hay en la base de la clínica —**incluida la historia anterior, que
  /// nunca estuvo en este teléfono**— y es la que responde al derecho de acceso.
  Future<void> _downloadServerData() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    if (!PatientSession.instance.isAuthenticated) {
      // Sin sesión el servidor respondería 401; se dice antes y en su idioma.
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.serverExportNeedsSession)),
      );
      return;
    }

    setState(() => _isLoading = true);
    final userName = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    ).userName;
    final outcome = await DataExportService().downloadAndShare(userName);

    if (!mounted) return;
    setState(() => _isLoading = false);
    showShareFeedback(
      messenger,
      theme,
      l10n,
      outcome,
      successMessage: l10n.serverExportSuccess,
    );
  }

  Future<void> _importBackup() async {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final l10n = AppLocalizations.of(context)!;
    final prefsProvider = Provider.of<UserProfileProvider>(
      context,
      listen: false,
    );
    final goalsProvider = Provider.of<HealthGoalsProvider>(
      context,
      listen: false,
    );
    final localeUnitsProvider = Provider.of<LocaleUnitsProvider>(
      context,
      listen: false,
    );
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final remindersProvider = Provider.of<RemindersProvider>(
      context,
      listen: false,
    );
    final deviceProvider = Provider.of<MeasuringDeviceProvider>(
      context,
      listen: false,
    );

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupImportConfirmTitle),
        content: Text(l10n.backupImportConfirmBody),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              l10n.cancel,
              style: TextStyle(color: surfaces.inkSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: surfaces.brand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.backupImportButton,
              style: TextStyle(color: surfaces.onBrand),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    final backupService = BackupService();
    final success = await backupService.importBackup();

    if (success) {
      // Refresh in-memory state from the restored data so the UI updates
      // without an app restart.
      await prefsProvider.reload();
      await goalsProvider.reload();
      await localeUnitsProvider.reload();
      await themeProvider.reload();
      await remindersProvider.reload();
      await deviceProvider.load();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.backupImportSuccess : l10n.backupImportError,
          ),
          backgroundColor: success
              ? clinical.optimal.accent
              : clinical.alert.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final clinical = Theme.of(context).clinical;
    final content = Theme.of(context).content;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      appBar: const SecondaryAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  children: [
                    // Encabezado común: ícono + título + descripción centrados.
                    SettingsPageHeader(
                      icon: Icons.cloud_sync,
                      title: l10n.myDataBackup,
                      description: l10n.backupDescription,
                      accent: SettingsSection.backup.tone(Theme.of(context)),
                    ),
                    const SizedBox(height: 32),
                    // PRIVACY INFO BOX
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: clinical.optimal.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: clinical.optimal.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconBadge(
                                Icons.shield_outlined,
                                color: clinical.optimal.accent,
                                background: clinical.optimal.accent.withValues(
                                  alpha: 0.15,
                                ),
                                padding: 10,
                                iconSize: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.backupPrivacyTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: clinical.optimal.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.backupPrivacyBody,
                            style: TextStyle(
                              fontSize: 13,
                              color: surfaces.ink,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: surfaces.onBrand.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: clinical.optimal.surface,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.fingerprint,
                                  color: clinical.optimal.accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.backupPrivacyHighlight,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: clinical.optimal.accent,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // EXPORT CARD
                    _buildActionCard(
                      icon: Icons.cloud_download_outlined,
                      iconColor: content.tone(ContentCategory.sleep).accent,
                      title: l10n.backupExportTitle,
                      subtitle: l10n.backupExportSubtitle,
                      buttonText: l10n.backupExportButton,
                      buttonIcon: Icons.save_alt,
                      onTap: _exportBackup,
                    ),

                    const SizedBox(height: 24),

                    // IMPORT CARD
                    _buildActionCard(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: clinical.caution.accent,
                      title: l10n.backupImportTitle,
                      subtitle: l10n.backupImportSubtitle,
                      buttonText: l10n.backupImportButton,
                      buttonIcon: Icons.restore,
                      onTap: _importBackup,
                    ),

                    const SizedBox(height: 24),

                    // SERVER EXPORT CARD (habeas data)
                    _buildActionCard(
                      icon: Icons.download_for_offline_outlined,
                      iconColor: surfaces.brand,
                      title: l10n.serverExportTitle,
                      subtitle: l10n.serverExportSubtitle,
                      buttonText: l10n.serverExportButton,
                      buttonIcon: Icons.cloud_download_outlined,
                      onTap: _downloadServerData,
                    ),

                    const SizedBox(height: 32),

                    // WHAT'S INCLUDED
                    Divider(color: surfaces.divider),
                    const SizedBox(height: 24),
                    Text(
                      l10n.backupWhatIncluded,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: surfaces.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildIncludedItem(l10n.backupIncludesVitalSigns),
                    _buildIncludedItem(l10n.backupIncludesAnthropo),
                    _buildIncludedItem(l10n.backupIncludesLipid),
                    _buildIncludedItem(l10n.backupIncludesBodyComp),
                    _buildIncludedItem(l10n.backupIncludesPersonalInfo),
                    _buildIncludedItem(l10n.backupIncludesGoals),
                    _buildIncludedItem(l10n.backupIncludesPhoto),
                    _buildIncludedItem(l10n.backupIncludesPreferences),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          ),

          if (_isLoading)
            Container(
              color: surfaces.ink.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData buttonIcon,
    required VoidCallback onTap,
  }) {
    final surfaces = Theme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaces.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: surfaces.cardShadow,
        border: Border.all(color: surfaces.inset, width: 1.5),
      ),
      child: Column(
        children: [
          IconBadge(
            icon,
            color: iconColor,
            background: iconColor.withValues(alpha: 0.1),
            padding: 16,
            iconSize: 32,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: surfaces.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: surfaces.inkSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(buttonIcon, size: 18, color: surfaces.card),
            label: Text(
              buttonText,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: surfaces.card,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: surfaces.onBrand,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedItem(String text) {
    final clinical = Theme.of(context).clinical;
    final surfaces = Theme.of(context).surfaces;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconBadge(
            Icons.check,
            color: clinical.optimal.accent,
            background: clinical.optimal.surface,
            padding: 4,
            iconSize: 14,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: surfaces.ink),
            ),
          ),
        ],
      ),
    );
  }
}
