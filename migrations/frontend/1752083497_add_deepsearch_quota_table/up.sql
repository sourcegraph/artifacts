-- Add deepsearch_quota table to track per-user quota counts

-- Create the quota table
CREATE TABLE IF NOT EXISTS deepsearch_quota(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    quota INTEGER NOT NULL DEFAULT 0,
    quota_date DATE DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

-- Index for quota lookups by user_id
CREATE INDEX IF NOT EXISTS deepsearch_quota_user_id_idx ON deepsearch_quota(user_id);

-- Enable tenant isolation
ALTER TABLE deepsearch_quota ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON deepsearch_quota;
CREATE POLICY tenant_isolation_policy ON deepsearch_quota AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
