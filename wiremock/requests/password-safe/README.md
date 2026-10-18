# Requests de prueba — password-safe

Colecciones de **Postman** y **Bruno** con una request por cada uno de los 15 mocks en
[`wiremock/mappings/password-safe/`](../../mappings/password-safe/), nombradas y numeradas igual
que los archivos de mapping para que sea fácil correlacionar cuál request dispara cuál stub.

Antes de usarlas, levanta el mock: `docker compose up -d` desde la carpeta `wiremock/` (ver [../../README.md](../../README.md)). Los valores de las variables (`VALID-API-KEY`, `INVALID-KEY`, `svc_integration`) son ficticios y solo sirven contra este mock.

> Se guarda fuera de `mappings/` a propósito: WireMock recorre esa carpeta
> **recursivamente** y trata cada `.json` que encuentra ahí como un stub — poner
> aquí un archivo con otro formato (como esta colección) rompería la carga de mocks.

## Archivos

```
postman/
  password-safe.postman_collection.json   # las 15 requests
  password-safe.postman_environment.json  # variables (baseUrl, validApiKey, invalidApiKey, runAsUser)
bruno/
  bruno.json                              # metadata de la colección (raíz que Bruno detecta al abrir la carpeta)
  NN-*.bru                                # una request por archivo, mismo orden/numeración que mappings/password-safe/
  environments/WireMock-BeyondTrust.bru   # mismas variables que el environment de Postman
```

El orden en el árbol de Bruno lo controla el campo `seq` de cada `.bru`, no el nombre de archivo.

## Importar en Postman

1. Postman → **Import** → arrastra los dos archivos `.json` de `postman/`.
2. Selecciona el environment `wiremock-password-safe-local` (arriba a la derecha).
3. Corre las requests una por una, o toda la carpeta con **Run collection**.

## Abrir en Bruno

1. Bruno → **Open Collection** → selecciona la carpeta `bruno/` (`wiremock/requests/password-safe/bruno/`).
2. Arriba a la derecha, selecciona el environment **WireMock-BeyondTrust**.
3. Corre las requests una por una, o toda la colección con **Run** (Runner).

## `baseUrl`

El stack publica el puerto `8080` en el host (ver [`../../README.md`](../../README.md)), así que
los environments traen `baseUrl = http://localhost:8080`. Levanta el mock con
`docker compose up -d` desde `wiremock/`. Si despliegas WireMock en otro host, cambia `baseUrl`.

## Qué dispara cada request

| # | Método | Endpoint | Condición | Status esperado |
|---|--------|----------|-----------|------------------|
| 01 | POST | `Auth/SignAppIn` | `Authorization` con `key=VALID-API-KEY` | 200 |
| 02 | POST | `Auth/SignAppIn` | `Authorization` con `key=INVALID-KEY` | 401 |
| 03 | POST | `Auth/SignAppIn` | sin header `Authorization` | 400 |
| 04 | POST | `Auth/Signout` | — | 200 |
| 05 | GET | `ManagedAccounts` | `?systemName=SYS-NOACCESS` | 403 |
| 06 | GET | `ManagedAccounts` | `?accountName=NOTFOUND` | 404 |
| 07 | GET | `ManagedAccounts` | sin esos query params | 200 |
| 08 | POST | `Requests` | body con `SystemID: 9999` | 403 |
| 09 | POST | `Requests` | body con `SystemID: 8888` | 400 |
| 10 | POST | `Requests` | cualquier otro `SystemID` | 201 |
| 11 | GET | `Requests/999/Credentials` | RequestID `999` | 403 |
| 12 | GET | `Requests/888/Credentials` | RequestID `888` | 404 |
| 13 | GET | `Requests/{id}/Credentials` | cualquier otro ID numérico | 200 |
| 14 | PUT | `Requests/777/Checkin` | RequestID `777` | 404 |
| 15 | PUT | `Requests/{id}/Checkin` | cualquier otro ID numérico | 204 |
