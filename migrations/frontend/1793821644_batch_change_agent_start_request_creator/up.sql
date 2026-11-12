-- Ownership can change, but a Start key always belongs to its original caller.
ALTER TABLE batch_change_agents
    ADD COLUMN IF NOT EXISTS start_request_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;
COMMENT ON COLUMN batch_change_agents.start_request_user_id IS 'Original creator of a keyed Start. Ownership transfers do not change this request namespace.';

-- The first owner grant also represents creation for historical imports. Do not
-- substitute a later owner when the original creator has been deleted.
UPDATE batch_change_agents AS a
SET start_request_user_id = (
    SELECT g.user_id
    FROM batch_change_agent_access_grants AS g
    WHERE g.tenant_id = a.tenant_id AND g.agent_id = a.id AND g.relation = 'owner'
    ORDER BY g.created_at, g.id
    LIMIT 1
)
WHERE a.start_request_id IS NOT NULL AND a.start_request_user_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agents_creator_start_request_id_idx
    ON batch_change_agents (tenant_id, start_request_user_id, start_request_id)
    WHERE start_request_id IS NOT NULL;
DROP INDEX IF EXISTS batch_change_agents_owner_start_request_id_idx;
