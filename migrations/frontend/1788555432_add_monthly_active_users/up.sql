-- monthly_active_users is the instance-local ledger of which user accounts were
-- active in a given calendar month (UTC). A row is written the first time a user
-- makes an authenticated request in a month, and never removed for that month.
--
-- user_id intentionally has no foreign key to users(id): a user that was active
-- in a month still counts for that month even after being hard-deleted.
CREATE TABLE IF NOT EXISTS monthly_active_users (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       INTEGER NOT NULL DEFAULT (current_setting('app.current_tenant'::text))::integer,
    user_id         INTEGER NOT NULL,
    -- First day of the UTC calendar month this row covers.
    month           DATE NOT NULL,
    first_active_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT monthly_active_users_tenant_month_user_key UNIQUE (tenant_id, month, user_id)
);

ALTER TABLE monthly_active_users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tenant_isolation_policy ON monthly_active_users;
CREATE POLICY tenant_isolation_policy ON monthly_active_users AS PERMISSIVE FOR ALL TO PUBLIC
    USING (tenant_id = (SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant));
