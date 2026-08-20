# Citas médicas — Estado de implementación

> Registro de lo construido para el módulo ligero de Citas médicas y de lo que
> queda pendiente. Complementa a `citas-medicas-analisis.md` (diseño),
> `citas-medicas-plan-implementacion.md` (plan) y `citas-medicas-prompt-ui.md`
> (prompt de UI). Entregado en el PR #35 sobre la rama
> `claude/medical-appointments-module-0ebkl9` (base: `main`).

## Decisiones tomadas en la sesión de implementación

- **Ubicación en el Dashboard:** el cuadrado de Citas es **vivo y siempre
  presente** (espejo del de Medicamentos), no la tarjeta condicional que
  aparece/desaparece que proponía el análisis. Mantiene la fila simétrica de dos
  cuadrados del fondo.
- **Alcance:** **esencial primero**. Se implementó el inventario + alta en dos
  modos + notificaciones básicas + cuadrado en Dashboard + entrada en Perfil +
  los 5 idiomas. La **recurrencia automática** y el **semáforo de cumplimiento**
  se difieren a una 2ª iteración de UI (su lógica de dominio ya está construida y
  testeada, solo falta exponerla en pantalla).
- **Reconciliación con `main`:** el backend venía de un análisis previo hecho
  sobre un `main` anterior a Medicamentos. Se portó sobre el `main` actual (la
  BD ya iba por v4 con Medicamentos → Citas es **v5**; `RecordRepository` ya
  traía el refactor `orderBy`; `NotificationService` ya exponía
  `scheduleOneTimeNotification`/`cancel`, a los que se añadió un canal propio de
  citas de forma aditiva).

## Lo que quedó implementado (Fase 1 — esencial)

### Datos y dominio (`lib/features/appointments/`)
- **Tabla `appointments`** (una sola, BD v4→v5, migración aditiva) en
  `lib/core/database/database_service.dart` (`_createAppointmentsTable`).
- **Modelo** `data/models/appointment.dart`: `Appointment` + enum
  `AppointmentStatus` (persistido por `name`), `copyWith` con flags `clear*`,
  `toMap`/`fromMap`, `defaultReminderOffsets` (24 h y 1 h antes).
- **Repositorio** `data/repositories/appointment_repository.dart`:
  `extends RecordRepository<Appointment>` con `orderBy` propio y getters
  derivados `toBook` · `scheduled` · `history`.
- **Servicios de dominio puros** (`domain/`):
  - `appointment_status_service.dart`: `isOverdue`, `book`, `markAttended`,
    `markMissed`, `nextRecurringOccurrence` (+ `addMonths` con recorte de día).
  - `appointment_compliance_service.dart`: `overdueCount`, `dueSoonCount`,
    `semaphore`, `nextAction`, `attendanceRate`.
  - `appointment_scheduler.dart`: `buildPlan` pura + `rescheduleAll` +
    `cancelAll`, con libro de ids persistido (rango 400000+) y ventana móvil;
    reutiliza `NotificationService`.
- **Controlador** `presentation/controllers/appointments_controller.dart`:
  orquesta repo + dominio + avisos (crear agendada/por sacar, agendar, confirmar
  asistencia/inasistencia, posponer, borrar) y expone builders de texto
  localizado + `refreshAndReschedule`.

### UI
- **Cuadrado vivo en el Dashboard**
  (`features/dashboard/presentation/widgets/appointments_card.dart`): próxima
  cita agendada / cita por sacar / CTA para añadir; chip «Vencida»; abre el
  inventario.
- **Pantalla «Mis citas»**
  (`features/appointments/presentation/screens/appointments_screen.dart`):
  secciones *Por sacar · Agendadas · Historial*, con acciones por ítem
  («Ya la saqué» → pide fecha; «Ya asistí»/«No asistí»; posponer; eliminar) y
  estado vacío amable.
- **Hoja de alta**
  (`features/appointments/presentation/widgets/appointment_add_sheet.dart`):
  formulario en dos modos («Ya tengo fecha» / «Debo sacarla»), con título
  obligatorio, especialidad, médico/lugar y notas opcionales.
- **Enganches:** ruta `/profile/appointments` (`app_router.dart`), fila «Mis
  citas» en Perfil + `SettingsSection.appointments` (`settings_accent.dart`),
  y deep-link de las notificaciones de citas al inventario (`main.dart`).

### Infraestructura
- **Ciclo de vida de avisos** (`main.dart`, `_NotificationsLifecycle`):
  reprograma los avisos de citas con texto localizado al arrancar y al volver de
  segundo plano, junto a los de Medicamentos.
- **Borrado entre usuarios** (`local_data_reset.dart`): al cerrar sesión se
  vacía la tabla `appointments` y se cancelan sus avisos (`cancelAll`).
- **Localización:** claves nuevas en los 5 `lib/l10n/app_*.arb` (es/en/it/pt/de)
  + generados.

### Cobertura de pruebas (`test/features/appointments/`)
- `appointment_status_service_test.dart`: `addMonths` (día conservado, cruce de
  año, recorte de mes, **año bisiesto**, hora conservada); `isOverdue` (por
  sacar/agendada, y **bordes**: sin fecha, fecha = hoy, instante exacto,
  missed/cancelled); `book` (limpia fecha objetivo y silenciado); recurrencia
  (siguiente ocurrencia, herencia de serie, creación de `series_id`,
  **intervalo ≤ 0 → null**, base = fecha agendada sin `completedOn`).
- `appointment_compliance_service_test.dart`: `overdueCount`, `dueSoonCount`
  (+ **límite exacto de la ventana**), `semaphore` (rojo/ámbar/verde/vacío y
  **ámbar por cita agendada inminente**), `nextAction` (prioriza vencidas, y
  **más temprana sin vencidas**, ignora cerradas), `attendanceRate` (+ filtro
  **`since`**).
- `appointment_scheduler_test.dart`: agendada (un aviso por offset), por sacar
  (9:00 − `leadDays`, y **sin `leadDays`**), vencida (re-empuje), silenciada,
  cerradas, **fuera de horizonte**, **offset anterior a la ventana descartado**,
  **agendada pasada → re-empuje**, **ids únicos por tipo** con varias citas.
- `appointments_controller_test.dart` (**nuevo**, integración con sqflite ffi en
  memoria + scheduler noop): alta agendada/por sacar, `book`, `markAttended`/
  `markMissed` (no recurrente cierra; recurrente genera la siguiente por sacar),
  `postpone`, `delete`, `overdueCount`.

## Verificación
- CI del PR #35 (`.github/workflows/deploy.yml`) en verde: **job «Verificación»
  = `flutter analyze` + `flutter test`** superado (incluye los tests de citas y
  los de cadenas/glifos).
- Prueba manual sugerida (en dispositivo; web es no-op para notificaciones):
  Perfil → «Mis citas»; añadir una cita por sacar y una agendada; confirmar
  «Ya la saqué» / «Ya asistí»; cerrar sesión vacía la tabla.

## Pendiente (2ª iteración — el dominio ya está listo, falta solo UI)

1. **Recurrencia en el alta.** Toggle «control periódico (cada N meses)» en la
   hoja de alta que fije `isRecurring` + `intervalMonths`, y reflejo visual de
   que, al confirmar asistencia, se generó automáticamente la siguiente «por
   sacar». Cubre el caso «endocrino cada 6 meses» del usuario. El dominio
   (`nextRecurringOccurrence`, ya usado por el controlador) no necesita cambios.
2. **Semáforo de cumplimiento.** Tarjetita verde/ámbar/rojo + «próxima acción»
   arriba del inventario y, opcionalmente, como chip en el cuadrado del
   Dashboard. La lógica ya existe en `AppointmentComplianceService`
   (`semaphore`, `nextAction`, `overdueCount`).

### Ideas más adelante (Fase 3 del análisis)
- Recurrencia también por semanas/días (hoy solo meses).
- Editar una cita existente desde el inventario (hoy: crear/confirmar/borrar).
- Sugerencias inteligentes de recall a partir del historial.
- Vincular una cita con las métricas que se miden en ella (p. ej. endocrino ↔
  perfil lipídico) y exportarla al PDF clínico.
- Silenciar/posponer avisos por cita y ajustar la antelación desde la UI (el
  modelo ya guarda `snoozedUntil` y `reminderOffsets`).
- Sincronización con el servidor (la tabla ya trae `is_synced`).
