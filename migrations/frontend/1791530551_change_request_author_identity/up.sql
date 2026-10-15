-- Preserve author display casing while allowing indexed comparisons under tenant
-- RLS without evaluating non-leakproof lower() on the column at read time.
ALTER TABLE change_requests
    ADD COLUMN IF NOT EXISTS author_external_id TEXT,
    ADD COLUMN IF NOT EXISTS author_email TEXT,
    ADD COLUMN IF NOT EXISTS author_normalized TEXT GENERATED ALWAYS AS (lower(author)) STORED;

COMMENT ON COLUMN change_requests.author_external_id IS 'Author account ID on its code host, populated by the provider sync adapter.';
COMMENT ON COLUMN change_requests.author_email IS 'Lowercase author email reported by the code host, populated by the provider sync adapter.';

-- GitHub is the only existing provider. Future adapters populate the identity
-- columns directly instead of depending on a provider-specific payload shape.
UPDATE change_requests
SET author_external_id = external_data->'user'->>'id',
    author_email = lower(external_data->'user'->>'email')
WHERE external_service_type = 'GITHUB'
    AND author_external_id IS NULL AND author_email IS NULL;

CREATE INDEX IF NOT EXISTS change_requests_author_login_idx
    ON change_requests (tenant_id, external_service_type, code_host_url, author_normalized);
CREATE INDEX IF NOT EXISTS change_requests_author_external_id_idx
    ON change_requests (tenant_id, external_service_type, code_host_url, author_external_id);
CREATE INDEX IF NOT EXISTS change_requests_author_email_idx
    ON change_requests (tenant_id, external_service_type, author_email);
