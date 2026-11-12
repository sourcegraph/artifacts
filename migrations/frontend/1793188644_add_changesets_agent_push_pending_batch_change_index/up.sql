CREATE INDEX CONCURRENTLY IF NOT EXISTS changesets_agent_push_pending_batch_change
    ON changesets (tenant_id, owned_by_batch_change_id)
    WHERE agent_push_pending;
