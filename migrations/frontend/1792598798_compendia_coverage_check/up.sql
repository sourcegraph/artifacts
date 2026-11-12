-- Coverage findings survive citation checks and chapter revisions.
-- coverage_check_after also leases research within a freshness check.
ALTER TABLE compendia ADD COLUMN IF NOT EXISTS coverage_check JSONB;
ALTER TABLE compendia ADD COLUMN IF NOT EXISTS coverage_check_after TIMESTAMP WITH TIME ZONE;
