#!/usr/bin/env bash
# Ejecuta los Pasos 1 a 6 del taller y guarda la salida de cada comando en evidencias/logs/.
# Las capturas de pantalla del navegador (contador, hostnames, dashboard de Traefik) se toman aparte.
#
# Uso, desde la raíz del repositorio y con Docker Desktop iniciado:
#   bash evidencias/generar-evidencias.sh
set -euo pipefail

cd "$(dirname "$0")/.."
raiz="$(pwd)"
logs="$raiz/evidencias/logs"
mkdir -p "$logs"

paso() { printf '\n==> %s\n' "$1"; }
# Guarda el comando y su salida (stdout y stderr) en el archivo indicado, y la muestra en pantalla
registrar() {
  local archivo="$1"; shift
  { printf '$ %s\n' "$*"; "$@" 2>&1; printf '\n'; } | tee -a "$logs/$archivo"
}
esperar_healthy() {
  local contenedor="$1"
  for _ in $(seq 1 30); do
    [ "$(docker inspect -f '{{.State.Health.Status}}' "$contenedor")" = healthy ] && return 0
    sleep 2
  done
  echo "El contenedor $contenedor no llegó a healthy" >&2; return 1
}

rm -f "$logs"/*.txt

paso "Versiones"
registrar 00-versiones.txt docker version
registrar 00-versiones.txt docker compose version

paso "Paso 1: hello-world"
cd "$raiz/hello-world"
registrar 01-hello-world.txt docker build --progress=plain -t helloapp:v1 .
registrar 01-hello-world.txt docker images helloapp

paso "Paso 3: construir y ejecutar friendlyhello"
cd "$raiz/friendlyhello"
registrar 03-build-check.txt docker build --check .
registrar 03-build.txt docker build -t friendlyhello .
registrar 03-build.txt docker images friendlyhello
docker rm -f fh-paso3 >/dev/null 2>&1 || true
docker run -d --rm --name fh-paso3 -p 4000:8000 friendlyhello >/dev/null
esperar_healthy fh-paso3
registrar 03-run.txt curl -s http://localhost:4000/
registrar 03-run.txt docker ps --filter name=fh-paso3
registrar 03-run.txt docker exec fh-paso3 id
docker stop fh-paso3 >/dev/null

paso "Paso 4: caché de capas y orden invertido"
# Copia de app.py fuera del build context, para restaurarlo al terminar el paso
respaldo="$(mktemp)"
cp app.py "$respaldo"
trap 'cp -f "$respaldo" "$raiz/friendlyhello/app.py"' EXIT
# Orden correcto: se cambia app.py y la capa de pip install sale CACHED
docker build -q -t friendlyhello . >/dev/null
echo "# cambio para el Paso 4 ($(date +%s))" >> app.py
inicio=$(date +%s)
registrar 04-cache-orden-correcto.txt docker build --progress=plain -t friendlyhello .
echo "Tiempo total: $(( $(date +%s) - inicio )) s" | tee -a "$logs/04-cache-orden-correcto.txt"
# Orden invertido: el mismo cambio en app.py obliga a reinstalar las dependencias
docker build -q -f Dockerfile.orden-invertido -t friendlyhello:orden-invertido . >/dev/null
echo "# otro cambio para el Paso 4 ($(date +%s))" >> app.py
inicio=$(date +%s)
registrar 04-cache-orden-invertido.txt docker build --progress=plain -f Dockerfile.orden-invertido -t friendlyhello:orden-invertido .
echo "Tiempo total: $(( $(date +%s) - inicio )) s" | tee -a "$logs/04-cache-orden-invertido.txt"
cp -f "$respaldo" app.py
rm -f "$respaldo"
trap - EXIT
# Deja la imagen friendlyhello construida con el app.py original
docker build -q -t friendlyhello . >/dev/null

paso "Paso 5: web + Redis con Compose"
registrar 05-compose.txt docker compose up -d --build --wait
for _ in 1 2 3 4 5; do registrar 05-compose.txt curl -s http://localhost:4000/; done
registrar 05-compose.txt docker compose ps
registrar 05-compose.txt docker compose down

paso "Paso 6: 5 réplicas detrás de Traefik"
registrar 06-traefik.txt docker compose -f docker-compose.traefik.yaml up -d --build --scale web=5 --wait
sleep 5
for _ in $(seq 1 15); do
  curl -s http://localhost:4000/ | sed -n 's/.*Hostname:<\/b> \([^<]*\)<br\/>.*Visits:<\/b> \(.*\)$/hostname=\1  visits=\2/p'
done | tee -a "$logs/06-traefik.txt"
printf '\nHostnames distintos:\n' | tee -a "$logs/06-traefik.txt"
for _ in $(seq 1 30); do
  curl -s http://localhost:4000/ | sed -n 's/.*Hostname:<\/b> \([^<]*\)<br\/>.*/\1/p'
done | sort -u | tee -a "$logs/06-traefik.txt"
registrar 06-traefik.txt docker compose -f docker-compose.traefik.yaml ps
registrar 06-traefik.txt docker ps --filter label=com.docker.compose.service=web
registrar 06-traefik.txt curl -s http://localhost:8080/api/http/services
echo
echo "Traefik sigue arriba para tomar las capturas:"
echo "  - http://localhost:4000 (recargar y capturar 3 hostnames distintos)"
echo "  - http://localhost:8080 (dashboard)"
echo "Al terminar: docker compose -f friendlyhello/docker-compose.traefik.yaml down"
