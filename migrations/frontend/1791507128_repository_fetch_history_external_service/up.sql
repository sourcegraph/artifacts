-- No foreign key: deleting a connection must not touch fetch history, and
-- readers treat a missing service as unknown.
ALTER TABLE repository_fetch_history ADD COLUMN IF NOT EXISTS external_service_id bigint;
