-- Drop Cody Pro related database objects that are no longer needed

-- Drop the access tokens lookup index for Cody Pro
DROP INDEX IF EXISTS access_tokens_lookup_internal;

-- Drop the cody_pro_enabled_at column from users table
ALTER TABLE users DROP COLUMN IF EXISTS cody_pro_enabled_at;
