# Citas médicas — Análisis y propuesta de diseño

> Documento de análisis previo a la implementación. Hermano del trabajo de
> medicamentos (`claude/medication-reminder-planning-h7n7kl`), pero deliberadamente
> **más ligero y discreto**: las citas no serán un módulo con destino propio en la
> navegación principal, sino una capa presente pero sin peso, que recuerde al
> paciente qué citas tiene y cuáles debe sacar, y que lleve un índice de
> cumplimiento.

---

## 1. La idea en una frase

Un **inventario personal de citas médicas** con dos caras:

- **Citas que ya tengo** (fecha y hora concretas) → recordarme antes de que lleguen.
- **Citas que debo sacar** (sé que las necesito, pero aún no las he pedido) →
  recordarme que las agende, con la periodicidad que corresponda.

Y sobre ese inventario, un **índice de cumplimiento**: ¿estoy asistiendo y
renovando mis controles a tiempo, o se me están acumulando citas vencidas?

Ejemplos del usuario, traducidos al modelo:

| Caso real | Tipo | Comportamiento |
|---|---|---|
| "Control con el endocrino cada 3 meses" | **Recurrente por sacar** (recall) | Cuando confirmo que asistí, se programa sola la siguiente "por sacar" a +3 meses. |
| "Necesito neuropsicología, pero recuérdamelo dentro de un mes" | **Puntual por sacar** (diferida) | Un solo recordatorio en la fecha objetivo: "ya es momento de pedir esta cita". |
| "Tengo cita el 20 a las 10:00 con cardiología" | **Agendada** | Avisos 24 h / 1 h antes; luego confirmo si asistí. |

---

## 2. Qué hay hoy en el mercado (y el hueco que llenamos)

La búsqueda de mercado deja una conclusión nítida: **casi todo lo que existe es
del lado de la clínica, no del paciente.** Los productos líderes
—[DoctorConnect](https://doctorconnect.net/best-medical-appointment-reminders-2026/),
[GoReminders](https://www.goreminders.com/doctor-appointment-reminders),
[Booknetic](https://www.booknetic.com/blog/doctors-appointment-reminder-software),
Acuity— son herramientas para consultorios que quieren **reducir las
inasistencias (no-shows)** enviando SMS/email/WhatsApp a sus pacientes, con
integración a sistemas EHR. Útiles, pero es el consultorio quien manda el
recordatorio, y solo de las citas que *ya existen en su agenda*.

Del lado del paciente, la gente termina improvisando con herramientas genéricas
—[Apple Reminders / Google Calendar](https://www.yougot.ai/blog/technology/app-comparisons/best-app-for-remembering-doctor-appointments),
[Any.do](https://www.any.do/reminders/),
[YouGot](https://www.yougot.ai/blog/health/wellness-habits/doctor-appointment-reminder-app)—
con recordatorios recurrentes tipo "cada 6 meses agendar limpieza dental". Sirven,
pero no saben nada de salud: no distinguen una cita agendada de una que hay que
sacar, no llevan un historial de cumplimiento, ni entienden "control trimestral
con especialista".

El concepto clínico que describe exactamente lo que el usuario pide tiene nombre
propio: **recall systems** y **care-gap reminders**
([AHRQ](https://www.ahrq.gov/cahps/quality-improvement/improvement-guide/6-strategies-for-improving/health-promotion-education/strategy6r-reminder-systems.html),
[Bridge](https://www.bridgeinteract.io/patient-recall-care-gap-messaging/)) — recordar
al paciente los controles preventivos y seguimientos *que le tocan según el tiempo
transcurrido desde la última visita*. Hoy eso vive dentro del EHR del consultorio.

**El hueco, y nuestra oportunidad:** un recall system *que vive con el paciente*,
no con una clínica. Como MyVitals ya es la app donde el paciente guarda sus signos
y su historial, es el lugar natural para que también sepa "estas son las citas que
tengo, estas las que debo sacar, y así voy de cumplimiento". Nadie del lado del
paciente lo está haciendo bien; casi todos venden a la clínica.

> Nota de diseño (buenas prácticas del mercado que sí adoptamos): los mejores
> recordatorios avisan en **varios puntos** (p. ej. 24 h y 1 h antes) y
> **explican el porqué** de la cita, no solo la fecha — eso aumenta la
> probabilidad de que el paciente actúe.

---

## 3. El modelo mental: el ciclo de vida de una cita

La pieza central del diseño es tratar cada cita como una entidad con **estado**,
no como una simple fecha en el calendario. Una cita se mueve por esta máquina de
estados:

```
                 (la creo como "algún día
                  necesito esta cita")
                          │
                          ▼
   ┌───────────────► POR SACAR ──────────────────┐
   │   (recall)    (dueToBookOn = fecha objetivo) │  la agendo
   │                        │                     ▼
   │                        │                  AGENDADA
   │                        │            (scheduledAt = fecha/hora)
   │                        │                     │
   │              (nunca la saqué                 │  llega el día
   │               y venció el plazo)             ▼
   │                        │              ┌──── ¿fui? ────┐
   │                        ▼              ▼               ▼
   │                    VENCIDA         ASISTÍ          NO ASISTÍ
   │                  (overdue)        (attended)       (missed)
   │                                      │               │
   └──────────────────────────────────────┘◄──────────────┘
      si es recurrente (cada N meses), al marcar ASISTÍ o NO ASISTÍ
      se genera automáticamente la SIGUIENTE "POR SACAR" a +N meses.
```

Estados (propuestos como enum estable por `name`, igual que en medicamentos):

- **`toBook`** (por sacar) — sé que la necesito; tiene una **fecha objetivo para
  agendarla** (`dueToBookOn`). Ej: neuropsicología "dentro de un mes".
- **`scheduled`** (agendada) — ya tiene **fecha y hora** (`scheduledAt`), con
  especialista/lugar opcionales.
- **`attended`** (asistí) — confirmé que fui. Cierra la ocurrencia.
- **`missed`** (no asistí / la perdí).
- **`overdue`** — *derivado, no se guarda*: una `toBook` cuya `dueToBookOn` ya
  pasó, o una `scheduled` cuyo `scheduledAt` pasó sin confirmar. Se calcula al
  vuelo, como en medicamentos se calcula "toma pendiente".
- **`cancelled`** (opcional) — la anulé.

**La recurrencia es la clave del "inventario que se mantiene solo":** una cita
recurrente (endocrino cada 3 meses) guarda su intervalo. Cuando el usuario marca
`attended`, el sistema **cierra esa ocurrencia y crea la siguiente `toBook`** con
`dueToBookOn = fecha de asistencia + intervalo` (menos, si se quiere, unos días de
antelación para pedir cupo). Así el usuario nunca vuelve a acordarse manualmente:
asiste, confirma, y la app ya sabe cuándo recordarle sacar la próxima.

> Este patrón "cerrar ocurrencia → materializar la siguiente" es exactamente el
> que el módulo de medicamentos usa para las tomas recurrentes. Reutilizamos la
> idea, no el código de dosis.

---

## 4. El índice de cumplimiento

Lo que el usuario llama "índice de cumplimiento de las citas" es la métrica que
convierte esto de una lista en una herramienta de salud. Propuesta de métricas
(todas calculadas en un servicio de dominio puro, sin tocar UI ni BD, testeable):

- **Tasa de asistencia** = `attended / (attended + missed)` en una ventana móvil
  (p. ej. últimos 12 meses). "Vas al 90% de tus citas."
- **Puntualidad de agendado (recall on-time)** = de las citas `toBook` recurrentes,
  ¿qué porcentaje se agendó **antes** de que su `dueToBookOn` venciera? Mide si el
  paciente se está adelantando o siempre va tarde.
- **Citas vencidas ahora** (`overdue`) — el número que de verdad importa día a día:
  "tienes 2 citas por sacar que ya se pasaron de fecha".
- **Racha / próxima acción** — "próxima cosa que hacer: sacar cita con endocrino
  (vence en 5 días)".

El índice global visible al usuario puede ser un semáforo simple (verde / ámbar /
rojo) alimentado sobre todo por *cuántas citas vencidas tiene*, porque es lo
accionable. El detalle numérico vive un nivel más adentro.

---

## 5. Dónde vive en la app (la parte "discreta")

Requisito explícito del usuario: **no un módulo pesado como medicamentos**, sino
algo *presente pero discreto*. Comparación de opciones:

| Opción | Presencia | Coste | Encaja con "discreto" |
|---|---|---|---|
| Destino propio en la barra inferior | Alta | Alto | ❌ Es justo lo que NO quiere |
| **Tarjeta condicional en el Dashboard** | Media, contextual | Bajo | ✅ |
| **Entrada + sección en Perfil** (junto a "Recordatorios") | Baja, siempre localizable | Bajo | ✅ |
| Solo notificaciones | Muy baja | Muy bajo | ⚠️ Se olvida que existe |

**Recomendación — un enfoque de dos toques, sin barra de navegación nueva:**

1. **Punto de entrada en Perfil.** El usuario ya mencionó el perfil, y ahí ya
   existe la pantalla **"Recordatorios"** (`reminders_screen.dart`) y su
   `RemindersProvider`. Añadimos una fila discreta **"Mis citas"** en el menú de
   perfil, que abre la pantalla-inventario completa (lista por estado: por sacar,
   agendadas, historial + el índice de cumplimiento arriba). Es el hogar estable
   de la función, sin robar espacio en la navegación principal.

2. **Aparición contextual en el Dashboard.** Una **tarjeta que solo aparece cuando
   hay algo que hacer**: una cita en los próximos días, o una cita vencida por
   sacar. Si no hay nada pendiente, la tarjeta no se muestra y el dashboard queda
   igual que hoy. Así "está presente y me recuerda", pero **no ocupa espacio
   cuando no aporta**. Es el mismo principio de las tarjetas condicionales que ya
   usa el dashboard.

3. **Notificaciones locales** como capa siempre-activa (ver §7), para que el
   recordatorio llegue aunque el usuario no abra la app.

4. **Confirmar desde la propia notificación / tarjeta.** Cuando toco el
   recordatorio, la acción principal es un botón grande: **"Ya la saqué"** /
   **"Ya asistí"** / **"Posponer"**. Esto es el "yo pueda confirmarle que ya la
   tomé" que pide el usuario, y es lo que alimenta el índice de cumplimiento.

Resultado: **cero peso visual cuando todo está al día; un empujón claro cuando
algo vence.** Discreto pero presente, exactamente lo pedido.

---

## 6. Modelo de datos propuesto

Alineado 1:1 con las convenciones ya establecidas en el repo (ver
`*_record.dart`, `medication.dart`): `id` TEXT con `Uuid`, fechas ISO-8601,
booleanos como 0/1, `is_synced` para la sincronización futura, enums guardados
por `name`. Nueva versión de esquema en `database_service.dart` (hoy en v3; la
rama de medicamentos la lleva a v4, así que citas sería **v5** — o v4 si se
integra en el mismo salto).

Con **una sola tabla** basta para el MVP (mucho más ligero que las 3 tablas de
medicamentos):

```
CREATE TABLE appointments (
  id                TEXT PRIMARY KEY,
  title             TEXT NOT NULL,       -- "Control endocrino"
  specialty         TEXT,                -- endocrinología, neuropsicología…
  provider          TEXT,                -- médico / IPS / lugar (opcional)
  location          TEXT,                -- dirección o nota (opcional)
  notes             TEXT,

  status            TEXT NOT NULL,       -- toBook | scheduled | attended | missed | cancelled
  scheduled_at      TEXT,               -- fecha/hora si status = scheduled
  due_to_book_on    TEXT,               -- fecha objetivo si status = toBook

  is_recurring      INTEGER NOT NULL DEFAULT 0,
  interval_months   INTEGER,            -- p. ej. 3 para "cada 3 meses"
  lead_days         INTEGER,            -- antelación para el aviso de "sacar"
  series_id         TEXT,               -- agrupa ocurrencias de la misma serie recurrente
  reminder_offsets  TEXT,               -- JSON: minutos antes para avisos (ej. [1440, 60] = 24h y 1h)
  snoozed_until     TEXT,               -- silenciar avisos hasta esta fecha

  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL,
  is_synced         INTEGER NOT NULL DEFAULT 0
);
```

Si más adelante se quiere historial fino de cada asistencia por separado (como
`medication_logs`), se puede añadir una tabla `appointment_events`, pero **no es
necesaria para empezar**: con `series_id` + estados de cada fila se reconstruye el
historial de cumplimiento.

El repositorio hereda de `RecordRepository<Appointment>` igual que
`MedicationRepository` (CRUD, caché en memoria y `is_synced` gratis; solo declara
tabla, mappers, id y orden). Esto es una fracción del código del módulo de
medicamentos.

---

## 7. Estrategia de notificaciones

Aquí **sí conviene reutilizar el patrón ya resuelto** en
`medication_scheduler.dart`, porque el problema es idéntico y ya está bien pensado:

- `flutter_local_notifications` **no sabe repetir "cada 3 meses"**. La solución que
  ya usa medicamentos: programar cada ocurrencia futura como una **notificación
  puntual** dentro de una **ventana móvil** (horizonte de N días) y volver a
  rellenar al abrir la app. Reusamos ese enfoque.
- **Libro de ids persistido** (`SharedPreferences`) para cancelar sin dejar
  notificaciones huérfanas al editar/borrar. Copiamos el patrón; usamos un **rango
  de ids propio** que no choque con los de medicamentos (dosis 200000+, inventario
  800000+) ni con los recordatorios simples (100–999). P. ej. citas 400000+.
- **Función `buildPlan` pura y testeable** que, dado el inventario de citas y la
  fecha actual, devuelve la lista de notificaciones a programar:
  - `scheduled` → avisos en cada `reminder_offset` (24 h y 1 h antes por defecto).
  - `toBook` → un aviso la mañana de `due_to_book_on` ("ya es momento de pedir tu
    cita con…").
  - `overdue` → un recordatorio de re-empuje ("tienes una cita vencida por sacar").
- **`rescheduleAll`** al arrancar la app, al volver de segundo plano y tras
  editar/confirmar — idéntico ciclo que medicamentos.
- **No-op en web** (`kIsWeb`), como ya hace toda la capa de notificaciones.

La notificación lleva un **payload** (`appointment|<id>|<kind>`) para el deep-link:
al tocarla, abre la cita con las acciones "Ya la saqué / Ya asistí / Posponer".

---

## 8. En qué se diferencia (a propósito) del módulo de medicamentos

Para mantenerlo discreto y barato, citas **no** replica el peso de medicamentos:

| Medicamentos | Citas (más ligero) |
|---|---|
| 3 tablas (med, dosis, logs) | **1 tabla** (`appointments`) |
| Pantalla "Hoy" + hub + inventario de stock | Sin stock; **una** pantalla-inventario + tarjeta condicional |
| Controlador orquestador grande | Controlador delgado (o incluso un provider simple) |
| Destino con presencia diaria | **Sin destino en nav**; aparece solo cuando hay algo pendiente |
| Consumo/proyección de inventario físico | "Inventario" = lista de citas por estado (no hay unidades que descontar) |

Lo que **sí** se reutiliza tal cual: el patrón `RecordRepository`, el patrón del
scheduler con libro de ids + ventana móvil, `NotificationService`, y las
convenciones de modelo/BD.

---

## 9. Alcance por fases

**Fase 1 — MVP (lo que resuelve el 90% de lo que pide el usuario):**
- Tabla `appointments` + repositorio + modelo.
- Crear cita en dos modos: "agendada" (con fecha) o "por sacar" (con fecha objetivo).
- Recurrencia mensual simple (cada N meses) con auto-generación de la siguiente al confirmar.
- Pantalla-inventario en Perfil: secciones *Por sacar · Agendadas · Historial*.
- Tarjeta condicional en Dashboard cuando hay algo próximo o vencido.
- Notificaciones (scheduled: 24 h/1 h; toBook: día objetivo) con deep-link a
  "Ya la saqué / Ya asistí / Posponer".
- Índice de cumplimiento básico: nº de vencidas + próxima acción.

**Fase 2 — refinamiento:**
- Índice de cumplimiento completo (tasa de asistencia, on-time de recall) con su tarjetita.
- Localización a los 5 idiomas (`app_*.arb`), como se hizo con medicamentos.
- Integración en el backup/export y en el borrado de datos del paciente (`wipeLocalUserData`).
- Silenciar/posponer avisos; ajustes de antelación por cita.

**Fase 3 — futuro / "conocimiento de las citas":**
- Sugerencias inteligentes de recall a partir del historial y del perfil clínico
  ("hace 4 meses que no ves al endocrino y sueles ir cada 3").
- Vincular una cita con las métricas que se miden en ella (p. ej. la cita del
  endocrino ↔ perfil lipídico), para que MyVitals cierre el círculo entre "me
  controlo" y "voy al control".
- Exportar un resumen de citas al PDF clínico que ya genera la app.

---

## 10. Decisiones abiertas para el usuario

Antes de implementar, conviene cerrar estas preguntas:

1. **Ubicación:** ¿confirmas Perfil (hogar estable) + tarjeta condicional en
   Dashboard? ¿O prefieres que la tarjeta viva en otra parte?
2. **Recurrencia:** ¿basta con "cada N meses", o también quieres "cada N
   semanas/días" y días concretos (como sí tiene medicamentos)?
3. **Antelación por defecto** de los avisos: ¿24 h y 1 h antes para agendadas? ¿Y
   para "por sacar", el mismo día o unos días antes?
4. **Índice de cumplimiento:** ¿lo quieres visible desde el MVP (aunque sea un
   semáforo simple) o lo dejamos para la Fase 2?
5. **Alcance del MVP:** ¿arrancamos con la Fase 1 completa, o primero solo el
   inventario + notificaciones y dejamos la recurrencia automática para después?

---

*Documento de análisis. No incluye implementación; sirve de base para la sesión
que construya la función sobre la rama `claude/medical-appointments-analysis-ov5yfd`.*
