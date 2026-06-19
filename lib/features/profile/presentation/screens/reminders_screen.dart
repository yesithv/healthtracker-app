import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myvitals_healthtracker_app/core/providers/reminders_provider.dart';
import 'package:myvitals_healthtracker_app/core/theme/app_theme.dart';
import 'package:myvitals_healthtracker_app/core/widgets/secondary_app_bar.dart';
import 'package:myvitals_healthtracker_app/l10n/generated/app_localizations.dart';
import 'package:myvitals_healthtracker_app/core/services/notification_service.dart';
import 'package:myvitals_healthtracker_app/core/models/reminder.dart';

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
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: reminder.time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateReminder(
        index,
        reminder.copyWith(time: picked, isEnabled: true),
      );
    }
  }

  Future<void> _toggleReminder(
      Reminder reminder, int index, bool value) async {
    _updateReminder(
      index,
      reminder.copyWith(isEnabled: value),
    );
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
      String body = _getTranslatedReminder(updatedReminder.translationKey, l10n);
      
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
    switch (key) {
      case 'reminderVitals':
        return const Color(0xFFEF4444); // Rojo
      case 'reminderMeds':
        return const Color(0xFF10B981); // Esmeralda
      case 'reminderWorkout':
        return const Color(0xFF3B82F6); // Azul
      case 'reminderWater':
        return const Color(0xFF0EA5E9); // Celeste
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remindersProvider = Provider.of<RemindersProvider>(context);
    final reminders = remindersProvider.reminders;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Column(
        children: [
          const SecondaryAppBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_outlined,
                            size: 40,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.remindersTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.remindersDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ...List.generate(
                        reminders.length,
                        (index) {
                          final reminder = reminders[index];
                          final label = _getTranslatedReminder(
                              reminder.translationKey, l10n);
                          final icon =
                              _getIconForReminder(reminder.translationKey);
                          final color =
                              _getColorForReminder(reminder.translationKey);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: reminder.isEnabled
                                    ? color.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.1),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _pickTime(reminder, index),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: reminder.isEnabled
                                              ? color.withValues(alpha: 0.1)
                                              : Colors.grey.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          icon,
                                          color: reminder.isEnabled
                                              ? color
                                              : Colors.grey[500],
                                          size: 24,
                                        ),
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
                                                    ? const Color(0xFF1E293B)
                                                    : Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: reminder.isEnabled
                                                      ? AppTheme.primaryColor
                                                      : Colors.grey[400],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  reminder.time
                                                      .format(context),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: reminder.isEnabled
                                                        ? AppTheme.primaryColor
                                                        : Colors.grey[400],
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
                                        activeThumbColor: Colors.white,
                                        activeTrackColor: color,
                                        inactiveThumbColor: Colors.grey[400],
                                        inactiveTrackColor: Colors.grey[200],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                      Text(
                        l10n.remindersNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
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
