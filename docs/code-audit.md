# Code audit — Bonaparte Catalog MVP

Fecha: 2026-11-05. Alcance: services, controller UI, rake, specs.

## Resumen

La arquitectura actual (pipeline síncrono + evidence YAML) ya encaja con KISS y con el challenge. No conviene forzar SOLID/micro-capas extra. Los gaps reales eran estilo RuboCop, claridad del controller y validaciones de borde.

## Qué está bien

- Separación Import → Resolve → Export (`SRP` práctico).
- Evidence fuera del runtime de red (determinismo).
- Headers de Origen reutilizados (`WorkbookExporter` → `WorkbookImporter::ORIGEN_HEADERS`).
- Tests de contrato, lookup y rerun.
- UI mínima sin ActiveRecord de dominio innecesario.

## Gaps encontrados

| Área | Hallazgo | Acción |
|---|---|---|
| RuboCop | Offenses de `Layout/SpaceInsideArrayLiteralBrackets` | Autocorregidos |
| Controller | `create` largo, tempfiles + validación mezclados | Extraer métodos privados |
| Seguridad | Sin límite de tamaño de upload | Límite 10 MB |
| Robustez | `evidence/` inexistente fallaba opaco | Validar path al cargar |
| Robustez | `year_from` inválido en YAML → excepción cruda | Error de catálogo claro |
| Rails | Falta `frozen_string_literal` en ApplicationController | Añadido |
| Performance | Releer YAML en cada request | OK para 5 archivos; memoizar solo si crece |
| Performance | `send_data` carga el xlsx en memoria | OK para entregables chicos |
| Rails | `allow_browser :modern` puede bloquear browsers viejos | Se deja; documentado |
| SOLID | No hace falta Interface Segregation / DIP con DI container | No aplicar |

## Principios

- **KISS:** un pipeline, un form, un rake. Sin jobs/Redis.
- **DRY:** headers y pipeline compartidos CLI/UI.
- **SOLID (solo lo útil):** cada servicio una responsabilidad; el pipeline orquesta. No introducir abstracciones “por si acaso”.

## Diferido a propósito

- Cache de evidence en memoria de proceso.
- ActiveStorage / historial de imports.
- Background jobs.
- Extracción de `CatalogResolver` en 4 clases (sobre-ingeniería para el tamaño actual).
