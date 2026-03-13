@echo off
setlocal

set "BACKEND_DIR=%~dp0"
set "ENV_FILE=%BACKEND_DIR%.env"

if exist "%ENV_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        if not "%%A"=="" set "%%A=%%B"
    )
)

call "%BACKEND_DIR%mvnw.cmd" spring-boot:run
