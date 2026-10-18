# wiremock

Servidor de mocks local para desarrollar y probar integraciones sin depender de APIs reales. Usa [WireMock](https://wiremock.org/) con la imagen [`holomekc/wiremock-gui`](https://github.com/holomekc/wiremock-gui), que añade una interfaz web para crear y editar stubs.

Incluye un ejemplo completo: una simulación de la API pública v3 de **BeyondTrust Password Safe** (15 escenarios, con respuestas correctas y de error), más colecciones de **Postman** y **Bruno** para probarla.

> Es una simulación con datos ficticios, solo para desarrollo local. No contiene código ni datos de BeyondTrust ni está afiliada a la empresa.

## Inicio rápido

Requisito: [Docker](https://docs.docker.com/get-docker/) con Compose v2.

```bash
cd wiremock
docker compose up -d
```

Comprueba que responde:

```bash
curl http://localhost:8080/ping
# {"status":"ok","service":"wiremock","message":"pong"}
```

| Qué | URL |
| --- | --- |
| API de mocks | `http://localhost:8080` |
| GUI de administración | `http://localhost:8080/__admin/webapp/` |
| API de administración (stubs cargados) | `http://localhost:8080/__admin/mappings` |

Para detener: `docker compose down`.

## Probar el ejemplo de Password Safe

Iniciar sesión con una clave válida (devuelve `200`):

```bash
curl -i -X POST http://localhost:8080/BeyondTrust/api/public/v3/Auth/SignAppIn \
  -H "Authorization: PS-Auth key=VALID-API-KEY;runas=svc_integration;"
```

Con otra clave devuelve `401`, y sin el header `Authorization`, `400`:

```bash
curl -i -X POST http://localhost:8080/BeyondTrust/api/public/v3/Auth/SignAppIn \
  -H "Authorization: PS-Auth key=INVALID-KEY;runas=svc_integration;"
```

Obtener credenciales de una solicitud (`200`; con el ID `999` devuelve `403` y con `888`, `404`):

```bash
curl -i http://localhost:8080/BeyondTrust/api/public/v3/Requests/123456/Credentials
```

La tabla completa de qué request dispara cada respuesta está en [requests/password-safe/README.md](requests/password-safe/README.md). Allí también se explica cómo importar las colecciones en Postman o abrirlas en Bruno.

## Estructura

```text
wiremock/
├── docker-compose.yml
├── mappings/                 # Stubs: WireMock los carga al arrancar (recursivo)
│   ├── health/ping.json      # GET /ping -> 200
│   └── password-safe/        # 15 stubs de la API de Password Safe (01-…15-)
├── __files/                  # Archivos estáticos servidos con bodyFileName (vacía por defecto)
├── requests/password-safe/   # Colecciones de prueba: postman/ y bruno/
└── collections/              # Exportación adicional de la colección Postman
```

Los nombres de los stubs de `password-safe` van numerados (`01-…` a `15-…`) y coinciden con los de las colecciones de prueba, para saber qué request dispara cada uno.

## Cómo funcionan los stubs

Cada archivo `.json` dentro de `mappings/` define un stub: qué request coincide y qué respuesta se devuelve. Ejemplo (`mappings/health/ping.json`):

```json
{
  "request": { "method": "GET", "url": "/ping" },
  "response": {
    "status": 200,
    "jsonBody": { "status": "ok", "service": "wiremock", "message": "pong" },
    "headers": { "Content-Type": "application/json" }
  }
}
```

Cuando varios stubs podrían coincidir, gana el de **menor `priority`**. El ejemplo de Password Safe lo usa así: los casos de error específicos (por ejemplo, el ID `999` de credenciales) tienen `priority: 1`, y el caso genérico de éxito (cualquier otro ID) tiene `priority: 5`.

El servidor arranca con `--global-response-templating`, por lo que las respuestas pueden usar [plantillas de WireMock](https://wiremock.org/docs/response-templating/) (por ejemplo, para reflejar parte del request).

### Agregar o editar stubs

- **A mano:** crea un `.json` en `mappings/` siguiendo el formato de [WireMock stubbing](https://wiremock.org/docs/stubbing/) y reinicia con `docker compose restart wiremock`.
- **Con la GUI:** abre `http://localhost:8080/__admin/webapp/`, crea o edita el stub y los cambios se guardan en `mappings/` (la carpeta está montada como volumen).

Para responder con un archivo (por ejemplo, un PDF o un JSON grande), colócalo en `__files/` y usa `bodyFileName` en lugar de `jsonBody`.

> **No guardes en `mappings/` archivos que no sean stubs.** WireMock trata como stub cada `.json` que encuentre allí, y un formato distinto (como una colección de Postman) rompería la carga. Por eso las colecciones viven en `requests/` y `collections/`.

## Configuración

El servicio se define en `docker-compose.yml`:

| Ajuste | Valor |
| --- | --- |
| Imagen | `holomekc/wiremock-gui:latest` |
| Puerto | `8080` (cámbialo en `ports:` si ya está en uso) |
| Argumentos | `--global-response-templating --disable-banner` |
| Memoria | límite de contenedor `500m`, `JAVA_OPTS=-Xms128m -Xmx320m` |
| Volúmenes | `./mappings` y `./__files` |

## Problemas frecuentes

| Síntoma | Causa y solución |
| --- | --- |
| `port is already allocated` | Otro programa usa el `8080`. Detenlo o cambia el mapeo `ports:`. |
| Un stub nuevo no responde | Revisa que el JSON sea válido y reinicia: `docker compose restart wiremock`. Mira el log: `docker compose logs -f wiremock`. |
| Responde un stub distinto al esperado | Hay otro stub que coincide con mayor prioridad (menor `priority`). Compruébalo en `http://localhost:8080/__admin/mappings`. |
| `404` con el mensaje "Request was not matched" | Ningún stub coincide con tu request. WireMock lista en el cuerpo del error los stubs más parecidos; compara método, ruta y headers. |
| La GUI no guarda cambios | Comprueba que `./mappings` esté montada (`docker compose config`) y que tengas permisos de escritura en esa carpeta. |

Si cambias el contenido de `mappings/` a mano mientras el contenedor corre, reinícialo para recargar.
