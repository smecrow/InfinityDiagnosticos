1. Última atualização
2026-03-13 - Scripts Linux/WSL criados, validados com `bash -n` e sincronizados para `/home/smecrow/InfinityGoTestSite` com permissão de execução.

2. Estado da sessão
encerrada limpa - O projeto agora tem launchers próprios para WSL/Linux para subir e parar o stack Docker sem depender dos `.bat` de Windows.

3. Arquivos tocados
STATUS.md: contexto final da criação dos scripts Linux/WSL
run-project-wsl.sh: launcher shell para subir o projeto com Docker Compose no WSL
stop-project-wsl.sh: launcher shell para desligar o stack Docker no WSL

4. Próximos passos
Usar `./run-project-wsl.sh` em `/home/smecrow/InfinityGoTestSite` para subir frontend, backend e PostgreSQL no WSL.
Usar `./stop-project-wsl.sh` na mesma pasta para derrubar os containers quando terminar.
Decidir depois se os `.bat` de Windows permanecem na raiz como compatibilidade ou se podem ser removidos.

5. Decisões pendentes
Definir se você quer que eu também adapte a documentação do projeto para apontar explicitamente os novos scripts `.sh`.
