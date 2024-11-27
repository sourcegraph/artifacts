ALTER TABLE github_apps
    DROP CONSTRAINT IF EXISTS github_apps_unique;

ALTER TABLE github_apps
    ADD CONSTRAINT github_apps_unique
        UNIQUE (app_id, client_id, slug, base_url, tenant_id);
