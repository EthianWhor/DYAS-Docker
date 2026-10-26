# syntax=docker/dockerfile:1

# Dockerfile multi-stage del proyecto Minecraft 2 (https://github.com/MarshallGomez1103/Mc2).
# Va en la carpeta Minecraft2/ del proyecto, junto al pom.xml.
#
# Minecraft 2 es un juego de escritorio (LibGDX/OpenGL), no una aplicación web: un contenedor
# no tiene pantalla ni GPU. Por eso la imagen arranca el menú de consola del juego
# (-Dmc2.console=true), que crea, lista, guarda y elimina mundos sin abrir la ventana gráfica.

# Etapa 1: compilar el .jar con Maven (las pruebas ya corren en el pipeline de CI)
FROM maven:3.9.16-eclipse-temurin-17-noble AS build
WORKDIR /src
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp -q dependency:go-offline
# El proyecto usa carpetas no estándar: fuentes y recursos en src/, pruebas en test/.
# -Dmaven.test.skip=true no compila las pruebas, así que test/ no se copia.
COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -ntp -q package -Dmaven.test.skip=true \
 && cp target/minecraft2-0.1.0-SNAPSHOT.jar /app.jar
# maven-shade-plugin deja dos .jar en target/ (el ejecutable y original-*.jar):
# se copia el nombre exacto en lugar de target/*.jar.

# Etapa 2: imagen final solo con el JRE y el .jar
FROM eclipse-temurin:17.0.20.1_1-jre-noble
RUN groupadd --system app && useradd --system --gid app --no-create-home app \
 && mkdir -p /data/worlds && chown -R app:app /data
WORKDIR /app
COPY --from=build --chown=app:app /app.jar app.jar
USER app

# Los mundos guardados (JSON) viven en un volumen, fuera de la capa de escritura del contenedor
VOLUME ["/data/worlds"]

# Sin HEALTHCHECK: el juego no es un servidor y no expone un endpoint que Docker pueda consultar.
# La JVM usa como máximo el 75 % de la memoria que el contenedor tenga asignada
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-Dmc2.console=true", "-Dmc2.worlds.dir=/data/worlds", "-jar", "/app/app.jar"]
