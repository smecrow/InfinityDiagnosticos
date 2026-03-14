#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$PROJECT_DIR/config/env/.env.docker"
ENV_EXAMPLE="$PROJECT_DIR/config/env/.env.docker.example"
COMPOSE_FILE="$PROJECT_DIR/docker/docker-compose.yml"
BACKEND_HEALTH_URL="http://localhost:8080/api/health"
FRONTEND_URL="http://localhost:3000"
NON_INTERACTIVE_MODE=0

setup_colors() {
  if [[ -t 1 ]]; then
    COLOR_RESET=$'\033[0m'
    COLOR_BOLD=$'\033[1m'
    COLOR_BLUE=$'\033[34m'
    COLOR_GREEN=$'\033[32m'
    COLOR_YELLOW=$'\033[33m'
    COLOR_RED=$'\033[31m'
    COLOR_CYAN=$'\033[36m'
  else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_BLUE=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_RED=""
    COLOR_CYAN=""
  fi
}

log_info() {
  printf '%s[INFO]%s %s\n' "$COLOR_BLUE" "$COLOR_RESET" "$1"
}

log_ok() {
  printf '%s[OK]%s %s\n' "$COLOR_GREEN" "$COLOR_RESET" "$1"
}

log_error() {
  printf '%s[ERRO]%s %s\n' "$COLOR_RED" "$COLOR_RESET" "$1" >&2
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

run_compose() {
  if [[ -f "$ENV_FILE" ]]; then
    "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" --env-file "$ENV_FILE" "$@"
  else
    "${COMPOSE_CMD[@]}" -f "$COMPOSE_FILE" "$@"
  fi
}

copy_env_file_if_missing() {
  if [[ ! -f "$ENV_EXAMPLE" ]]; then
    log_error "Arquivo .env.docker.example nao encontrado."
    exit 1
  fi

  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log_info "Arquivo .env.docker criado automaticamente a partir do modelo padrao."
  fi
}

ensure_compose_available() {
  if ! detect_compose_cmd; then
    log_error "Docker Compose nao foi encontrado no ambiente."
    log_error "Instale o Docker com suporte a Compose e execute este script novamente."
    exit 1
  fi
}

ensure_docker_is_active() {
  if ! docker info >/dev/null 2>&1; then
    log_error "Docker nao esta ativo ou acessivel neste WSL."
    log_error "Inicie o Docker Desktop com integracao WSL ou o daemon Docker nativo e tente novamente."
    exit 1
  fi
}

service_url_is_up() {
  local url="$1"
  curl --silent --show-error --fail "$url" >/dev/null 2>&1
}

wait_for_url() {
  local url="$1"
  local service_name="$2"
  local attempts="$3"
  local delay_seconds="$4"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt += 1)); do
    if service_url_is_up "$url"; then
      log_ok "$service_name em execucao."
      return 0
    fi

    sleep "$delay_seconds"
  done

  return 1
}

get_docker_status() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'parado'
    return 0
  fi

  if docker info >/dev/null 2>&1; then
    printf 'ok'
  else
    printf 'parado'
  fi
}

get_container_id() {
  local service_name="$1"

  if ! detect_compose_cmd >/dev/null 2>&1; then
    return 1
  fi

  if ! docker info >/dev/null 2>&1; then
    return 1
  fi

  run_compose ps -q "$service_name" 2>/dev/null | head -n 1
}

map_container_state_to_status() {
  case "$1" in
    healthy|running)
      printf 'ok'
      ;;
    starting|created|restarting)
      printf 'iniciando'
      ;;
    *)
      printf 'parado'
      ;;
  esac
}

get_container_status() {
  local service_name="$1"
  local container_id
  local raw_status

  container_id="$(get_container_id "$service_name" || true)"

  if [[ -z "$container_id" ]]; then
    printf 'parado'
    return 0
  fi

  raw_status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"

  if [[ -z "$raw_status" ]]; then
    printf 'parado'
    return 0
  fi

  map_container_state_to_status "$raw_status"
}

get_http_service_status() {
  local service_name="$1"
  local url="$2"
  local container_status

  container_status="$(get_container_status "$service_name")"

  case "$container_status" in
    ok)
      if service_url_is_up "$url"; then
        printf 'ok'
      else
        printf 'iniciando'
      fi
      ;;
    iniciando)
      printf 'iniciando'
      ;;
    *)
      printf 'parado'
      ;;
  esac
}

format_status_label() {
  case "$1" in
    ok)
      printf '%sok%s' "$COLOR_GREEN" "$COLOR_RESET"
      ;;
    iniciando)
      printf '%siniciando%s' "$COLOR_YELLOW" "$COLOR_RESET"
      ;;
    *)
      printf '%sparado%s' "$COLOR_RED" "$COLOR_RESET"
      ;;
  esac
}

print_active_urls() {
  local frontend_status
  local backend_status

  frontend_status="$(get_http_service_status frontend "$FRONTEND_URL")"
  backend_status="$(get_http_service_status backend "$BACKEND_HEALTH_URL")"

  if [[ "$frontend_status" == "ok" ]]; then
    printf '%sFrontend:%s %s%s%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_BOLD" "$FRONTEND_URL" "$COLOR_RESET"
  fi

  if [[ "$backend_status" == "ok" ]]; then
    printf '%sBackend:%s  %s%s%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_BOLD" "$BACKEND_HEALTH_URL" "$COLOR_RESET"
  fi
}

print_selection_screen() {
  local docker_status
  local frontend_status
  local backend_status
  local postgres_status

  docker_status="$(get_docker_status)"
  frontend_status="$(get_http_service_status frontend "$FRONTEND_URL")"
  backend_status="$(get_http_service_status backend "$BACKEND_HEALTH_URL")"
  postgres_status="$(get_container_status postgres)"

  clear || true
  printf '%sGerenciador do ambiente Docker%s\n\n' "$COLOR_BOLD" "$COLOR_RESET"
  printf 'Docker     - %s\n' "$(format_status_label "$docker_status")"
  printf 'Frontend   - %s\n' "$(format_status_label "$frontend_status")"
  printf 'Backend    - %s\n' "$(format_status_label "$backend_status")"
  printf 'PostgreSQL - %s\n' "$(format_status_label "$postgres_status")"
  printf '\n'

  if [[ "$frontend_status" == "ok" || "$backend_status" == "ok" ]]; then
    print_active_urls
    printf '\n'
  fi

  printf '%s1.%s Iniciar ambiente Docker\n' "$COLOR_CYAN" "$COLOR_RESET"
  printf '%s2.%s Parar ambiente Docker\n' "$COLOR_CYAN" "$COLOR_RESET"
  printf '%s3.%s Atualizar status\n' "$COLOR_CYAN" "$COLOR_RESET"
  printf '%s4.%s Sair\n\n' "$COLOR_CYAN" "$COLOR_RESET"
}

return_to_selection_screen() {
  if [[ "$NON_INTERACTIVE_MODE" -eq 1 ]]; then
    return 0
  fi

  log_info "Retornando ao menu em 2 segundos..."
  sleep 2
}

print_compose_status() {
  printf '\n[DIAGNOSTICO] Status atual dos containers:\n'
  run_compose ps || true
}

start_docker_stack() {
  copy_env_file_if_missing
  ensure_compose_available
  ensure_docker_is_active

  log_info "Docker ativo."
  log_info "Subindo frontend, backend e PostgreSQL com Docker Compose..."
  if ! run_compose up --build -d; then
    log_error "Falha ao subir os containers do projeto."
    print_compose_status
    exit 1
  fi

  log_info "Aguardando a inicializacao do backend..."
  if ! wait_for_url "$BACKEND_HEALTH_URL" "Backend" 30 2; then
    log_error "O backend nao respondeu em tempo habil."
    print_compose_status
    printf '\n[DIAGNOSTICO] Ultimos logs do backend:\n'
    run_compose logs backend --tail=120 || true
    exit 1
  fi

  log_info "Aguardando a inicializacao do frontend..."
  if ! wait_for_url "$FRONTEND_URL" "Frontend" 20 2; then
    log_error "O frontend nao respondeu em tempo habil."
    print_compose_status
    printf '\n[DIAGNOSTICO] Ultimos logs do frontend:\n'
    run_compose logs frontend --tail=120 || true
    exit 1
  fi

  printf '\n'
  log_ok "Projeto iniciado com sucesso no Docker."
  log_ok "Frontend: $FRONTEND_URL"
  log_ok "Backend:  $BACKEND_HEALTH_URL"
  log_ok "Para parar frontend, backend e PostgreSQL: ./scripts/start-docker-wsl.sh stop"
}

stop_docker_stack() {
  ensure_compose_available
  ensure_docker_is_active

  log_info "Desligando frontend, backend e PostgreSQL..."
  if ! run_compose down; then
    log_error "Falha ao desligar os containers do projeto."
    exit 1
  fi

  printf '\n'
  log_ok "Containers desligados com sucesso."
  log_info "Este script afeta apenas o ambiente Docker. Para o ambiente local sem Docker, use ./scripts/start-local-wsl.sh stop"
}

run_interactive_menu() {
  local option

  while true; do
    print_selection_screen
    read -r -p "Escolha uma opcao: " option

    case "$option" in
      1)
        start_docker_stack
        return_to_selection_screen
        ;;
      2)
        stop_docker_stack
        return_to_selection_screen
        ;;
      3)
        ;;
      4)
        break
        ;;
      *)
        log_error "Opcao invalida."
        return_to_selection_screen
        ;;
    esac
  done
}

main() {
  cd "$PROJECT_DIR" || exit 1
  setup_colors

  case "${1:-}" in
    start)
      NON_INTERACTIVE_MODE=1
      start_docker_stack
      ;;
    stop)
      NON_INTERACTIVE_MODE=1
      stop_docker_stack
      ;;
    status)
      NON_INTERACTIVE_MODE=1
      print_selection_screen
      ;;
    "")
      run_interactive_menu
      ;;
    *)
      log_error "Uso: ./scripts/start-docker-wsl.sh [start|stop|status]"
      exit 1
      ;;
  esac
}

main "$@"
