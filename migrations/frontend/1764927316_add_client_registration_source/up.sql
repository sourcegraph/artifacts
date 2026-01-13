-- Create enum for client registration source
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'client_registration_source') THEN
        CREATE TYPE client_registration_source AS ENUM (
            'manual',      -- Created manually by admin
            'dcr',         -- Created via RFC 7591 Dynamic Client Registration
            'predefined'   -- Well-known clients (Cody, CLI, etc.)
        );
    END IF;
END
$$;

-- Add registration_source column with default 'manual' for existing clients
ALTER TABLE idp_clients
    ADD COLUMN IF NOT EXISTS registration_source client_registration_source NOT NULL DEFAULT 'manual';

-- Update existing DCR clients to have correct registration_source
-- DCR clients have deterministic IDs starting with 'sgo_cid_dcr_'
UPDATE idp_clients
SET registration_source = 'dcr'
WHERE opaque_id LIKE 'sgo_cid_dcr_%' AND registration_source = 'manual';

-- Update existing predefined clients to have correct registration_source
UPDATE idp_clients
SET registration_source = 'predefined'
WHERE opaque_id IN (
    'sgo_cid_codyvscode',
    'sgo_cid_codyjetbrains',
    'sgo_cid_codyvisualstudio',
    'sgo_cid_sourcegraphraycast',
    'sgo_cid_sourcegraph-cli'
) AND registration_source = 'manual';
