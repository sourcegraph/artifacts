-- Restore the pre-spec-scoped dedup indexes and drop the column. Dropping the
-- column first would auto-drop the COALESCE(changeset_spec_id, 0) indexes, but we
-- drop them explicitly for clarity and idempotency.
DROP INDEX IF EXISTS changeset_hook_jobs_dedup_with_oid;
DROP INDEX IF EXISTS changeset_hook_jobs_dedup_without_oid;

ALTER TABLE changeset_hook_jobs
    DROP COLUMN IF EXISTS changeset_spec_id;

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_with_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type, commit_oid)
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_without_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type)
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NULL;
