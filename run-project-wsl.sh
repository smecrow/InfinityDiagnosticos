#!/usr/bin/env bash
set -u

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$PROJECT_DIR/.env.docker"
ENV_EXAMPLE="$PROJECT_DIR/.env.docker.example"
BACKEND_HEALTH_URL="http://localhost:8080/api/health"
FRONTEND_URL="http://localhost:3000"

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

wait_for_url() {
  local url="$1"
  local service_name="$2"
  local attempts="$3"
  local delay_seconds="$4"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt++)); do
    if curl --silent --show-error --fail "$url" >/dev/null 2>&1; then
      log_info "$service_name em execucao."
      return 0
    fi

    sleep "$delay_seconds"
  done

  return 1
}

cd "$PROJECT_DIR" || exit 1

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  log_error "Arquivo .env.docker.example nao encontrado."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  log_info "Arquivo .env.docker criado automaticamente a partir do modelo padrao."
fi

if ! detect_compose_cmd; then
  log_error "Docker Compose nao foi encontrado no ambiente."
  log_error "Instale o Docker com suporte a Compose e execute este script novamente."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  log_error "Docker nao esta ativo ou acessivel neste WSL."
  log_error "Inicie o Docker Desktop com integracao WSL ou o daemon Docker nativo e tente novamente."
  exit 1
fi

log_info "Docker ativo."
log_info "Subindo frontend, backend e PostgreSQL com Docker Compose..."
if ! "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" up --build -d; then
  log_error "Falha ao subir os containers do projeto."
  exit 1
fi

log_info "Aguardando a inicializacao do backend..."
if ! wait_for_url "$BACKEND_HEALTH_URL" "backend" 30 2; then
  log_error "backend nao ficou em execucao."
  printf '\n[DIAGNOSTICO] Status atual dos containers:\n'
  "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" ps
  printf '\n[DIAGNOSTICO] Ultimos logs do backend:\n'
  "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" logs backend --tail=120
  exit 1
fi

log_info "Aguardando a inicializacao do frontend..."
if ! wait_for_url "$FRONTEND_URL" "frontend" 20 2; then
  log_error "frontend nao ficou em execucao."
  printf '\n[DIAGNOSTICO] Status atual dos containers:\n'
  "${COMPOSE_CMD[@]}" --env-file "$ENV_FILE" ps
  exit 1
fi

printf '\n'
log_ok "Projeto iniciado com sucesso."
log_ok "Frontend: $FRONTEND_URL"
log_ok "Backend:  $BACKEND_HEALTH_URL"
