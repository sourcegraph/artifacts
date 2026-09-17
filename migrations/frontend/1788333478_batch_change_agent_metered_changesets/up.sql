-- One row per changeset merged in an agent-managed batch change whose agent was
-- created at or after the Agentic Batch Changes GA date. Rows are the
-- idempotency and tier-position record for outcome-based metering: the sweep
-- in cmd/worker/internal/batchchangeagents records each changeset exactly once
-- and consumes one unit of the tier SKU for it. Agents created before GA are
-- excluded by the sweep's query and never get a row.
--
-- No foreign keys on purpose: rows are an audit trail and must outlive the
-- changeset, batch change, agent and user they describe.
--
-- Deleting an agent closes its batch change instead of deleting it, and the
-- classic deletion path refuses agent-managed batch changes, so a changeset
-- merged after its agent was deleted is still found through
-- changesets.owned_by_batch_change_id. The one remaining gap is a hard-deleted
-- owner user, which cascades to the agent and its batch change.
CREATE TABLE IF NOT EXISTS batch_change_agent_metered_changesets (
    id BIGSERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    changeset_id BIGINT NOT NULL,
    batch_change_id BIGINT NOT NULL,
    agent_id INTEGER NOT NULL,
    -- Snapshot of batch_change_agents.owner_user_id at metering time: the user
    -- whose quota was consumed.
    owner_user_id INTEGER NOT NULL,
    -- 1-based position of this merge among the metered merges of its batch
    -- change. Drives the tier SKU (1-100 tier 1, 101-300 tier 2, 301+ tier 3)
    -- and records why a changeset was charged at that tier.
    merge_sequence INTEGER NOT NULL,
    -- Set by the sweep right after inserting the row and BEFORE the tier SKU
    -- is consumed, so that a changeset is never metered twice: a consume that
    -- fails afterwards leaves the row processed and is not retried
    -- (under-metering once, never double-billing). A false row only exists if
    -- the sweep crashed between insert and mark; it is not retried either.
    processed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    CONSTRAINT batch_change_agent_metered_changesets_changeset_unique
        UNIQUE (tenant_id, changeset_id),
    CONSTRAINT batch_change_agent_metered_changesets_merge_sequence_check
        CHECK (merge_sequence > 0)
);

-- Positions are unique per batch change. Also serves the per-batch-change
-- count lookup.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_metered_changesets_sequence_idx
    ON batch_change_agent_metered_changesets (tenant_id, batch_change_id, merge_sequence);

ALTER TABLE batch_change_agent_metered_changesets ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON batch_change_agent_metered_changesets;
CREATE POLICY tenant_isolation_policy ON batch_change_agent_metered_changesets AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
