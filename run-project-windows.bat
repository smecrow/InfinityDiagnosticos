@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "BACKEND_DIR=%PROJECT_DIR%backend"

title InfinityGo Windows Launcher

start "InfinityGo Backend" cmd /k "cd /d ""%BACKEND_DIR%"" && call run-backend-dev.cmd"
start "InfinityGo Frontend" cmd /k "cd /d ""%PROJECT_DIR%"" && call npm.cmd run dev"

endlocal
