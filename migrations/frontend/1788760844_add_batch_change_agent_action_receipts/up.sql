-- Durable idempotency receipts for direct user actions. The action's database
-- effects and completed receipt are committed together, so retrying a request
-- after a lost response can return the original result without repeating it.
CREATE TABLE IF NOT EXISTS batch_change_agent_action_receipts (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    agent_id INTEGER NOT NULL REFERENCES batch_change_agents(id) ON DELETE CASCADE,
    request_id UUID NOT NULL,
    action_kind TEXT NOT NULL,
    request_payload JSONB NOT NULL,
    result_payload JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_action_receipts_request_key
        UNIQUE (tenant_id, agent_id, request_id)
);

ALTER TABLE batch_change_agent_action_receipts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_action_receipts;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_action_receipts AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));
