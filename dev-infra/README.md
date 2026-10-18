# dev-infra

Stack de desarrollo local con Docker Compose: almacenamiento de objetos y las bases de datos más comunes, listas para usar desde tu máquina y con un usuario de desarrollo ya creado en cada una.

| Servicio | Qué es | Puerto |
| --- | --- | --- |
| MinIO | Almacenamiento de objetos compatible con S3 (con consola web) | `9000` (API), `9001` (consola) |
| PostgreSQL | Base de datos relacional | `5432` |
| MySQL | Base de datos relacional | `3306` |
| Redis | Almacén en memoria | `6379` |
| Oracle Free | Base de datos relacional | `1521` |
| MongoDB | Base de datos de documentos | `27017` |
| SQL Server | Base de datos relacional (Azure SQL Edge, funciona en ARM) | `1433` |

Además hay dos contenedores de un solo uso que dejan todo configurado y terminan: `minio-setup` (crea el bucket y su usuario) y `mssql-init` (crea el login y la base en SQL Server).

> **Solo para desarrollo local.** Las credenciales son de ejemplo. No expongas estos puertos en una red compartida.

## Inicio rápido

Requisito: [Docker](https://docs.docker.com/get-docker/) con Compose v2.

```bash
cd dev-infra
cp .env.example .env     # crea tu configuración local (no se versiona)
docker compose up -d     # levanta todo
docker compose ps        # comprueba el estado
```

`minio-setup` y `mssql-init` aparecerán como `Exited (0)`: es lo esperado, significa que terminaron bien. Oracle puede tardar un par de minutos en estar listo la primera vez.

Para detener: `docker compose down`. Para detener y **borrar todos los datos**: `docker compose down -v`.

> Si quieres usar otros usuarios o contraseñas, edita `.env` **antes** del primer `up`. Ver [Configuración](#configuración).

## Configuración

Las credenciales **no se versionan**. Toda la configuración está en un único archivo, `.env`, que se crea desde la plantilla versionada `.env.example`. Docker Compose lo carga automáticamente y, si falta alguna variable, se detiene con el mensaje `Copia .env.example a .env`.

| Variable | Uso | Por defecto |
| --- | --- | --- |
| `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` | Credenciales root (administrador) de MinIO. | `admin` / `password-dev` |
| `MINIO_BUCKET_NAME` | Nombre del bucket que crea `minio-setup` al arrancar. | `developer` |
| `MINIO_BUCKET_USER` / `MINIO_BUCKET_PASSWORD` | Usuario y contraseña con acceso a ese bucket (access key y secret key). | `developer` / `password-dev` |
| `DEV_USER` / `DEV_PASSWORD` | Usuario y contraseña que se crean en PostgreSQL, MySQL, Redis, Oracle, MongoDB y SQL Server. También nombran la base de datos de SQL Server. | `developer` / `password-dev` |
| `DB_ROOT_PASSWORD` | Contraseña de `root` en PostgreSQL, MySQL y MongoDB, y de `system` en Oracle. | `password-dev` |
| `MSSQL_SA_PASSWORD` | Contraseña de `sa` en SQL Server. Debe cumplir la política de complejidad de Microsoft (mínimo 8 caracteres con mayúsculas, minúsculas, números y símbolos). | `Dev-Passw0rd!2026` |

Evita comillas simples y dobles en las contraseñas: se interpolan en scripts SQL.

> **Importante:** los scripts que crean los usuarios solo se ejecutan la primera vez que se crea cada volumen. Si cambias `.env` después, recrea los datos con `docker compose down -v && docker compose up -d`. La excepción es Redis, que regenera sus usuarios en cada arranque.

## Credenciales y conexión

Los valores de la tabla son los de `.env.example`; si los cambiaste, usa los tuyos.

| Servicio | Host | Usuario | Contraseña | Permisos |
| --- | --- | --- | --- | --- |
| MinIO (root) | `http://localhost:9000` · consola `http://localhost:9001` | `MINIO_ROOT_USER` | `MINIO_ROOT_PASSWORD` | Administrador |
| MinIO (bucket) | `http://localhost:9000` | `MINIO_BUCKET_USER` (access key) | `MINIO_BUCKET_PASSWORD` (secret key) | Lectura, escritura y borrado en el bucket `MINIO_BUCKET_NAME` |
| PostgreSQL | `localhost:5432`, BD `postgres` | `root` | `DB_ROOT_PASSWORD` | Superusuario |
| PostgreSQL | `localhost:5432`, BD `postgres` | `DEV_USER` | `DEV_PASSWORD` | Superusuario |
| MySQL | `localhost:3306` | `root` | `DB_ROOT_PASSWORD` | Root |
| MySQL | `localhost:3306` | `DEV_USER` | `DEV_PASSWORD` | `ALL PRIVILEGES ON *.* WITH GRANT OPTION` |
| Redis | `localhost:6379` | `default` y `DEV_USER` | `DEV_PASSWORD` | `~* &* +@all` |
| Oracle | `localhost:1521`, servicio `FREEPDB1` | `system` | `DB_ROOT_PASSWORD` | DBA |
| Oracle | `localhost:1521`, servicio `FREEPDB1` | `DEV_USER` | `DEV_PASSWORD` | `DBA, CONNECT, RESOURCE` |
| MongoDB | `localhost:27017`, BD `admin` | `root` | `DB_ROOT_PASSWORD` | Rol `root` |
| MongoDB | `localhost:27017`, BD `admin` | `DEV_USER` | `DEV_PASSWORD` | Rol `root` |
| SQL Server | `localhost:1433` | `sa` | `MSSQL_SA_PASSWORD` | `sysadmin` |
| SQL Server | `localhost:1433`, BD `DEV_USER` | `DEV_USER` | `DEV_PASSWORD` | `sysadmin` |

Cadenas de conexión de ejemplo (con los valores por defecto):

```text
postgresql://developer:password-dev@localhost:5432/postgres
mysql://developer:password-dev@localhost:3306
redis://developer:password-dev@localhost:6379
mongodb://developer:password-dev@localhost:27017/?authSource=admin
jdbc:oracle:thin:@//localhost:1521/FREEPDB1            (usuario developer / password-dev)
Server=localhost,1433;Database=developer;User Id=developer;Password=password-dev;TrustServerCertificate=True
```

Desde otro contenedor de la misma red de Compose (`dev-network`), usa el nombre del servicio como host (`postgres`, `mysql`, `redis`, `oracle`, `mongo`, `mssql`, `minio`) en lugar de `localhost`.

## Uso diario

Todos los comandos se ejecutan desde esta carpeta (`dev-infra/`).

```bash
docker compose up -d                 # Levantar el stack
docker compose ps                    # Estado de los contenedores
docker compose logs -f postgres      # Logs de un servicio
docker compose restart redis         # Reiniciar un servicio
docker compose down                  # Detener (los datos se conservan)
docker compose down -v               # Detener y BORRAR los volúmenes
```

### Levantar solo algunos servicios

Cada servicio se puede arrancar por separado. Útil si tu máquina va justa de memoria (Oracle y SQL Server son los más pesados):

```bash
docker compose up -d postgres redis             # solo PostgreSQL y Redis
docker compose up -d minio minio-setup          # MinIO con su bucket
docker compose up -d mssql mssql-init           # SQL Server con su login
```

Nombres de servicio: `minio`, `minio-setup`, `postgres`, `mysql`, `redis`, `oracle`, `mongo`, `mssql`, `mssql-init`.

### Datos persistentes

Los datos viven en volúmenes de Docker con nombre: `minio-data`, `postgres-data`, `mysql-data`, `redis-data`, `oracle-data`, `mongo-data`, `mongo-configdb`, `mssql-data`, `mssql-extensibility`, `mssql-extensibility-data` y `mssql-extensibility-log`. Sobreviven a `docker compose down` y se borran con `down -v`.

## Archivos

| Archivo | Descripción |
| --- | --- |
| `docker-compose.yml` | Definición del stack. |
| `.env.example` | Plantilla con todas las variables (cópiala a `.env`, que no se versiona). |
| `minio-setup-bucket.sh` | Crea el bucket y su usuario en MinIO (lo ejecuta `minio-setup`). |
| `minio-configurator.sh` | Configurador genérico de bucket y usuario para cualquier MinIO. |
| `minio-public-policy.json` / `minio-private-writer.json` | Plantillas de las políticas del bucket. Ambos scripts de MinIO las leen y sustituyen `${MINIO_BUCKET_NAME}` por el valor de `.env`. Edítalas si quieres otros permisos. |
| `postgres-init-developer.sh` | Crea el rol `DEV_USER` en PostgreSQL. |
| `mysql-init-developer.sh` | Crea el usuario `DEV_USER` en MySQL. |
| `oracle-init-developer.sh` | Crea el usuario `DEV_USER` en Oracle (`FREEPDB1`). |
| `mongo-init-developer.js` | Crea el usuario `DEV_USER` (rol `root`) en MongoDB. |
| `mssql-init-developer.sh` / `mssql-init-developer.sql` | Crean el login y la base `DEV_USER` en SQL Server (los ejecuta `mssql-init`). |

Redis no tiene archivo de inicialización: su ACL se genera al arrancar a partir de `DEV_USER` y `DEV_PASSWORD`.

## Inicialización automática

### MinIO

`minio-setup` espera a que MinIO responda y comprueba si el bucket `MINIO_BUCKET_NAME` ya existe. Si no existe, crea:

- el bucket, con los prefijos `public/` y `private/`;
- una política de lectura anónima para `public/*`;
- la política `<MINIO_BUCKET_NAME>-private-writer` (lectura, escritura, borrado y listado en todo el bucket);
- el usuario `MINIO_BUCKET_USER` con la contraseña `MINIO_BUCKET_PASSWORD` y esa política asignada.

Si el bucket ya existe, termina sin hacer cambios. Para forzar una nueva configuración, usa `minio-configurator.sh` (abajo) o recrea los volúmenes.

### PostgreSQL, MySQL, Oracle y MongoDB

Se ejecutan los scripts montados en el directorio de inicialización de cada imagen, solo la primera vez que se crea el volumen. Para aplicarlos de nuevo sin borrar datos, ejecuta el script a mano:

```bash
docker exec postgres sh /docker-entrypoint-initdb.d/10-create-developer.sh
docker exec mysql sh /docker-entrypoint-initdb.d/10-create-developer.sh
```

### SQL Server

`mssql-init` espera a que SQL Server acepte conexiones y aplica `mssql-init-developer.sql`. Es idempotente: puedes repetirlo con `docker compose run --rm mssql-init`.

### Redis

Genera `/tmp/users.acl` en cada arranque con los usuarios `default` y `DEV_USER`, así que siempre coincide con tu `.env` sin recrear volúmenes.

## Configurador genérico de MinIO

`minio-configurator.sh` configura un bucket y un usuario en **cualquier** MinIO (local o remoto), no solo en este stack. A diferencia de `minio-setup-bucket.sh`, se puede ejecutar varias veces sobre el mismo bucket: reaplica las políticas.

Necesita `bash`, el cliente [`mc`](https://min.io/docs/minio/linux/reference/minio-mc.html) y las dos plantillas de política (por defecto, en la misma carpeta que el script).

```bash
./minio-configurator.sh <bucket> <usuario>
```

Variables de entorno (si no se definen, el script las pide de forma interactiva):

| Variable | Por defecto |
| --- | --- |
| `MINIO_ENDPOINT` | `http://127.0.0.1:9000` |
| `MINIO_ROOT_USER` | `admin` |
| `MINIO_ROOT_PASSWORD` | `password-dev` |
| `MINIO_ALIAS` | `minio` |
| `MINIO_BUCKET_PASSWORD` | se pide si no está definida |
| `MINIO_POLICY_DIR` | carpeta del script |

Ejemplo no interactivo:

```bash
MINIO_ENDPOINT=http://localhost:9000 \
MINIO_ROOT_USER=admin \
MINIO_ROOT_PASSWORD=password-dev \
MINIO_BUCKET_PASSWORD=password-dev \
./minio-configurator.sh mi-bucket mi-usuario
```

Sin instalar `mc`, contra el MinIO de este stack (la imagen de MinIO ya trae `bash` y `mc`):

```bash
docker run --rm --network dev-network \
  -v "$PWD:/work:ro" \
  -e MINIO_ENDPOINT=http://minio:9000 \
  -e MINIO_ROOT_USER=admin \
  -e MINIO_ROOT_PASSWORD=password-dev \
  -e MINIO_BUCKET_PASSWORD=password-dev \
  --entrypoint /usr/bin/bash \
  madlabcg/minio:madlab-2026.09 /work/minio-configurator.sh mi-bucket mi-usuario
```

## Imágenes

| Servicio | Imagen |
| --- | --- |
| MinIO y `minio-setup` | `madlabcg/minio:madlab-2026.09` |
| PostgreSQL | `postgres:latest` |
| MySQL | `mysql:latest` |
| Redis | `redis:latest` |
| Oracle | `gvenzl/oracle-free:latest` |
| MongoDB | `mongo:latest` |
| SQL Server | `mcr.microsoft.com/azure-sql-edge:latest` |
| `mssql-init` | `mcr.microsoft.com/mssql/server:2022-latest` (solo como cliente `sqlcmd`) |

> [!NOTE]
> **Sobre la imagen de MinIO.** MinIO dejó de publicar imágenes oficiales en Docker Hub y quay.io. Este stack usa [`madlabcg/minio`](https://hub.docker.com/r/madlabcg/minio), una imagen **pública** que mantiene el autor de este repositorio. Es una copia, sin modificaciones, de la imagen pública de [Chainguard](https://images.chainguard.dev/directory/image/minio/overview) (MinIO compilado desde el código fuente, `linux/amd64` y `linux/arm64`). La copia existe para poder fijar la versión, porque Chainguard solo publica gratis el tag `latest`. La imagen incluye `bash` y `mc`, por eso también la usa `minio-setup`; no incluye `sed`, `awk` ni `grep`.
>
> Para actualizar a una versión nueva:
>
> ```bash
> docker run --rm cgr.dev/chainguard/minio:latest --version        # versión actual de Chainguard
> docker buildx imagetools create \
>   -t madlabcg/minio:madlab-<version> \
>   -t madlabcg/minio:latest \
>   cgr.dev/chainguard/minio:latest                                 # copia ambas arquitecturas
> ```
>
> Después cambia el tag en `docker-compose.yml`. Si prefieres no depender de esa copia, puedes reemplazar la imagen por cualquier otra de MinIO compatible, o por `cgr.dev/chainguard/minio:latest`.

## Problemas frecuentes

| Síntoma | Causa y solución |
| --- | --- |
| `Copia .env.example a .env` al hacer `up` | Falta tu `.env`. Ejecuta `cp .env.example .env`. |
| `port is already allocated` | Otro programa usa ese puerto. Detenlo o cambia el mapeo `ports:` en `docker-compose.yml`. |
| Cambié `.env` pero el usuario o la contraseña no cambiaron | Los scripts solo corren al crear el volumen. `docker compose down -v && docker compose up -d`. |
| Oracle tarda en responder | Es normal la primera vez (puede tardar un par de minutos). Sigue el progreso con `docker compose logs -f oracle` hasta ver que la base está lista. |
| SQL Server rechaza la contraseña de `sa` o el contenedor se detiene | La contraseña no cumple la política de complejidad de Microsoft. Revisa `MSSQL_SA_PASSWORD` y mira `docker compose logs mssql`. |
| Aviso `platform (linux/amd64) does not match the detected host platform` en `mssql-init` | `mssql-init` usa una imagen solo `amd64` que corre emulada en Apple Silicon. Es un aviso, no afecta el resultado. |
| `minio-setup` dice que el bucket ya existe y no crea el usuario | Es el comportamiento esperado si el volumen ya tenía datos. Usa `minio-configurator.sh` o recrea los volúmenes. |
| Caracteres raros o error al iniciar un script con una contraseña | Evita comillas simples y dobles en las contraseñas. |

## Notas

- Las credenciales por defecto son deliberadamente simples. Cámbialas en tu `.env` si el equipo es compartido o expuesto.
- Varias imágenes usan `latest`; fija una versión en `docker-compose.yml` si necesitas reproducibilidad.
- En x86_64 también puedes usar `mcr.microsoft.com/mssql/server:2022-latest` como servidor de SQL Server: hay una línea comentada en el compose.
- Probado en macOS con Apple Silicon y OrbStack.
