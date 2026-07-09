-- Rename the `reference` column to `tag`. Idempotent: only rename when the old
-- column still exists and the new one does not yet. The existing unique
-- constraint automatically tracks the renamed column.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'container_registry_manifests' AND column_name = 'reference'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'container_registry_manifests' AND column_name = 'tag'
    ) THEN
        ALTER TABLE container_registry_manifests RENAME COLUMN reference TO tag;
    END IF;
END $$;
