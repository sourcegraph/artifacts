-- Records human-approval gates raised before an agent tool (currently
-- prepare_batch_spec) executes. While a request is pending the owning message
-- stays 'processing' but is waiting on the user, mirroring the ask_user pause.
CREATE TABLE IF NOT EXISTS batch_change_agent_tool_approvals (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    message_id INTEGER NOT NULL REFERENCES batch_change_agent_messages(id) ON DELETE CASCADE,
    -- tool_call_id is the model-emitted tool call ID this approval gates.
    tool_call_id TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    -- request_message is the human-readable prompt shown to the approver,
    -- snapshotted at request time so policy changes don't rewrite history.
    request_message TEXT NOT NULL DEFAULT '',
    -- request_findings holds the structured reasons (and optional affected
    -- snippets) backing request_message, snapshotted when the gate was raised,
    -- so the UI can render them as a list and reveal long snippets on demand.
    request_findings JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- state tracks the approval lifecycle. Validated in application code rather
    -- than a DB enum: pending -> allowed / changes_requested.
    state TEXT NOT NULL DEFAULT 'pending',
    -- decision is the human's choice once made: allow, request_changes.
    decision TEXT,
    -- note carries the human's free-text feedback (required for request_changes).
    note TEXT NOT NULL DEFAULT '',
    decided_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_tool_approvals_state_check
        CHECK (state IN ('pending', 'allowed', 'changes_requested')),
    CONSTRAINT batch_change_agent_tool_approvals_decision_check
        CHECK (decision IS NULL OR decision IN ('allow', 'request_changes'))
);

ALTER TABLE batch_change_agent_tool_approvals
    DROP CONSTRAINT IF EXISTS batch_change_agent_tool_approvals_lifecycle_check;
ALTER TABLE batch_change_agent_tool_approvals
    ADD CONSTRAINT batch_change_agent_tool_approvals_lifecycle_check
        CHECK (
            (state = 'pending' AND decision IS NULL AND note = '' AND decided_by_user_id IS NULL)
            OR (state = 'allowed' AND decision = 'allow' AND note = '')
            OR (state = 'changes_requested' AND decision = 'request_changes' AND note <> '')
        );

-- One approval per (message, tool call). Includes tenant_id to keep the
-- constraint tenant-isolated.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_tool_approvals_message_tool_call_idx
    ON batch_change_agent_tool_approvals (tenant_id, message_id, tool_call_id);

ALTER TABLE batch_change_agent_tool_approvals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_tool_approvals;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_tool_approvals AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
