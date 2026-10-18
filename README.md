# dev-tools

Caja de herramientas para desarrolladores. Reúne en un solo repositorio todo lo necesario para montar un entorno de trabajo local y probar integraciones sin depender de servicios reales:

- **Bases de datos y almacenamiento** locales (PostgreSQL, MySQL, Oracle, SQL Server, MongoDB, Redis y MinIO) con Docker Compose.
- **Emuladores de AWS, Azure y GCP** con una consola web unificada.
- **Servidor de mocks** (WireMock) con un ejemplo completo de una API de gestión de contraseñas.
- **Skills de IA** para analizar logs por tecnología.
- **Datos de ejemplo** en JSON para seeds, mocks y pruebas.

Cada carpeta es independiente: usa solo la que necesites.

> **Solo para desarrollo local.** Nada de lo que hay aquí está pensado para producción ni para exponerse a una red compartida. Ver [Seguridad](#seguridad).

## Contenido

| Carpeta                    | Qué es                                                                                                                                               | Documentación                              |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| [`dev-infra/`](dev-infra/) | Stack local con Docker Compose: MinIO, PostgreSQL, MySQL, Redis, Oracle, MongoDB y SQL Server, con un usuario de desarrollo creado en cada servicio. | [dev-infra/README.md](dev-infra/README.md) |
| [`floci/`](floci/)         | Emuladores locales de AWS, Azure y GCP con una consola web unificada, usando las imágenes del proyecto de código abierto [Floci](https://floci.io).  | [floci/README.md](floci/README.md)         |
| [`wiremock/`](wiremock/)   | Servidor de mocks [WireMock](https://wiremock.org/) con GUI, stubs de ejemplo (API de BeyondTrust Password Safe) y colecciones de Postman y Bruno.   | [wiremock/README.md](wiremock/README.md)   |
| [`ia-tools/`](ia-tools/)   | Skills de IA para diagnosticar logs de Kafka, Kubernetes, Spring Boot, .NET, bases de datos y más.                                                   | [ia-tools/README.md](ia-tools/README.md)   |
| [`demo/`](demo/)           | Catálogos JSON bilingües (países, bancos, profesiones…) para seeds, mocks y pruebas.                                                                 | [demo/README.md](demo/README.md)           |

```text
dev-tools/
├── dev-infra/    # Bases de datos y almacenamiento local (Docker Compose)
├── floci/        # Emuladores de nube AWS / Azure / GCP (Docker Compose)
├── wiremock/     # Mock server + colecciones Postman y Bruno
├── ia-tools/     # Skills de análisis de logs
├── demo/         # Datos de ejemplo en JSON
├── LICENSE
└── SECURITY.md   # Política de seguridad
```

## Requisitos

| Herramienta                                                                     | Para qué                                                                                                                |
| ------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| [Docker](https://docs.docker.com/get-docker/) con Compose v2 (`docker compose`) | `dev-infra/`, `floci/` y `wiremock/`. Probado con [OrbStack](https://orbstack.dev/) en macOS (Apple Silicon).           |
| [MinIO Client (`mc`)](https://min.io/docs/minio/linux/reference/minio-mc.html)  | Opcional: usar `dev-infra/minio-configurator.sh` desde tu máquina (también se puede ejecutar desde la imagen de MinIO). |
| [AWS CLI](https://aws.amazon.com/cli/), `az` o `gcloud`                         | Opcional: hablar con los emuladores de `floci/`.                                                                        |
| [Postman](https://www.postman.com/) o [Bruno](https://www.usebruno.com/)        | Opcional: probar los mocks de `wiremock/`.                                                                              |
| [`jq`](https://jqlang.github.io/jq/)                                            | Opcional: consultar los JSON de `demo/`.                                                                                |

**Recursos:** el stack completo de `dev-infra/` incluye Oracle y SQL Server, que consumen bastante memoria. Si tu máquina va justa, levanta solo los servicios que necesites (ver [dev-infra/README.md](dev-infra/README.md#levantar-solo-algunos-servicios)).

## Inicio rápido

```bash
git clone https://github.com/ifirestone/dev-tools.git
cd dev-tools
```

`dev-infra/` necesita un archivo de credenciales local (`.env`, no versionado) que se crea desde la plantilla:

```bash
cp dev-infra/.env.example dev-infra/.env
```

Edita los valores si quieres otros usuarios o contraseñas. Después, desde la raíz del repositorio:

```bash
docker compose -f dev-infra/docker-compose.yml up -d   # Bases de datos y almacenamiento
docker compose -f floci/docker-compose.yml up -d       # Emuladores de nube
docker compose -f wiremock/docker-compose.yml up -d    # Servidor de mocks
```

Los tres stacks son independientes y no comparten puertos, así que pueden correr a la vez. Para detener uno: `docker compose -f <carpeta>/docker-compose.yml down` (añade `-v` para borrar también sus datos).

## Puertos y credenciales

Con los valores por defecto de las plantillas. Si cambiaste algo en tu `.env`, usa tus valores.

### dev-infra

| Servicio      | Host                                   | Usuario                                           | Contraseña                                                |
| ------------- | -------------------------------------- | ------------------------------------------------- | --------------------------------------------------------- |
| MinIO API     | `http://localhost:9000`                | `admin` (root) · `developer` (bucket `developer`) | `password-dev`                                            |
| MinIO Console | `http://localhost:9001`                | `admin`                                           | `password-dev`                                            |
| PostgreSQL    | `localhost:5432`                       | `root` · `developer`                              | `password-dev`                                            |
| MySQL         | `localhost:3306`                       | `root` · `developer`                              | `password-dev`                                            |
| Redis         | `localhost:6379`                       | `default` · `developer`                           | `password-dev`                                            |
| Oracle        | `localhost:1521` (servicio `FREEPDB1`) | `system` · `developer`                            | `password-dev`                                            |
| MongoDB       | `localhost:27017`                      | `root` · `developer`                              | `password-dev`                                            |
| SQL Server    | `localhost:1433`                       | `sa` · `developer`                                | `Dev-Passw0rd!2026` (`sa`) · `password-dev` (`developer`) |

Detalles, cadenas de conexión y reinicialización en [dev-infra/README.md](dev-infra/README.md).

### wiremock

| Servicio              | URL                                     |
| --------------------- | --------------------------------------- |
| WireMock              | `http://localhost:8080`                 |
| GUI de administración | `http://localhost:8080/__admin/webapp/` |

### floci

| Servicio      | URL                                             | Emula                                             |
| ------------- | ----------------------------------------------- | ------------------------------------------------- |
| Consola web   | `http://localhost:4500/console/{aws,azure,gcp}` | —                                                 |
| `floci-aws`   | `http://localhost:4566`                         | AWS (S3, DynamoDB, Lambda, IAM…)                  |
| `floci-azure` | `http://localhost:4577`                         | Azure (Storage, Functions, Cosmos DB, Key Vault…) |
| `floci-gcp`   | `http://localhost:4588`                         | GCP (GCS, Firestore, Pub/Sub, BigQuery…)          |

Credenciales de prueba de AWS: `AWS_ACCESS_KEY_ID=test`, `AWS_SECRET_ACCESS_KEY=test`, región `us-east-1`.

```bash
aws --endpoint-url http://localhost:4566 s3 ls
```

## Seguridad

- Todas las credenciales documentadas aquí son **de ejemplo y solo para desarrollo local**. No expongas estos puertos en una red compartida ni reutilices estos valores en otros entornos.
- `dev-infra/.env` contiene tus credenciales y está en `.gitignore`: solo se versiona la plantilla `.env.example`. **Nunca subas credenciales reales** al repositorio.
- Los emuladores de `floci/` montan `/var/run/docker.sock`, lo que les da control sobre Docker en tu máquina. Quita ese montaje en las nubes donde no uses Lambda/ECS, Functions o Cloud Run (ver [floci/README.md](floci/README.md)).
- Varios servicios usan imágenes con el tag `latest`. Fija una versión si necesitas reproducibilidad.
- ¿Encontraste un problema de seguridad? Sigue la [política de seguridad](SECURITY.md): reporta de forma privada y no publiques credenciales ni detalles en un issue público.

## Problemas frecuentes

| Síntoma                                                                    | Causa y solución                                                                                                                                                    |
| -------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `port is already allocated`                                                | Otro programa usa ese puerto (por ejemplo, un PostgreSQL local en `5432`). Detén ese programa o cambia el mapeo `ports:` en el `docker-compose.yml`.                |
| `docker compose` dice que falta una variable (`Copia .env.example a .env`) | No creaste `dev-infra/.env`. Ejecuta `cp dev-infra/.env.example dev-infra/.env`.                                                                                    |
| Cambié el `.env` y los usuarios de las bases no cambiaron                  | Los scripts de inicialización solo corren al crear cada volumen. Recrea los datos con `docker compose -f dev-infra/docker-compose.yml down -v` y vuelve a levantar. |
| Aviso `platform (linux/amd64) does not match the detected host platform`   | Una imagen solo existe para x86_64 y corre emulada en Apple Silicon. Es un aviso, no un error (ver [dev-infra/README.md](dev-infra/README.md#notas)).               |

Cada carpeta tiene su propia sección de solución de problemas.

## Contribuir

Las contribuciones son bienvenidas.

1. Crea una carpeta en la raíz con un nombre descriptivo (`scripts/`, `python/`, `node/`…) o mejora una existente.
2. Incluye en ella un `README.md`: qué es, cómo se usa y qué puertos o credenciales requiere.
3. Añade una fila a la tabla [Contenido](#contenido) de este README.
4. Nunca incluyas credenciales reales, datos personales ni binarios pesados. Los valores de ejemplo deben ser obviamente ficticios.
5. Abre un pull request describiendo qué cambia y cómo lo probaste.

## Licencia

[MIT](LICENSE) © 2025-2026 Ivan Firestone. Puedes usar, copiar y modificar este contenido libremente, conservando el aviso de copyright.

Este repositorio orquesta software de terceros y no incluye su código: [Floci](https://floci.io) (MIT), [WireMock](https://wiremock.org/) y [`wiremock-gui`](https://hub.docker.com/r/holomekc/wiremock-gui), MinIO (vía una copia de la imagen de Chainguard), y las imágenes oficiales de las bases de datos. Cada uno se rige por su propia licencia.

Los nombres de productos y marcas mencionados (MinIO, PostgreSQL, MySQL, Oracle, SQL Server, MongoDB, Redis, AWS, Azure, GCP, BeyondTrust, WireMock, Postman, Bruno…) pertenecen a sus respectivos dueños. Este proyecto no está afiliado a ellos ni respaldado por ellos. Las colecciones y mocks de `wiremock/` son simulaciones con datos ficticios, no contienen código ni datos de BeyondTrust.
