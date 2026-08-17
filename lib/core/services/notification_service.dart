import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Canal Android de los avisos de medicamentos (tomas e inventario), separado
  /// del canal de recordatorios diarios para que el usuario pueda gestionarlos
  /// por separado desde los ajustes del sistema.
  static const String medicationChannelId = 'medication_reminders_channel';

  /// Se invoca cuando el usuario toca una notificación de medicamentos, con su
  /// `payload`. Lo fija la app (que tiene acceso al router) para hacer el
  /// deep-link a la hoja de la toma. Ver `_onDidReceiveNotificationResponse`.
  static void Function(String payload)? onNotificationTap;

  Future<void> init() async {
    // flutter_local_notifications does not support web — skip gracefully.
    if (kIsWeb) return;

    // Inicializar zona horaria nativa
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuración para iOS
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );
  }

  void _onDidReceiveNotificationResponse(NotificationResponse response) {
    // Enruta el toque a quien lo haya registrado (la app, con el router). El
    // payload identifica la toma o la alerta de inventario (ver
    // MedicationScheduler para su formato).
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      onNotificationTap?.call(payload);
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    bool? granted;

    // Request Android 13+ permissions
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      granted = await androidImplementation.requestNotificationsPermission();
      // Also request exact alarms permission
      await androidImplementation.requestExactAlarmsPermission();
    }

    // Request iOS permissions
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosImplementation != null) {
      granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return granted ?? false;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    if (kIsWeb) return;

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Si la hora ya pasó hoy, programarla para mañana
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_reminders_channel',
      'Recordatorios Diarios',
      channelDescription: 'Notificaciones sobre chequeos de salud diarios',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  /// Programa una notificación de UNA sola vez para [dateTime] (en la zona
  /// local). A diferencia de [scheduleDailyReminder], no se repite: el módulo de
  /// medicamentos materializa cada toma futura como una notificación puntual
  /// dentro de una ventana móvil (ver MedicationScheduler), lo que cubre por
  /// igual las pautas diarias, por días de la semana y "cada N días" —esta
  /// última no la puede repetir el plugin de forma nativa—. No programa nada en
  /// el pasado.
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    if (kIsWeb) return;

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      medicationChannelId,
      'Recordatorios de medicamentos',
      channelDescription:
          'Avisos de tomas de medicamentos y de recompra de inventario',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  /// Cancela cualquier notificación por [id] (equivalente a [cancelReminder];
  /// nombre genérico para el planificador de medicamentos).
  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
