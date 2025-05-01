ALTER TABLE agent_rules ADD COLUMN IF NOT EXISTS impact TEXT GENERATED ALWAYS AS (data->>'impact') STORED;
ALTER TABLE agent_rules DROP CONSTRAINT IF EXISTS check_impact;
ALTER TABLE agent_rules ADD CONSTRAINT check_impact CHECK (impact IN ('low', 'medium', 'high'));
CREATE INDEX IF NOT EXISTS idx_agent_rules_impact ON agent_rules (impact);
