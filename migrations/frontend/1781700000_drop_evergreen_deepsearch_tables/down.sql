CREATE TABLE IF NOT EXISTS evergreen_deepsearch (
    id SERIAL PRIMARY KEY,
    slug TEXT NOT NULL,
    title TEXT NOT NULL,
    source_conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS evergreen_deepsearch_tenant_slug_unique ON evergreen_deepsearch (tenant_id, slug);
CREATE INDEX IF NOT EXISTS evergreen_deepsearch_source_conversation_id ON evergreen_deepsearch (source_conversation_id);

ALTER TABLE evergreen_deepsearch ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deepsearch;
CREATE POLICY tenant_isolation_policy ON evergreen_deepsearch AS PERMISSIVE FOR ALL TO PUBLIC
    USING ((tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE OR REPLACE FUNCTION update_evergreen_deepsearch_updated_at()
    RETURNS TRIGGER
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_evergreen_deepsearch_updated_at ON evergreen_deepsearch;
CREATE TRIGGER update_evergreen_deepsearch_updated_at
    BEFORE UPDATE ON evergreen_deepsearch
    FOR EACH ROW
    EXECUTE FUNCTION update_evergreen_deepsearch_updated_at();

CREATE TABLE IF NOT EXISTS evergreen_deepsearch_versions (
    id SERIAL PRIMARY KEY,
    evergreen_deepsearch_id INTEGER NOT NULL REFERENCES evergreen_deepsearch(id) ON DELETE CASCADE,
    conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    state TEXT NOT NULL DEFAULT 'completed',
    failure_message TEXT,
    queued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    process_after TIMESTAMPTZ,
    num_resets INTEGER NOT NULL DEFAULT 0,
    num_failures INTEGER NOT NULL DEFAULT 0,
    last_heartbeat_at TIMESTAMPTZ,
    execution_logs JSON[],
    worker_hostname TEXT NOT NULL DEFAULT '',
    cancel BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS evergreen_deepsearch_versions_eds_id ON evergreen_deepsearch_versions (evergreen_deepsearch_id);
CREATE INDEX IF NOT EXISTS evergreen_deepsearch_versions_dequeue_idx
    ON evergreen_deepsearch_versions (tenant_id, state, process_after, queued_at, id)
    WHERE state IN ('queued', 'errored');

ALTER TABLE evergreen_deepsearch_versions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deepsearch_versions;
CREATE POLICY tenant_isolation_policy ON evergreen_deepsearch_versions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (((SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text))
        OR (tenant_id = (SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));
