-- Pin each BCA secret grant to the concrete executor secret the user approved.
-- The FK (with cascade delete) means a grant cannot outlive its secret; the
-- read path additionally checks the pinned row against current name
-- resolution, so a grant cannot silently transfer to a different secret that
-- later takes over the same name. secret_name stays as a display label; the
-- executor secret key is immutable, so the label cannot drift from the pinned
-- row.
--
-- The new column is non-nullable with no default, so existing rows are deleted
-- first: they carry only a name and cannot be mapped back to the secret row
-- the user actually reviewed. The feature is still hidden behind the
-- batch-change-agents-remember-secret-approvals feature flag, and the worst
-- outcome of dropping a row is that the approval gate asks the user again.
-- The destructive step is guarded on the column not existing yet, so the
-- migration stays idempotent.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'batch_change_agent_secret_grants' AND column_name = 'executor_secret_id'
    ) THEN
        DELETE FROM batch_change_agent_secret_grants;
        ALTER TABLE batch_change_agent_secret_grants
            ADD COLUMN executor_secret_id INTEGER NOT NULL
                REFERENCES executor_secrets(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Uniqueness moves from the secret name to the pinned secret ID, so a grant
-- for an old (now masked) secret and a grant for the new secret that took over
-- the same name can coexist. Still split into two partial indexes because
-- agent_id is nullable, and still tenant-prefixed.
DROP INDEX IF EXISTS batch_change_agent_secret_grants_agent_scope_idx;
DROP INDEX IF EXISTS batch_change_agent_secret_grants_user_scope_idx;
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_agent_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, agent_id, executor_secret_id)
    WHERE agent_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS batch_change_agent_secret_grants_user_scope_idx
    ON batch_change_agent_secret_grants (tenant_id, user_id, executor_secret_id)
    WHERE agent_id IS NULL;

-- Lookup path for the ON DELETE CASCADE from executor_secrets.
CREATE INDEX IF NOT EXISTS batch_change_agent_secret_grants_executor_secret_id_idx
    ON batch_change_agent_secret_grants (executor_secret_id);
