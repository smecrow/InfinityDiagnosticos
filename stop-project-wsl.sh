#!/usr/bin/env bash
set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env.docker"

log_info() {
  printf '[INFO] %s\n' "$1"
}

log_ok() {
  printf '[OK] %s\n' "$1"
}

log_error() {
  printf '[ERRO] %s\n' "$1" >&2
}

detect_compose_cmd() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD=(docker compose)
    return 0
  fi

  if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD=(docker-compose)
    return 0
  fi

  return 1
}

cd "$PROJECT_DIR" || exit 1

if ! detect_compose_cmd; then
  log_error "Docker Compose nao foi encontrado no ambiente."
  log_error "Instale o Docker com suporte a Compose e execute este script novamente."
  exit 1
fi

log_info "Desligando frontend, backend e PostgreSQL..."
if [[ -f "$ENV_FILE" ]]; then
  if ! "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" down; then
    log_error "Falha ao desligar os containers do projeto."
    exit 1
  fi
else
  if ! "${COMPOSE_CMD[@]}" down; then
    log_error "Falha ao desligar os containers do projeto."
    exit 1
  fi
fi

printf '\n'
log_ok "Containers desligados com sucesso."
