import 'package:flutter/material.dart';
import 'package:myvitals_healthtracker_app/core/theme/theme_context.dart';
import 'package:myvitals_healthtracker_app/core/theme/tokens/content_palette.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/core/models/reminder.dart';
import 'package:myvitals_healthtracker_app/core/widgets/icon_badge.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    await _notificationService.requestPermissions();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  Future<void> _pickTime(Reminder reminder, int index) async {
    final surfaces = Theme.of(context).surfaces;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: surfaces.brand,
              onPrimary: surfaces.onBrand,
              onSurface: surfaces.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateReminder(index, reminder.copyWith(time: picked, isEnabled: true));
    }
  }

  Future<void> _toggleReminder(Reminder reminder, int index, bool value) async {
    _updateReminder(index, reminder.copyWith(isEnabled: value));
  }

  Future<void> _updateReminder(int index, Reminder updatedReminder) async {
    setState(() => _isLoading = true);

    final remindersProvider = Provider.of<RemindersProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    final newReminders = List<Reminder>.from(remindersProvider.reminders);
    newReminders[index] = updatedReminder;

    // Guardar en sistema
    await remindersProvider.updateReminders(newReminders);

    // Actualizar notificación local
    final notifId = index + 100; // Unique ID per reminder
    if (updatedReminder.isEnabled) {
      String title = l10n.reminderTitle;
      String body = _getTranslatedReminder(
        updatedReminder.translationKey,
        l10n,
      );

      await _notificationService.scheduleDailyReminder(
        id: notifId,
        title: title,
        body: body,
        time: updatedReminder.time,
      );
    } else {
      await _notificationService.cancelReminder(notifId);
    }

    setState(() => _isLoading = false);
  }

  String _getTranslatedReminder(String key, AppLocalizations l10n) {
    switch (key) {
      case 'reminderVitals':
        return l10n.reminderVitals;
      case 'reminderMeds':
        return l10n.reminderMeds;
      case 'reminderWorkout':
        return l10n.reminderWorkout;
      case 'reminderWater':
        return l10n.reminderWater;
      default:
        return l10n.reminderDefaultTitle;
    }
  }

  IconData _getIconForReminder(String key) {
    switch (key) {
      case 'reminderVitals':
        return Icons.favorite_outline;
      case 'reminderMeds':
        return Icons.medication_outlined;
      case 'reminderWorkout':
        return Icons.fitness_center_outlined;
      case 'reminderWater':
        return Icons.water_drop_outlined;
      default:
        return Icons.alarm;
    }
  }

  Color _getColorForReminder(String key) {
    final clinical = Theme.of(context).clinical;
    final content = Theme.of(context).content;
    switch (key) {
      case 'reminderVitals':
        return clinical.alert.accent; // Rojo
      case 'reminderMeds':
        return clinical.optimal.accent; // Esmeralda
      case 'reminderWorkout':
        return clinical.info.accent; // Azul
      case 'reminderWater':
        return clinical.info.accent; // Celeste
      default:
        return content.tone(ContentCategory.emotional).accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = Theme.of(context).surfaces;
    final content = Theme.of(context).content;
    final l10n = AppLocalizations.of(context)!;
    final remindersProvider = Provider.of<RemindersProvider>(context);
    final reminders = remindersProvider.reminders;

    return Scaffold(
      backgroundColor: surfaces.canvas,
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    children: [
                      Center(
                        child: IconBadge(
                          Icons.notifications_active_outlined,
                          color: content.tone(ContentCategory.emotional).accent,
                          background: content
                              .tone(ContentCategory.emotional)
                              .accent
                              .withValues(alpha: 0.1),
                          padding: 16,
                          iconSize: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.remindersTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: surfaces.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.remindersDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: surfaces.inkSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...List.generate(reminders.length, (index) {
                        final reminder = reminders[index];
                        final label = _getTranslatedReminder(
                          reminder.translationKey,
                          l10n,
                        );
                        final icon = _getIconForReminder(
                          reminder.translationKey,
                        );
                        final color = _getColorForReminder(
                          reminder.translationKey,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: surfaces.card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: reminder.isEnabled
                                  ? color.withValues(alpha: 0.3)
                                  : surfaces.inkMuted.withValues(alpha: 0.1),
                              width: 2,
                            ),
                            boxShadow: surfaces.cardShadow,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _pickTime(reminder, index),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 20,
                                ),
                                child: Row(
                                  children: [
                                    IconBadge(
                                      icon,
                                      color: reminder.isEnabled
                                          ? color
                                          : surfaces.inkMuted,
                                      background: reminder.isEnabled
                                          ? color.withValues(alpha: 0.1)
                                          : surfaces.inkMuted.withValues(
                                              alpha: 0.1,
                                            ),
                                      padding: 12,
                                      iconSize: 24,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: reminder.isEnabled
                                                  ? surfaces.ink
                                                  : surfaces.inkMuted,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: reminder.isEnabled
                                                    ? surfaces.brand
                                                    : surfaces.inkMuted,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                reminder.time.format(context),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: reminder.isEnabled
                                                      ? surfaces.brand
                                                      : surfaces.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: reminder.isEnabled,
                                      onChanged: (val) =>
                                          _toggleReminder(reminder, index, val),
                                      activeThumbColor: surfaces.onBrand,
                                      activeTrackColor: color,
                                      inactiveThumbColor: surfaces.inkMuted,
                                      inactiveTrackColor: surfaces.divider,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                      Text(
                        l10n.remindersNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: surfaces.inkMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
