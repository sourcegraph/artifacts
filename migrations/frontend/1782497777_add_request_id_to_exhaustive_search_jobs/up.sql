ALTER TABLE exhaustive_search_jobs
    ADD COLUMN IF NOT EXISTS request_id uuid;

-- Named UNIQUE constraint (not a bare unique index) so idempotent inserts can
-- target it via ON CONFLICT ON CONSTRAINT. Includes tenant_id to isolate by
-- tenant. request_id is nullable: jobs created without a client-supplied
-- idempotency key store NULL, and Postgres treats NULLs as distinct so they
-- never conflict (no backfill needed, so the migration is cheap). Wrapped in a
-- catalog check to stay re-runnable.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'exhaustive_search_jobs_request_id_key'
    ) THEN
        ALTER TABLE exhaustive_search_jobs
            ADD CONSTRAINT exhaustive_search_jobs_request_id_key UNIQUE (tenant_id, request_id);
    END IF;
END $$;
