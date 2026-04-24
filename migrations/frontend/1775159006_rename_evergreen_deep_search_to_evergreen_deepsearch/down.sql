-- Rename FK constraints on versions table back
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deepsearch_versions_conversation_id_fkey') THEN
        EXECUTE 'ALTER TABLE evergreen_deepsearch_versions RENAME CONSTRAINT evergreen_deepsearch_versions_conversation_id_fkey TO evergreen_deep_search_versions_conversation_id_fkey';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deepsearch_versions_evergreen_deepsearch_id_fkey') THEN
        EXECUTE 'ALTER TABLE evergreen_deepsearch_versions RENAME CONSTRAINT evergreen_deepsearch_versions_evergreen_deepsearch_id_fkey TO evergreen_deep_search_versions_evergreen_deep_search_id_fkey';
    END IF;
END $$;

-- Rename FK constraints on parent table back
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deepsearch_source_conversation_id_fkey') THEN
        EXECUTE 'ALTER TABLE evergreen_deepsearch RENAME CONSTRAINT evergreen_deepsearch_source_conversation_id_fkey TO evergreen_deep_search_source_conversation_id_fkey';
    END IF;
END $$;

-- Rename indexes on versions table back
ALTER INDEX IF EXISTS evergreen_deepsearch_versions_pkey RENAME TO evergreen_deep_search_versions_pkey;
ALTER INDEX IF EXISTS evergreen_deepsearch_versions_eds_id RENAME TO evergreen_deep_search_versions_eds_id;

-- Add back conversation_id column to parent table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'evergreen_deepsearch') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evergreen_deepsearch' AND column_name = 'conversation_id') THEN
            ALTER TABLE evergreen_deepsearch ADD COLUMN conversation_id INTEGER;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deep_search_conversation_id_fkey') THEN
            ALTER TABLE evergreen_deepsearch ADD CONSTRAINT evergreen_deep_search_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES deepsearch_conversations(id) ON DELETE SET NULL;
        END IF;
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'evergreen_deep_search') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evergreen_deep_search' AND column_name = 'conversation_id') THEN
            ALTER TABLE evergreen_deep_search ADD COLUMN conversation_id INTEGER;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'evergreen_deep_search_conversation_id_fkey') THEN
            ALTER TABLE evergreen_deep_search ADD CONSTRAINT evergreen_deep_search_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES deepsearch_conversations(id) ON DELETE SET NULL;
        END IF;
    END IF;
END $$;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'evergreen_deepsearch') THEN
        CREATE INDEX IF NOT EXISTS evergreen_deep_search_conversation_id ON evergreen_deepsearch (conversation_id);
    ELSIF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'evergreen_deep_search') THEN
        CREATE INDEX IF NOT EXISTS evergreen_deep_search_conversation_id ON evergreen_deep_search (conversation_id);
    END IF;
END $$;

-- Rename indexes on parent table back
ALTER INDEX IF EXISTS evergreen_deepsearch_pkey RENAME TO evergreen_deep_search_pkey;
ALTER INDEX IF EXISTS evergreen_deepsearch_tenant_slug_unique RENAME TO evergreen_deep_search_tenant_slug_unique;
ALTER INDEX IF EXISTS evergreen_deepsearch_source_conversation_id RENAME TO evergreen_deep_search_source_conversation_id;

-- Rename sequences back
ALTER SEQUENCE IF EXISTS evergreen_deepsearch_id_seq RENAME TO evergreen_deep_search_id_seq;
ALTER SEQUENCE IF EXISTS evergreen_deepsearch_versions_id_seq RENAME TO evergreen_deep_search_versions_id_seq;

-- Rename the FK column back
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'evergreen_deepsearch_versions' AND column_name = 'evergreen_deepsearch_id') THEN
        ALTER TABLE evergreen_deepsearch_versions RENAME COLUMN evergreen_deepsearch_id TO evergreen_deep_search_id;
    END IF;
END $$;

-- Rename tables back
ALTER TABLE IF EXISTS evergreen_deepsearch RENAME TO evergreen_deep_search;
ALTER TABLE IF EXISTS evergreen_deepsearch_versions RENAME TO evergreen_deep_search_versions;
