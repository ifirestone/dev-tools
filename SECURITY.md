# Política de seguridad

## Alcance

`dev-tools` es una colección de herramientas **para desarrollo local**: configuraciones de Docker Compose, mocks, datos de ejemplo y skills de IA. No es un producto para producción ni se despliega como servicio.

Por eso, lo siguiente **no se considera una vulnerabilidad**:

- Las credenciales de ejemplo documentadas (`password-dev`, `test` / `test`, `VALID-API-KEY`, etc.). Son valores ficticios, públicos a propósito y válidos solo en tu máquina.
- Que los servicios escuchen en `localhost` sin TLS, o que algunas imágenes usen el tag `latest`.
- Que los emuladores de `floci/` monten `/var/run/docker.sock`. Está documentado y es necesario para sus funciones con contenedores.
- Que los usuarios de desarrollo tengan permisos amplios (superusuario, `sysadmin`, `root`). Es el comportamiento buscado en un entorno local.

Si usas estas configuraciones fuera de una máquina de desarrollo, cambia todas las credenciales y revisa los puertos expuestos. Ver la sección [Seguridad del README](README.md#seguridad).

## Qué sí reportar

Por favor avisa si encuentras, por ejemplo:

- **Credenciales, tokens, claves o datos personales reales** en el repositorio o en su historial.
- Un script o configuración que pueda **exponer servicios a la red** de forma no documentada, ejecutar código inesperado o dañar datos fuera de los volúmenes del propio stack.
- Una instrucción en un skill de `ia-tools/` que pueda inducir a un asistente a filtrar datos sensibles o a ejecutar acciones no deseadas.
- Dependencias o imágenes referenciadas que hayan sido comprometidas.

## Cómo reportar

Usa el reporte privado de vulnerabilidades de GitHub:

1. Entra a la pestaña **Security** del repositorio.
2. Elige **Report a vulnerability**.
3. Describe el problema, cómo reproducirlo y su impacto.

Si ese botón no aparece, abre un issue con el título "Problema de seguridad" **sin incluir detalles ni datos sensibles**, y te indicaré cómo continuar de forma privada.

No publiques el detalle de una vulnerabilidad ni credenciales reales en un issue o pull request público.

## Qué esperar

Es un proyecto personal mantenido sin garantías de tiempo de respuesta. Intentaré confirmar la recepción de tu reporte en un plazo razonable, corregir lo que corresponda y, si quieres, reconocer tu aporte.

## Versiones soportadas

Solo la rama principal (`master`). No se publican versiones ni se mantienen ramas anteriores.

## Si encuentras tus propias credenciales aquí

Si por error publicaste credenciales reales en un fork o en una contribución, **rótalas de inmediato** (cámbialas en el servicio correspondiente). Borrar el archivo o el commit no es suficiente: el historial de git y las copias en caché pueden conservarlas.
