@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~dp0"
set "ENV_FILE=%PROJECT_DIR%.env.docker"
set "PROGRAM_FILES=%ProgramFiles%"
set "PROGRAM_W6432=%ProgramW6432%"
set "PROGRAM_FILES_X86=%ProgramFiles(x86)%"
set "LOCAL_APP_DATA=%LocalAppData%"
set "SYSTEM32_DIR=%SystemRoot%\System32"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "DOCKER_CMD="
set "DOCKER_BIN_DIR="

title InfinityGo Docker Stop
cd /d "%PROJECT_DIR%"

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
    echo [ERRO] Instale o Docker Desktop ou ajuste o PATH e tente novamente.
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

echo [INFO] Desligando frontend, backend e PostgreSQL...
if exist "%ENV_FILE%" (
    "%DOCKER_CMD%" compose --env-file "%ENV_FILE%" down
) else (
    "%DOCKER_CMD%" compose down
)

if errorlevel 1 (
    echo [ERRO] Falha ao desligar os containers do projeto.
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Containers desligados com sucesso.
echo [INFO] Revise as mensagens acima antes de fechar esta janela.
pause
"%POWERSHELL_EXE%" -NoProfile -Command "Start-Sleep -Seconds 2" >nul
exit /b 0
