# Cloudflare Speedtest Worker

Este diretório ficou como referência legada.

O fluxo principal do projeto não usa mais este Worker. A partir de 2026-03-13, o site executa o speedtest no backend com o Speedtest CLI oficial da Ookla, usando o `server-id` `35474` documentado em `../speedtest.txt`.

Se você decidir reutilizar este Worker no futuro, trate-o como código histórico e revalide o contrato antes de recolocar em produção.
