-- Rename tables (IF EXISTS handles idempotency)
ALTER TABLE IF EXISTS evergreen_deep_search RENAME TO evergreen_deepsearch;
ALTER TABLE IF EXISTS evergreen_deep_search_versions RENAME TO evergreen_deepsearch_versions;

-- Rename the FK column in versions table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evergreen_deepsearch_versions' AND column_name = 'evergreen_deep_search_id') THEN
        ALTER TABLE evergreen_deepsearch_versions RENAME COLUMN evergreen_deep_search_id TO evergreen_deepsearch_id;
    END IF;
END $$;

-- Rename sequences
ALTER SEQUENCE IF EXISTS evergreen_deep_search_id_seq RENAME TO evergreen_deepsearch_id_seq;
ALTER SEQUENCE IF EXISTS evergreen_deep_search_versions_id_seq RENAME TO evergreen_deepsearch_versions_id_seq;

-- Rename indexes on evergreen_deepsearch
ALTER INDEX IF EXISTS evergreen_deep_search_pkey RENAME TO evergreen_deepsearch_pkey;
ALTER INDEX IF EXISTS evergreen_deep_search_tenant_slug_unique RENAME TO evergreen_deepsearch_tenant_slug_unique;
ALTER INDEX IF EXISTS evergreen_deep_search_source_conversation_id RENAME TO evergreen_deepsearch_source_conversation_id;

-- Drop conversation_id from parent table (denormalized; now accessed via versions table)
DROP INDEX IF EXISTS evergreen_deep_search_conversation_id;
DROP INDEX IF EXISTS evergreen_deepsearch_conversation_id;
ALTER TABLE evergreen_deepsearch DROP CONSTRAINT IF EXISTS evergreen_deep_search_conversation_id_fkey;
ALTER TABLE evergreen_deepsearch DROP CONSTRAINT IF EXISTS evergreen_deepsearch_conversation_id_fkey;
ALTER TABLE evergreen_deepsearch DROP COLUMN IF EXISTS conversation_id;

-- Rename indexes on evergreen_deepsearch_versions
ALTER INDEX IF EXISTS evergreen_deep_search_versions_pkey RENAME TO evergreen_deepsearch_versions_pkey;
ALTER INDEX IF EXISTS evergreen_deep_search_versions_eds_id RENAME TO evergreen_deepsearch_versions_eds_id;

-- Rename FK constraints on evergreen_deepsearch (use DO block for idempotency)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deep_search_source_conversation_id_fkey') THEN
        ALTER TABLE evergreen_deepsearch RENAME CONSTRAINT evergreen_deep_search_source_conversation_id_fkey TO evergreen_deepsearch_source_conversation_id_fkey;
    END IF;
END $$;

-- Rename FK constraints on evergreen_deepsearch_versions
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deep_search_versions_conversation_id_fkey') THEN
        ALTER TABLE evergreen_deepsearch_versions RENAME CONSTRAINT evergreen_deep_search_versions_conversation_id_fkey TO evergreen_deepsearch_versions_conversation_id_fkey;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deep_search_versions_evergreen_deep_search_id_fkey') THEN
        ALTER TABLE evergreen_deepsearch_versions RENAME CONSTRAINT evergreen_deep_search_versions_evergreen_deep_search_id_fkey TO evergreen_deepsearch_versions_evergreen_deepsearch_id_fkey;
    END IF;
END $$;
