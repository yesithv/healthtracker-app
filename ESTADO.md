# Estado de este repositorio

> Actualizado el **31-ago-2026**. El README describe cómo es la app; esto describe **cómo está**, y
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
| Rangos de referencia, laboratorios, báscula, Descubre | Contra la API real | |
| Exportación: PDF de historia, copia local reimportable, volcado del habeas data | Tres caminos que no se solapan | Fase 5 |
| Términos y privacidad en cinco idiomas, con gate para quien no haya aceptado la vigente | Funciona | Fase 7 |
| Canales de contacto editables por el paciente, anotados como decisión suya | Funciona | Fase 7 |
| **Frescura de la historia clínica**: dice hasta cuándo llegan los datos de la clínica y avisa a los dos días | Funciona | Fase 9. Solo para pacientes migrados |
| Borrar la cuenta | Funciona | Anonimiza sin tocar el legacy; desde la Fase 11 también borra el correo |

**653 pruebas** en verde. Cinco idiomas: es, en, pt, it, de.

## Qué falta

| Qué | A quién bloquea |
|---|---|
| **Nada de la publicación está hecho**: `applicationId`, firma de release, pipeline móvil ni ficha de tienda. Es la Fase 12 | A poner esto en manos de nadie |
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
