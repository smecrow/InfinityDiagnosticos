\set ON_ERROR_STOP on

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_roles
        WHERE rolname = 'infinitygo_app'
    ) THEN
        CREATE ROLE infinitygo_app WITH LOGIN PASSWORD 'infinitygo_app';
    ELSE
        ALTER ROLE infinitygo_app WITH LOGIN PASSWORD 'infinitygo_app';
    END IF;
END
$$;

SELECT 'CREATE DATABASE infinitygodiagnostics OWNER infinitygo_app ENCODING ''UTF8'' TEMPLATE template0'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'infinitygodiagnostics'
)
\gexec

GRANT ALL PRIVILEGES ON DATABASE infinitygodiagnostics TO infinitygo_app;
