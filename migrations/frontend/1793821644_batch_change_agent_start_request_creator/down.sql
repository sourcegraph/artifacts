-- Recreate this first: if ownership transfers introduced duplicate keys for a
-- current owner, refuse downgrade rather than discard a run or its receipt.
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agents_owner_start_request_id_idx
    ON batch_change_agents (tenant_id, owner_user_id, start_request_id)
    WHERE start_request_id IS NOT NULL;
DROP INDEX IF EXISTS batch_change_agents_creator_start_request_id_idx;
ALTER TABLE batch_change_agents DROP COLUMN IF EXISTS start_request_user_id;
