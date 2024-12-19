ALTER TABLE tenants
    ADD COLUMN IF NOT EXISTS external_url TEXT NOT NULL DEFAULT '' CHECK (LOWER(external_url) = external_url);
