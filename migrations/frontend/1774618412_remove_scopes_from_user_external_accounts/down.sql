ALTER TABLE user_external_accounts ADD COLUMN IF NOT EXISTS scopes text[] NOT NULL DEFAULT '{}'::text[];
