-- Search indexing work, one row per change request. A trigger queues a change
-- request whenever its indexed fields change, and the worker rewrites its
-- index entry.
CREATE TABLE IF NOT EXISTS change_request_search_queue (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    state TEXT NOT NULL DEFAULT 'queued',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT false,
    UNIQUE (tenant_id, change_request_id)
);

ALTER TABLE change_request_search_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_search_queue;
CREATE POLICY tenant_isolation_policy ON change_request_search_queue AS PERMISSIVE FOR ALL TO PUBLIC
    USING (
        (SELECT current_setting('app.current_tenant') = 'workertenant')
        OR tenant_id = (SELECT NULLIF(current_setting('app.current_tenant'), 'workertenant')::integer AS current_tenant)
    );

CREATE INDEX IF NOT EXISTS change_request_search_queue_dequeue_idx
    ON change_request_search_queue (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

-- The text that change request search matches, one row per change request.
CREATE TABLE IF NOT EXISTS change_request_search_index (
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    search_text TEXT NOT NULL,
    indexed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (tenant_id, change_request_id)
);

ALTER TABLE change_request_search_index ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_search_index;
CREATE POLICY tenant_isolation_policy ON change_request_search_index AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));

-- Trigram index for substring (ILIKE) matching.
CREATE INDEX IF NOT EXISTS change_request_search_index_search_text_trgm_idx
    ON change_request_search_index USING gin (search_text gin_trgm_ops);

COMMENT ON TABLE change_request_search_index IS 'Search text of each change request, written by the change request search indexer from change_request_search_queue.';

-- Synchronization rewrites every column, so only queue changes to the fields
-- that the indexer reads.
CREATE OR REPLACE FUNCTION enqueue_change_request_search_index() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE'
        AND OLD.title IS NOT DISTINCT FROM NEW.title
        AND OLD.body IS NOT DISTINCT FROM NEW.body
        AND OLD.repository_name IS NOT DISTINCT FROM NEW.repository_name
        AND OLD.author IS NOT DISTINCT FROM NEW.author
    THEN
        RETURN NEW;
    END IF;
    INSERT INTO change_request_search_queue (tenant_id, change_request_id)
    VALUES (NEW.tenant_id, NEW.id)
    ON CONFLICT (tenant_id, change_request_id) DO UPDATE SET
        state = 'queued',
        queued_at = now(),
        process_after = NULL,
        started_at = NULL,
        finished_at = NULL,
        failure_message = NULL,
        num_failures = 0,
        num_resets = 0,
        cancel = false;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change_request_search_index_enqueue ON change_requests;
CREATE TRIGGER change_request_search_index_enqueue
    AFTER INSERT OR UPDATE OF title, body, repository_name, author ON change_requests
    FOR EACH ROW EXECUTE FUNCTION enqueue_change_request_search_index();

-- Rebuild the index from scratch: queue every change request, replacing any
-- earlier work. To rebuild after changing what the indexer writes, add a
-- migration that runs these two statements again.
TRUNCATE TABLE change_request_search_queue;
INSERT INTO change_request_search_queue (tenant_id, change_request_id)
SELECT tenant_id, id FROM change_requests;
