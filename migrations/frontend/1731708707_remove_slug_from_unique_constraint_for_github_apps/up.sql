DROP INDEX IF EXISTS github_apps_app_id_slug_base_url_unique;

ALTER TABLE github_apps
    DROP CONSTRAINT IF EXISTS github_apps_unique;

-- Delete duplicate rows keeping only the most recent ones
DELETE FROM github_apps a
    USING github_apps b
    WHERE a.app_id = b.app_id
      AND a.client_id = b.client_id
      AND a.base_url = b.base_url
      AND a.tenant_id = b.tenant_id
      AND a.id < b.id;

ALTER TABLE github_apps
    ADD CONSTRAINT github_apps_unique
        UNIQUE (app_id, client_id, base_url, tenant_id);
