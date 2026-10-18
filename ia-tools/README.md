# ia-tools

Skills de IA para **diagnosticar logs y problemas operativos**. Cada skill es un módulo especializado en una tecnología: le das un log, una traza o una alerta, y el asistente identifica el origen, pregunta lo que le falta para no suponer, y devuelve un reporte estructurado con hallazgos, causa probable y siguientes pasos.

Están escritos en español y en el formato de *skill* (`SKILL.md` con metadatos `name` y `description`) que usan asistentes como [Claude Code](https://claude.com/claude-code). El contenido es texto plano en Markdown, así que también sirve como instrucciones para cualquier otro asistente.

## Skills disponibles

Cada skill vive en `skills/<nombre>/SKILL.md`.

| Skill | Analiza logs de |
| --- | --- |
| `log-analyzer-cloud` | Nube pública: AWS (CloudWatch, CloudTrail, Lambda…), Azure y GCP |
| `log-analyzer-database` | PostgreSQL, Oracle y SQL Server |
| `log-analyzer-docker` | Docker Engine, Docker Compose y builds (Dockerfile/BuildKit) |
| `log-analyzer-dotnet` | .NET / C#: ASP.NET Core, Worker Services, EF Core, Serilog, NLog |
| `log-analyzer-ibm-api-connect` | IBM API Connect: DataPower Gateway, API Manager, Portal, Analytics |
| `log-analyzer-kafka` | Apache Kafka: broker, controller, Connect, Streams, producers y consumers |
| `log-analyzer-kubernetes` | Kubernetes (vanilla, EKS, GKE, AKS) y OpenShift |
| `log-analyzer-laravel` | Laravel 9, 10 y 11 |
| `log-analyzer-minio` | MinIO: standalone, distribuido y Kubernetes Operator |
| `log-analyzer-php` | Runtime de PHP: php-fpm, mod_php y CLI |
| `log-analyzer-quarkus` | Quarkus, en JVM o nativo (GraalVM) |
| `log-analyzer-spring-boot` | Spring Boot y Spring Framework |
| `log-analyzer-sre` | Alertas y métricas de SRE: Prometheus, Grafana, AlertManager, PagerDuty, Datadog, SLOs |
| `log-analyzer-web-server` | nginx, Apache httpd, Tomcat e IIS |
| `log-analyzer-windows-event-log` | Windows Server Event Log (Application, System, Security…) |

El campo `description` de cada `SKILL.md` lista las señales concretas que activan ese skill (por ejemplo, `kafka.server` o `ISR` para Kafka), de modo que el asistente elige el correcto a partir del log que le pegues.

## Cómo usarlos

### Con Claude Code

1. Copia las carpetas de los skills que quieras a tu directorio de skills:
   - **Para todos tus proyectos:** `~/.claude/skills/`
   - **Solo para un proyecto:** `<tu-proyecto>/.claude/skills/`

   ```bash
   # Todos los skills, para todos tus proyectos
   cp -R ia-tools/skills/* ~/.claude/skills/

   # Solo uno
   cp -R ia-tools/skills/log-analyzer-kafka ~/.claude/skills/
   ```

2. Reinicia la sesión de Claude Code para que los cargue.
3. Pega un log o adjunta un archivo y pide el análisis. No hace falta nombrar el skill: se activa por el contenido del log.

```text
Analiza este log, identifica la tecnología y dime cuál es el origen del problema.
```

### Con otros asistentes

Copia el contenido del `SKILL.md` de la tecnología que corresponda (o varios) como instrucciones del sistema o al inicio de la conversación, y pega después el log.

## Qué hace cada skill

Todos siguen la misma estructura, para que los reportes sean comparables entre tecnologías:

1. **Señales de detección:** cómo reconocer que el log es de esa tecnología.
2. **Preguntar antes de analizar:** una tabla con el contexto que el skill debe pedir si falta (entorno, versión, componente afectado…), en lugar de asumirlo.
3. **Datos sensibles a marcar:** qué tipo de información delicada puede aparecer en ese log (contraseñas, tokens, hostnames internos, payloads).
4. **Patrones de error de la tecnología:** los mensajes más frecuentes con su interpretación y qué revisar. El nombre de esta sección varía según el skill (por ejemplo, "Patrones de error y advertencia", "Event IDs críticos" o una sección por producto).
5. **Formato de reporte estándar:** resumen ejecutivo, hallazgos, causa probable y acciones recomendadas.

Casi todos cierran además con una sección de **Referencias** (documentación oficial).

## Principios

- **No asumir contexto no declarado.** Si falta un dato que cambia el diagnóstico (por ejemplo, el factor de replicación en Kafka), el skill lo pregunta.
- **Priorizar la evidencia del log** sobre las suposiciones.
- **Señalar los datos sensibles sin ocultarlos:** los marca para que decidas qué hacer, no los censura ni los modifica.
- **Un skill por tecnología o dimensión**, para que cada uno sea corto, enfocado y fácil de mantener.

## Privacidad

Los logs suelen contener información sensible. Antes de pegar un log en un asistente de IA, revisa y elimina contraseñas, tokens, claves, datos personales y nombres de sistemas internos, según las políticas de tu organización. Los skills ayudan a identificarlos, pero la decisión de qué compartir es tuya.

## Agregar o mejorar un skill

1. Crea `skills/log-analyzer-<tecnologia>/SKILL.md`.
2. Empieza con el bloque de metadatos:

   ```markdown
   ---
   name: log-analyzer-<tecnologia>
   description: "Analiza logs de <tecnología> y produce un diagnóstico estructurado. Úsalo cuando el log contenga <señales concretas>."
   ---
   ```

3. Sigue las cinco secciones de [Qué hace cada skill](#qué-hace-cada-skill).
4. Añade una fila a la tabla de [Skills disponibles](#skills-disponibles).
5. Usa solo ejemplos ficticios: nunca incluyas logs reales con datos de clientes o de tu organización.
