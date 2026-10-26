# Evidencias

Las evidencias del taller (capturas y salidas de comandos) se publican en el **Wiki** del repositorio.
Esta carpeta guarda el script que las genera y, una vez ejecutado, las salidas en texto.

| Archivo | Contenido |
|---------|-----------|
| `generar-evidencias.sh` | Ejecuta los Pasos 1 a 6 y guarda la salida de cada comando en `logs/`. |
| `logs/` | Salidas de los comandos (se crea al ejecutar el script). |
| `capturas/` | Capturas de pantalla para el Wiki. |

## Cómo generarlas

Requisitos: Docker Desktop iniciado (`docker version` muestra **Client** y **Server**).

```bash
bash evidencias/generar-evidencias.sh
```

El script deja Traefik corriendo al final para tomar las capturas del navegador:

| Captura | Dónde |
|---------|-------|
| `03-hola-sin-redis.png` | Paso 3, http://localhost:4000 con `docker run` (sin Redis). |
| `05-contador.png` | Paso 5, http://localhost:4000 con el contador aumentando. |
| `06-hostname-1.png`, `06-hostname-2.png`, `06-hostname-3.png` | Paso 6, tres recargas con *hostnames* distintos. |
| `06-dashboard-traefik.png` | Paso 6, http://localhost:8080. |
| `07-dockerhub.png` | Parte 3, la imagen en Docker Hub con las etiquetas `0.1.0` y `latest`. |
| `08-mc2-contenedor.png` | Parte 4, el menú de Minecraft 2 corriendo en el contenedor. |

La Parte 3 (publicar en Docker Hub) y la Parte 4 (Minecraft 2) se hacen a mano: ver el Wiki.
