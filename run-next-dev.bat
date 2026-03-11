@echo off
setlocal

set "PROJECT_DIR=/mnt/c/Users/Admin/Documents/Code/InfinityGoTestSite"
set "WSL_DISTRO=Ubuntu"

title InfinityGo Next Dev
wsl -d %WSL_DISTRO% bash -lc "cd \"%PROJECT_DIR%\" && npm run dev; status=\$?; echo.; if [ \$status -ne 0 ]; then echo O comando falhou com codigo \$status.; fi; exec bash"

endlocal
