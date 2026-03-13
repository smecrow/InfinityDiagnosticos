1. Última atualização
2026-03-13 - Refinado o script local unificado com cores no menu/logs e exibição das URLs de `localhost` quando frontend e backend estiverem ativos.

2. Estado da sessão
encerrada limpa - O fluxo local sem Docker agora é operado pelo `run-project-local-wsl.sh`, que mostra o status de frontend/backend/PostgreSQL no topo, permite iniciar ou parar pelo mesmo menu, retorna automaticamente para a tela de seleção e exibe as URLs clicáveis de `localhost` quando o ambiente está ativo; o `stop-project-local-wsl.sh` ficou só como atalho de compatibilidade.

3. Arquivos tocados
.env.local.example: variáveis padrão para execução local sem Docker
run-project-local-wsl.sh: bootstrap local com checagem/instalação de Java 21, Node.js 22, PostgreSQL, Speedtest CLI, criação automática do cluster PostgreSQL, normalização do `mvnw`, cache Maven local, logs progressivos do backend, status colorido no topo, URLs de `localhost` e menu interativo unificado de iniciar/parar
stop-project-local-wsl.sh: atalho de compatibilidade que delega a parada para `run-project-local-wsl.sh stop`
stop-project-wsl.sh: aviso explícito de que o script atende apenas ao ambiente Docker
backend/mvnw: final de linha convertido para Unix para execução correta no WSL
STATUS.md: sincronizado com o novo fluxo local

4. Próximos passos
Executar `./run-project-local-wsl.sh` no WSL para validar a instalação dos pré-requisitos e subir o ambiente local completo.
Usar `./run-project-local-wsl.sh` como ponto único de entrada do ambiente local sem Docker; `./stop-project-local-wsl.sh` permanece apenas como compatibilidade.
Disparar o speedtest pelo frontend local para comparar o resultado do backend rodando na máquina com o resultado do navegador no `speedtest.net`.
Se a diferença continuar alta fora do Docker, investigar gargalo local de SO, driver, VPN, antivírus ou rota do CLI em relação ao navegador.

5. Decisões pendentes
Definir se o fluxo local sem Docker passa a ser o caminho principal de desenvolvimento ou se permanece apenas como alternativa para validação do speedtest.
