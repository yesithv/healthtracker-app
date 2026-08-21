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

  /// Constructor generativo para poder crear dobles de prueba (subclases que
  /// sobrescriben `scheduleOneTimeNotification`/`cancel`) sin tocar los plugins.
  /// La app siempre usa el singleton vía la fábrica `NotificationService()`.
  @visibleForTesting
  NotificationService.forTesting();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Canal Android de los avisos de medicamentos (tomas e inventario), separado
  /// del canal de recordatorios diarios para que el usuario pueda gestionarlos
  /// por separado desde los ajustes del sistema.
  static const String medicationChannelId = 'medication_reminders_channel';

  /// Canal Android de los avisos de citas médicas (recordatorios de una cita
  /// agendada y de "sacar" una cita pendiente), separado del de medicamentos para
  /// que el usuario pueda gestionarlos aparte desde los ajustes del sistema.
  static const String appointmentChannelId = 'appointment_reminders_channel';

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
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
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

  /// Si la app se ABRIÓ tocando una notificación (arranque en frío), devuelve su
  /// payload; null en caso contrario o en web. El `initialize` no dispara
  /// `onDidReceiveNotificationResponse` para ese toque inicial, así que la app lo
  /// consulta al arrancar y hace el deep-link ella misma. Ver `main.dart`.
  Future<String?> launchPayload() async {
    if (kIsWeb) return null;
    final details =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    final payload = details!.notificationResponse?.payload;
    return (payload != null && payload.isNotEmpty) ? payload : null;
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
  ///
  /// [channelId]/[channelName]/[channelDescription] permiten a otros
  /// planificadores (p. ej. el de citas) usar su propio canal Android; por
  /// defecto se usa el canal de medicamentos para no cambiar su comportamiento.
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
    String channelId = medicationChannelId,
    String channelName = 'Recordatorios de medicamentos',
    String channelDescription =
        'Avisos de tomas de medicamentos y de recompra de inventario',
  }) async {
    if (kIsWeb) return;

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();
    final NotificationDetails platformChannelSpecifics = NotificationDetails(
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
