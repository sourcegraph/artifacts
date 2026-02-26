-- Add a hash column for efficient comparison of redacted_contents
ALTER TABLE critical_and_site_config
ADD COLUMN IF NOT EXISTS redacted_contents_hash bytea
GENERATED ALWAYS AS (digest(redacted_contents, 'sha256')) STORED;
