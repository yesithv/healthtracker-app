import 'package:myvitals_healthtracker_app/features/appointments/data/models/appointment.dart';
import 'package:myvitals_healthtracker_app/features/appointments/data/repositories/appointment_repository.dart';

/// Siembra citas médicas de ejemplo para la DEMOSTRACIÓN, para que el módulo se
/// vea poblado (la app normal arranca vacía). Es **idempotente**: si ya hay
/// alguna cita, no hace nada.
///
/// El juego cubre a propósito **todos los estados y características** del módulo,
/// para que la demo enseñe la funcionalidad completa de una sola pasada:
/// una cita **agendada próxima** (dispara la tarjeta y avisos), una **por sacar
/// recurrente** (control endocrino cada 3 meses), una **por sacar vencida**
/// (enciende el semáforo en rojo y la «próxima acción»), una **por sacar
/// puntual**, y algo de **historial** (asistí/no asistí) para la sección
/// Historial y la tasa de asistencia. Es coherente con «Camila Herrera» y sus
/// medicamentos demo (tiroides, colesterol, glucosa).
Future<void> seedDemoAppointmentsIfEmpty() async {
  final repo = AppointmentRepository.instance;

  // Relee desde la base ya conmutada a la demo antes de decidir.
  await repo.refresh();
  if (repo.items.isNotEmpty) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime atDay(DateTime day, int hour, int minute) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  // Enlaza la serie recurrente del endocrino: la ocurrencia asistida del
  // historial y la próxima «por sacar» comparten `series_id`.
  const endoSeries = 'demo-appt-series-endo';

  final appointments = <Appointment>[
    // 1) Agendada próxima (en 3 días, 10:00): enciende la tarjeta del dashboard
    //    y programa los avisos de 24 h / 1 h antes.
    Appointment(
      id: 'demo-appt-cardio',
      title: 'Cita con cardiología',
      specialty: 'Cardiología',
      provider: 'Dra. Elena Ríos',
      location: 'Clínica del Country, consultorio 402',
      notes: 'Llevar el último electrocardiograma.',
      status: AppointmentStatus.scheduled,
      scheduledAt: atDay(today.add(const Duration(days: 3)), 10, 0),
      reminderOffsets: Appointment.defaultReminderOffsets,
      createdAt: today.subtract(const Duration(days: 10)),
      updatedAt: today.subtract(const Duration(days: 10)),
    ),

    // 2) Por sacar recurrente: control endocrino cada 3 meses (fecha objetivo
    //    en ~3 semanas). Al confirmar asistencia, el controlador genera sola la
    //    siguiente ocurrencia.
    Appointment(
      id: 'demo-appt-endo-next',
      title: 'Control endocrino',
      specialty: 'Endocrinología',
      provider: 'Dr. Mauricio Salas',
      notes: 'Control trimestral de tiroides.',
      status: AppointmentStatus.toBook,
      dueToBookOn: today.add(const Duration(days: 21)),
      isRecurring: true,
      intervalMonths: 3,
      leadDays: 7,
      seriesId: endoSeries,
      reminderOffsets: Appointment.defaultReminderOffsets,
      createdAt: today.subtract(const Duration(days: 5)),
      updatedAt: today.subtract(const Duration(days: 5)),
    ),

    // 3) Por sacar VENCIDA: laboratorio de control que ya pasó su fecha objetivo
    //    → chip «Vencida», semáforo rojo y «próxima acción».
    Appointment(
      id: 'demo-appt-lab',
      title: 'Sacar laboratorio: perfil lipídico',
      specialty: 'Laboratorio clínico',
      notes: 'Ayuno de 12 horas.',
      status: AppointmentStatus.toBook,
      dueToBookOn: today.subtract(const Duration(days: 8)),
      reminderOffsets: Appointment.defaultReminderOffsets,
      createdAt: today.subtract(const Duration(days: 30)),
      updatedAt: today.subtract(const Duration(days: 30)),
    ),

    // 4) Por sacar puntual (no recurrente): recordatorio diferido.
    Appointment(
      id: 'demo-appt-neuro',
      title: 'Pedir cita de neuropsicología',
      specialty: 'Neuropsicología',
      status: AppointmentStatus.toBook,
      dueToBookOn: today.add(const Duration(days: 40)),
      reminderOffsets: Appointment.defaultReminderOffsets,
      createdAt: today.subtract(const Duration(days: 2)),
      updatedAt: today.subtract(const Duration(days: 2)),
    ),

    // 5) Historial — ocurrencia anterior del endocrino, asistida (misma serie).
    Appointment(
      id: 'demo-appt-endo-prev',
      title: 'Control endocrino',
      specialty: 'Endocrinología',
      provider: 'Dr. Mauricio Salas',
      status: AppointmentStatus.attended,
      scheduledAt: atDay(today.subtract(const Duration(days: 82)), 9, 30),
      isRecurring: true,
      intervalMonths: 3,
      seriesId: endoSeries,
      createdAt: today.subtract(const Duration(days: 110)),
      updatedAt: today.subtract(const Duration(days: 82)),
    ),

    // 6) Historial — cardiología asistida.
    Appointment(
      id: 'demo-appt-cardio-prev',
      title: 'Cita con cardiología',
      specialty: 'Cardiología',
      provider: 'Dra. Elena Ríos',
      status: AppointmentStatus.attended,
      scheduledAt: atDay(today.subtract(const Duration(days: 63)), 11, 0),
      createdAt: today.subtract(const Duration(days: 90)),
      updatedAt: today.subtract(const Duration(days: 63)),
    ),

    // 7) Historial — odontología no asistida (baja un poco la tasa de asistencia).
    Appointment(
      id: 'demo-appt-dental',
      title: 'Limpieza dental',
      specialty: 'Odontología',
      status: AppointmentStatus.missed,
      scheduledAt: atDay(today.subtract(const Duration(days: 40)), 15, 0),
      createdAt: today.subtract(const Duration(days: 70)),
      updatedAt: today.subtract(const Duration(days: 40)),
    ),
  ];

  for (final appt in appointments) {
    await repo.insert(appt);
  }
}
