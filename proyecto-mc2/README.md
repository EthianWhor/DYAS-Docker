# Parte 4: Minecraft 2 en un contenedor

Archivos de la Parte 4 del taller para el proyecto del equipo,
[Minecraft 2](https://github.com/MarshallGomez1103/Mc2). Se copian a la carpeta `Minecraft2/` del
proyecto, junto al `pom.xml`:

| Archivo | Para qué |
|---------|----------|
| `Dockerfile` | Imagen *multi-stage*: Maven + JDK 17 compilan el `.jar`; la imagen final solo tiene el JRE 17 y el `.jar`, y corre con el usuario `app`. |
| `.dockerignore` | Deja fuera `target/`, `worlds/`, `test/`, `docs/`, `perf/` y los archivos de Docker. |
| `docker-compose.yml` | Levanta el juego con un volumen para los mundos guardados. |

## Diferencias con el Dockerfile de ejemplo del taller

El ejemplo del taller es para una aplicación Spring Boot. Minecraft 2 es un juego de escritorio
(LibGDX/OpenGL), así que se adaptó:

- **Java 17** en lugar de 21: el `pom.xml` compila con `maven.compiler.release=17`.
- **Carpetas no estándar:** el proyecto tiene las fuentes en `src/` y las pruebas en `test/`. Se
  compila con `-Dmaven.test.skip=true`, que no compila las pruebas, y por eso solo se copia `src/`.
- **Nombre exacto del `.jar`:** `maven-shade-plugin` deja dos archivos en `target/`
  (`minecraft2-0.1.0-SNAPSHOT.jar` y `original-minecraft2-0.1.0-SNAPSHOT.jar`). Con `cp target/*.jar`
  el `cp` falla, así que se copia el nombre exacto.
- **Modo consola:** un contenedor no tiene pantalla ni GPU. La imagen arranca el menú de consola del
  juego (`-Dmc2.console=true`), que crea, lista, guarda y elimina mundos. La opción *Jugar* necesita
  la ventana OpenGL y no funciona dentro del contenedor.
- **Sin base de datos ni `.env`:** el juego guarda los mundos en archivos JSON. La propiedad
  `-Dmc2.worlds.dir=/data/worlds` los lleva a un volumen.
- **Sin `HEALTHCHECK`:** no es un servidor y no expone un endpoint que Docker pueda consultar.

## Uso

Desde la carpeta `Minecraft2/` del proyecto:

```bash
docker build --check .
docker build -t mc2:dev .
docker run --rm -it -v mc2-mundos:/data/worlds mc2:dev
```

O con Compose (el menú es interactivo, por eso `run` y no `up`):

```bash
docker compose run --rm mc2
```

Comprobaciones para la evidencia:

```bash
docker images mc2                                   # tamaño de la imagen final
docker run --rm --entrypoint id mc2:dev             # uid=...(app): no corre como root
docker run --rm --entrypoint java mc2:dev -version  # solo JRE 17, sin Maven
```

## Verificación hecha sin Docker

En un equipo sin Docker se reprodujo la etapa de compilación con los mismos comandos y un directorio
que solo tenía `pom.xml` y `src/` (lo que deja pasar el `.dockerignore`): `dependency:go-offline` y
`package -Dmaven.test.skip=true` terminan bien y generan los dos `.jar`. Después, el `.jar` corrió
en modo consola con `-Dmc2.worlds.dir`, creó un mundo y lo guardó como JSON en ese directorio.
La construcción real con `docker build` está pendiente de ejecutar.
