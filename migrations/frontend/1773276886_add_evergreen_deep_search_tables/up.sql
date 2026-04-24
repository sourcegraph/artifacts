-- evergreen_deep_search: URL-addressable living documents backed by Deep Search conversations.
-- Each doc has a vanity slug (/d/{slug}) and a reference to the
-- Deep Search conversation that contains the generated document.
CREATE TABLE IF NOT EXISTS evergreen_deep_search (
    id SERIAL PRIMARY KEY,
    slug TEXT NOT NULL,
    title TEXT NOT NULL,
    source_conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE SET NULL,
    conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

-- Slug must be unique per tenant
CREATE UNIQUE INDEX IF NOT EXISTS evergreen_deep_search_tenant_slug_unique ON evergreen_deep_search (tenant_id, slug);

-- Index foreign keys to avoid sequential scans on cascading deletes
CREATE INDEX IF NOT EXISTS evergreen_deep_search_source_conversation_id ON evergreen_deep_search (source_conversation_id);
CREATE INDEX IF NOT EXISTS evergreen_deep_search_conversation_id ON evergreen_deep_search (conversation_id);

ALTER TABLE evergreen_deep_search ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deep_search;

CREATE POLICY tenant_isolation_policy ON evergreen_deep_search AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING ((tenant_id = (
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
