ALTER TABLE diagnostics
ADD COLUMN speed_test_provider VARCHAR(50),
ADD COLUMN speed_test_region VARCHAR(80),
ADD COLUMN speed_test_completed_at TIMESTAMPTZ;
