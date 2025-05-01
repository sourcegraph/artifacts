CREATE INDEX IF NOT EXISTS access_tokens_lookup_internal ON access_tokens (subject_user_id, internal) INCLUDE (value_sha256) WHERE deleted_at IS NULL;

-- This index only existed on dotcom (and is what we are replacing), but
-- convenient to drop here.
DROP INDEX IF EXISTS dotcom_only_copy_pro_access_token_lookup_idx;
