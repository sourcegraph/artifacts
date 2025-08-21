-- Recreate Cody Pro related database objects

-- Recreate the cody_pro_enabled_at column in users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS cody_pro_enabled_at TIMESTAMP WITH TIME ZONE;

-- Recreate the access tokens lookup index for Cody Pro
CREATE INDEX IF NOT EXISTS access_tokens_lookup_internal ON access_tokens (subject_user_id, internal) INCLUDE (value_sha256) WHERE deleted_at IS NULL;
