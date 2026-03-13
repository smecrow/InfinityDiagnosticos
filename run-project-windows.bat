@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~dp0"
set "ENV_FILE=%PROJECT_DIR%.env.docker"
set "ENV_EXAMPLE=%PROJECT_DIR%.env.docker.example"
set "PROGRAM_FILES=%ProgramFiles%"
set "PROGRAM_W6432=%ProgramW6432%"
set "PROGRAM_FILES_X86=%ProgramFiles(x86)%"
set "LOCAL_APP_DATA=%LocalAppData%"
set "SYSTEM32_DIR=%SystemRoot%\System32"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "BACKEND_HEALTH_URL=http://localhost:8080/api/health"
set "FRONTEND_URL=http://localhost:3000"
set "DOCKER_CMD="
set "DOCKER_BIN_DIR="
set "DOCKER_DESKTOP_EXE="
set "CONTAINER_STATUS="

title InfinityGo Docker Launcher
cd /d "%PROJECT_DIR%"

if not exist "%ENV_EXAMPLE%" (
    echo [ERRO] Arquivo .env.docker.example nao encontrado.
    echo.
    pause
    exit /b 1
)

if not exist "%ENV_FILE%" (
    copy /y "%ENV_EXAMPLE%" "%ENV_FILE%" >nul
    echo [INFO] Arquivo .env.docker criado automaticamente a partir do modelo padrao.
)

where docker.exe >nul 2>nul
if not errorlevel 1 (
    for /f "usebackq delims=" %%D in (`where docker.exe`) do (
        set "DOCKER_CMD=%%D"
        goto docker_cmd_found
    )
) else (
    set "DOCKER_CANDIDATE=!PROGRAM_FILES!\Docker\Docker\resources\bin\docker.exe"
    if exist "!DOCKER_CANDIDATE!" (
        set "DOCKER_CMD=!DOCKER_CANDIDATE!"
    ) else (
        set "DOCKER_CANDIDATE=!PROGRAM_W6432!\Docker\Docker\resources\bin\docker.exe"
        if exist "!DOCKER_CANDIDATE!" (
            set "DOCKER_CMD=!DOCKER_CANDIDATE!"
        ) else (
            set "DOCKER_CANDIDATE=!PROGRAM_FILES_X86!\Docker\Docker\resources\bin\docker.exe"
            if exist "!DOCKER_CANDIDATE!" (
                set "DOCKER_CMD=!DOCKER_CANDIDATE!"
            ) else (
                set "DOCKER_CANDIDATE=!LOCAL_APP_DATA!\Programs\Docker\Docker\resources\bin\docker.exe"
                if exist "!DOCKER_CANDIDATE!" (
                    set "DOCKER_CMD=!DOCKER_CANDIDATE!"
                )
            )
        )
    )
)

:docker_cmd_found
if "!DOCKER_CMD!"=="" (
    echo [ERRO] Docker nao encontrado no PATH nem nos caminhos padrao do Docker Desktop.
    echo [ERRO] Instale o Docker Desktop e execute este arquivo novamente.
    echo [DICA] Verifique se o arquivo docker.exe existe em uma destas pastas:
    echo [DICA]   !PROGRAM_FILES!\Docker\Docker\resources\bin
    echo [DICA]   !PROGRAM_W6432!\Docker\Docker\resources\bin
    echo [DICA]   !PROGRAM_FILES_X86!\Docker\Docker\resources\bin
    echo [DICA]   !LOCAL_APP_DATA!\Programs\Docker\Docker\resources\bin
    echo.
    pause
    exit /b 1
)

for %%F in ("%DOCKER_CMD%") do set "DOCKER_BIN_DIR=%%~dpF"
if defined DOCKER_BIN_DIR (
    set "PATH=%DOCKER_BIN_DIR%;%PATH%"
)

"%DOCKER_CMD%" info >nul 2>nul
if errorlevel 1 (
    echo [INFO] Docker ainda nao esta ativo. Tentando abrir o Docker Desktop...

    set "DOCKER_DESKTOP_EXE=!PROGRAM_FILES!\Docker\Docker\Docker Desktop.exe"
    if exist "!DOCKER_DESKTOP_EXE!" (
        start "" "!DOCKER_DESKTOP_EXE!"
    ) else (
        set "DOCKER_DESKTOP_EXE=!LOCAL_APP_DATA!\Programs\Docker\Docker\Docker Desktop.exe"
        if exist "!DOCKER_DESKTOP_EXE!" (
            start "" "!DOCKER_DESKTOP_EXE!"
        ) else (
            echo [ERRO] Nao encontrei o Docker Desktop nos caminhos padrao.
            echo [ERRO] Abra o Docker Desktop manualmente e execute este arquivo novamente.
            echo.
            pause
            exit /b 1
        )
    )

    echo [INFO] Aguardando o Docker ficar disponivel...
    for /l %%I in (1,1,60) do (
        "%DOCKER_CMD%" info >nul 2>nul
        if not errorlevel 1 goto docker_ready
        "%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2" >nul
    )

    echo [ERRO] O Docker Desktop nao ficou pronto a tempo.
    echo [ERRO] Confira se o motor do Docker iniciou corretamente e tente novamente.
    echo.
    pause
    exit /b 1
)

:docker_ready
echo [INFO] Docker ativo.
echo [INFO] Docker localizado em: %DOCKER_CMD%
echo [INFO] Subindo frontend, backend e PostgreSQL com Docker Compose...
"%DOCKER_CMD%" compose --env-file "%ENV_FILE%" up --build -d
if errorlevel 1 (
    echo [ERRO] Falha ao subir os containers do projeto.
    echo.
    pause
    exit /b 1
)

echo [INFO] Aguardando a inicializacao do backend...
"%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 35" >nul
"%POWERSHELL_EXE%" -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; $response = Invoke-WebRequest -UseBasicParsing '%BACKEND_HEALTH_URL%'; if ($response.StatusCode -eq 200) { exit 0 } } catch { } exit 1"
if errorlevel 1 (
    echo [ERRO] backend nao ficou em execucao.
    echo.
    echo [DIAGNOSTICO] Status atual dos containers:
    "%DOCKER_CMD%" compose --env-file "%ENV_FILE%" ps
    echo.
    echo [DIAGNOSTICO] Ultimos logs do backend:
    "%DOCKER_CMD%" compose --env-file "%ENV_FILE%" logs backend --tail=120
    echo.
    pause
    exit /b 1
)
echo [INFO] backend em execucao.

echo [INFO] Aguardando a inicializacao do frontend...
"%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 10" >nul
"%POWERSHELL_EXE%" -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; $response = Invoke-WebRequest -UseBasicParsing '%FRONTEND_URL%'; if ($response.StatusCode -eq 200) { exit 0 } } catch { } exit 1"
if errorlevel 1 (
    echo [ERRO] frontend nao ficou em execucao.
    echo.
    echo [DIAGNOSTICO] Status atual dos containers:
    "%DOCKER_CMD%" compose --env-file "%ENV_FILE%" ps
    echo.
    pause
    exit /b 1
)
echo [INFO] frontend em execucao.

echo.
echo [OK] Projeto iniciado com sucesso.
echo [OK] Frontend: http://localhost:3000
echo [OK] Backend:  http://localhost:8080/api/health
echo.
echo [INFO] Revise as mensagens acima antes de fechar esta janela.
pause

start "" "http://localhost:3000"
"%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 3" >nul
exit /b 0
