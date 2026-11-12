ALTER TABLE repository_fetch_history ADD COLUMN IF NOT EXISTS external_connectivity_error boolean NOT NULL DEFAULT FALSE;

-- Existing rows take the default once and count as exported, so old history
-- is not sent. Postgres stores a non-volatile default without rewriting the
-- table. New rows start unexported.
ALTER TABLE repository_fetch_history ADD COLUMN IF NOT EXISTS telemetry_exported_at timestamp with time zone DEFAULT now();
ALTER TABLE repository_fetch_history ALTER COLUMN telemetry_exported_at DROP DEFAULT;
