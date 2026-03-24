-- Add column to store the last 5 characters of the token for identification purposes
ALTER TABLE access_tokens ADD COLUMN IF NOT EXISTS token_last_chars TEXT;

COMMENT ON COLUMN access_tokens.token_last_chars IS 'Last 5 characters of the token, stored at creation time to help users identify which token they have configured.';
