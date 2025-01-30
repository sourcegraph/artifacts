CREATE TABLE IF NOT EXISTS agent_reviews (
    id                 SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB,
    tenant_id          INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);


ALTER TABLE agent_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_reviews;
CREATE POLICY tenant_isolation_policy ON agent_reviews AS PERMISSIVE FOR ALL TO PUBLIC USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE TABLE IF NOT EXISTS agent_review_diagnostics (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB,

    -- Foreign keys
    review_id INTEGER NOT NULL REFERENCES agent_reviews(id) ON DELETE CASCADE,
    tenant_id    INTEGER                  DEFAULT (current_setting('app.current_tenant'::text))::INTEGER NOT NULL
);

ALTER TABLE agent_review_diagnostics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_review_diagnostics;
CREATE POLICY tenant_isolation_policy ON agent_review_diagnostics AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::INTEGER AS current_tenant));

CREATE TABLE IF NOT EXISTS agent_review_diagnostic_feedback (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    data JSONB,
    -- Foreign keys
    diagnostic_id INTEGER NOT NULL REFERENCES agent_review_diagnostics(id) ON DELETE CASCADE,
    tenant_id    INTEGER                  DEFAULT (current_setting('app.current_tenant'::text))::INTEGER NOT NULL
);

ALTER TABLE agent_review_diagnostic_feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON agent_review_diagnostic_feedback;
CREATE POLICY tenant_isolation_policy ON agent_review_diagnostic_feedback AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::INTEGER AS current_tenant));
