CREATE TABLE diagnostics (
    id UUID PRIMARY KEY,
    created_at TIMESTAMPTZ NOT NULL,
    device_type VARCHAR(100) NOT NULL,
    operating_system VARCHAR(100) NOT NULL,
    browser VARCHAR(100) NOT NULL,
    browser_version VARCHAR(50) NOT NULL,
    language VARCHAR(20) NOT NULL,
    timezone VARCHAR(80) NOT NULL,
    platform VARCHAR(100),
    logical_cores INTEGER,
    memory_gigabytes NUMERIC(10, 2),
    connection_type VARCHAR(50) NOT NULL,
    online BOOLEAN NOT NULL,
    latency_ms NUMERIC(10, 2),
    jitter_ms NUMERIC(10, 2),
    packet_loss_percent NUMERIC(10, 2),
    download_mbps NUMERIC(10, 2),
    upload_mbps NUMERIC(10, 2)
);

CREATE INDEX idx_diagnostics_created_at ON diagnostics (created_at DESC);
