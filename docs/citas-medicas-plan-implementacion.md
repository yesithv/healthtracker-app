# Plan de implementación — Inventario de citas médicas (capa ligera)

> Paso de implementación de la **Fase 1 (MVP)** descrita en
> `docs/citas-medicas-analisis.md`. El prompt para construir la UI está en
> `docs/citas-medicas-prompt-ui.md`.

## Contexto

MyVitals (Flutter, `myvitals_healthtracker_app`) es una app de seguimiento de salud
del lado del **paciente**. Se quiere una capa **ligera y discreta** de citas médicas
—no un módulo pesado como medicamentos, ni un destino en la navegación— que:

- lleve un **inventario de citas**: las que ya tiene (fecha/hora) y las que **debe
  sacar** (recall — control con endocrino cada 3 meses; o "recuérdame pedir
  neuropsicología dentro de un mes");
- **recuerde** por notificación y deje **confirmar** ("ya la saqué / ya asistí /
  posponer") desde la propia tarjeta/notificación;
- lleve un **índice de cumplimiento** (semáforo: citas vencidas + próxima acción).

Resultado: el paciente no vuelve a olvidar sacar un control periódico ni asistir a
una cita, con cero peso visual cuando todo está al día.

## Higiene de ramas

Todo el trabajo de citas vive en `claude/medical-appointments-analysis-ov5yfd`,
creada desde `origin/main`. La rama de medicamentos
(`claude/medication-reminder-planning-h7n7kl`) queda **intacta**; solo se leyó para
estudiar patrones.

## Hallazgos de arquitectura (a reutilizar)

- **Persistencia:** `RecordRepository<T>` (`lib/core/database/record_repositories.dart`)
  da CRUD + caché en memoria + `is_synced`. Los repos concretos solo declaran tabla,
  mappers e id. **OJO:** en `main` la base ordena por `measurement_date DESC` fijo (en
  `refresh`, `getAll`, `getUnsynced`); las tablas de citas **no** tienen esa columna →
  hace falta un refactor mínimo a getters `orderBy`/`unsyncedOrderBy` sobreescribibles
  (idéntico al que introdujo la rama de medicamentos).
- **Esquema/migraciones:** `lib/core/database/database_service.dart` — `_dbVersion`,
  `_createDB`, `_upgradeDB` (aditivo) y `_createIndexes`.
- **Notificaciones:** `lib/core/services/notification_service.dart`
  (`scheduleOneTimeNotification`, `cancel`, no-op en web). El patrón scheduler con
  **libro de ids persistido + ventana móvil + `buildPlan` pura** está resuelto en
  `lib/features/medications/domain/medication_scheduler.dart`; se replica para citas
  con rango de ids propio (400000+) para no colisionar con dosis (200000+), inventario
  (800000+) ni recordatorios simples (100–999).
- **Convenciones de modelo:** `id` TEXT con `Uuid`, fechas ISO-8601, bool 0/1, enums
  por `name`, `copyWith` con flags `clear*`, `toMap`/`fromMap` (ver
  `features/medications/data/models/medication.dart`).
- **UI de enganche:** `_MenuTile` en `profile_screen.dart`, tarjetas del dashboard en
  `features/dashboard/presentation/widgets/`, providers en `main.dart`.
- **Ciclo de vida:** repos se vacían al cerrar sesión (`clearAll`) y hay
  `wipeLocalUserData`; enganchar ahí el nuevo repo.
- **Localización:** `lib/l10n/app_*.arb` (en/es/it/pt/de) + `lib/l10n/generated/`.

## Enfoque (Fase 1 — MVP)

Feature nueva bajo `lib/features/appointments/`, mucho más ligera que medicamentos
(**1 tabla**, sin stock, sin destino en nav).

### Paso 1 — Base de datos y repositorio base
- Refactor mínimo de `RecordRepository`: `String get orderBy` (default
  `'measurement_date DESC'`) y `String get unsyncedOrderBy`, usados en
  `refresh`/`getAll`/`getUnsynced`.
- `database_service.dart`: subir `_dbVersion`, crear tabla `appointments` en
  `_createDB`, añadirla en `_upgradeDB` (aditivo) e índice por `scheduled_at` /
  `due_to_book_on`.
- Tabla `appointments` (una sola): `id, title, specialty, provider, location, notes,
  status (toBook|scheduled|attended|missed|cancelled), scheduled_at, due_to_book_on,
  is_recurring, interval_months, lead_days, series_id, reminder_offsets (JSON),
  snoozed_until, created_at, updated_at, is_synced`.

### Paso 2 — Modelo y repositorio de la feature
- `appointments/data/models/appointment.dart`: modelo inmutable + enum
  `AppointmentStatus` (por `name`) + `copyWith`/`toMap`/`fromMap`.
- `appointments/data/repositories/appointment_repository.dart`:
  `extends RecordRepository<Appointment>` con `orderBy` propio y helpers derivados
  (`toBook`, `scheduled`, `history`, `overdue(now)`, `upcoming(now)`).

### Paso 3 — Dominio puro (testeable, sin UI/BD)
- `appointment_status_service.dart`: derivar `overdue`, próxima acción, y la
  transición de **recurrencia** — al marcar `attended`/`missed` de una recurrente,
  generar la siguiente `toBook` (`dueToBookOn = fecha + interval_months`, mismo
  `series_id`).
- `appointment_compliance_service.dart`: métricas del índice (nº vencidas + próxima
  acción para el semáforo del MVP; tasa de asistencia y recall on-time preparadas
  para Fase 2).
- `appointment_scheduler.dart`: `buildPlan` pura + `rescheduleAll` + `cancelAll` con
  libro de ids (rango 400000+). `scheduled` → avisos según `reminder_offsets` (24 h y
  1 h por defecto); `toBook` → aviso el día de `due_to_book_on`; `overdue` →
  re-empuje. Payload `appointment|<id>|<kind>`.

### Paso 4 — Controlador
- `appointments_controller.dart` (`ChangeNotifier` delgado): crear agendada / por
  sacar, marcar asistí/no asistí/posponer, editar, borrar — componiendo repo +
  dominio + scheduler.
- Registrar repo y controller en `main.dart`; llamar `rescheduleAll` al arrancar y al
  volver de segundo plano; enganchar el repo en `clearAll` / `wipeLocalUserData`.

### Paso 5 — UI (discreta)
- Pantalla-inventario `appointments_screen.dart` sobre `SettingsPageLayout`: semáforo
  arriba + secciones *Por sacar · Agendadas · Historial*; alta en dos modos; acciones.
  Ruta en el router **sin** destino de navegación inferior.
- Fila `_MenuTile` "Mis citas" en `profile_screen.dart`.
- Tarjeta condicional `appointments_dashboard_card.dart` que solo se pinta si hay algo
  próximo o vencido.
- (Detalle visual completo en `docs/citas-medicas-prompt-ui.md`.)

### Paso 6 — Localización y tests
- Claves nuevas en los 5 `app_*.arb` + regenerar `app_localizations*`.
- Tests de dominio espejo de `test/features/medications/`:
  `appointment_status_service_test.dart`, `appointment_compliance_service_test.dart`,
  `appointment_scheduler_test.dart`, `appointments_controller_test.dart`.

## Decisiones confirmadas
- **Alcance:** Fase 1 completa (inventario + agendadas + por sacar + recurrencia
  automática + notificaciones + tarjeta en dashboard + índice básico).
- **Ubicación:** "Mis citas" en Perfil **y** tarjeta condicional en el dashboard.
- **Recurrencia:** solo por meses (`interval_months`); sin semanas/días.
- **Índice:** semáforo simple (verde/ámbar/rojo por nº de vencidas + próxima acción);
  métricas numéricas detalladas para Fase 2.

## Verificación
- `flutter analyze` limpio y `flutter test` verde (con los nuevos tests de dominio).
- Manual: cita "por sacar" recurrente cada 3 meses → "ya asistí" → se genera la
  siguiente `toBook` a +3 meses; cita agendada → aparece la tarjeta del dashboard y se
  programan avisos (en dispositivo; web es no-op); "Mis citas" abre desde Perfil; el
  dashboard queda limpio sin pendientes.
- Regresión: cerrar sesión vacía la tabla `appointments`.
