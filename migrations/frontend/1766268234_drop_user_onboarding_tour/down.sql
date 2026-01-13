CREATE TABLE IF NOT EXISTS user_onboarding_tour (
    id SERIAL PRIMARY KEY,
    raw_json text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

ALTER TABLE user_onboarding_tour DROP CONSTRAINT IF EXISTS user_onboarding_tour_users_fk;
ALTER TABLE user_onboarding_tour ADD CONSTRAINT user_onboarding_tour_users_fk FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE user_onboarding_tour ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON user_onboarding_tour;
CREATE POLICY tenant_isolation_policy ON user_onboarding_tour USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
