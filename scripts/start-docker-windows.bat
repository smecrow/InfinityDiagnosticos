@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_DIR=%%~fI\"
set "ENV_FILE=%PROJECT_DIR%config\env\.env.docker"
set "ENV_EXAMPLE=%PROJECT_DIR%config\env\.env.docker.example"
set "COMPOSE_FILE=%PROJECT_DIR%docker\docker-compose.yml"
set "PROGRAM_FILES=%ProgramFiles%"
set "PROGRAM_W6432=%ProgramW6432%"
set "PROGRAM_FILES_X86=%ProgramFiles(x86)%"
set "LOCAL_APP_DATA=%LocalAppData%"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "BACKEND_HEALTH_URL=http://localhost:8080/api/health"
set "FRONTEND_URL=http://localhost:3000"
set "DOCKER_CMD="
set "DOCKER_BIN_DIR="
set "DOCKER_DESKTOP_EXE="
set "NON_INTERACTIVE_MODE=0"

call :setup_colors
call :copy_env_file_if_missing
if errorlevel 1 exit /b 1

title InfinityGo - Gerenciador Docker
pushd "%PROJECT_DIR%" >nul 2>nul
if errorlevel 1 (
    call :log_error "Não foi possível acessar a pasta do projeto no Windows."
    call :log_error "Se você estiver chamando o .bat por um caminho do WSL, use o Explorer ou copie o projeto para uma pasta do Windows."
    exit /b 1
)
set "PROJECT_DIR=%CD%\"
set "ENV_FILE=%PROJECT_DIR%config\env\.env.docker"
set "ENV_EXAMPLE=%PROJECT_DIR%config\env\.env.docker.example"
set "COMPOSE_FILE=%PROJECT_DIR%docker\docker-compose.yml"

if "%~1"=="" goto run_interactive_menu
if /I "%~1"=="start" goto cli_start
if /I "%~1"=="stop" goto cli_stop
if /I "%~1"=="status" goto cli_status
call :log_error "Uso: scripts\start-docker-windows.bat [start^|stop^|status]"
exit /b 1

:cli_start
set "NON_INTERACTIVE_MODE=1"
call :start_docker_stack
exit /b %errorlevel%

:cli_stop
set "NON_INTERACTIVE_MODE=1"
call :stop_docker_stack
exit /b %errorlevel%

:cli_status
set "NON_INTERACTIVE_MODE=1"
call :print_selection_screen
exit /b 0

:setup_colors
for /f %%E in ('echo prompt $E^| cmd') do set "ESC=%%E"
if defined ESC (
    set "COLOR_RESET=!ESC![0m"
    set "COLOR_BOLD=!ESC![1m"
    set "COLOR_BLUE=!ESC![34m"
    set "COLOR_GREEN=!ESC![32m"
    set "COLOR_YELLOW=!ESC![33m"
    set "COLOR_RED=!ESC![31m"
    set "COLOR_CYAN=!ESC![36m"
) else (
    set "COLOR_RESET="
    set "COLOR_BOLD="
    set "COLOR_BLUE="
    set "COLOR_GREEN="
    set "COLOR_YELLOW="
    set "COLOR_RED="
    set "COLOR_CYAN="
)
exit /b 0

:log_info
echo !COLOR_BLUE![INFO]!COLOR_RESET! %~1
exit /b 0

:log_ok
echo !COLOR_GREEN![OK]!COLOR_RESET! %~1
exit /b 0

:log_error
echo !COLOR_RED![ERRO]!COLOR_RESET! %~1
exit /b 0

:copy_env_file_if_missing
if not exist "%ENV_EXAMPLE%" (
    call :log_error "Arquivo .env.docker.example não encontrado."
    exit /b 1
)

if not exist "%ENV_FILE%" (
    copy /y "%ENV_EXAMPLE%" "%ENV_FILE%" >nul
    call :log_info "Arquivo .env.docker criado automaticamente a partir do modelo padrão."
)
exit /b 0

:detect_docker_cmd
set "DOCKER_CMD="
set "DOCKER_BIN_DIR="

where docker.exe >nul 2>nul
if not errorlevel 1 (
    for /f "usebackq delims=" %%D in (`where docker.exe`) do (
        set "DOCKER_CMD=%%D"
        goto docker_cmd_found
    )
)

set "DOCKER_CANDIDATE=!PROGRAM_FILES!\Docker\Docker\resources\bin\docker.exe"
if exist "!DOCKER_CANDIDATE!" (
    set "DOCKER_CMD=!DOCKER_CANDIDATE!"
    goto docker_cmd_found
)

set "DOCKER_CANDIDATE=!PROGRAM_W6432!\Docker\Docker\resources\bin\docker.exe"
if exist "!DOCKER_CANDIDATE!" (
    set "DOCKER_CMD=!DOCKER_CANDIDATE!"
    goto docker_cmd_found
)

set "DOCKER_CANDIDATE=!PROGRAM_FILES_X86!\Docker\Docker\resources\bin\docker.exe"
if exist "!DOCKER_CANDIDATE!" (
    set "DOCKER_CMD=!DOCKER_CANDIDATE!"
    goto docker_cmd_found
)

set "DOCKER_CANDIDATE=!LOCAL_APP_DATA!\Programs\Docker\Docker\resources\bin\docker.exe"
if exist "!DOCKER_CANDIDATE!" (
    set "DOCKER_CMD=!DOCKER_CANDIDATE!"
)

:docker_cmd_found
if not defined DOCKER_CMD exit /b 1

for %%F in ("%DOCKER_CMD%") do set "DOCKER_BIN_DIR=%%~dpF"
if defined DOCKER_BIN_DIR set "PATH=%DOCKER_BIN_DIR%;%PATH%"
exit /b 0

:require_docker_cmd
call :detect_docker_cmd
if not errorlevel 1 exit /b 0

call :log_error "Docker não encontrado no PATH nem nos caminhos padrão do Docker Desktop."
call :log_error "Instale o Docker Desktop e execute este arquivo novamente."
call :log_info "Verifique se o arquivo docker.exe existe em uma destas pastas:"
echo   %PROGRAM_FILES%\Docker\Docker\resources\bin
echo   %PROGRAM_W6432%\Docker\Docker\resources\bin
echo   %PROGRAM_FILES_X86%\Docker\Docker\resources\bin
echo   %LOCAL_APP_DATA%\Programs\Docker\Docker\resources\bin
exit /b 1

:is_docker_active
set "%~1=0"
if not defined DOCKER_CMD exit /b 0

"%DOCKER_CMD%" info >nul 2>nul
if errorlevel 1 exit /b 0

set "%~1=1"
exit /b 0

:ensure_docker_is_active_for_start
call :is_docker_active DOCKER_ACTIVE
if "!DOCKER_ACTIVE!"=="1" exit /b 0

call :log_info "Docker ainda não está ativo. Tentando abrir o Docker Desktop..."

set "DOCKER_DESKTOP_EXE=!PROGRAM_FILES!\Docker\Docker\Docker Desktop.exe"
if exist "!DOCKER_DESKTOP_EXE!" (
    start "" "!DOCKER_DESKTOP_EXE!"
) else (
    set "DOCKER_DESKTOP_EXE=!LOCAL_APP_DATA!\Programs\Docker\Docker\Docker Desktop.exe"
    if exist "!DOCKER_DESKTOP_EXE!" (
        start "" "!DOCKER_DESKTOP_EXE!"
    ) else (
        call :log_error "Não encontrei o Docker Desktop nos caminhos padrão."
        call :log_error "Abra o Docker Desktop manualmente e execute este arquivo novamente."
        exit /b 1
    )
)

call :log_info "Aguardando o Docker ficar disponível..."
for /l %%I in (1,1,60) do (
    call :is_docker_active DOCKER_ACTIVE
    if "!DOCKER_ACTIVE!"=="1" exit /b 0
    "%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2" >nul
)

call :log_error "O Docker Desktop não ficou pronto a tempo."
call :log_error "Confira se o motor do Docker iniciou corretamente e tente novamente."
exit /b 1

:run_compose
if exist "%ENV_FILE%" (
    "%DOCKER_CMD%" compose -f "%COMPOSE_FILE%" --env-file "%ENV_FILE%" %*
) else (
    "%DOCKER_CMD%" compose -f "%COMPOSE_FILE%" %*
)
exit /b %errorlevel%

:url_is_up
set "%~2=0"
"%POWERSHELL_EXE%" -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; $response = Invoke-WebRequest -UseBasicParsing '%~1'; if ($response.StatusCode -eq 200) { exit 0 } } catch { } exit 1" >nul 2>nul
if errorlevel 1 exit /b 0
set "%~2=1"
exit /b 0

:wait_for_url
setlocal
set "WAIT_URL=%~1"
set "WAIT_SERVICE=%~2"
set "WAIT_ATTEMPTS=%~3"
set "WAIT_DELAY=%~4"

for /l %%I in (1,1,%WAIT_ATTEMPTS%) do (
    call :url_is_up "%WAIT_URL%" URL_UP
    if "!URL_UP!"=="1" (
        call :log_ok "%WAIT_SERVICE% em execução."
        endlocal & exit /b 0
    )
    "%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds %WAIT_DELAY%" >nul
)

endlocal & exit /b 1

:get_docker_status
call :detect_docker_cmd >nul 2>nul
if errorlevel 1 (
    set "%~1=parado"
    exit /b 0
)

call :is_docker_active DOCKER_ACTIVE
if "!DOCKER_ACTIVE!"=="1" (
    set "%~1=ok"
) else (
    set "%~1=parado"
)
exit /b 0

:get_container_name
set "CONTAINER_NAME="
if /I "%~1"=="frontend" set "CONTAINER_NAME=infinitygo-frontend"
if /I "%~1"=="backend" set "CONTAINER_NAME=infinitygo-backend"
if /I "%~1"=="postgres" set "CONTAINER_NAME=infinitygo-postgres"
set "%~2=%CONTAINER_NAME%"
exit /b 0

:is_container_running
"%POWERSHELL_EXE%" -NoProfile -Command ^
    "$containerNames = & '%DOCKER_CMD%' ps --format '{{.Names}}' 2>$null; if ($containerNames -contains '%~1') { exit 0 } exit 1" >nul 2>nul
if errorlevel 1 (
    set "%~2=0"
) else (
    set "%~2=1"
)
exit /b 0

:get_container_status
setlocal
set "SERVICE_NAME=%~1"
set "CONTAINER_NAME="
set "IS_RUNNING=0"

call :detect_docker_cmd >nul 2>nul
if errorlevel 1 endlocal & set "%~2=parado" & exit /b 0

call :is_docker_active DOCKER_ACTIVE
if not "!DOCKER_ACTIVE!"=="1" endlocal & set "%~2=parado" & exit /b 0

call :get_container_name "%SERVICE_NAME%" CONTAINER_NAME
if not defined CONTAINER_NAME endlocal & set "%~2=parado" & exit /b 0

call :is_container_running "%CONTAINER_NAME%" IS_RUNNING
if "!IS_RUNNING!"=="1" (
    endlocal & set "%~2=ok" & exit /b 0
)

endlocal & set "%~2=parado" & exit /b 0

:get_http_service_status
setlocal
set "SERVICE_NAME=%~1"
set "SERVICE_URL=%~2"

call :get_container_status "%SERVICE_NAME%" CONTAINER_STATUS
if /I "!CONTAINER_STATUS!"=="ok" (
    call :url_is_up "%SERVICE_URL%" URL_UP
    if "!URL_UP!"=="1" (
        endlocal & set "%~3=ok" & exit /b 0
    )
    endlocal & set "%~3=iniciando" & exit /b 0
)

if /I "!CONTAINER_STATUS!"=="iniciando" (
    endlocal & set "%~3=iniciando" & exit /b 0
)

endlocal & set "%~3=parado" & exit /b 0

:format_status_label
if /I "%~1"=="ok" (
    set "%~2=!COLOR_GREEN!ok!COLOR_RESET!"
    exit /b 0
)
if /I "%~1"=="iniciando" (
    set "%~2=!COLOR_YELLOW!iniciando!COLOR_RESET!"
    exit /b 0
)
set "%~2=!COLOR_RED!parado!COLOR_RESET!"
exit /b 0

:print_active_urls
call :get_http_service_status frontend "%FRONTEND_URL%" FRONTEND_STATUS
call :get_http_service_status backend "%BACKEND_HEALTH_URL%" BACKEND_STATUS

if /I "!FRONTEND_STATUS!"=="ok" echo !COLOR_CYAN!Frontend:!COLOR_RESET! !COLOR_BOLD!%FRONTEND_URL%!COLOR_RESET!
if /I "!BACKEND_STATUS!"=="ok" echo !COLOR_CYAN!Backend:!COLOR_RESET!  !COLOR_BOLD!%BACKEND_HEALTH_URL%!COLOR_RESET!
exit /b 0

:print_selection_screen
call :get_docker_status DOCKER_STATUS
call :get_http_service_status frontend "%FRONTEND_URL%" FRONTEND_STATUS
call :get_http_service_status backend "%BACKEND_HEALTH_URL%" BACKEND_STATUS
call :get_container_status postgres POSTGRES_STATUS

call :format_status_label "!DOCKER_STATUS!" DOCKER_LABEL
call :format_status_label "!FRONTEND_STATUS!" FRONTEND_LABEL
call :format_status_label "!BACKEND_STATUS!" BACKEND_LABEL
call :format_status_label "!POSTGRES_STATUS!" POSTGRES_LABEL

cls
echo !COLOR_BOLD!Gerenciador do ambiente Docker!COLOR_RESET!
echo.
echo Docker     - !DOCKER_LABEL!
echo Frontend   - !FRONTEND_LABEL!
echo Backend    - !BACKEND_LABEL!
echo PostgreSQL - !POSTGRES_LABEL!
echo.

if /I "!FRONTEND_STATUS!"=="ok" (
    call :print_active_urls
    echo.
)
if /I "!FRONTEND_STATUS!" NEQ "ok" if /I "!BACKEND_STATUS!"=="ok" (
    call :print_active_urls
    echo.
)

echo !COLOR_CYAN!1.!COLOR_RESET! Iniciar ambiente Docker
echo !COLOR_CYAN!2.!COLOR_RESET! Parar ambiente Docker
echo !COLOR_CYAN!3.!COLOR_RESET! Atualizar status
echo !COLOR_CYAN!4.!COLOR_RESET! Sair
echo.
exit /b 0

:return_to_selection_screen
if "%NON_INTERACTIVE_MODE%"=="1" exit /b 0
call :log_info "Retornando ao menu em 2 segundos..."
"%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2" >nul
exit /b 0

:print_compose_status
echo.
echo [DIAGNÓSTICO] Status atual dos containers:
call :run_compose ps
exit /b 0

:start_docker_stack
call :require_docker_cmd
if errorlevel 1 exit /b 1

call :ensure_docker_is_active_for_start
if errorlevel 1 exit /b 1

call :log_info "Docker ativo."
call :log_info "Subindo frontend, backend e PostgreSQL com Docker Compose..."
call :run_compose up --build -d
if errorlevel 1 (
    call :log_error "Falha ao subir os containers do projeto."
    call :print_compose_status
    exit /b 1
)

call :log_info "Aguardando a inicialização do backend..."
call :wait_for_url "%BACKEND_HEALTH_URL%" "Backend" 30 2
if errorlevel 1 (
    call :log_error "O backend não respondeu em tempo hábil."
    call :print_compose_status
    echo.
    echo [DIAGNÓSTICO] Últimos logs do backend:
    call :run_compose logs backend --tail=120
    exit /b 1
)

call :log_info "Aguardando a inicialização do frontend..."
call :wait_for_url "%FRONTEND_URL%" "Frontend" 20 2
if errorlevel 1 (
    call :log_error "O frontend não respondeu em tempo hábil."
    call :print_compose_status
    echo.
    echo [DIAGNÓSTICO] Últimos logs do frontend:
    call :run_compose logs frontend --tail=120
    exit /b 1
)

echo.
call :log_ok "Projeto iniciado com sucesso no Docker."
call :log_ok "Frontend: %FRONTEND_URL%"
call :log_ok "Backend:  %BACKEND_HEALTH_URL%"
call :log_ok "Para parar frontend, backend e PostgreSQL: scripts\start-docker-windows.bat stop"
exit /b 0

:stop_docker_stack
call :detect_docker_cmd >nul 2>nul
if errorlevel 1 (
    call :log_info "Docker não foi encontrado. Considerando ambiente parado."
    exit /b 0
)

call :is_docker_active DOCKER_ACTIVE
if not "!DOCKER_ACTIVE!"=="1" (
    call :log_info "Docker já está inativo."
    exit /b 0
)

call :log_info "Desligando frontend, backend e PostgreSQL..."
call :run_compose down
if errorlevel 1 (
    call :log_error "Falha ao desligar os containers do projeto."
    exit /b 1
)

echo.
call :log_ok "Containers desligados com sucesso."
call :log_info "Este script afeta apenas o ambiente Docker. Para o ambiente local sem Docker, use ./scripts/start-local-wsl.sh stop"
exit /b 0

:run_interactive_menu
call :print_selection_screen
choice /c 1234 /n /m "Escolha uma opção: "
echo.

if errorlevel 4 goto end
if errorlevel 3 goto run_interactive_menu
if errorlevel 2 (
    call :stop_docker_stack
    call :return_to_selection_screen
    goto run_interactive_menu
)
if errorlevel 1 (
    call :start_docker_stack
    call :return_to_selection_screen
    goto run_interactive_menu
)

goto run_interactive_menu

:end
exit /b 0
