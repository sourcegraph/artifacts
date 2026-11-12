DROP INDEX IF EXISTS batch_change_agent_access_grants_active_by_user_idx;

ALTER TABLE batch_change_agent_access_grants
    DROP CONSTRAINT IF EXISTS batch_change_agent_access_grants_provenance_check;
ALTER TABLE batch_change_agent_access_grants
    DROP COLUMN IF EXISTS provenance;

DELETE FROM batch_change_agent_access_grants WHERE relation = 'collaborator';
ALTER TABLE batch_change_agent_access_grants
    DROP CONSTRAINT IF EXISTS batch_change_agent_access_grants_relation_check;
ALTER TABLE batch_change_agent_access_grants
    ADD CONSTRAINT batch_change_agent_access_grants_relation_check
    CHECK (relation IN ('owner', 'viewer'));
