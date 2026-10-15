ALTER TABLE github_apps DROP CONSTRAINT IF EXISTS github_apps_permissions_is_object;
ALTER TABLE github_apps DROP COLUMN IF EXISTS permissions;
