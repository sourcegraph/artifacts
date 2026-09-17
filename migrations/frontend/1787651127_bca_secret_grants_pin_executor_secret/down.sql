-- Restore the name-based shape. Grants for the same name pinned to different
-- secrets collapse to one row first, so the name-based unique indexes can be
-- rebuilt.
DELETE FROM batch_change_agent_secret_grants a
    USING batch_change_agent_secret_grants b
    WHERE a.id > b.id
      AND a.tenant_id = b.tenant_id
      AND a.user_id = b.user_id
      AND a.agent_id IS NOT DISTINCT FROM b.agent_id
      AND a.secret_name = b.secret_name;

-- Dropping the column also drops the ID-based unique indexes and the cascade
-- lookup index, which include it.
ALTER TABLE batch_change_agent_secret_grants DROP COLUMN IF EXISTS executor_secret_id;

CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_agent_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, agent_id, secret_name)
    WHERE agent_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_user_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, secret_name)
    WHERE agent_id IS NULL;
