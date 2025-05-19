#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

PROJECT_SLUG="zit"
PROJECT_SLUG_DASH="zit"
DOMAIN="mospolytime.ru"
DOCKER_USER="root"

CREDENTIALS_PATH="/opt/${PROJECT_SLUG}/secrets.env"
GLOBAL_CREDS_PATH="/opt/secrets.env"
DATA_BASE_PATH="/opt/data"

DEV_NET="dev-network"
PROD_NET="prod-network"

POSTGRES_IMAGE="postgres:17-alpine"

FRONTEND_PORT_START=3000
BACKEND_PORT_START=8000

log() { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
error() {
  echo -e "\e[31m[ERROR]\e[0m $*" >&2
  exit 1
}

[[ "$EUID" -eq 0 ]] || error "Скрипт должен быть запущен от root"
command_exists() { command -v "$1" &>/dev/null; }

ensure_apt_pkg() {
  local pkg="$1"
  dpkg -s "$pkg" &>/dev/null || {
    log "Установка пакета $pkg"
    apt-get install -y "$pkg"
  }
}

generate_secret() {
  local length=${1:-64}
  openssl rand -base64 $((length * 2)) | tr -dc 'A-Za-z0-9' | head -c "$length"
}

find_free_port() {
  local port=$1
  while ss -ltn "sport = :$port" | grep -q LISTEN; do
    ((port++))
  done
  echo "$port"
}

ensure_docker_network() {
  local net="$1"
  if ! docker network inspect "$net" &>/dev/null; then
    log "Создаём Docker сеть: $net"
    docker network create "$net"
  else
    log "Docker сеть $net уже существует"
  fi
}

ensure_container() {
  local name="$1" opts="${2:---restart=unless-stopped}"
  shift 2
  if ! docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    log "Запуск контейнера $name"
    docker run -d --name "$name" $opts "$@"
  elif ! docker ps --format '{{.Names}}' | grep -qx "$name"; then
    log "Запуск существующего контейнера $name"
    docker start "$name"
  else
    log "Контейнер $name уже запущен"
  fi
}

log "Обновление системы и установка nginx, Docker"
apt-get update -qq
ensure_apt_pkg dialog
export DEBIAN_FRONTEND=noninteractive
apt-get upgrade -y -qq
ensure_apt_pkg curl
ensure_apt_pkg nginx

if ! command_exists docker; then
  log "Установка Docker"
  curl -fsSL https://get.docker.com | sh
fi

if id "$DOCKER_USER" &>/dev/null; then
  if getent group docker &>/dev/null; then
    log "Добавление пользователя $DOCKER_USER в группу docker"
    usermod -aG docker "$DOCKER_USER"
    log "Пользователь $DOCKER_USER добавлен в группу docker"
  else
    warn "Группа docker не существует. Пропускаем добавление пользователя."
  fi
else
  warn "Пользователь $DOCKER_USER не существует. Пропускаем добавление в группу docker."
fi

mkdir -p "$DATA_BASE_PATH"
mkdir -p "$(dirname "$CREDENTIALS_PATH")"
mkdir -p "$(dirname "$GLOBAL_CREDS_PATH")"

if [[ ! -f "$GLOBAL_CREDS_PATH" ]]; then
  log "Генерация глобальных учётных данных"

  SUF_DEV=$(openssl rand -hex 4)
  SUF_PROD=$(openssl rand -hex 4)

  GLOBAL_POSTGRES_USER_DEV="postgres_dev_${SUF_DEV}"
  GLOBAL_POSTGRES_PASS_DEV=$(generate_secret 32)
  GLOBAL_POSTGRES_USER_PROD="postgres_prod_${SUF_PROD}"
  GLOBAL_POSTGRES_PASS_PROD=$(generate_secret 32)

  cat >"$GLOBAL_CREDS_PATH" <<EOF
GLOBAL_POSTGRES_USER_DEV=$GLOBAL_POSTGRES_USER_DEV
GLOBAL_POSTGRES_PASS_DEV=$GLOBAL_POSTGRES_PASS_DEV
GLOBAL_POSTGRES_USER_PROD=$GLOBAL_POSTGRES_USER_PROD
GLOBAL_POSTGRES_PASS_PROD=$GLOBAL_POSTGRES_PASS_PROD

EOF
  chmod 600 "$GLOBAL_CREDS_PATH"
  chown root:root "$GLOBAL_CREDS_PATH"
else
  log "Загрузка существующих глобальных креденшалов"
  source "$GLOBAL_CREDS_PATH"
fi

ensure_docker_network "$DEV_NET"
ensure_docker_network "$PROD_NET"

ensure_container "postgres-dev" \
  -e POSTGRES_USER="$GLOBAL_POSTGRES_USER_DEV" \
  -e POSTGRES_PASSWORD="$GLOBAL_POSTGRES_PASS_DEV" \
  --network "$DEV_NET" \
  -v "$DATA_BASE_PATH/postgres-dev:/var/lib/postgresql/data" \
  "$POSTGRES_IMAGE"
ensure_container "postgres-prod" \
  -e POSTGRES_USER="$GLOBAL_POSTGRES_USER_PROD" \
  -e POSTGRES_PASSWORD="$GLOBAL_POSTGRES_PASS_PROD" \
  --network "$PROD_NET" \
  -v "$DATA_BASE_PATH/postgres-prod:/var/lib/postgresql/data" \
  "$POSTGRES_IMAGE"

if [[ ! -f "$CREDENTIALS_PATH" ]]; then
  log "Генерация учётных данных и портов для проекта $PROJECT_SLUG"

  SUF_DEV=$(openssl rand -hex 4)
  SUF_PROD=$(openssl rand -hex 4)

  PROJECT_FRONTEND_PORT_DEV=$(find_free_port $FRONTEND_PORT_START)
  PROJECT_FRONTEND_PORT_PROD=$(find_free_port $((PROJECT_FRONTEND_PORT_DEV + 1)))
  PROJECT_BACKEND_PORT_DEV=$(find_free_port $BACKEND_PORT_START)
  PROJECT_BACKEND_PORT_PROD=$(find_free_port $((PROJECT_BACKEND_PORT_DEV + 1)))

  PROJECT_POSTGRES_DB_DEV="${PROJECT_SLUG}_dev"
  PROJECT_POSTGRES_USER_DEV="${PROJECT_SLUG}_dev_user_${SUF_DEV}"
  PROJECT_POSTGRES_PASS_DEV=$(generate_secret 32)
  PROJECT_POSTGRES_DB_PROD="${PROJECT_SLUG}_prod"
  PROJECT_POSTGRES_USER_PROD="${PROJECT_SLUG}_prod_user_${SUF_PROD}"
  PROJECT_POSTGRES_PASS_PROD=$(generate_secret 32)
  
  cat >"$CREDENTIALS_PATH" <<EOF
PROJECT_FRONTEND_PORT_DEV=$PROJECT_FRONTEND_PORT_DEV
PROJECT_BACKEND_PORT_DEV=$PROJECT_BACKEND_PORT_DEV
PROJECT_FRONTEND_PORT_PROD=$PROJECT_FRONTEND_PORT_PROD
PROJECT_BACKEND_PORT_PROD=$PROJECT_BACKEND_PORT_PROD

PROJECT_POSTGRES_DB_DEV=$PROJECT_POSTGRES_DB_DEV
PROJECT_POSTGRES_USER_DEV=$PROJECT_POSTGRES_USER_DEV
PROJECT_POSTGRES_PASS_DEV=$PROJECT_POSTGRES_PASS_DEV
PROJECT_POSTGRES_DB_PROD=$PROJECT_POSTGRES_DB_PROD
PROJECT_POSTGRES_USER_PROD=$PROJECT_POSTGRES_USER_PROD
PROJECT_POSTGRES_PASS_PROD=$PROJECT_POSTGRES_PASS_PROD
EOF
  chmod 600 "$CREDENTIALS_PATH"
  chown root:root "$CREDENTIALS_PATH"
else
  log "Загрузка существующих креденшалов для проекта $PROJECT_SLUG"
  source "$CREDENTIALS_PATH"
fi

log "Ожидание 30 секунд..."
sleep 30

log "Создание баз данных и пользователей PostgreSQL"
docker exec -i postgres-dev psql -U "$GLOBAL_POSTGRES_USER_DEV" -c "CREATE DATABASE $PROJECT_POSTGRES_DB_DEV;" 2>/dev/null || log "База $PROJECT_POSTGRES_DB_DEV уже существует"
docker exec -i postgres-dev psql -U "$GLOBAL_POSTGRES_USER_DEV" -c "CREATE USER $PROJECT_POSTGRES_USER_DEV WITH PASSWORD '$PROJECT_POSTGRES_PASS_DEV';" 2>/dev/null || log "Пользователь $PROJECT_POSTGRES_USER_DEV уже существует"
docker exec -i postgres-dev psql -U "$GLOBAL_POSTGRES_USER_DEV" -c "GRANT ALL PRIVILEGES ON DATABASE $PROJECT_POSTGRES_DB_DEV TO $PROJECT_POSTGRES_USER_DEV;" 2>/dev/null
docker exec -i postgres-dev psql -U "$GLOBAL_POSTGRES_USER_DEV" -d "$PROJECT_POSTGRES_DB_DEV" -c "GRANT USAGE, CREATE ON SCHEMA public TO $PROJECT_POSTGRES_USER_DEV;" &>/dev/null || log "Не удалось предоставить привилегии на схему public для $PROJECT_POSTGRES_USER_DEV"

docker exec -i postgres-prod psql -U "$GLOBAL_POSTGRES_USER_PROD" -c "CREATE DATABASE $PROJECT_POSTGRES_DB_PROD;" 2>/dev/null || log "База $PROJECT_POSTGRES_DB_PROD уже существует"
docker exec -i postgres-prod psql -U "$GLOBAL_POSTGRES_USER_PROD" -c "CREATE USER $PROJECT_POSTGRES_USER_PROD WITH PASSWORD '$PROJECT_POSTGRES_PASS_PROD';" 2>/dev/null || log "Пользователь $PROJECT_POSTGRES_USER_PROD уже существует"
docker exec -i postgres-prod psql -U "$GLOBAL_POSTGRES_USER_PROD" -c "GRANT ALL PRIVILEGES ON DATABASE $PROJECT_POSTGRES_DB_PROD TO $PROJECT_POSTGRES_USER_PROD;" 2>/dev/null
docker exec -i postgres-prod psql -U "$GLOBAL_POSTGRES_USER_PROD" -d "$PROJECT_POSTGRES_DB_PROD" -c "GRANT USAGE, CREATE ON SCHEMA public TO $PROJECT_POSTGRES_USER_PROD;" &>/dev/null || log "Не удалось предоставить привилегии на схему public для $PROJECT_POSTGRES_USER_PROD"

log "Настройка Nginx для проекта $PROJECT_SLUG"
cat >/etc/nginx/sites-available/${PROJECT_SLUG}.conf <<EOF
server {
    listen 80;
    server_name ${PROJECT_SLUG_DASH}.${DOMAIN};
    location / {
        proxy_pass http://127.0.0.1:${PROJECT_FRONTEND_PORT_PROD};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name ${PROJECT_SLUG_DASH}-dev.${DOMAIN};
    location / {
        proxy_pass http://127.0.0.1:${PROJECT_FRONTEND_PORT_DEV};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name ${PROJECT_SLUG_DASH}-backend.${DOMAIN};
    location / {
        proxy_pass http://127.0.0.1:${PROJECT_BACKEND_PORT_PROD};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}

server {
    listen 80;
    server_name ${PROJECT_SLUG_DASH}-backend-dev.${DOMAIN};
    location / {
        proxy_pass http://127.0.0.1:${PROJECT_BACKEND_PORT_DEV};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
ln -sf /etc/nginx/sites-available/${PROJECT_SLUG}.conf /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

log "Содержимое $GLOBAL_CREDS_PATH:"
cat "$GLOBAL_CREDS_PATH"

log "Содержимое $CREDENTIALS_PATH:"
cat "$CREDENTIALS_PATH"

log "Скрипт завершён успешно для проекта $PROJECT_SLUG"
