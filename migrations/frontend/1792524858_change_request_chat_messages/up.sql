-- Messages in a change request's chat. They are stored only in Sourcegraph,
-- not posted to the code host.
CREATE TABLE IF NOT EXISTS change_request_chat_messages (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    change_request_id BIGINT NOT NULL REFERENCES change_requests(id) ON DELETE CASCADE,
    author_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    body TEXT NOT NULL,
    -- The change request's head when the message was sent.
    head_oid TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS change_request_chat_messages_change_request_idx
    ON change_request_chat_messages (tenant_id, change_request_id, id);

ALTER TABLE change_request_chat_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON change_request_chat_messages;
CREATE POLICY tenant_isolation_policy ON change_request_chat_messages AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
