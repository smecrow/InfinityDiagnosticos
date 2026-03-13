# Cloudflare Speedtest Worker

Este Worker expõe as rotas usadas pelo frontend para medir conexão sem depender do backend principal:

- `GET /ping`
- `GET /download?bytes=1000000`
- `POST /upload`

## Variáveis opcionais

- `ALLOWED_ORIGIN`: origem permitida para CORS. Exemplo: `https://seu-dominio.com`
- `MAX_DOWNLOAD_BYTES`: limite máximo do payload de download
- `MAX_UPLOAD_BYTES`: limite máximo do payload de upload

Os valores atuais de referência no repositório foram ajustados para links mais rápidos:

- `MAX_DOWNLOAD_BYTES=20000000`
- `MAX_UPLOAD_BYTES=8000000`

## Contrato esperado pelo frontend

As respostas devem incluir os headers:

- `X-Speedtest-Provider`
- `X-Speedtest-Region`

O frontend atual lê esses headers para salvar no backend:

- provedor da medição
- região/ponto de medição

## Exemplo de uso no frontend

Defina em `.env`:

`NEXT_PUBLIC_SPEEDTEST_BASE_URL=https://infinitygo-speedtest.smecrowl9.workers.dev`
