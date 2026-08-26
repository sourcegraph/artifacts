-- Add diff_tour_quota table to track per-user quota counts

CREATE TABLE IF NOT EXISTS diff_tour_quota(
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    quota INTEGER NOT NULL DEFAULT 0,
    quota_date DATE DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    tenant_id integer NOT NULL DEFAULT current_setting('app.current_tenant')::integer
);

CREATE INDEX IF NOT EXISTS diff_tour_quota_user_id_idx ON diff_tour_quota(user_id);

ALTER TABLE diff_tour_quota ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON diff_tour_quota;
CREATE POLICY tenant_isolation_policy ON diff_tour_quota AS PERMISSIVE FOR ALL TO PUBLIC USING (tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
