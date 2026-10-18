# demo

Catálogos de referencia en JSON, en **inglés y español**, para poblar bases de datos, crear mocks o rellenar formularios de prueba. Son datos de ejemplo: úsalos para desarrollo y pruebas, no como fuente oficial.

Todos los archivos tienen la forma `{ "data": ... }`. En casi todos, `data` es una lista de objetos; en `images.json` es un objeto.

## Archivos

| Archivo | Registros | Campos |
| --- | --- | --- |
| `banks.json` | 40 | `code`, `name`, `swift`, `country` |
| `countries.json` | 198 | `code` (ISO alpha-2), `alpha3`, `name_en`, `name_es`, `currency_code`, `phone_code` |
| `document_types.json` | 20 | `code`, `en`, `es`, `country_scope` |
| `government_institutions.json` | 99 | `code`, `name_en`, `name_es`, `acronym`, `country_en`, `country_es` |
| `images.json` | 16 tamaños (9 `horizontal`, 7 `square`) | `base_url`, `syntax` y, por tamaño: `name`, `width`, `height`, `bg_color`, `text_color`, `format`, `text`, `url` |
| `jobtitles.json` | 149 | `code`, `en`, `es`, `level`, `department` |
| `languages.json` | 97 | `code`, `en`, `es` |
| `profesions.json` | 209 | `code`, `en`, `es` |
| `time-frames.json` | 59 | `code`, `en`, `es`, `amount`, `unit`, `days_approx` |
| `universities.json` | 110 | `code`, `name`, `country_en`, `country_es`, `city` |

`images.json` describe tamaños de imagen de relleno para [placehold.co](https://placehold.co); `syntax` es la plantilla de la URL y cada entrada trae su `url` ya armada. Esas imágenes se descargan del servicio externo, así que necesitas conexión a internet para verlas.

## Ejemplos

Buscar un país por código (con [`jq`](https://jqlang.github.io/jq/)):

```bash
jq '.data[] | select(.code == "DO")' demo/countries.json
```

Listar los nombres de países en español:

```bash
jq -r '.data[].name_es' demo/countries.json
```

Cargarlo desde Python:

```python
import json

with open("demo/countries.json", encoding="utf-8") as f:
    countries = json.load(f)["data"]

print(next(c for c in countries if c["code"] == "DO"))
```

Los archivos están en UTF-8 (hay acentos y caracteres especiales).

## Notas

- Los códigos son identificadores estables dentro de cada archivo, pensados para usarse como clave en tus seeds.
- Los datos de bancos, universidades e instituciones son ejemplos representativos, no un listado exhaustivo ni actualizado.
- Si añades un catálogo nuevo, mantén la forma `{ "data": ... }`, incluye los campos `en` / `es` y añade una fila a la tabla de arriba.
