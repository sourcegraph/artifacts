ALTER TABLE agent_rules ADD COLUMN IF NOT EXISTS state TEXT GENERATED ALWAYS AS ((data->>'state')::TEXT) STORED;
ALTER TABLE agent_rules DROP CONSTRAINT IF EXISTS agent_rules_state_enum;
ALTER TABLE agent_rules ADD CONSTRAINT agent_rules_state_enum CHECK (state IN ('deleted'));

CREATE INDEX IF NOT EXISTS idx_agent_rules_state ON agent_rules (state);
