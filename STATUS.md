1. Última atualização
2026-03-13 - A checagem de status do Docker no Windows passou a usar PowerShell por baixo do `.bat` para ler `docker ps` com mais confiabilidade.

2. Estado da sessão
encerrada limpa - O backend continua com parsing mais tolerante da saída do Speedtest CLI, e o gerenciador Docker do Windows agora resolve o status de `frontend`, `backend` e `postgres` por meio de uma chamada PowerShell ao `docker ps --format "{{.Names}}"`, evitando a fragilidade do `for /f` do `cmd.exe` com a saída do Docker.

3. Arquivos tocados
scripts/start-docker-windows.bat: detecção de status ajustada para usar PowerShell na leitura de `docker ps --format "{{.Names}}"` dos `container_name` do Compose
backend/src/main/java/com/infinitygo/diagnosticbackend/diagnostic/service/OoklaCliSpeedTestRunner.java: extração do payload JSON da saída do CLI e mensagem de erro com resumo da saída bruta
scripts/start-docker-wsl.sh: permissão de execução restaurada para uso direto com `./scripts/start-docker-wsl.sh`
scripts/start-docker-windows.bat: compatibilidade melhorada com caminhos UNC via `pushd`, recálculo de caminhos e normalização para CRLF
scripts/start-local-wsl.sh: frontend local no WSL ajustado para subir com `--webpack`, `WATCHPACK_POLLING=true` e `CHOKIDAR_USEPOLLING=1`
scripts/start-docker-wsl.sh: gerenciador único do Docker no WSL com menu, cores, status de Docker/frontend/backend/PostgreSQL e fluxo `start|stop|status`
scripts/start-docker-windows.bat: gerenciador único do Docker no Windows com menu, status de Docker/frontend/backend/PostgreSQL e fluxo `start|stop|status`
backend/src/main/java/com/infinitygo/diagnosticbackend/config/SecurityConfig.java: regras de acesso simplificadas para liberar `POST` e `PATCH` de `/api/diagnostics/*/speedtest`
frontend/components/diagnostic-dashboard.tsx: mensagem de erro do speedtest refinada para destacar resposta `401` do backend
config/env/: arquivos de ambiente do fluxo local e do fluxo Docker centralizados fora da raiz
frontend/.env.example: exemplo de variável pública do frontend movido para junto do app Next.js
frontend/: app Next.js, assets, componentes, configs TypeScript/Next, `node_modules` e artefatos locais movidos para o módulo do frontend
scripts/start-local-wsl.sh: script principal para iniciar e parar o ambiente local no WSL, com frontend em `frontend/`
scripts/*.sh e scripts/*.bat: caminhos de `ENV_FILE` e `ENV_EXAMPLE` atualizados para `config/env/`
docker/docker-compose.yml: contextos de build atualizados para `../frontend` e `../backend`
docker/frontend.Dockerfile: Dockerfile do frontend movido e corrigido para copiar também `public/`
docker/backend.Dockerfile: Dockerfile do backend movido para a pasta Docker
docs/: documentação funcional e operacional agrupada
legacy/cloudflare-speedtest/: Worker legado isolado fora do fluxo principal
.gitignore: ignores atualizados para `frontend/.next`, `frontend/node_modules` e `frontend/tsconfig.tsbuildinfo`
frontend/.dockerignore: novo ignore dedicado ao build Docker do frontend
STATUS.md: sincronizado com a reorganização estrutural

4. Próximos passos
Executar `scripts\\start-docker-windows.bat status` com os containers já ativos para confirmar que o painel deixou de marcar tudo como parado.
Recriar o backend do Docker para carregar a nova lógica de parsing do Speedtest CLI antes de testar novamente.
Tentar o speedtest de novo e, se ainda falhar, observar a nova mensagem retornada pelo frontend com o resumo da saída do CLI.
Executar `./scripts/start-docker-wsl.sh` no WSL para confirmar que o erro `Permission denied` desapareceu.
Executar `scripts\\start-docker-windows.bat` a partir do Windows para confirmar que o caminho UNC do WSL não quebra mais o `.bat`.
Reiniciar o backend local ou recriar os containers Docker para carregar a nova configuração de segurança antes de testar o speedtest novamente.
Executar `./scripts/start-local-wsl.sh` no WSL para validar se o frontend parou de recarregar em loop com `webpack` e polling.
Executar `./scripts/start-docker-wsl.sh` no WSL e validar o menu interativo, o status no topo e as ações de iniciar/parar no mesmo script.
Usar `./scripts/start-docker-wsl.sh` como ponto único de entrada do ambiente Docker no WSL.
Executar `scripts\\start-docker-windows.bat` no Windows e validar o menu interativo, o status no topo e as ações de iniciar/parar no mesmo script.
Usar `scripts\\start-docker-windows.bat` como ponto único de entrada do ambiente Docker no Windows.
Confirmar que `docker compose -f docker/docker-compose.yml --env-file config/env/.env.docker` resolve corretamente os contextos `../frontend` e `../backend`.
Disparar o speedtest pelo frontend local para confirmar que a reorganização não alterou o fluxo funcional já existente.

5. Decisões pendentes
Definir se a raiz deve ganhar um `README.md` curto documentando a nova estrutura (`frontend`, `backend`, `scripts`, `docker`, `docs`, `config`, `legacy`).
