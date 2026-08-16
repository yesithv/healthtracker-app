# Demostración

En la portada, bajo «Iniciar sesión» y «Crear cuenta», hay un enlace: **ver la
demostración**. Abre la app con dos años de historia clínica de un paciente
inventado —perfil, ajustes, objetivos, recordatorios y unos 80 registros— y
deja navegarla entera, registrar y editar. Un aviso permanente arriba recuerda
que son datos de prueba y ofrece la salida, que devuelve a la portada.

Se ve en el **idioma del usuario**, incluidos los comentarios de los registros,
y con el **tema que ya tuviera elegido**: la demo tiene que parecerse a la app
que enseña, no a otra.

## Las dos garantías

Entrar no puede destruir nada de quien abre la demo, y salir devuelve todo como
estaba. Todo lo demás se apoya en esto:

**1. Las preferencias se copian antes de sembrar.** Lo que hubiera —el tema que
eligió, su idioma, un alta a medias— se guarda en un blob y se restaura íntegro
al salir. La demo no «limpia» al terminar: rebobina. Un `clear()` a secas
dejaría al visitante sin sus ajustes.

**2. Los registros van a otra base de datos.** `my-vitals-demo.db` es un archivo
distinto del de producción. Entrar cambia de archivo, salir vuelve al de siempre
y vacía el desechable. El historial real no se abre siquiera mientras dura la
demo — y por eso el visitante puede registrar y editar sin riesgo.

Mientras dura, tampoco sale ninguna petición a la API: la demo tiene sesión
sembrada, pero ese paciente no existe en el servidor.

## Comprobado de punta a punta

Con un usuario que ya tenía tema `consultaSerena` e idioma `pt`:

| | Antes | En demo | Después de salir |
|---|---|---|---|
| Ruta | `/welcome` | `/dashboard` | `/welcome` |
| Tema · idioma | consultaSerena · pt | consultaSerena · pt | consultaSerena · pt |
| Perfil | vacío | Camila Herrera | vacío |
| Panel | sin datos | ~80 registros | sin datos |

Las preferencias antes y después son idénticas byte a byte. El aviso de una sola
vez no vuelve a salir al recargar la página, y la demo sobrevive a un F5 sin
echar al visitante.

## Capturas guionizadas

Para generar capturas sin tocar la pantalla, la app puede arrancar ya dentro de
la demo. Es lo único que sigue siendo bandera de compilación:

```sh
flutter run -d chrome --dart-define=DEMO_MODE=true
```

| Bandera | Valores | Por defecto |
|---|---|---|
| `DEMO_MODE` | `true` | *(arranque normal)* |
| `DEMO_LANG` | `es` · `en` · `de` · `pt` · `it` | el idioma del usuario |
| `DEMO_THEME` | `pulsoClinico` · `consultaSerena` | el tema del usuario |
| `DEMO_UNITS` | `metric` · `imperial` | las del usuario |

Idioma, tema y unidades sólo se imponen si se piden a mano; al entrar desde la
portada nunca se tocan.

```sh
# La misma pantalla, en inglés y con el otro tema
flutter run -d chrome \
  --dart-define=DEMO_MODE=true \
  --dart-define=DEMO_LANG=en \
  --dart-define=DEMO_THEME=consultaSerena
```

## Qué historia cuenta

Camila Herrera, 36 años, 165 cm. Dos años cuidándose, y los datos lo enseñan:

| | Hace dos años | Hoy |
|---|---|---|
| Peso · IMC | 80,5 kg · 29,6 *(sobrepeso)* | 63,5 kg · 23,3 *(normal)* |
| Tensión | 134/86 *(elevada)* | 114/74 *(normal)* |
| Pulso en reposo | 76 lpm | 64 lpm |
| Colesterol total · LDL · HDL | 230 · 150 · 42 | 181 · 98 · 62 |
| Grasa corporal · visceral | 36,0 % · nivel 10 | 26,0 % · nivel 5 |

Las cadencias son las que recomienda la práctica clínica, no las de un
generador denso: cada examen aparece con la frecuencia con la que un paciente
real se lo hace, contando **hacia atrás desde hoy** —así, si la ventana de dos
años no se llena por tiempo, se llena por número de tomas—:

| Indicador | Cadencia | Tomas (~2 años) |
|---|---|---|
| Peso · IMC | una vez al mes | ~24 |
| Perímetros (cinta) | cada dos o tres meses | ~8 |
| Bioimpedancia | una de cada dos pesajes (~cada 2 meses) | ~13 |
| Analítica lipídica | cada trimestre | 9 |
| Tensión · pulso | una vez al mes | ~24 |

A la tensión se le suma un **tramo de siete días seguidos** de automedición al
principio —los que el médico manda tras encontrarla elevada—, así que la serie
enseña también una racha diaria real. Ninguna toma cae en el mismo día del mes:
cada fecha lleva un desajuste de unos días, porque a una analítica se va cuando
hay cita, no en fechas de reloj. Hay mesetas, algún síntoma suelto y un repunte
cada diciembre, porque una línea perfecta no se parece a nadie.

Los objetivos están puestos **a medias a propósito**: el de peso sigue en curso
(faltan ~1,5 kg) y el de grasa corporal ya está cumplido, para que una sola
pantalla enseñe los dos estados de la interfaz de metas.

La generación es **determinista**: la misma fecha produce los mismos números, así
que una captura repetida semanas después sale idéntica.

## La foto de la usuaria

El avatar de Camila se resuelve en tres peldaños (`DemoSeeder.demoAvatar`), de más a
menos concreto: una **foto real** versionada en `assets/demo/demo_avatar.jpg` si
existe; si no, un **retrato ilustrado** dibujado por código —no es la cara de nadie
real y sale idéntico en cada arranque—; y por último un **monograma** con las
iniciales. Para poner una foto real basta con dejar caer un JPEG cuadrado con licencia
libre en esa ruta y recompilar, sin tocar código; los detalles y la fuente van en
`assets/demo/README.md`.

## Exportar la historia clínica consolidada

Desde la pestaña **Historial**, arriba del todo, hay un botón nuevo: **exportar
la historia clínica completa**. A diferencia del export por indicador —cada uno
saca su tabla en PDF—, éste genera **un único documento** con los cuatro
indicadores para enseñar al médico: una cabecera con la paciente (Camila Herrera,
36 años), un aviso de que son datos autoreportados, un resumen de últimos valores
marcados dentro/fuera de rango, y por indicador su tendencia (gráfica vectorial),
sus estadísticas del periodo y los últimos registros con sus comentarios. Pide
antes el periodo (6 meses / **1 año** / todo).

La demo es el mejor sitio para revisarlo: con los ~80 registros de dos años, la
gráfica de tensión enseña la bajada de 134/86 a 114/74 y la de peso la de 80 a 63
kg. El periodo «todo» es el que más estira el documento (varias páginas), así que
es donde asoman los cortes de página, el pie con numeración y los rangos vacíos.

Sigue el esquema de un *Patient Summary* internacional (ISO 27269 / HL7 FHIR IPS):
la app figura como FUENTE, cada valor lleva su unidad UCUM y su rango de
referencia, y el documento deja claro que no es un diagnóstico. La agregación es
pura y determinista (`lib/core/export/clinical_summary.dart`), separada del
dibujo del PDF (`lib/core/export/medical_history_pdf.dart`), así que se comprueba
desde `test/core/export/` igual que el resto de la demo.

## Cómo está montado

```
lib/core/demo/
  demo_mode.dart      Banderas de compilación. Sólo el arranque guionizado.
  demo_session.dart   El interruptor: entrar, salir, copia y vuelta atrás.
  demo_dataset.dart   Genera los registros. Puro: ni disco, ni red, ni reloj.
  demo_seeder.dart    Qué perfil y qué ajustes tiene el personaje, y su avatar.
  demo_actions.dart   Entrar/salir desde la interfaz (recarga providers, navega).
lib/core/widgets/
  demo_banner.dart    El aviso permanente y la salida.
```

`demo_dataset.dart` no toca nada de fuera, y por eso se puede comprobar entero
desde una prueba unitaria. `test/core/demo/` vigila lo que estas piezas rompen
con facilidad: que los valores sean posibles, que las familias no se contradigan
(el IMC sale del peso y la talla, el VLDL de los triglicéridos, los kg de músculo
del peso de ese día), que el resultado no cambie entre ejecuciones, que la
siembra siga encajando con lo que leen los providers, y que la vuelta atrás no
pierda el tipo de una preferencia — JSON no distingue un `int` de un `double`
entero, y `SharedPreferences` sí.

```sh
flutter test test/core/demo/
```

## Sobre la cuenta obligatoria

La cuenta sigue siendo obligatoria **para usar** la app. Esta tercera vía no es
el antiguo «explorar sin cuenta» que se eliminó: aquélla dejaba llevar mediciones
propias sin registrarse, ésta abre la historia de alguien que no existe, marcada
como tal con un aviso que no se puede cerrar y borrada al salir. Es un escaparate,
no un modo de uso.

## Límites conocidos, ya resueltos

Dos límites que arrastraba la app real —y que la demo dejaba a la vista— ya están
corregidos:

- **Las gráficas ignoraban el filtro de tiempo.** Los cuatro `*_history_tab.dart`
  recortaban a los últimos 6 registros (`recentRecords`), sea cual fuera el filtro,
  así que «Siempre» enseñaba una línea plana reciente en vez de la mejora de dos
  años. Ahora usan un muestreo uniforme de toda la serie filtrada
  (`lib/core/charts/chart_series.dart`, que conserva el primer y el último punto) y
  el eje X lleva fechas con año cuando el rango lo pide.
- **La tarjeta de «Progreso de Autocuidado» estaba escrita a mano.** Enseñaba nivel
  1 y casi todo bloqueado aunque hubiera dos años de historia detrás. Ahora el
  nivel, la barra y las medallas se calculan desde los registros
  (`lib/features/profile/data/profile_achievements.dart`); con ~80 registros y el
  tramo de siete días de automedición, el personaje llega al nivel 4 («constante»)
  con las seis medallas ganadas.
