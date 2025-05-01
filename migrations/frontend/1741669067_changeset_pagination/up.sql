-- Not generated columns because we parse the external timestamps in Go.
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS external_created_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS external_updated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS is_open BOOLEAN GENERATED ALWAYS AS ((data->>'state')::text = 'open') STORED;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS is_merged BOOLEAN GENERATED ALWAYS AS ((data->>'merged')::boolean) STORED;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS mergeable_state TEXT GENERATED ALWAYS AS ((data->>'mergeable_state')::text) STORED;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS author_external_username TEXT GENERATED ALWAYS AS ((data->'author'->>'external_username')::text) STORED;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS state TEXT GENERATED ALWAYS AS ((data->>'state')::text) STORED;
ALTER TABLE agent_changesets ADD COLUMN IF NOT EXISTS draft BOOLEAN GENERATED ALWAYS AS ((data->>'draft')::boolean) STORED;

CREATE INDEX IF NOT EXISTS idx_agent_changesets_external_created_at ON agent_changesets (external_created_at);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_external_updated_at ON agent_changesets (external_updated_at);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_is_open ON agent_changesets (is_open);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_is_merged ON agent_changesets (is_merged);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_mergeable_state ON agent_changesets (mergeable_state);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_author_external_username ON agent_changesets (author_external_username);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_state ON agent_changesets (state);
CREATE INDEX IF NOT EXISTS idx_agent_changesets_draft ON agent_changesets (draft);
