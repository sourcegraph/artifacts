-- Create base rules table
CREATE TABLE IF NOT EXISTS agent_rules
(
    id SERIAL PRIMARY KEY,
    data JSONB NOT NULL,
    uri TEXT NOT NULL GENERATED ALWAYS AS (data->>'uri') STORED,
    parent_rule_id INTEGER GENERATED ALWAYS AS ((data->>'parent_rule_id')::integer) STORED REFERENCES agent_rules(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    UNIQUE (tenant_id, uri)
);

-- Create rule revisions table
CREATE TABLE IF NOT EXISTS agent_rule_revisions
(
    id SERIAL PRIMARY KEY,
    rule_id INTEGER NOT NULL GENERATED ALWAYS AS ((data->>'rule_id')::integer) STORED REFERENCES agent_rules(id) ON DELETE CASCADE,
    instruction TEXT NOT NULL GENERATED ALWAYS AS (data->>'instruction') STORED,
    instruction_hash TEXT NOT NULL GENERATED ALWAYS AS (digest(data->>'instruction', 'sha256')) STORED,
    title TEXT GENERATED ALWAYS AS (data->>'title') STORED,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    data JSONB NOT NULL,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    UNIQUE (tenant_id, rule_id, instruction_hash)
);

COMMENT ON COLUMN agent_rule_revisions.instruction_hash IS E''
    'There is a maximum length for a unique index, so we use a hash of the instruction'
    'to enforce uniqueness. This is not a security feature, it is only used to enforce uniqueness';

CREATE INDEX IF NOT EXISTS idx_agent_rule_revisions_rule_id ON agent_rule_revisions (rule_id);



-- Enable RLS on both tables
ALTER TABLE agent_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE agent_rule_revisions ENABLE ROW LEVEL SECURITY;

-- Create tenant isolation policies
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_rules;
CREATE POLICY tenant_isolation_policy ON agent_rules AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

DROP POLICY IF EXISTS tenant_isolation_policy ON agent_rule_revisions;
CREATE POLICY tenant_isolation_policy ON agent_rule_revisions AS PERMISSIVE FOR ALL TO PUBLIC
USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));

-- add rule columns to review_diagnostics table
ALTER TABLE agent_review_diagnostics ADD COLUMN IF NOT EXISTS rule_id INTEGER GENERATED ALWAYS AS ((data->'rule'->>'rule_id')::integer) STORED REFERENCES agent_rules(id) ON DELETE CASCADE;
ALTER TABLE agent_review_diagnostics ADD COLUMN IF NOT EXISTS rule_revision_id INTEGER GENERATED ALWAYS AS ((data->'rule'->>'revision_id')::integer) STORED REFERENCES agent_rule_revisions(id) ON DELETE CASCADE;
ALTER TABLE agent_review_diagnostics ADD COLUMN IF NOT EXISTS rule_uri TEXT GENERATED ALWAYS AS (data->'rule'->>'uri') STORED;
