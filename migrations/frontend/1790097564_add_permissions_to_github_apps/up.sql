-- The permissions granted to the GitHub App, as reported by GitHub's
-- GET /app endpoint: a JSON object mapping permission name to access level,
-- e.g. {"contents": "write", "metadata": "read"}.
--
-- NULL means the permissions have not been fetched yet (for example, apps
-- created before this column existed). An empty object means GitHub reported
-- no permissions.
ALTER TABLE github_apps ADD COLUMN IF NOT EXISTS permissions jsonb;

ALTER TABLE github_apps DROP CONSTRAINT IF EXISTS github_apps_permissions_is_object;
ALTER TABLE github_apps ADD CONSTRAINT github_apps_permissions_is_object
    CHECK (permissions IS NULL OR jsonb_typeof(permissions) = 'object');
