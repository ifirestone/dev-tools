# floci

Emuladores locales de **AWS, Azure y GCP** para desarrollar y probar sin cuenta de nube, sin costos y sin conexión. Son tres emuladores (Floci para AWS, Floci-AZ para Azure y Floci-GCP para GCP) más una consola web unificada que los muestra a los tres en un solo lugar. Los puertos se publican directo en tu máquina, sin túnel ni TLS propio. Pensado para correr en el equipo de un desarrollador (probado con OrbStack en macOS con Apple Silicon).

> **Solo para desarrollo local.** Los emuladores usan credenciales de prueba fijas, sin valor fuera de tu máquina, y montan el socket de Docker. Ver [Seguridad](#seguridad).

## Sobre Floci

Este directorio **no contiene código de Floci**: solo un `docker-compose.yml` que orquesta sus imágenes oficiales de Docker. Floci es un proyecto de código abierto (licencia MIT) mantenido por terceros, y toda la emulación la hacen sus imágenes. Para documentación, servicios soportados, configuración avanzada, novedades y reportar problemas, consulta el proyecto original:

| Recurso | Enlace |
| --- | --- |
| Sitio y documentación | <https://floci.io> |
| Emulador de AWS (`floci/floci`) | <https://github.com/floci-io/floci> |
| Emulador de Azure (`floci/floci-az`) | <https://github.com/floci-io/floci-az> |
| Emulador de GCP (`floci/floci-gcp`) | <https://github.com/floci-io/floci-gcp> |
| Consola web (`floci/floci-ui`) | <https://floci.io/floci/ui/> · [Docker Hub](https://hub.docker.com/r/floci/floci-ui) |

Este repositorio no está afiliado al proyecto Floci. Si algo falla en un emulador (y no en cómo está orquestado aquí), el lugar correcto para reportarlo son los repositorios de arriba.

## Inicio rápido

Requisito: [Docker](https://docs.docker.com/get-docker/) con Compose v2.

```bash
cd floci
docker compose up -d
docker compose ps
```

No necesitas crear ningún archivo de configuración: no hay `.env` ni credenciales que gestionar.

Abre la consola web:

| Nube | Consola |
| --- | --- |
| AWS | <http://localhost:4500/console/aws> |
| Azure | <http://localhost:4500/console/azure> |
| GCP | <http://localhost:4500/console/gcp> |

(Con OrbStack también está disponible en `https://floci-ui.orb.local/console/<nube>`.)

Para detener: `docker compose down`. Para detener y borrar los datos de los emuladores: `docker compose down -v`.

## Ejemplo: usar S3 de AWS

Apunta cualquier SDK o la CLI de AWS al emulador con `--endpoint-url` y las credenciales de prueba:

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1

aws --endpoint-url http://localhost:4566 s3 mb s3://mi-bucket
aws --endpoint-url http://localhost:4566 s3 ls
```

Si no tienes la CLI de AWS instalada, puedes usar su imagen oficial dentro de la red de Compose:

```bash
docker run --rm --network floci_default \
  -e AWS_ACCESS_KEY_ID=test -e AWS_SECRET_ACCESS_KEY=test -e AWS_DEFAULT_REGION=us-east-1 \
  amazon/aws-cli --endpoint-url http://floci-aws:4566 s3 ls
```

Para Azure (`http://localhost:4577`) y GCP (`http://localhost:4588`) usa los SDK o CLIs de cada nube apuntando a esos endpoints. Los servicios disponibles en cada emulador aparecen en su log de arranque: `docker logs floci-azure`.

## Seguridad

- Las credenciales de AWS (`test` / `test`) son de prueba. No sirven fuera del emulador y no debes reemplazarlas por reales.
- Los emuladores montan `/var/run/docker.sock`, lo que les da control sobre Docker en tu máquina. Se usa para las funciones que levantan contenedores reales (Lambda/ECS, Functions, Cloud Run). Si no vas a usarlas en una nube concreta, quita ese montaje de su servicio en `docker-compose.yml`; el resto de la emulación no lo necesita.
- Los puertos `4500`, `4566`, `4577` y `4588` quedan abiertos en tu máquina. No los expongas en una red compartida.

## Estructura

```text
floci/
├── docker-compose.yml
└── README.md
```

No hay `.env.example`: los tres emuladores usan claves de prueba fijas y no hay dominios que configurar.

## Servicios

| Servicio      | Imagen                    | Puerto | Qué emula                                                              |
| ------------- | ------------------------- | ------ | ------------------------------------------------------------------------ |
| `floci-aws`   | `floci/floci:latest`      | `4566` | AWS (S3, DynamoDB, Lambda, IAM, etc. — ver `docker logs floci-aws`)      |
| `floci-azure` | `floci/floci-az:latest`   | `4577` | Azure (Blob/Queue/Table Storage, Functions, Cosmos DB, Key Vault, SQL…)  |
| `floci-gcp`   | `floci/floci-gcp:latest`  | `4588` | GCP (GCS, Firestore, Pub/Sub, BigQuery, Cloud Functions, Cloud Run…)     |
| `floci-ui`    | `floci/floci-ui:latest`   | `4500` | Consola web con las 3 nubes (`/console/aws`, `/console/gcp`, `/console/azure`) |

Datos persistidos en volúmenes nombrados: `floci_aws_data`, `floci_azure_data`, `floci_gcp_data`.

## Notas / decisiones de diseño

- **`floci-ui` está declarado como servicio propio, no como sidecar automático.**
  `floci-aws` trae código para crear/administrar `floci-ui` bajo demanda usando
  `docker.sock` (clases `FlociUiManager`/`ContainerLifecycleManager` en su binario), pero
  ese mecanismo solo se dispara desde un botón en la propia consola la primera vez que se
  usa, y si el contenedor `floci-ui` ya existe lo **adopta** tal cual en vez de recrearlo
  con la config vigente. Eso lo hace poco confiable para "todo arriba con un solo
  `docker compose up`", así que se desactivó (`FLOCI_SERVICES_UI_ENABLED=false` en
  `floci-aws`) y se levanta como cuarto servicio explícito, con su propia config completa.
  Ni `floci-gcp` ni `floci-azure` tienen ese código de gestión de UI — es exclusivo de
  `floci-aws`.

- **`floci-ui` no descubre las otras nubes solo: hay que decirle dónde están.**
  Por defecto asume que cada nube compañera está en `http://localhost:<puerto>`, lo cual
  solo funciona si todo corre fuera de Docker en el mismo host. Dentro de la red de
  Compose, `localhost` en el contenedor de `floci-ui` apunta a sí mismo, no a
  `floci-gcp`/`floci-azure` — por eso, sin las variables de abajo, la consola muestra AWS
  bien pero GCP/Azure quedan en `"runtime":"unavailable"` aunque los contenedores estén
  sanos. Se resuelve con dos variables de entorno en `floci-ui`, apuntando a los nombres
  DNS reales de Compose:

  ```yaml
  FLOCI_GCP_ENDPOINT=http://floci-gcp:4588
  FLOCI_AZURE_ENDPOINT=http://floci-azure:4577
  ```

  Se puede verificar el estado que ve la consola de cada nube con:

  ```bash
  curl http://localhost:4500/api/clouds/aws/status
  curl http://localhost:4500/api/clouds/gcp/status
  curl http://localhost:4500/api/clouds/azure/status
  ```

- **`docker.sock` no es solo para la consola.** Cada emulador que lo monta lo usa para
  features propias que levantan contenedores reales:
  - `floci-aws`: Lambda (hot-reload) / ECS con contenedores locales.
  - `floci-gcp`: Cloud Functions, Cloud Run y GKE.
  - `floci-azure`: Functions, Postgres/MySQL/MariaDB flexible server, Event Hubs y Service
    Bus — lo anuncia explícitamente en su propio banner de arranque
    (`docker logs floci-azure`), servicio por servicio.

  Si no vas a usar ninguna de esas features en una nube en particular, se le puede quitar
  el mount de `docker.sock` sin afectar el resto (API-level emulation, IAM, storage en
  memoria, etc. no lo necesitan).

## Troubleshooting rápido

- `docker compose logs -f floci-aws` / `floci-gcp` / `floci-azure` / `floci-ui`.
- Si después de un `docker compose down && docker compose up -d` la consola vuelve a
  mostrar solo AWS (o queda vieja/desactualizada): confirmar que `floci-ui` sí se recreó
  (`docker compose ps` — debería figurar con el resto, no aparte) y no quedó un contenedor
  `floci-ui` huérfano de una sesión anterior. Si quedó uno viejo, bajarlo con
  `docker rm -f floci-ui` y volver a `docker compose up -d floci-ui`.
- `"runtime":"unavailable"` en `/api/clouds/<nube>/status` con un error tipo
  `Cannot reach Floci-GCP at http://localhost:<puerto>` = `floci-ui` está usando el
  endpoint por defecto en vez del que se le pasó por variable de entorno — revisar que
  `FLOCI_GCP_ENDPOINT`/`FLOCI_AZURE_ENDPOINT` sigan definidas en el servicio `floci-ui`.
