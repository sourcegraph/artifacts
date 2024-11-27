CREATE UNIQUE INDEX IF NOT EXISTS github_apps_app_id_slug_base_url_unique ON github_apps USING btree (app_id, slug, base_url, tenant_id);

ALTER TABLE github_apps
    DROP CONSTRAINT IF EXISTS github_apps_unique;

ALTER TABLE github_apps
    ADD CONSTRAINT github_apps_unique
        UNIQUE (app_id, client_id, slug, base_url, tenant_id);
