# Bonaparte Catalog

Pipeline determinista en Ruby on Rails: lee un Excel con hoja `Origen`, lo resuelve contra evidencia versionada en `evidence/` y genera un catálogo enriquecido (Aplicaciones, Intercambios, Atributos, Catálogo, Métricas).

Sin red, scrapers ni LLM en runtime. Mismo input → mismo resultado lógico.

---

## Setup

```bash
bundle install
bin/rails db:prepare
```

Requisitos: Ruby 3.4+, PostgreSQL (boot de Rails; el pipeline no guarda el catálogo en DB), Bundler.

## Probar en la UI

```bash
bin/rails server
```

Abre `http://localhost:3000`, sube un `.xlsx` con hoja `Origen` (por ejemplo `data/data_prueba_técnica.xlsx`) y descarga el catálogo enriquecido.

## Alternativa por CLI

```bash
bin/rails catalog:enrich
```

```bash
INPUT=data/data_prueba_técnica.xlsx \
OUTPUT=output/catalogo_enriquecido.xlsx \
bin/rails catalog:enrich
```

## Tests

```bash
bundle exec rspec
```

Import, evidence, resolve, export, rerun determinista y UI.

---

## Cómo tomé las decisiones

### 1. Entender el problema primero

- Inspeccioné `data_prueba_técnica.xlsx` (5 productos) y `ejemplo_prueba_técnica.xlsx` (**solo contrato de forma**, no dataset).
- El core no es “rellenar Excel”: es descubrir, validar, relacionar y exportar con trazabilidad.
- Prioricé: **correctitud y evidencia > cobertura forzada > polish**.

### 2. Dos arquitecturas que evalué

| | A — Pipeline + evidencia congelada | B — Plataforma con research paralelo |
|---|---|---|
| Idea | Import → resolve YAML → export | Jobs AI/Web/Catalog + staging + canónico |
| Encaje | Challenge reproducible, $0 | Producto a escala / API B2B |
| Riesgo | Parecer “simple” si no lo documento | Sobre-ingeniería y costo |

**Elegí A** (tomando de B la separación de etapas y el provenance). Detalle en [docs/technical-decisions.md](docs/technical-decisions.md).

### 3. Por qué seguí por este camino

- Es un challenge de entrevista: se evalúa enfoque, no una plataforma completa.
- **Determinismo:** investigar en vivo en cada import rompe “mismo Excel N veces = mismo output”.
- **Cero costo:** ACES/PIES, APIs de partes y muchos catálogos serios son de **pago o licencia**. No me pareció razonable depender de ellos aquí.
- Preferí un Excel **parcial y verificable** a uno “completo” inventado.

### 4. Decisiones que tomé

- Evidence en `evidence/*.yml` (captura **manual** de PDFs/páginas públicas gratis; una sola vez).
- Resolve/export como función pura sobre ese snapshot + `rules-v1`.
- Applications compactas (fieles a la fuente); sin inventar submodelos/mercados.
- `ejemplo_*` nunca como fuente de fitment/intercambios.
- UI mínima de upload/descarga + rake CLI (mismo pipeline).
- KISS: POROs/servicios, sin Redis/jobs/ActiveRecord de catálogo en el MVP.

### 5. Qué prioricé

1. Evidencia y no fabricar datos
2. Reproducibilidad / idempotencia
3. Código claro y testeable
4. Cobertura útil donde hubo fuente
5. UX mínima suficiente

### 6. Limitación de fuentes (importante)

Existen herramientas y catálogos industriales (feeds ACES/PIES, APIs comerciales, EPCs OEM con acceso restringido) que darían applications densas tipo año×trim×mercado. **Requieren pago, contrato o cuenta.**  
En este deliverable usé **búsqueda manual** en catálogos/PDFs públicos (Fraco, Rexite, Elgin, cruces aftermarket, etc.), documentada en cada YAML. Ver [evidence/README.md](evidence/README.md).

### 7. Fuentes consultadas

De estas fuentes extraje la evidencia versionada en `evidence/`:

| Producto | Fuente | URL |
|---|---|---|
| `RM-152` | Rexite — Catálogo Bombas de Aceite 2023 | [PDF](https://rexite.net/wp-content/uploads/2025/10/CATALOGO-BOMBAS-DE-ACEITE-REXITE-2023.pdf) |
| `RM-152` | PartsHawk — Melling M152 (atributos / OEM) | [ficha](https://partshawk.com/melling-m152-engine-oil-pump.html) |
| `FSX-5840301` | FRACO — catálogo / manual FS5840301 | [PDF](https://www.fraco.com.co/images/QR/FS5840301.pdf) |
| `HL-7025S` | Elgin Industries — AFM / DFM lifters | [página](https://www.elginind.com/usa-made-ls-engine-afm-lifter-sets-active-fuel-management-oe-replacement/) |
| `TK1283-1` | FindItParts — cruces Dayco KTC1372 | [ficha](https://www.finditparts.com/products/16663863/dayco-ktc1372) |
| `TK1283-1` | Cloyes — cobertura Pentastar 9-0511S (solo identidad del cruce) | [página](https://cloyes.com/chrysler-pentastar-3-2-3-6l-dohc-v6-timing-chain-replacement/) |
| `SP26-329R/L+20` | Sufijo `+20` del número de parte (literal) | — |
| `SP26-329R/L+20` | iGlobalParts — patrón SPRG26-329R/L-S (apoyo, sin fitment exportado) | [listing](https://iglobalparts.com/piston-ring-set-prg-10-5106-r-l-sizes/) |

---

## Futuros alcances (más allá del challenge)

Si esto escalara a producto real, estos son los siguientes pasos que consideraría (sin implementarlos ahora):

| Alcance | Idea |
|---|---|
| Memoize / cache de evidence | Evitar releer YAML en cada request; versionar snapshot |
| Discovery vs Catalog Build | Investigar offline → staging; export solo lee hechos aceptados |
| Providers / adapters | Fraco PDF, Rexite, Elgin, APIs licenciadas detrás de una interfaz |
| Delegar a servicios | Normalización, matching y clasificación como servicios versionados |
| Persistencia de runs | `ImportRun`, provenance en DB, reproceso selectivo |
| Jobs async | Enriquecer lotes grandes sin bloquear la UI |
| Catálogo canónico | Deduplicar productos entre refaccionarias / API B2B |
| Revisión humana | Cola de conflictos low-confidence antes de exportar |

Conecta con la visión B, manteniendo el corte determinista del export.

## Cobertura de los 5 productos

Parcial a propósito (vacío documentado > inventar):

| Parte | Marca | Notas |
|---|---|---|
| `RM-152` | REXITE | Apps + intercambios + atributos |
| `FSX-5840301` | FRACO | Apps + atributos |
| `HL-7025S` | ELGIN | Catálogo + OEM/atributos + apps DFM compactas |
| `TK1283-1` | REVO | Intercambios; sin applications |
| `SP26-329R/L+20` | SAFETY | Catálogo + sobremedida `+20` |

## Documentación

| Doc | Contenido |
|---|---|
| [docs/technical-decisions.md](docs/technical-decisions.md) | A vs B y decisión |
| [docs/output-contract.md](docs/output-contract.md) | Contrato de hojas |
| [docs/business-rules.md](docs/business-rules.md) | `rules-v1` |
| [docs/mvp-scope.md](docs/mvp-scope.md) | Alcance MVP |
| [docs/code-audit.md](docs/code-audit.md) | Audit / RuboCop / KISS |
| [evidence/README.md](evidence/README.md) | Captura de evidencia |
