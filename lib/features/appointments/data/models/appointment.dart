import 'dart:convert';

import 'package:myvitals_healthtracker_app/core/diagnostics/debug_log.dart';

import 'package:uuid/uuid.dart';

/// Estado de una cita dentro de su ciclo de vida:
/// - [toBook]: hay que sacarla; su fecha objetivo vive en [Appointment.dueToBookOn]
///   (recall — p. ej. "control con endocrino cada 3 meses" o "pedir neuropsicología
///   dentro de un mes").
/// - [scheduled]: ya tiene fecha y hora ([Appointment.scheduledAt]).
/// - [attended]: se confirmó la asistencia (cierra la ocurrencia).
/// - [missed]: no se asistió / se perdió.
/// - [cancelled]: anulada.
///
/// El estado derivado "vencida" (overdue) NO se guarda: se calcula al vuelo desde
/// las fechas (ver `AppointmentStatusService`).
///
/// Se persiste por `name` (string estable), no por índice, para que reordenar el
/// enum no corrompa datos existentes.
enum AppointmentStatus { toBook, scheduled, attended, missed, cancelled }

AppointmentStatus _statusFromName(String? name) => AppointmentStatus.values
    .firstWhere((e) => e.name == name, orElse: () => AppointmentStatus.toBook);

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// Serializa los minutos-antes de los avisos como texto JSON (`[1440,60]`).
String? _encodeOffsets(List<int>? offsets) =>
    offsets == null ? null : jsonEncode(offsets);

/// Lee la lista de minutos-antes. Tolera null y JSON corrupto (→ lista vacía).
List<int> _decodeOffsets(Object? value) {
  if (value == null) return const [];
  try {
    final decoded = jsonDecode(value as String);
    if (decoded is List) {
      return decoded.whereType<num>().map((e) => e.toInt()).toList();
    }
  } catch (e) {
    debugLogError('Appointment.parseReminderOffsets', e);
    // JSON corrupto: se ignora y se devuelve vacío.
  }
  return const [];
}

/// Una cita médica del usuario: identidad, estado y —si es un control periódico—
/// su recurrencia. Es el elemento del "inventario de citas".
///
/// Sigue las convenciones de los demás modelos del repo (`*_record.dart`,
/// `medication.dart`): `id` TEXT con [Uuid], fechas ISO-8601, booleanos como 0/1 y
/// `is_synced` para la sincronización futura.
class Appointment {
  final String id;
  final String title;

  /// Especialidad (endocrinología, neuropsicología…). Informativa.
  final String? specialty;

  /// Médico, IPS o entidad. Informativa.
  final String? provider;

  /// Dirección o nota de lugar. Informativa.
  final String? location;

  final String? notes;

  final AppointmentStatus status;

  /// Fecha y hora de la cita cuando [status] es [AppointmentStatus.scheduled].
  final DateTime? scheduledAt;

  /// Fecha objetivo para agendarla cuando [status] es [AppointmentStatus.toBook].
  final DateTime? dueToBookOn;

  // --- Recurrencia (control periódico) ---
  final bool isRecurring;

  /// Periodicidad en meses (ej. 3 = "cada 3 meses"). Null si no es recurrente.
  final int? intervalMonths;

  /// Días de antelación para recordar sacar la próxima (se restan de la fecha
  /// objetivo al recordar). Opcional.
  final int? leadDays;

  /// Enlaza todas las ocurrencias de una misma serie recurrente. Se comparte
  /// entre la cita cerrada y la siguiente `toBook` que genera el dominio.
  final String? seriesId;

  // --- Avisos ---
  /// Minutos de antelación de cada aviso de una cita agendada (ej. `[1440, 60]`
  /// = 24 h y 1 h antes). Vacío = sin avisos por adelantado.
  final List<int> reminderOffsets;

  /// Silencia los avisos hasta esta fecha (tras "ya la saqué" o "posponer").
  final DateTime? snoozedUntil;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Appointment({
    String? id,
    required this.title,
    this.specialty,
    this.provider,
    this.location,
    this.notes,
    this.status = AppointmentStatus.toBook,
    this.scheduledAt,
    this.dueToBookOn,
    this.isRecurring = false,
    this.intervalMonths,
    this.leadDays,
    this.seriesId,
    List<int>? reminderOffsets,
    this.snoozedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4(),
       reminderOffsets = reminderOffsets ?? const [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Appointment copyWith({
    String? title,
    String? specialty,
    String? provider,
    String? location,
    String? notes,
    AppointmentStatus? status,
    DateTime? scheduledAt,
    DateTime? dueToBookOn,
    bool? isRecurring,
    int? intervalMonths,
    int? leadDays,
    String? seriesId,
    List<int>? reminderOffsets,
    DateTime? snoozedUntil,
    DateTime? updatedAt,
    bool? isSynced,
    // Los null no se distinguen de "no provisto" en copyWith; estos flags
    // permiten limpiar explícitamente los campos opcionales que el dominio
    // necesita borrar al cambiar de estado (ej. al agendar una cita "por sacar"
    // se fija `scheduledAt` y se limpia `dueToBookOn`).
    bool clearScheduledAt = false,
    bool clearDueToBookOn = false,
    bool clearSnoozedUntil = false,
  }) {
    return Appointment(
      id: id,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      provider: provider ?? this.provider,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
      dueToBookOn: clearDueToBookOn ? null : (dueToBookOn ?? this.dueToBookOn),
      isRecurring: isRecurring ?? this.isRecurring,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      leadDays: leadDays ?? this.leadDays,
      seriesId: seriesId ?? this.seriesId,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'specialty': specialty,
      'provider': provider,
      'location': location,
      'notes': notes,
      'status': status.name,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'due_to_book_on': dueToBookOn?.toIso8601String(),
      'is_recurring': isRecurring ? 1 : 0,
      'interval_months': intervalMonths,
      'lead_days': leadDays,
      'series_id': seriesId,
      'reminder_offsets': _encodeOffsets(reminderOffsets),
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      title: map['title'] as String,
      specialty: map['specialty'] as String?,
      provider: map['provider'] as String?,
      location: map['location'] as String?,
      notes: map['notes'] as String?,
      status: _statusFromName(map['status'] as String?),
      scheduledAt: _parseDate(map['scheduled_at']),
      dueToBookOn: _parseDate(map['due_to_book_on']),
      isRecurring: map['is_recurring'] == 1,
      intervalMonths: map['interval_months'] as int?,
      leadDays: map['lead_days'] as int?,
      seriesId: map['series_id'] as String?,
      reminderOffsets: _decodeOffsets(map['reminder_offsets']),
      snoozedUntil: _parseDate(map['snoozed_until']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      isSynced: map['is_synced'] == 1,
    );
  }

  /// Antelación por defecto de los avisos de una cita agendada: 24 h y 1 h antes.
  static const List<int> defaultReminderOffsets = [1440, 60];
}
