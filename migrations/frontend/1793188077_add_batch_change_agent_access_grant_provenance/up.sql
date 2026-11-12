-- Access RFC terms: user_id = subject, relation = capability,
-- granted_by_user_id + provenance = provenance, expires_at and revoked_at as is.
-- The bearer stays read_token and the instance rule stays visibility.

ALTER TABLE batch_change_agent_access_grants
    DROP CONSTRAINT IF EXISTS batch_change_agent_access_grants_relation_check;
ALTER TABLE batch_change_agent_access_grants
    ADD CONSTRAINT batch_change_agent_access_grants_relation_check
    CHECK (relation IN ('owner', 'viewer', 'collaborator'));

ALTER TABLE batch_change_agent_access_grants
    ADD COLUMN IF NOT EXISTS provenance TEXT;

-- Backfill: the first owner grant is 'creation', every other grant is 'handover'.
UPDATE batch_change_agent_access_grants g
SET provenance = CASE
    WHEN g.relation = 'owner' AND NOT EXISTS (
        SELECT 1 FROM batch_change_agent_access_grants earlier
        WHERE earlier.agent_id = g.agent_id
          AND earlier.relation = 'owner'
          AND (earlier.created_at, earlier.id) < (g.created_at, g.id)
    ) THEN 'creation'
    ELSE 'handover'
END
WHERE g.provenance IS NULL;

ALTER TABLE batch_change_agent_access_grants
    ALTER COLUMN provenance SET NOT NULL;

ALTER TABLE batch_change_agent_access_grants
    DROP CONSTRAINT IF EXISTS batch_change_agent_access_grants_provenance_check;
ALTER TABLE batch_change_agent_access_grants
    ADD CONSTRAINT batch_change_agent_access_grants_provenance_check
    CHECK (provenance IN ('creation', 'handover', 'invite'));

CREATE INDEX IF NOT EXISTS batch_change_agent_access_grants_active_by_user_idx
    ON batch_change_agent_access_grants (tenant_id, user_id)
    WHERE revoked_at IS NULL;
