# Documentación — índice y por dónde empezar

La documentación de la app vive en el `README.md` de la raíz (cómo es), el `ESTADO.md` (cómo está)
y esta carpeta `docs/`. Esta página es el punto de entrada.

## ¿Por dónde empiezo?

**"Quiero entender qué es la app y cómo está hecha"**
1. [`../README.md`](../README.md) — qué incluye, plataforma, arquitectura (feature-first + provider +
   go_router), persistencia (SQLite v5), integración con la API y funcionalidades.

**"Quiero ejecutarla"**
- Sección *4. Puesta en marcha* del [`../README.md`](../README.md):
  `flutter run --dart-define=API_BASE_URL=http://localhost:8081` (con la HealthTracker-Api arriba).

**"Quiero ver la demostración"**
- [`../DEMO.md`](../DEMO.md) — el modo demostración (persona de ejemplo, base sembrada, recorrido).

**"Voy a tocar el sistema de temas"**
- [`../lib/core/theme/README.md`](../lib/core/theme/README.md) — el vocabulario de tokens y el
  contrato semántico (verificado por `semantic_contract_test.dart`).

**"¿En qué estado está / qué falta para publicar?"**
- [`../ESTADO.md`](../ESTADO.md) — qué funciona, qué falta, trampas y **camino a producción**.
- `healthtracker-localdev/ESTADO-Y-PLAN.md` — el plan por fases del ecosistema (fuente única).

## Inventario

| Documento | Qué es | Estado |
|---|---|---|
| [`../README.md`](../README.md) | Cómo es la app: arquitectura, API, funcionalidades | Vigente |
| [`../ESTADO.md`](../ESTADO.md) | Cómo está + camino a producción | Vigente |
| [`../DEMO.md`](../DEMO.md) | Modo demostración | Vigente |
| [`../lib/core/theme/README.md`](../lib/core/theme/README.md) | Sistema de temas / contrato semántico | Vigente |
| [`citas-medicas-analisis.md`](citas-medicas-analisis.md) · [`…-plan-implementacion.md`](citas-medicas-plan-implementacion.md) · [`…-estado.md`](citas-medicas-estado.md) · [`…-prompt-ui.md`](citas-medicas-prompt-ui.md) | Análisis/plan del módulo de Citas | **Histórico (superado)** — el módulo ya está en `lib/features/appointments/` |

## Convenciones

- El **`README.md`** describe «cómo es» (estable); **`ESTADO.md`**, «cómo está» (cambia a menudo).
- Los documentos `citas-medicas-*` son **históricos**: se conservan como referencia del diseño
  previo, no describen el estado actual (el módulo ya está implementado y probado).
- El estado y el plan del ecosistema viven en `ESTADO-Y-PLAN.md` (localdev), no aquí.
