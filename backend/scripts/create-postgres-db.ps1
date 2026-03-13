param(
    [string]$SuperUser = "postgres",
    [string]$DbHost = "localhost",
    [int]$Port = 5432,
    [string]$PsqlPath = "$env:ProgramFiles\PostgreSQL\18\bin\psql.exe"
)

$sqlFile = Join-Path $PSScriptRoot "create-postgres-db.sql"

if (-not (Test-Path $PsqlPath)) {
    throw "psql.exe nao encontrado em '$PsqlPath'. Ajuste o parametro -PsqlPath para a instalacao correta do PostgreSQL."
}

if (-not (Test-Path $sqlFile)) {
    throw "Arquivo SQL nao encontrado em '$sqlFile'."
}

Write-Host "Executando bootstrap do banco 'infinitygodiagnostics' com o usuario administrador '$SuperUser'..."
Write-Host "Se necessario, o PostgreSQL pedira a senha do superusuario."

& $PsqlPath -h $DbHost -p $Port -U $SuperUser -d postgres -f $sqlFile

if ($LASTEXITCODE -ne 0) {
    throw "Falha ao executar o bootstrap do PostgreSQL. Codigo de saida: $LASTEXITCODE"
}

Write-Host "Banco 'infinitygodiagnostics' e role 'infinitygo_app' preparados com sucesso."
