-- Links Deep Search conversations to the change request they were asked about,
-- so that the change request page can list and continue them.
CREATE TABLE IF NOT EXISTS change_request_deepsearch_conversations (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    deepsearch_conversation_id INTEGER NOT NULL REFERENCES deepsearch_conversations(id) ON DELETE CASCADE,
    -- The change request's head when the conversation was started.
    head_oid TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT change_request_deepsearch_conversations_conversation_unique UNIQUE (tenant_id, deepsearch_conversation_id)
);

CREATE INDEX IF NOT EXISTS change_request_deepsearch_conversations_change_request_idx
    ON change_request_deepsearch_conversations (tenant_id, change_request_id);

ALTER TABLE change_request_deepsearch_conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_deepsearch_conversations;
CREATE POLICY tenant_isolation_policy ON change_request_deepsearch_conversations AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
