# Sistema de temas

Prueba de concepto de temas seleccionables por el usuario. Un tema cambia
**colores y tipografía**; no cambia la navegación, los iconos, la maqueta ni el
significado de ningún color.

## Por qué cambiar de tema no cuelga la app

Un cambio de tema es **un repintado, no una recarga**. La secuencia completa es:

1. `ThemeProvider` cambia un enum y notifica.
2. `MyVitalsApp` —el **único** widget suscrito— reconstruye `MaterialApp`.
3. `MaterialApp` recibe otra `ThemeData` y el `InheritedWidget` de `Theme`
   invalida a quien la lea.
4. Los widgets se repintan con los tokens nuevos.

Ni se recrea el árbol, ni se vuelve a medir la maqueta, ni se toca la base de
datos, ni hay E/S en el camino. Las tres decisiones que lo sostienen:

- **`ThemeData` memoizada** (`AppThemeCatalog.themeOf`). `ColorScheme.fromSeed`
  deriva la rampa tonal con aritmética en espacio HCT; se hace una vez por tema
  y se guarda. Un test comprueba que dos llamadas devuelven la misma instancia.
- **Fuentes empaquetadas**, no descargadas. Antes se resolvía Inter por red con
  `google_fonts`: la primera vez había que bajarla, así que cambiar de tema
  podía provocar un parpadeo de fuente —o fallar sin conexión—. Ahora los `.ttf`
  viajan en el binario (~2 MB) y el cambio es determinista y funciona offline.
- **Nadie escucha al provider.** Las pantallas leen `Theme.of(context)`, que es
  una búsqueda O(1). Si una pantalla hiciera `watch` sobre `ThemeProvider`, se
  reconstruiría entera sin necesidad.

La preferencia se lee **antes de `runApp`**, para que el primer frame ya salga
vestido y no haya un destello del tema por defecto en cada arranque.

## Los colores siguen significando lo mismo

Dos vocabularios, y ninguno depende del tema:

- **`ClinicalStatus`** — `info` · `optimal` · `caution` · `alert` · `neutral`.
  Qué tan bien está un valor.
- **`MetricFamily`** — `vitals` · `anthropometry` · `lipids` ·
  `bodyComposition`. De qué indicador hablamos.

El reparto de responsabilidades es el punto entero:

| Quién | Decide |
|---|---|
| `core/utils/health_classifiers.dart` | Si 128/84 es «elevada». Criterio clínico, viene de los rangos del backoffice. |
| El tema | Con qué ámbar exacto se pinta «elevada». |

Un tema **no puede** decidir que «óptimo» sea morado, ni apagar el ámbar a gris,
ni dejar una insignia por debajo del contraste AA.
`test/core/theme/semantic_contract_test.dart` lo verifica sobre todos los temas
del catálogo —franja de matiz, saturación mínima, separación entre familias y
contraste en los tres fondos posibles— y el build falla si un tema lo incumple.
Añadir un tema lo somete automáticamente a todas las reglas.

## Anatomía

```
core/theme/
├── theme_catalog.dart        Registro de temas + ThemeData memoizada
├── theme_context.dart        Theme.of(context).surfaces / .clinical / .metrics / .type
├── semantic_contract.dart    Las reglas, como aritmética comprobable
├── app_theme.dart            Fachada obsoleta (pantallas sin migrar)
├── tokens/
│   ├── tone.dart             accent + surface + onAccent, y BadgeIdiom
│   ├── clinical_palette.dart ClinicalStatus → Tone
│   ├── metric_palette.dart   MetricFamily → Tone
│   ├── app_surfaces.dart     Lienzo, tarjeta, tinta, radios, idiomas
│   └── app_typography.dart   Roles: numeral, sectionLabel, meta…
└── themes/
    ├── pulso_clinico.dart    Azul clínico, denso, insignias sólidas
    ├── consulta_serena.dart  Lienzo cálido, serif, insignias suaves
    └── type_scale.dart       Escala y pesos de fuente variable
```

## Cómo se usa

```dart
final theme = Theme.of(context);      // una vez por build, no veinte

theme.surfaces.card                   // superficies y forma
theme.type.numeral                    // roles tipográficos
theme.clinical.tone(cat.status)       // estado clínico → color
theme.metrics.tone(MetricFamily.vitals)  // identidad del indicador
```

Reglas:

- **Nunca** escribas un `Color(0xFF…)` en una pantalla. Si no hay token para lo
  que necesitas, el token es lo que falta.
- **Nunca** preguntes qué tema está activo. Si el comportamiento debe cambiar
  entre temas, eso es un token (así nacieron `badgeIdiom` y `monitorBezel`).
- Para un estado clínico usa `StatusChip`, que ya resuelve el idioma del tema.
- El color nunca va solo: acompáñalo de forma, icono o texto.

## Añadir un tema

1. Crea `themes/mi_tema.dart` con las cuatro extensiones.
2. Añade el valor a `AppThemeId` y su ficha a `AppThemeCatalog.specs`.
3. `flutter test`. El contrato semántico dirá qué falta.

No hace falta tocar ninguna pantalla, ni la ficha del selector: el muestrario se
dibuja **dentro** del tema que describe y sus colores se leen de los propios
tokens, así que no puede desincronizarse.

## Estado de la migración

Migrado: arranque, asistente de alta (3 pasos), panel y los widgets compartidos
que usan (`ActionButton`, `StatusChip`, `BmiStatusBadge`, `MainAppBar`,
`DashedBorderContainer`, `ProfileSettingsLayout`…).

Sin migrar: historial, Descubre, perfil y ajustes — siguen con colores escritos
a mano y se ven igual en ambos temas. **`WelcomeScreen` es la costura visible**:
está en medio del flujo de un usuario nuevo y sigue en azul fijo.

La migración es incremental a propósito: había ~1.160 colores a mano repartidos
por la app, y hacerlo de golpe garantizaba dejar media interfaz a medias. Al
migrar una pantalla, sustituye `AppTheme.primaryColor` por el token que toque y
borra el import; cuando no queden usos, `app_theme.dart` desaparece.
