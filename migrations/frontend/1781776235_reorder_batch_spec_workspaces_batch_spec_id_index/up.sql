CREATE INDEX CONCURRENTLY IF NOT EXISTS batch_spec_workspaces_batch_spec_id_id
    ON batch_spec_workspaces (batch_spec_id, id);
