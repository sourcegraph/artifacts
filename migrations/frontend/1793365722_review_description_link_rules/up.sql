CREATE TABLE IF NOT EXISTS review_description_link_rules (
    id SERIAL PRIMARY KEY,
    tenant_id INTEGER NOT NULL DEFAULT current_setting('app.current_tenant')::integer,
    -- Text such as 'SRC-' that starts a reference, followed by its identifier.
    key_prefix TEXT NOT NULL,
    -- The URL a reference links to, with '<num>' replaced by its identifier.
    url_template TEXT NOT NULL,
    -- Whether identifiers may contain letters, not only digits.
    alphanumeric BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT review_description_link_rules_key_prefix_key UNIQUE (tenant_id, key_prefix)
);

ALTER TABLE review_description_link_rules ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON review_description_link_rules;
CREATE POLICY tenant_isolation_policy ON review_description_link_rules AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT current_setting('app.current_tenant')::integer AS current_tenant));
