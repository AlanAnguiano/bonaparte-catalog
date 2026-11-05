# Decisiones técnicas — Bonaparte Catalog Challenge

Documento de arquitectura y decisiones para el challenge de Bonaparte.

No describe implementación detallada. Explica las alternativas consideradas, para qué sirve cada una, y por qué elegimos la arquitectura actual.

---

## 1. Contexto

El challenge pide una aplicación Ruby on Rails que:

1. Lea `data/data_prueba_técnica.xlsx` (5 productos de origen).
2. Enriquecer esos productos con aplicaciones, intercambios, atributos y clasificación de catálogo.
3. Exporte un Excel con la misma estructura que `data/ejemplo_prueba_técnica.xlsx`.
4. Sea **reproducible**: importar el mismo Excel N veces debe producir el mismo resultado lógico.

Restricciones que condicionan la arquitectura:

- Es un **challenge de trabajo**, no un producto en producción.
- No debe generar **costos** (APIs de pago, LLM de pago, infra innecesaria).
- `ejemplo_prueba_técnica.xlsx` es solo el **contrato de forma** del entregable. **No** es fuente de verdad ni dataset de enriquecimiento.
- No inventar fitment, intercambios ni atributos sin evidencia.

---

## 2. Las dos arquitecturas consideradas

### Arquitectura A — Pipeline determinista con evidencia congelada

Pensada como solución proporcional al challenge.

```text
Excel de entrada
    → Import + validación
    → Normalización local
    → Resolve contra evidence/ versionada en el repo
    → Validación
    → Export Excel (forma del ejemplo)
```

Características:

- La investigación ocurre **fuera** del import (manual o semi-asistida, una sola vez).
- Los hechos verificados viven en un snapshot versionado (`evidence/` u equivalente).
- El import es una función casi pura:

  `f(input_excel, evidence_snapshot, rules_version) → output_excel`

- Sin orquestador complejo, sin Redis obligatorio, sin providers en vivo en cada run.
- Export desacoplado de investigación.

**Para qué sirve**

- Demostrar criterio de datos, determinismo y claridad de enfoque.
- Entregar un workbook trazable sin depender de red ni de servicios de pago.
- Explicar con facilidad qué se verificó, qué faltó y por qué.

### Arquitectura B — Plataforma de investigación paralela

Documentada conceptualmente en `.cursor/rules/bonaparte-architecture.mdc`.

```text
Excel → ImportRun
     → ResearchTasks (AI / Web / Catalog providers en paralelo)
     → ResearchResults (staging JSONB)
     → Normalización / Resolución / Validación
     → Catálogo canónico
     → Export
```

Características:

- Orquestador de jobs, estados, reintentos y finalización por condiciones persistidas.
- Providers intercambiables detrás de una interfaz común.
- Staging antes de consolidar; productos originales vs canónicos.
- Pensada para crecer hacia API B2B, reproceso selectivo y muchas fuentes.

**Para qué sirve**

- Un producto real de catalogación a escala.
- Múltiples fuentes concurrentes, fallos parciales y reprocesamiento selectivo.
- Evolución hacia plataforma, no solo un entregable de challenge.

---

## 3. Comparación directa

| Aspecto | A — Pipeline + snapshot | B — Orquestación + providers |
|---|---|---|
| Unidad de trabajo | Input + evidencia versionada → workbook | `ImportRun` que investiga y luego consolida |
| Momento de investigación | Antes / fuera del export | Dentro del run, en paralelo |
| Determinismo | Fuerte por construcción | Solo si toda respuesta externa se congela antes del resolve |
| Costo operativo | Casi cero | Riesgo de APIs, scraping, workers, Redis |
| Complejidad inicial | Baja | Alta (jobs, estados, canónico, UI) |
| Extensibilidad | Interfaces nominales; un adapter basta | Diseñada para muchos providers |
| Encaje con el challenge | Alto | Bajo para el MVP; alto a largo plazo |
| Riesgo principal | Parecer “poco plataforma” si no se documenta bien | Sobre-ingeniería y tiempo perdido en infra |

### Coincidencias (las conservamos)

Ambas coinciden en principios que sí aplican al challenge:

- Separar import, resolución y export.
- No inventar datos; conservar provenance.
- Staging / evidencia intermedia antes de consolidar.
- La IA (si se usara) solo propone candidatos; no es autoridad final.
- Export sin re-investigar.
- Idempotencia y resultados independientes del orden accidental de ejecución.

### Diferencias clave (dónde divergimos)

| Decisión | A | B | Elección |
|---|---|---|---|
| Investigación en cada import | No | Sí (async) | **No** |
| Redis / orquestador rico | No | Sí | **No** |
| Catálogo canónico global | No necesario | Sí | **Diferido** |
| UI de carga / preview | No | Sí | **No en MVP** |
| Tres providers desde el día 1 | No | Sí | **No** |
| Costo de APIs/LLM | Evitar | Posible | **Evitar** |

---

## 4. Decisión adoptada

**Elegimos la Arquitectura A** (pipeline determinista con evidencia congelada), tomando de B solo principios de separación y trazabilidad, no su complejidad operativa.

### Por qué

1. **Reproducibilidad.** El requisito explícito es que el mismo Excel produzca el mismo resultado. Eso exige que el import no consulte la red ni regenere IA en cada corrida.
2. **Alcance del challenge.** Se evalúa enfoque, correctitud y claridad, no una plataforma B2B completa.
3. **Costo cero.** No tiene sentido pagar APIs o infra para un entregable de entrevista.
4. **Tiempo.** Un orquestador + staging canónico + tres researchers retrasa el primer producto bien enriquecido.
5. **Honestidad de datos.** Preferimos hojas parciales con fuentes citadas antes que un Excel “completo” sin evidencia.

### Qué conservamos de B (sin implementarlo como sistema)

- Separación clara: import → resolve → export.
- Provenance por hecho (fuente, URL/documento, fecha de captura).
- La idea de “adapters de fuente” como interfaz, aunque al inicio el adapter sea leer fixtures versionados.
- La regla de no mezclar investigación con exportación.

### Qué descartamos explícitamente para este challenge

- Orquestador de jobs con estados complejos.
- Redis / cola obligatoria.
- Providers AI / Web / Catalog en vivo dentro del import.
- `CanonicalProduct` vs `Product` como modelo temprano.
- UI de importación y preview.
- Uso de `ejemplo_prueba_técnica.xlsx` como fuente de datos.

---

## 5. Flujo adoptado

```text
data_prueba_técnica.xlsx
        │
        ▼
  Import + validación de headers / filas
        │
        ▼
  Normalización local (sin destruir el valor original)
        │
        ▼
  Resolve desde evidence/ versionada (sin red)
        │
        ▼
  Validación (relaciones, duplicados, campos)
        │
        ▼
  Export → workbook con hojas:
    Origen | Aplicaciones | Intercambios | Atributos | Catálogo | Métricas
```

Invariante de reproducibilidad:

```text
f(input_excel, evidence_snapshot, rules_version) → output_excel
```

Misma entrada + misma evidencia + mismas reglas ⇒ mismo resultado lógico en N imports.

---

## 6. Fuentes de evidencia

Jerarquía (de mayor a menor confianza):

| Nivel | Fuente | ¿Entra al Excel? |
|---|---|---|
| A | Catálogo / PDF / página oficial del fabricante del SKU | Sí |
| B | Catálogo de marca documentada como intercambio del SKU | Sí, con cuidado |
| C | Ficha de revendedor que cita el mismo número de parte | Apoyo, no única fuente |
| D | Texto de `Descripcion` en `Origen` | Solo candidatos / literales (`+20`) |
| E | Similaridad descriptiva o el workbook ejemplo | **Nunca** |

Reglas:

- `ejemplo_prueba_técnica.xlsx` valida **estructura** (tests de export), no alimenta applications/intercambios/atributos.
- La evidencia se captura una vez, se versiona en el repo y se cita (URL, fecha, notas).
- Si no hay evidencia A/B: el hecho no se exporta. Se documenta la limitación.

Applications: exportar solo lo que la fuente soporte (forma compacta y fiel). No inventar submodelos, mercados ni expansiones año×trim que la fuente no liste.

---

## 7. Prioridades del entregable

1. Correctitud y evidencia.
2. Determinismo e idempotencia.
3. Implementación clara y mantenible.
4. Cobertura útil (sin fabricar).
5. Pulido del workbook.

---

## 8. Trabajo previo al código

Antes de implementar:

1. Congelar el contrato de hojas/columnas del Excel de salida.
2. Capturar evidencia verificable, empezando por un producto fuerte.
3. Escribir reglas mínimas de matching, deduplicación y clasificación.
4. Definir alcance MVP: un comando de import→export + tests de estructura y rerun.
5. Documentar qué quedará vacío y por qué.

Orden de construcción previsto:

1. Import + export vacío pero válido estructuralmente.
2. End-to-end con un producto y su evidence snapshot.
3. Generalizar a los demás productos según evidencia disponible.
4. Tests de determinismo (mismo input N veces → mismo resultado lógico).

---

## 9. Evolución futura (fuera del challenge)

Si este trabajo se convirtiera en producto real, la Arquitectura B (o un híbrido Discovery vs Catalog Build) sería el siguiente paso natural:

- Discovery no determinista → escribe resultados de investigación.
- Catalog Build determinista → solo lee resultados aceptados/versionados y exporta.

Ese corte permite crecer hacia providers paralelos **sin** romper reproducibilidad del export. No lo implementamos ahora porque excede el challenge.

---

## 10. Resumen ejecutivo

| Pregunta | Respuesta |
|---|---|
| ¿Qué arquitecturas vimos? | A: pipeline + evidencia congelada. B: plataforma con research paralelo. |
| ¿Para qué sirve A? | Challenge reproducible, barato, explicable. |
| ¿Para qué sirve B? | Producto de catalogación a escala. |
| ¿Cuál elegimos? | **A**, con principios de separación/trazabilidad tomados de B. |
| ¿Por qué? | Determinismo, cero costo, alcance real del challenge, honestidad de datos. |
| ¿Qué no hacemos? | Orquestadores, APIs de pago, usar el ejemplo como dataset, inventar fitment. |

## 11. Documentos relacionados

- `docs/output-contract.md` — forma del Excel de salida
- `docs/business-rules.md` — reglas `rules-v1`
- `docs/mvp-scope.md` — alcance MVP
- `evidence/` — YAML por producto (captura 2026-11-05)
