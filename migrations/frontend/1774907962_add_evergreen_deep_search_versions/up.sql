-- evergreen_deep_search_versions: tracks version history for evergreen deep search articles.
-- Each successful refresh creates a new version pointing to the replayed conversation.
CREATE TABLE IF NOT EXISTS evergreen_deep_search_versions (
    id SERIAL PRIMARY KEY,
    evergreen_deep_search_id INTEGER NOT NULL REFERENCES evergreen_deep_search(id) ON DELETE CASCADE,
    conversation_id INTEGER REFERENCES deepsearch_conversations(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE INDEX IF NOT EXISTS evergreen_deep_search_versions_eds_id
    ON evergreen_deep_search_versions (evergreen_deep_search_id);

ALTER TABLE evergreen_deep_search_versions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON evergreen_deep_search_versions;

CREATE POLICY tenant_isolation_policy ON evergreen_deep_search_versions AS PERMISSIVE
    FOR ALL TO PUBLIC
        USING ((tenant_id = (
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)))
        WITH CHECK ((tenant_id = (
            SELECT
                (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

-- Add updated_at column to evergreen_deep_search
ALTER TABLE evergreen_deep_search ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE;
