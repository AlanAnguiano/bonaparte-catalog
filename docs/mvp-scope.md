# Alcance MVP — antes / durante el primer código

## Objetivo del MVP

Un comando (rake/servicio) que:

1. Lea `data/data_prueba_técnica.xlsx`.
2. Resuelva contra `evidence/` + `rules-v1`.
3. Escriba un Excel con las 6 hojas del contrato.
4. Sea reproducible: mismo input N veces → mismo resultado lógico.

## Incluye

- Import + validación de headers.
- Normalización no destructiva.
- Carga de evidence YAML.
- Proyección a Aplicaciones / Intercambios / Atributos / Catálogo / Métricas.
- Tests de estructura vs headers del ejemplo.
- Test de rerun determinista (comparación lógica de hojas).
- README con fuentes, huecos y cómo correr el pipeline.

## No incluye (challenge)

- UI de upload.
- Redis / orquestador multi-provider.
- APIs o LLM de pago.
- Scraping en runtime.
- Catálogo canónico global multi-import.
- Completar applications densas estilo ACES sin evidencia.

## Cobertura esperada por producto (pre-código)

Orden de preferencia / fuerza de evidencia:

| # | Parte | Marca | Expectativa MVP |
|---|---|---|---|
| 1 | `RM-152` | REXITE | Applications + interchanges + atributos + catálogo |
| 2 | `FSX-5840301` | FRACO | Applications + atributos + catálogo; interchanges parciales |
| 3 | `HL-7025S` | ELGIN | Catálogo + atributos + interchanges OEM; applications compactas |
| 4 | `TK1283-1` | REVO | Catálogo + interchanges documentados con salvedad de marca; applications **vacías** hasta mejor prueba Revo |
| 5 | `SP26-329R/L+20` | SAFETY | Catálogo + atributo de sobremedida; applications/interchanges **vacíos o mínimos** |

Un Excel parcial y trazable es éxito. Un Excel “lleno” sin fuentes no lo es.

## Criterio de done del pre-código

- [x] Contrato de salida
- [x] Reglas de negocio `rules-v1`
- [x] Evidence YAML para los 5 productos
- [x] Este alcance MVP
- [ ] Revisión humana de evidence antes de codear resolve/export
