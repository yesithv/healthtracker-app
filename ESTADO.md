# Estado de este repositorio

> Actualizado el **04-sep-2026**. El README describe cómo es la app; esto describe **cómo está**, y
> cambia mucho más a menudo.
>
> El estado del ecosistema entero vive en `healthtracker-localdev/ESTADO-Y-PLAN.md`.

## Qué es esto y con quién habla

La app del paciente: donde registra sus mediciones, ve su historia y consulta lo que la clínica
tiene de él. Es **local primero** —todo se guarda en SQLite del teléfono y se sincroniza después—
para que funcione sin cobertura, que es la mitad del tiempo en una consulta.

```
  App Flutter ──► App-Api ──► PostgreSQL
       │
       └── SQLite local: lo que se registra vive aquí antes de subir
```

**Solo habla con la App-Api.** Ni con el BackOffice, ni con la ACL, ni con el legacy.

## Qué funciona hoy

| Qué | Estado | Comprobado con |
|---|---|---|
| Entrar con el código de seis dígitos que dicta la clínica | Funciona | Recorrido de punta a punta con datos reales |
| Alta por correo para quien no viene del legacy | Funciona | Recorrido (Fase 3) |
| Registrar las cuatro familias: antropometría, signos vitales, lípidos, composición corporal | Local + subida | Prueba de guardado extremo a extremo por pantalla (Fase 5) |
| Histórico y gráficas, con lo migrado del legacy y lo propio | Funciona | Reinstalar ya no cuesta el historial (Fase 5) |
| Perfil en el servidor: datos, metas, idioma y unidades | Funciona | Fase 4 |
| Rangos de referencia, laboratorios, báscula, Descubre | Contra la API real | Fase 12: los umbrales salen **solo** de la base; sin bandas del servidor la grasa se enseña sin veredicto, y la báscula se pregunta al entrar |
| Exportación: PDF de historia, copia local reimportable, volcado del habeas data | Tres caminos que no se solapan | Fase 5. En la Fase 12 el volcado del servidor pasó a traer también términos, consentimientos y metas, y el texto del botón dejó de prometer «todo» |
| Términos y privacidad en cinco idiomas, con gate para quien no haya aceptado la vigente | Funciona | Fase 7 |
| Canales de contacto editables por el paciente, anotados como decisión suya | Funciona | Fase 7 |
| **Frescura de la historia clínica**: dice hasta cuándo llegan los datos de la clínica y avisa a los dos días | Funciona | Fase 9. Solo para pacientes migrados |
| Borrar la cuenta | Funciona | Anonimiza sin tocar el legacy; desde la Fase 11 también borra el correo |

**668 pruebas** en verde. Cinco idiomas: es, en, pt, it, de.

## Qué falta

| Qué | A quién bloquea |
|---|---|
| **Nada de la publicación está hecho**: `applicationId`, firma de release, pipeline móvil ni ficha de tienda. Es la Fase 13 | A poner esto en manos de nadie |
| **Los textos legales son borradores pendientes de abogado.** Describen con precisión lo que el sistema hace, pero llevan marcados los puntos que exigen una decisión jurídica: responsable del tratamiento, plazos de conservación, encargados, canal de PQR y ley aplicable. **No deben publicarse así** | A la publicación |
| La foto de perfil se pierde al reinstalar: es lo único del perfil que no está en el servidor | Al paciente que reinstala |
| Cambiar el correo de la cuenta no existe | A quien cambie de dirección |

## Cómo se levanta y cómo se prueba

```bash
flutter pub get
flutter test                    # 653 pruebas, sin servidor
flutter run                     # contra la API que diga ApiConfig
```

Con el ecosistema levantado (`../healthtracker-localdev/scripts/stack.sh up`), la app apunta a la
App-Api en `:8081`. Para ver los caminos del servidor sin la app, `./scripts/smoke.sh` los recorre
por HTTP.

## Las trampas de este repositorio

**Las pruebas de widget necesitan el mock de `path_provider`.** Sin él la prueba se queda colgada
**sin decir nada**: ni error, ni fallo, ni salida. Es el síntoma más desconcertante de este
repositorio y ya costó dos sesiones. Si una prueba nueva no imprime nada, es esto.

**`await provider.ready` dentro de un `testWidgets` no se resuelve.** El reloj falso de
`testWidgets` no hace avanzar el canal nativo, así que la espera nunca termina. Esa comprobación va
en un `test()` normal.

**La app es local primero, y eso cambia qué prueba cada cosa.** Que una medición aparezca en
pantalla no significa que haya subido: significa que está en SQLite. Lo que prueba la subida es
que el servidor la devuelva después, y eso es una prueba de integración del servidor, no de aquí.

**`hydrateIdentity` solo rellena huecos; `setClinicDataSyncedAt` siempre pisa.** No es un descuido:
el perfil lo manda el teléfono —es donde la persona escribe— pero la fecha de la clínica la manda
el servidor. Si esa fecha no se sobrescribiera al llegar `null`, una fecha vieja guardada seguiría
afirmando que la historia está más al día de lo que está.

**El nombre no se manda si la persona no lo ha tocado.** La app guarda un único campo de nombre y
al enviarlo hay que partirlo por el primer espacio; para «María del Carmen / Gómez Pérez» esa
partida no coincide con la del legacy, y mandarla sin que nadie haya cambiado nada reescribiría su
ficha clínica sola.

**Los cinco ARB tienen que decir lo mismo.** `legal_claims_test.dart` comprueba que ninguno afirme
cosas que el sistema no hace; ya cazó dos afirmaciones falsas sobre privacidad que llevaban meses
traducidas a cinco idiomas.

**Y no basta con no mentir: tampoco se puede prometer de más.** El botón «Descargar todos mis
datos» decía «todo lo que la clínica guarda sobre ti», y el volcado del servidor no lleva las notas
que el personal escribe sobre el paciente, ni el relato clínico de sus consultas anteriores —de
esas salen las mediciones curadas—, ni el rastro de auditoría, que contiene accesos de otras
personas. Son exclusiones deliberadas y la política las nombra una a una; `legal_claims_test.dart`
rechaza desde la Fase 12 el «todo» en `serverExportSubtitle`, en los cinco idiomas.

**Los umbrales clínicos no se escriben aquí.** Viven en la base, se administran desde el backoffice
y llegan resueltos por `GET /me/reference-ranges` —el servidor ya eligió báscula, sexo y edad—. La
app solo pinta. Quedaban unos cortes de fábrica «por si acaso» en `health_classifiers.dart`, y el de
**grasa corporal** era ciego a los tres: para una mujer de 36 decía «elevada» en un 26 % que su
clínica considera **normal** (su banda llega a 32.9). Desde la Fase 12 ese indicador **no clasifica
sin bandas del servidor**: se enseña el número sin color. Un ámbar equivocado engaña; un número no.

Los que **sí** conservan respaldo son los que no dependen de nadie: IMC (OMS), WHtR (Ashwell), WHR
(OMS) y grasa visceral (escala de la báscula, idéntica a la base). Si añades otro respaldo, la
pregunta es esa: ¿depende de sexo, edad o instrumento? Si sí, no lo pongas.

**La báscula es la que decide qué rangos recibes.** `MeasuringDeviceProvider.shouldPrompt` llevaba
desde siempre documentado como «debe preguntarse en el onboarding» y **no lo leía ninguna pantalla**:
solo se llegaba a esa pantalla entrando a mano en Perfil. El resultado, medido en el banco, era **42
pacientes de 42 sin elegir** y sin rangos de grasa, músculo ni visceral. Ahora `completeLoginAndEnter`
—la única puerta de entrada— pregunta después de los términos, y la pantalla legal recibe a dónde
seguir para que aceptar no se salte el paso.

**Los rangos de la demo son una copia, y las copias se separan.** `demo_reference_ranges.dart` lleva
las cifras congeladas de la persona de la demostración porque la demo corre sin servidor. No se
escriben a mano: salen del fixture, y `check-demo-ranges.sh` en `healthtracker-localdev` los compara
contra la base. Ojo con la edad: esa persona nació en 1990, así que **en 2030 cruza al tramo 40-59**
y sus cifras dejarían de ser suyas; la prueba falla ese día y lo dice.
