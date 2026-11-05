# Contrato de salida — Excel enriquecido

Define la forma del workbook que debe producir el pipeline. La referencia visual es `data/ejemplo_prueba_técnica.xlsx`, **solo como contrato de estructura**. No se copian sus filas de datos.

Fuente de entrada: `data/data_prueba_técnica.xlsx`.

---

## Hojas obligatorias (orden sugerido de escritura)

1. `Origen`
2. `Métricas`
3. `Aplicaciones`
4. `Intercambios`
5. `Atributos`
6. `Catálogo`

El ejemplo usa ese orden de sheets en el workbook. El pipeline debe emitir los mismos nombres de hoja y headers compatibles.

---

## `Origen`

Copia fiel de la entrada (sin enriquecer).

| Columna | Notas |
|---|---|
| `Cod interno` | Entero / string estable; no exportar como `6536.0` |
| `Número de parte` | Clave de referencia; preservar sufijos (`+20`, `R/L`) |
| `Descripción del artículo` | Tipo comercial corto |
| `Descripcion` | Texto largo del retailer; no validado como fitment |
| `Grupo de articulos` | Grupo comercial de entrada |
| `Fabricante` | Marca de la refacción |
| `Unidad` | `JUEGO` / `PZA` |

Una fila por producto fuente. Para el challenge: **5 filas**.

---

## `Aplicaciones`

Una fila = una configuración vehicular documentada.

| Columna | Notas |
|---|---|
| `Referencia` | = `Número de parte` |
| `Marca` | = `Fabricante` del producto |
| `Producto` | Nombre normalizado de catálogo |
| `Posición` | Puede quedar vacío (en el ejemplo está vacío) |
| `Fabricante` | Make del vehículo (Nissan, Chevrolet, …) |
| `Modelo` | Modelo vehicular |
| `Submodelo` | Solo si la fuente lo da; si no, vacío |
| `Año` | Entero de un solo año. Si la fuente da rango, expandir **solo años** (no inventar submodelos) |
| `Litros` | Decimal si la fuente lo da |
| `CC` | Entero si la fuente lo da |
| `CID` | Entero si la fuente lo da |
| `Cilindros` | Entero |
| `Bloque` | `L` / `V` cuando se conozca |
| `Combustible` | p. ej. `Gasolina` |
| `Mercado` | Solo si la fuente lo afirma (`MEX` / `USA`); si no, vacío |

**Regla compacta:** no fabricar trims ni mercados. Preferir filas `make + model + year + engine` fieles a la fuente.

---

## `Intercambios`

| Columna | Notas |
|---|---|
| `Referencia` | Parte fuente |
| `Marca` | Marca fuente |
| `Producto` | Nombre normalizado |
| `Intercambio` | Número de parte equivalente |
| `Marca intercambio` | Marca del equivalente |
| `Origen` | Solo `Aftermarket` o `OEM` |

No listar números solo porque aparecen en `Descripcion` salvo que otra fuente A/B confirme equivalencia (o se documenten explícitamente como candidatos rechazados fuera del Excel).

---

## `Atributos`

| Columna | Notas |
|---|---|
| `Referencia` | |
| `Marca` | |
| `Producto` | |
| `Clase` | Agrupador (Diámetro, Material, Tipo, …) |
| `Atributo` | Nombre del atributo |
| `Unidad` | `mm`, etc.; vacío si no aplica |
| `Valor` | String o número serializado de forma estable |

Una fila por atributo. Sin atributos inventados.

---

## `Catálogo`

Una fila por producto fuente (idealmente 5).

| Columna | Notas |
|---|---|
| `Referencia` | |
| `Marca` | |
| `Categoría` | Para este challenge: `Vehículo ligero` |
| `Sistema` | Para este challenge: `MOTOR` |
| `Subsistema` | Según taxonomía en `docs/business-rules.md` |
| `Producto` | Nombre normalizado |
| `Descripción` | Plantilla a partir de hechos aceptados únicamente |

---

## `Métricas`

Layout compatible con el ejemplo:

| Celda | Contenido |
|---|---|
| `A1` | Título, p. ej. `Catálogo Bonaparte - Refaccionaria Trópico de Cáncer` |
| `A2` / `B2` | `Referencias:` / conteo de productos en `Origen` |
| `A4` / `B4` | `Aplicaciones` / total de filas de datos |
| `A5` / `B5` | `Origen` / 0 (en el ejemplo todo es incremento) |
| `A6` / `B6` | `Incrementos` / `=B4-B5` (o valor derivado equivalente) |
| `A8`–`B10` | Igual patrón para `Intercambios` |
| `A12`–`B14` | Igual patrón para `Atributos` |

Los conteos se calculan del export real. **No** hardcodear 10 / 2610 / 31 / 74 del ejemplo.

---

## Orden estable (determinismo)

Antes de escribir cada hoja de enriquecimiento, ordenar por claves explícitas:

1. `Aplicaciones`: Referencia, Fabricante, Modelo, Submodelo, Año, Litros, CC, CID, Combustible, Mercado  
2. `Intercambios`: Referencia, Marca intercambio, Intercambio, Origen  
3. `Atributos`: Referencia, Clase, Atributo, Unidad, Valor  
4. `Catálogo`: Referencia  

Sin timestamps de corrida dentro de las hojas de negocio.
