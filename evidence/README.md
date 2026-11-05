# Evidence snapshot

Hechos verificados (o explícitamente limitados) para el resolve determinista.

- **No** se consulta la red durante import/export.
- Cada producto tiene un YAML.
- `captured_on`: fecha de captura de la evidencia.
- `confidence`: `A` | `B` | `C` | `D` (ver `docs/business-rules.md`).
- Solo hechos con `export: true` deben proyectarse al Excel.

Orden de preferencia de investigación:

1. `rm-152.yml`
2. `fsx-5840301.yml`
3. `hl-7025s.yml`
4. `tk1283-1.yml`
5. `sp26-329rl-20.yml`

El workbook `data/ejemplo_prueba_técnica.xlsx` **no** es una fuente aquí.

## Approach de captura

La evidencia se obtuvo por **investigación manual asistida, una sola vez**, no por scraping automatizado ni por jobs en runtime.

Pasos:

1. Buscar en la web el número de parte + fabricante (fuentes públicas y gratis).
2. Abrir URLs concretas (páginas de fabricante, PDFs de catálogo, fichas con tablas de cruce).
3. Leer el contenido y extraer solo hechos con provenance (URL, fecha, nivel de confianza).
4. Escribir esos hechos en los YAML de este directorio, marcando `export: true` o `false`.
5. Rechazar claims que solo existían en la `Descripcion` del retailer o que no tenían respaldo A/B.

Qué **no** se usó:

- Scrapers / crawlers / automatización masiva de sitios
- APIs o LLM de pago
- Consultas en vivo durante el import/export
- El Excel de ejemplo como dataset de enriquecimiento

En una frase: buscar → abrir fuente pública → copiar hechos verificables a YAML → el pipeline solo lee este snapshot.
