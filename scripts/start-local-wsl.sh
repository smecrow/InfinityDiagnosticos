#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FRONTEND_DIR="$PROJECT_DIR/frontend"
ENV_FILE="$PROJECT_DIR/config/env/.env.local"
ENV_EXAMPLE="$PROJECT_DIR/config/env/.env.local.example"
RUNTIME_DIR="/tmp/infinitygo-local-run"
BACKEND_PID_FILE="$RUNTIME_DIR/backend.pid"
FRONTEND_PID_FILE="$RUNTIME_DIR/frontend.pid"
BACKEND_LOG_FILE="$RUNTIME_DIR/backend.log"
FRONTEND_LOG_FILE="$RUNTIME_DIR/frontend.log"
BACKEND_HEALTH_URL="http://localhost:8080/api/health"
FRONTEND_URL="http://localhost:3000"

APT_UPDATED=0
BACKEND_STARTED=0
FRONTEND_STARTED=0
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
    COLOR_GRAY=$'\033[90m'
  else
    COLOR_RESET=""
    COLOR_BOLD=""
    COLOR_BLUE=""
    COLOR_GREEN=""
    COLOR_YELLOW=""
    COLOR_RED=""
    COLOR_CYAN=""
    COLOR_GRAY=""
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

ensure_runtime_dir() {
  mkdir -p "$RUNTIME_DIR"
}

cleanup_on_error() {
  if [[ "$FRONTEND_STARTED" -eq 1 ]] && [[ -f "$FRONTEND_PID_FILE" ]]; then
    kill_if_running "$(cat "$FRONTEND_PID_FILE")" >/dev/null 2>&1 || true
    rm -f "$FRONTEND_PID_FILE"
  fi

  if [[ "$BACKEND_STARTED" -eq 1 ]] && [[ -f "$BACKEND_PID_FILE" ]]; then
    kill_if_running "$(cat "$BACKEND_PID_FILE")" >/dev/null 2>&1 || true
    rm -f "$BACKEND_PID_FILE"
  fi
}

trap cleanup_on_error ERR

run_sudo() {
  sudo "$@"
}

apt_update_once() {
  if [[ "$APT_UPDATED" -eq 0 ]]; then
    log_info "Atualizando a lista de pacotes do sistema..."
    run_sudo apt-get update
    APT_UPDATED=1
  fi
}

install_apt_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    log_error "Este script foi preparado para Debian/Ubuntu no WSL."
    exit 1
  fi

  apt_update_once
  run_sudo apt-get install -y --no-install-recommends "$@"
}

copy_env_file_if_missing() {
  if [[ ! -f "$ENV_EXAMPLE" ]]; then
    log_error "Arquivo .env.local.example nao encontrado."
    exit 1
  fi

  if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    log_info "Arquivo .env.local criado automaticamente a partir do modelo."
  fi
}

load_env_file() {
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    local key="${line%%=*}"
    local value="${line#*=}"

    key="${key//[[:space:]]/}"
    value="${value%$'\r'}"

    export "$key=$value"
  done < "$ENV_FILE"
}

ensure_basic_tools() {
  local missing_packages=()

  command -v curl >/dev/null 2>&1 || missing_packages+=("curl")
  command -v pg_isready >/dev/null 2>&1 || missing_packages+=("postgresql-client")

  if [[ "${#missing_packages[@]}" -gt 0 ]]; then
    log_info "Instalando utilitarios basicos do sistema..."
    install_apt_packages ca-certificates "${missing_packages[@]}"
  fi
}

extract_java_major() {
  java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1
}

ensure_java() {
  if command -v java >/dev/null 2>&1; then
    local java_major
    java_major="$(extract_java_major)"

    if [[ "$java_major" =~ ^[0-9]+$ ]] && (( java_major >= 21 )); then
      return 0
    fi
  fi

  log_info "Instalando Java 21..."
  install_apt_packages openjdk-21-jdk
}

extract_node_major() {
  node -p "process.versions.node.split('.')[0]"
}

install_nodejs_22() {
  log_info "Instalando Node.js 22..."
  install_apt_packages ca-certificates curl gnupg

  local setup_script
  setup_script="$(mktemp)"

  curl -fsSL https://deb.nodesource.com/setup_22.x -o "$setup_script"
  run_sudo bash "$setup_script"
  rm -f "$setup_script"

  install_apt_packages nodejs
}

ensure_node() {
  if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    local node_major
    node_major="$(extract_node_major)"

    if [[ "$node_major" =~ ^[0-9]+$ ]] && (( node_major >= 20 )); then
      return 0
    fi
  fi

  install_nodejs_22
}

ensure_postgresql() {
  if command -v psql >/dev/null 2>&1 \
    && command -v pg_isready >/dev/null 2>&1 \
    && command -v pg_lsclusters >/dev/null 2>&1 \
    && command -v pg_ctlcluster >/dev/null 2>&1 \
    && command -v pg_createcluster >/dev/null 2>&1; then
    return 0
  fi

  log_info "Instalando PostgreSQL local..."
  install_apt_packages postgresql postgresql-contrib postgresql-common
}

get_latest_postgresql_version() {
  local version
  version="$(find /usr/lib/postgresql -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | tail -n 1)"

  if [[ -z "$version" ]]; then
    log_error "Nao foi possivel identificar a versao instalada do PostgreSQL."
    exit 1
  fi

  printf '%s\n' "$version"
}

ensure_postgresql_cluster() {
  if ! command -v pg_lsclusters >/dev/null 2>&1 || ! command -v pg_createcluster >/dev/null 2>&1; then
    log_error "As ferramentas de cluster do PostgreSQL nao estao disponiveis."
    exit 1
  fi

  if pg_lsclusters --no-header | grep -q .; then
    return 0
  fi

  local version
  version="$(get_latest_postgresql_version)"

  log_info "Criando o cluster padrao do PostgreSQL..."
  run_sudo pg_createcluster --start "$version" main
}

ensure_speedtest_cli() {
  if command -v speedtest >/dev/null 2>&1; then
    return 0
  fi

  log_info "Instalando Speedtest CLI oficial da Ookla..."
  install_apt_packages ca-certificates curl

  local arch
  arch="$(dpkg --print-architecture)"

  case "$arch" in
    amd64|arm64) ;;
    *)
      log_error "Arquitetura sem pacote oficial validado para o Speedtest CLI da Ookla: $arch"
      exit 1
      ;;
  esac

  local package_url
  package_url="https://packagecloud.io/ookla/speedtest-cli/packages/ubuntu/jammy/speedtest_1.2.0.84-1.ea6b6773cf_${arch}.deb/download.deb?distro_version_id=237"

  local temp_deb
  temp_deb="$(mktemp --suffix=.deb)"

  curl -fsSL "$package_url" -o "$temp_deb"
  run_sudo apt-get install -y --no-install-recommends "$temp_deb"
  rm -f "$temp_deb"
}

start_postgresql_service() {
  if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    log_info "PostgreSQL local ja esta em execucao."
    return 0
  fi

  ensure_postgresql_cluster

  if command -v pg_lsclusters >/dev/null 2>&1 && command -v pg_ctlcluster >/dev/null 2>&1; then
    local cluster_info
    cluster_info="$(pg_lsclusters --no-header | awk 'NR==1 {print $1" "$2}')"

    if [[ -z "$cluster_info" ]]; then
      log_error "Nenhum cluster do PostgreSQL foi encontrado no sistema."
      exit 1
    fi

    log_info "Iniciando o cluster padrao do PostgreSQL..."
    if ! run_sudo pg_ctlcluster ${cluster_info} start; then
      log_error "Falha ao iniciar o cluster do PostgreSQL com pg_ctlcluster."
      exit 1
    fi
  elif command -v service >/dev/null 2>&1; then
    log_info "Iniciando o servico do PostgreSQL..."
    if ! run_sudo service postgresql start; then
      log_error "Falha ao iniciar o PostgreSQL com o comando service."
      exit 1
    fi
  elif command -v systemctl >/dev/null 2>&1; then
    log_info "Iniciando o servico do PostgreSQL..."
    if ! run_sudo systemctl start postgresql; then
      log_error "Falha ao iniciar o PostgreSQL com systemctl."
      exit 1
    fi
  else
    log_error "Nao foi possivel iniciar o PostgreSQL automaticamente."
    exit 1
  fi

  local attempt
  for ((attempt = 1; attempt <= 20; attempt += 1)); do
    if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
      log_ok "PostgreSQL local em execucao."
      return 0
    fi

    sleep 1
  done

  log_error "O PostgreSQL nao respondeu na porta 5432."
  exit 1
}

validate_sql_identifier() {
  local identifier="$1"

  if [[ ! "$identifier" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    log_error "Valor invalido para identificador SQL: $identifier"
    exit 1
  fi
}

escape_sql_literal() {
  printf "%s" "${1//\'/\'\'}"
}

ensure_database() {
  validate_sql_identifier "$POSTGRES_DB"
  validate_sql_identifier "$POSTGRES_USER"

  local escaped_password
  escaped_password="$(escape_sql_literal "$POSTGRES_PASSWORD")"

  run_sudo -u postgres psql -v ON_ERROR_STOP=1 postgres <<SQL
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$POSTGRES_USER') THEN
        CREATE ROLE "$POSTGRES_USER" LOGIN PASSWORD '$escaped_password';
    ELSE
        ALTER ROLE "$POSTGRES_USER" WITH LOGIN PASSWORD '$escaped_password';
    END IF;
END
\$\$;
SQL

  if ! run_sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname = '$POSTGRES_DB'" | grep -q 1; then
    run_sudo -u postgres createdb --owner="$POSTGRES_USER" "$POSTGRES_DB"
  fi

  run_sudo -u postgres psql -v ON_ERROR_STOP=1 postgres -c "ALTER DATABASE \"$POSTGRES_DB\" OWNER TO \"$POSTGRES_USER\";" >/dev/null
}

install_frontend_dependencies() {
  if [[ ! -d "$FRONTEND_DIR/node_modules" ]] || [[ "$FRONTEND_DIR/package-lock.json" -nt "$FRONTEND_DIR/node_modules" ]]; then
    log_info "Instalando dependencias do frontend..."
    (
      cd "$FRONTEND_DIR"
      npm ci
    )
  fi
}

normalize_maven_wrapper() {
  local wrapper_file="$PROJECT_DIR/backend/mvnw"

  if [[ ! -f "$wrapper_file" ]]; then
    log_error "Arquivo do Maven Wrapper nao encontrado em backend/mvnw."
    exit 1
  fi

  if grep -q $'\r' "$wrapper_file"; then
    log_info "Normalizando o backend/mvnw para final de linha Unix..."
    perl -pi -e 's/\r$//' "$wrapper_file"
    chmod +x "$wrapper_file"
  fi
}

prepare_backend_maven_home() {
  mkdir -p "$PROJECT_DIR/backend/.m2"
}

read_pid_file() {
  local pid_file="$1"

  if [[ ! -f "$pid_file" ]]; then
    return 1
  fi

  local pid
  pid="$(tr -d '[:space:]' < "$pid_file")"

  if [[ -z "$pid" ]]; then
    return 1
  fi

  printf '%s\n' "$pid"
}

is_pid_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1
}

service_url_is_up() {
  local url="$1"
  curl --silent --show-error --fail "$url" >/dev/null 2>&1
}

get_service_status() {
  local pid_file="$1"
  local url="$2"
  local pid

  if pid="$(read_pid_file "$pid_file")" && is_pid_running "$pid"; then
    if service_url_is_up "$url"; then
      printf 'ok'
    else
      printf 'iniciando'
    fi
    return 0
  fi

  printf 'parado'
}

get_postgresql_status() {
  if command -v pg_isready >/dev/null 2>&1 && pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
    printf 'ok'
  else
    printf 'parado'
  fi
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

  frontend_status="$(get_service_status "$FRONTEND_PID_FILE" "$FRONTEND_URL")"
  backend_status="$(get_service_status "$BACKEND_PID_FILE" "$BACKEND_HEALTH_URL")"

  if [[ "$frontend_status" == "ok" ]]; then
    printf '%sFrontend:%s %s%s%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_BOLD" "$FRONTEND_URL" "$COLOR_RESET"
  fi

  if [[ "$backend_status" == "ok" ]]; then
    printf '%sBackend:%s  %s%s%s\n' "$COLOR_CYAN" "$COLOR_RESET" "$COLOR_BOLD" "$BACKEND_HEALTH_URL" "$COLOR_RESET"
  fi
}

print_selection_screen() {
  local frontend_status
  local backend_status
  local postgresql_status

  frontend_status="$(get_service_status "$FRONTEND_PID_FILE" "$FRONTEND_URL")"
  backend_status="$(get_service_status "$BACKEND_PID_FILE" "$BACKEND_HEALTH_URL")"
  postgresql_status="$(get_postgresql_status)"

  clear || true
  printf '%sGerenciador do ambiente local%s\n\n' "$COLOR_BOLD" "$COLOR_RESET"
  printf 'Frontend   - %s\n' "$(format_status_label "$frontend_status")"
  printf 'Backend    - %s\n' "$(format_status_label "$backend_status")"
  printf 'PostgreSQL - %s\n' "$(format_status_label "$postgresql_status")"
  printf '\n'

  if [[ "$frontend_status" == "ok" || "$backend_status" == "ok" ]]; then
    print_active_urls
    printf '\n'
  fi

  printf '%s1.%s Iniciar ambiente local\n' "$COLOR_CYAN" "$COLOR_RESET"
  printf '%s2.%s Parar ambiente local\n' "$COLOR_CYAN" "$COLOR_RESET"
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

kill_if_running() {
  local pid="$1"

  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    kill "$pid" >/dev/null 2>&1 || true
    return 0
  fi

  return 1
}

remove_stale_pid_file() {
  local pid_file="$1"

  if [[ ! -f "$pid_file" ]]; then
    return 0
  fi

  local pid
  pid="$(cat "$pid_file")"

  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    log_error "Ja existe um processo em execucao para $(basename "$pid_file" .pid)."
    log_error "Use ./scripts/start-local-wsl.sh stop antes de iniciar novamente."
    exit 1
  fi

  rm -f "$pid_file"
}

collect_descendant_pids() {
  local pid="$1"
  local child_pid
  local child_pids

  if ! command -v pgrep >/dev/null 2>&1; then
    return 0
  fi

  child_pids="$(pgrep -P "$pid" || true)"

  for child_pid in $child_pids; do
    collect_descendant_pids "$child_pid"
    printf '%s\n' "$child_pid"
  done
}

terminate_pid_and_children() {
  local pid="$1"
  local signal="$2"
  local descendant_pid
  local descendant_pids

  descendant_pids="$(collect_descendant_pids "$pid")"

  for descendant_pid in $descendant_pids; do
    kill "-$signal" "$descendant_pid" >/dev/null 2>&1 || true
  done

  kill "-$signal" "$pid" >/dev/null 2>&1 || true
}

wait_for_process_exit() {
  local pid="$1"
  local attempts="$2"
  local delay_seconds="$3"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt += 1)); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      return 0
    fi

    sleep "$delay_seconds"
  done

  return 1
}

stop_process_tree() {
  local pid_file="$1"
  local service_name="$2"
  local pid

  if ! pid="$(read_pid_file "$pid_file")"; then
    log_info "$service_name nao possui PID salvo."
    return 0
  fi

  if ! kill -0 "$pid" >/dev/null 2>&1; then
    rm -f "$pid_file"
    log_info "$service_name ja estava parado."
    return 0
  fi

  terminate_pid_and_children "$pid" TERM

  if wait_for_process_exit "$pid" 10 1; then
    rm -f "$pid_file"
    log_ok "$service_name parado com sucesso."
    return 0
  fi

  terminate_pid_and_children "$pid" KILL
  rm -f "$pid_file"
  log_ok "$service_name finalizado a força."
}

wait_for_url() {
  local url="$1"
  local service_name="$2"
  local attempts="$3"
  local delay_seconds="$4"
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt += 1)); do
    if curl --silent --show-error --fail "$url" >/dev/null 2>&1; then
      log_ok "$service_name em execucao."
      return 0
    fi

    sleep "$delay_seconds"
  done

  return 1
}

print_recent_log_excerpt() {
  local log_file="$1"

  if [[ ! -f "$log_file" ]]; then
    return 0
  fi

  tail -n 12 "$log_file" || true
}

wait_for_backend_startup() {
  local backend_pid="$1"
  local attempts=90
  local delay_seconds=2
  local attempt

  for ((attempt = 1; attempt <= attempts; attempt += 1)); do
    if curl --silent --show-error --fail "$BACKEND_HEALTH_URL" >/dev/null 2>&1; then
      log_ok "Backend em execucao."
      return 0
    fi

    if ! kill -0 "$backend_pid" >/dev/null 2>&1; then
      log_error "O processo do backend encerrou antes de responder."
      print_recent_log_excerpt "$BACKEND_LOG_FILE"
      exit 1
    fi

    if (( attempt == 1 || attempt % 5 == 0 )); then
      log_info "Backend ainda iniciando... acompanhe em $BACKEND_LOG_FILE"
      print_recent_log_excerpt "$BACKEND_LOG_FILE"
    fi

    sleep "$delay_seconds"
  done

  log_error "O backend nao respondeu em tempo habil."
  print_recent_log_excerpt "$BACKEND_LOG_FILE"
  exit 1
}

start_backend() {
  log_info "Iniciando o backend local..."
  normalize_maven_wrapper
  prepare_backend_maven_home

  setsid bash -lc "
    cd \"$PROJECT_DIR/backend\"
    export MAVEN_USER_HOME=\"$PROJECT_DIR/backend/.m2\"
    export MVNW_VERBOSE=true
    export SPRING_PROFILES_ACTIVE=postgres
    export DATABASE_URL=\"jdbc:postgresql://localhost:5432/$POSTGRES_DB\"
    export DATABASE_USERNAME=\"$POSTGRES_USER\"
    export DATABASE_PASSWORD=\"$POSTGRES_PASSWORD\"
    export ADMIN_USERNAME=\"$ADMIN_USERNAME\"
    export ADMIN_PASSWORD=\"$ADMIN_PASSWORD\"
    export OOKLA_CLI_BINARY=\"$OOKLA_CLI_BINARY\"
    export OOKLA_SERVER_ID=\"$OOKLA_SERVER_ID\"
    export OOKLA_PROVIDER_LABEL=\"$OOKLA_PROVIDER_LABEL\"
    export OOKLA_REGION_LABEL=\"$OOKLA_REGION_LABEL\"
    export OOKLA_TIMEOUT_SECONDS=\"$OOKLA_TIMEOUT_SECONDS\"
    exec bash ./mvnw -Dmaven.repo.local=\"$PROJECT_DIR/backend/.m2/repository\" spring-boot:run
  " >"$BACKEND_LOG_FILE" 2>&1 &

  local backend_pid="$!"
  echo "$backend_pid" > "$BACKEND_PID_FILE"
  BACKEND_STARTED=1

  log_info "Log do backend: $BACKEND_LOG_FILE"
  wait_for_backend_startup "$backend_pid"
}

start_frontend() {
  log_info "Iniciando o frontend local..."

  setsid bash -lc "
    cd \"$FRONTEND_DIR\"
    export NEXT_TELEMETRY_DISABLED=1
    export WATCHPACK_POLLING=true
    export CHOKIDAR_USEPOLLING=1
    exec npm run dev -- --webpack --hostname 0.0.0.0 --port 3000
  " >"$FRONTEND_LOG_FILE" 2>&1 &

  echo "$!" > "$FRONTEND_PID_FILE"
  FRONTEND_STARTED=1

  if ! wait_for_url "$FRONTEND_URL" "Frontend" 60 2; then
    log_error "O frontend nao respondeu em tempo habil."
    tail -n 120 "$FRONTEND_LOG_FILE" || true
    exit 1
  fi
}

start_local_stack() {
  BACKEND_STARTED=0
  FRONTEND_STARTED=0
  ensure_runtime_dir
  remove_stale_pid_file "$BACKEND_PID_FILE"
  remove_stale_pid_file "$FRONTEND_PID_FILE"
  copy_env_file_if_missing
  load_env_file
  ensure_basic_tools
  ensure_java
  ensure_node
  ensure_postgresql
  ensure_speedtest_cli
  start_postgresql_service
  ensure_database
  install_frontend_dependencies

  if [[ "$(get_service_status "$BACKEND_PID_FILE" "$BACKEND_HEALTH_URL")" == "ok" ]]; then
    log_info "Backend ja esta em execucao."
  else
    start_backend
  fi

  if [[ "$(get_service_status "$FRONTEND_PID_FILE" "$FRONTEND_URL")" == "ok" ]]; then
    log_info "Frontend ja esta em execucao."
  else
    start_frontend
  fi

  trap - ERR

  printf '\n'
  log_ok "Projeto iniciado sem Docker."
  log_ok "Frontend: $FRONTEND_URL"
  log_ok "Backend:  $BACKEND_HEALTH_URL"
  log_ok "Logs do backend:  $BACKEND_LOG_FILE"
  log_ok "Logs do frontend: $FRONTEND_LOG_FILE"
  log_ok "Para parar frontend e backend: ./scripts/start-local-wsl.sh stop"
  log_info "Neste modo, o Speedtest CLI roda na sua maquina local. O resultado tende a ficar mais proximo do speedtest do navegador."
  BACKEND_STARTED=0
  FRONTEND_STARTED=0
}

stop_local_stack() {
  ensure_runtime_dir
  stop_process_tree "$FRONTEND_PID_FILE" "Frontend"
  stop_process_tree "$BACKEND_PID_FILE" "Backend"
  log_info "O PostgreSQL local nao foi desligado por este script."
}

run_interactive_menu() {
  local option

  while true; do
    print_selection_screen
    read -r -p "Escolha uma opcao: " option

    case "$option" in
      1)
        start_local_stack
        return_to_selection_screen
        ;;
      2)
        stop_local_stack
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
  setup_colors

  case "${1:-}" in
    start)
      NON_INTERACTIVE_MODE=1
      start_local_stack
      ;;
    stop)
      NON_INTERACTIVE_MODE=1
      stop_local_stack
      ;;
    status)
      NON_INTERACTIVE_MODE=1
      print_selection_screen
      ;;
    "")
      run_interactive_menu
      ;;
    *)
      log_error "Uso: ./scripts/start-local-wsl.sh [start|stop|status]"
      exit 1
      ;;
  esac
}

main "$@"
