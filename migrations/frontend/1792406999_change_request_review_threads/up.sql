-- Inline review threads of a change request, as of its last synchronization.
-- Each synchronization replaces all threads of the change request in the same
-- transaction as its snapshot, so the line range always refers to the stored
-- base and head commits.
CREATE TABLE IF NOT EXISTS change_request_review_threads (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    -- The code host's ID of the thread's first comment.
    external_id TEXT NOT NULL,
    path TEXT NOT NULL,
    -- The line range in the current diff. NULL if the thread is outdated or
    -- not attached to lines.
    start_side TEXT,
    start_line INTEGER,
    end_side TEXT,
    end_line INTEGER,
    resolved BOOLEAN NOT NULL,
    outdated BOOLEAN NOT NULL,
    comments JSONB NOT NULL,
    CONSTRAINT change_request_review_threads_pkey PRIMARY KEY (tenant_id, change_request_id, external_id),
    CONSTRAINT change_request_review_threads_range_check CHECK (
        (start_side IS NULL AND start_line IS NULL AND end_side IS NULL AND end_line IS NULL)
        OR (start_side IN ('base', 'head') AND end_side IN ('base', 'head') AND start_line > 0 AND end_line > 0)
    )
);

ALTER TABLE change_request_review_threads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_review_threads;
CREATE POLICY tenant_isolation_policy ON change_request_review_threads AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
