# Evidencias

Las evidencias del taller (capturas y salidas de comandos) se publican en el **Wiki** del repositorio.
Esta carpeta guarda el script que las genera y las salidas completas de los comandos.

| Archivo | Contenido |
|---------|-----------|
| `generar-evidencias.sh` | Ejecuta los Pasos 1 a 6 y guarda la salida de cada comando en `logs/`. |
| `logs/00` a `logs/06` | Salidas de los Pasos 1 a 6, generadas con el script. |
| `logs/07-*` | Parte 3: publicación en Docker Hub y ejercicio 1 con la imagen publicada. |
| `logs/08-mc2-*` | Salidas de la Parte 4 (Minecraft 2): `--check`, construcción, imagen final y ejecución. |

## Cómo generarlas

Requisitos: Docker Desktop iniciado (`docker version` muestra **Client** y **Server**).

```bash
bash evidencias/generar-evidencias.sh
```

El script deja Traefik corriendo al final para tomar las capturas del navegador
(http://localhost:4000 y el dashboard en http://localhost:8080). Las capturas están en el Wiki.

La Parte 3 (publicar en Docker Hub) y la Parte 4 (Minecraft 2) se hacen a mano: ver el Wiki.
