# Prompt — Diseño de UI/UX del inventario de citas médicas (MyVitals)

> Prompt autocontenido, listo para pegar en una sesión nueva que diseñe o
> construya la interfaz de la función de citas médicas. Contexto completo en
> `docs/citas-medicas-analisis.md` y `docs/citas-medicas-plan-implementacion.md`.

---

Eres un diseñador/desarrollador de Flutter trabajando en la app MyVitals
(`myvitals_healthtracker_app`), una app de salud del lado del paciente. Vas a
diseñar la interfaz de una nueva capa **ligera y discreta** de "Citas médicas".
NO es un módulo pesado ni un destino en la barra de navegación inferior. Lee
primero `docs/citas-medicas-analisis.md` y `docs/citas-medicas-plan-implementacion.md`.

## Regla de oro
Cero peso visual cuando todo está al día; un empujón claro cuando algo vence.
Presente pero discreto.

## Reutiliza el sistema de diseño existente (no inventes uno nuevo)
- Tema y tokens: `lib/core/theme/` (tokens de color/tipografía, `Tone`,
  `ContentPalette`, `SettingsSection`/`settings_accent.dart`). Respeta claro y oscuro.
- Tipografías empaquetadas (Newsreader/Inter) vía los estilos del tema; no uses
  fuentes nuevas.
- Patrones de pantalla ya existentes a imitar:
  - Menú de perfil y filas: `_MenuTile` en
    `features/profile/presentation/screens/profile_screen.dart`.
  - Encabezado/estructura de subpantallas: `SettingsPageLayout` /
    `SettingsPageHeader` (`lib/core/widgets/`).
  - Tarjetas del dashboard: `features/dashboard/presentation/widgets/*_card.dart`.
- Localización en 5 idiomas: toda cadena visible como clave en `lib/l10n/app_*.arb`
  (es/en/it/pt/de). Nada de texto hardcodeado.

## Pantallas y componentes a diseñar

### 1. Entrada en Perfil — fila "Mis citas"
Una fila `_MenuTile` con ícono (p. ej. `Icons.event_available_outlined`) y su acento
de `SettingsSection`, que abre la pantalla-inventario. Nada más en el nivel de perfil.

### 2. Pantalla-inventario "Mis citas" (sobre `SettingsPageLayout`)
De arriba a abajo:
- **Semáforo de cumplimiento** (verde/ámbar/rojo) + una línea de "próxima acción"
  ("Saca tu cita con endocrino — vence en 5 días"). El color lo manda sobre todo el
  nº de citas vencidas. Discreto: una tarjetita, no un dashboard.
- **Sección "Por sacar"** (recall): cada ítem muestra título/especialidad y su fecha
  objetivo; los vencidos se resaltan (chip "Vencida"). Acción principal por ítem:
  **"Ya la saqué"** (pasa a agendada, pide fecha) y **"Posponer"**.
- **Sección "Agendadas"**: fecha y hora, especialista/lugar. Acción al pasar la
  fecha: **"Ya asistí"** / **"No asistí"**.
- **Sección "Historial"**: citas cerradas (asistí/no asistí), colapsable.
- **FAB / botón "Añadir cita"** que abre el alta en dos modos (ver #4).

### 3. Tarjeta condicional en el Dashboard
Un widget que SOLO se pinta si hay algo próximo (agendada en pocos días) o algo
vencido (por sacar pasada de fecha). Si no hay nada, no renderiza (no ocupa espacio).
Muestra la cosa más urgente + acción rápida ("Ya la saqué" / "Ya asistí"). Estilo
coherente con las tarjetas del dashboard existentes.

### 4. Hoja/pantalla de alta de cita (dos modos, un solo formulario)
- Selector de modo: **"Ya tengo fecha"** (agendada) vs **"Debo sacarla"** (por sacar).
  - Agendada → fecha + hora, especialidad, médico/lugar (opcionales), notas.
  - Por sacar → fecha objetivo para agendarla, especialidad, notas.
- Toggle **"Es un control periódico"** → si se activa, campo "cada N meses"
  (solo meses; ej. 3). Explica en una línea: "Al confirmar que asististe, te
  recordaremos sacar la siguiente automáticamente".
- Antelación de avisos con valores por defecto sensatos (agendada: 24 h y 1 h antes).

### 5. Confirmación desde notificación/tarjeta
Al tocar un recordatorio, la acción principal es un botón grande y claro:
**"Ya la saqué"** / **"Ya asistí"** / **"Posponer"**. Esto es lo que alimenta el
índice de cumplimiento; hazlo de un toque.

## Estados a cubrir en cada vista
`toBook` (por sacar), `scheduled` (agendada), `attended`, `missed`, y el derivado
`overdue` (resaltado). Estados vacíos amables ("No tienes citas pendientes 🎉").
Cuando una cita recurrente se marca asistida, refleja visualmente que se creó la
siguiente "por sacar".

## Entregable
Mockups o widgets Flutter de: fila en Perfil, pantalla-inventario con sus 3 secciones
+ semáforo, tarjeta condicional del dashboard, hoja de alta en dos modos, y las
acciones de confirmación. Todo con soporte claro/oscuro, los 5 idiomas y reutilizando
tokens/patrones existentes. Accesible (tamaños de toque, contraste).
