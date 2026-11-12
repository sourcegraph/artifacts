-- Generalize the existing thread snapshot without changing its identity or RLS.
-- Empty kind marks legacy inline threads until the next GitHub synchronization.
ALTER TABLE change_request_review_threads
    ADD COLUMN IF NOT EXISTS kind TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT '1970-01-01 00:00:00+00',
    ADD COLUMN IF NOT EXISTS review_state TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS review_commit_sha TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS original_context JSONB;

-- Existing inline rows remain readable. Complete discussions are fetched on
-- the next normal sync, including PR comments that were not stored before.
-- Match this timestamp to synced_at so an older worker's inline-only sync
-- invalidates completeness even after a newer worker has synchronized once.
ALTER TABLE change_requests
    ADD COLUMN IF NOT EXISTS discussions_synced_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS change_request_review_threads_chronological
    ON change_request_review_threads (tenant_id, change_request_id, created_at, external_id);
