WITH ranked_user_jobs AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY tenant_id, priority, user_id, cancel
            ORDER BY process_after DESC NULLS LAST, id DESC
        ) AS rank
    FROM permission_sync_jobs
    WHERE state = 'queued'::text
      AND user_id IS NOT NULL
),
stale_user_jobs AS (
    SELECT id
    FROM ranked_user_jobs
    WHERE rank > 1
)
UPDATE permission_sync_jobs
SET cancel = TRUE,
    state = 'canceled'::text,
    finished_at = NOW(),
    cancellation_reason = 'Superseded by a processing sync job for the same user.'
WHERE id IN (SELECT id FROM stale_user_jobs);

WITH ranked_repo_jobs AS (
    SELECT
        id,
        ROW_NUMBER() OVER (
            PARTITION BY tenant_id, priority, repository_id, cancel
            ORDER BY process_after DESC NULLS LAST, id DESC
        ) AS rank
    FROM permission_sync_jobs
    WHERE state = 'queued'::text
      AND repository_id IS NOT NULL
),
stale_repo_jobs AS (
    SELECT id
    FROM ranked_repo_jobs
    WHERE rank > 1
)
UPDATE permission_sync_jobs
SET cancel = TRUE,
    state = 'canceled'::text,
    finished_at = NOW(),
    cancellation_reason = 'Superseded by a processing sync job for the same user.'
WHERE id IN (SELECT id FROM stale_repo_jobs);

DROP INDEX IF EXISTS permission_sync_jobs_unique;

CREATE UNIQUE INDEX IF NOT EXISTS permission_sync_jobs_unique_user
    ON permission_sync_jobs USING btree (priority, user_id, cancel, tenant_id)
    WHERE (state = 'queued'::text) AND (user_id IS NOT NULL);

CREATE UNIQUE INDEX IF NOT EXISTS permission_sync_jobs_unique_repo
    ON permission_sync_jobs USING btree (priority, repository_id, cancel, tenant_id)
    WHERE (state = 'queued'::text) AND (repository_id IS NOT NULL);
