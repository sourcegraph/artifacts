CREATE TABLE IF NOT EXISTS orgs_open_beta_stats (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id integer,
    org_id integer,
    created_at timestamp with time zone DEFAULT now(),
    data jsonb NOT NULL DEFAULT '{}'::jsonb,
    tenant_id integer REFERENCES tenants(id) ON DELETE CASCADE ON UPDATE CASCADE
);
