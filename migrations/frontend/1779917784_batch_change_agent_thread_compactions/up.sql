-- batch_change_agent_thread_compactions stores LLM-generated summaries of a
-- thread's earlier turns so the agent loop can fit long-running threads into
-- the model's context window. The table is append-only: each compaction row
-- captures the summary of every turn with id <= up_to_turn_id (which itself
-- incorporates the summary from the previous compaction row, if any). The
-- agent loader picks the latest row per thread and replays
-- [summary turn] + [turns with id > up_to_turn_id] to the LLM. UI rendering
-- continues to read raw turns from batch_change_agent_turns and is unaffected
-- by compaction.
CREATE TABLE IF NOT EXISTS batch_change_agent_thread_compactions (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    thread_id INTEGER NOT NULL REFERENCES batch_change_agent_threads(id) ON DELETE CASCADE,
    -- up_to_turn_id is the highest batch_change_agent_turns.id covered by this
    -- compaction. Turns with id > up_to_turn_id are replayed verbatim after
    -- the summary turn.
    up_to_turn_id BIGINT NOT NULL REFERENCES batch_change_agent_turns(id) ON DELETE CASCADE,
    -- summary is the model-generated recap of everything up to and including
    -- up_to_turn_id, formatted into structured sections (GOAL_STATE,
    -- DECISIONS_MADE, WORK_COMPLETED, FAILED_APPROACHES, UNRESOLVED, ARTIFACTS).
    summary TEXT NOT NULL,
    -- stats is the accumulated LLMStats for every turn covered by this
    -- compaction. The agent loop uses it to continue stats accounting from
    -- where the verbatim tail starts.
    stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- summary_stats records the cost of producing this compaction itself
    -- (the summarisation LLM call). Surfaced separately so the per-message
    -- aggregate can attribute compaction overhead distinctly from regular
    -- turn cost.
    summary_stats JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

COMMENT ON COLUMN batch_change_agent_thread_compactions.up_to_turn_id IS
    'Highest batch_change_agent_turns.id included in this compaction. Turns with id > up_to_turn_id are replayed verbatim after the summary.';

COMMENT ON COLUMN batch_change_agent_thread_compactions.summary IS
    'Model-generated structured recap of all turns up to and including up_to_turn_id. Replayed to the LLM as a single user-role turn.';

ALTER TABLE batch_change_agent_thread_compactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_thread_compactions;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_thread_compactions AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant'::text)::integer AS current_tenant));

-- Latest-per-thread lookup pattern: ORDER BY thread_id, id DESC LIMIT 1.
CREATE INDEX IF NOT EXISTS batch_change_agent_thread_compactions_thread_id_idx
    ON batch_change_agent_thread_compactions (thread_id, id DESC, tenant_id);
