# Reglas de negocio — matching, clasificación y conflictos

Reglas mínimas para el resolve determinista. Version: `rules-v1`.

---

## 1. Identidad de producto

- Clave primaria lógica: `(Número de parte, Fabricante)`.
- El `Cod interno` se preserva pero **no** es la clave de enrichment.
- Preservar el part number literal: no eliminar `+20`, `R/L`, guiones ni sufijos.
- Alias de marca (solo si se documentan):

  | Entrada | Marca canónica export |
  |---|---|
  | `FRACO` | `FRACO` |
  | `REXITE` | `REXITE` |
  | `ELGIN` | `ELGIN` |
  | `REVO` | `REVO` |
  | `SAFETY` | `SAFETY` |

No renombrar a formas del ejemplo (`TECH TIMING`, etc.) sin regla explícita.

---

## 2. Qué se puede sacar de `Descripcion`

| Uso permitido | Ejemplo |
|---|---|
| Candidatos a interchange (requieren confirmación A/B) | `DM-152`, `9-0511S`, `JC20` |
| Atributos literales del part number | `+20` → sobremedida |
| Contexto de investigación | motor `KA24E`, “CON RESORTE” |

| Uso prohibido |
|---|
| Expandir `89/03` a applications sin catálogo |
| Tratar similaridad de texto como equivalencia |
| Copiar filas de `ejemplo_prueba_técnica.xlsx` |

---

## 3. Niveles de evidencia (export)

| Nivel | Fuente | Exporta |
|---|---|---|
| A | Catálogo / PDF / página del fabricante del SKU | Sí |
| B | Catálogo de marca con interchange documentado hacia el SKU | Sí |
| C | Revendedor que cita el mismo número | Solo apoyo; no como única fuente de applications |
| D | Solo `Descripcion` del retailer | No en hojas de enrichment |
| E | Ejemplo workbook / parecido descriptivo | Nunca |

Si dos fuentes A/B conflictúan: gana la del **fabricante del SKU** (nivel A propio). Registrar el conflicto en notes de evidence, no silenciarlo.

---

## 4. Applications

- Una fila por año cuando la fuente da un rango de años **y** el mismo make/model/engine aplica a todos esos años.
- No inventar `Submodelo` ni `Mercado`.
- No transferir fitment de un interchange a nuestro SKU salvo interchange nivel A/B explícito **y** decisión documentada en el YAML del producto.
- Motor fields (`Litros`, `CC`, `CID`, `Cilindros`, `Bloque`, `Combustible`) solo si la fuente o el motor code documentado los soporta.

---

## 5. Intercambios

- Requiere número + marca del equivalente + `Aftermarket`/`OEM`.
- OEM solo con número OEM documentado.
- El mismo número bajo otra marca en una tabla de cruces (p. ej. Sumax `TK1283-1`) **no** prueba automáticamente que `REVO TK1283-1` sea idéntico; documentar la incertidumbre.

---

## 6. Atributos

- Solo hechos A/B (o literales inequívocos del part number, p. ej. `+20`).
- Unidades normalizadas a `mm` cuando la fuente da mm.
- No mezclar idiomas arbitrariamente: preferir español en labels de clase/atributo cuando escribamos nosotros; valores técnicos pueden quedar como en la fuente (`Cast Iron`, `Gear`) si se citan textualmente — documentar en evidence.

---

## 7. Taxonomía de `Catálogo` (rules-v1)

Todos: `Categoría = Vehículo ligero`, `Sistema = MOTOR`.

| Grupo / familia | Subsistema | Producto normalizado |
|---|---|---|
| Juego de empaques | `JUNTAS Y SISTEMAS DE SELLADO` | `JUEGO DE EMPAQUES DE MOTOR` |
| Bomba de aceite | `BOMBAS` | `BOMBA DE ACEITE DEL MOTOR` |
| Punterías / lifters | `COMPONENTES DEL TREN DE VÁLVULAS` | `PUNTERÍA HIDRÁULICA` |
| Kit de distribución (cadena) | `COMPONENTES DEL TREN DE VÁLVULAS` | `KIT DE CADENA DE TIEMPO` |
| Pistones | `COMPONENTES DEL BLOQUE DE CILINDROS` | `PISTÓN DE MOTOR` |

Descripción: plantilla corta + hechos aceptados concatenados. Sin claims no respaldados.

---

## 8. Deduplicación

Claves compositas:

- Application: referencia, marca, fabricante_vehiculo, modelo, submodelo, año, litros, cc, cid, cilindros, bloque, combustible, mercado, posición
- Interchange: referencia, marca, intercambio, marca_intercambio, origen
- Attribute: referencia, marca, clase, atributo, unidad, valor
- Catalog: referencia, marca

Re-resolver desde evidence no debe crear duplicados.

---

## 9. Determinismo

```text
f(input_excel, evidence_snapshot, rules_version) → output_excel
```

- Sin red en resolve/export.
- Sort estable según `docs/output-contract.md`.
- `rules_version` y evidencia versionadas en el repo.
