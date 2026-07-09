-- Rename the `tag` column back to `reference`. Idempotent: only rename when the
-- `tag` column exists and `reference` does not.
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'container_registry_manifests' AND column_name = 'tag'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'container_registry_manifests' AND column_name = 'reference'
    ) THEN
        ALTER TABLE container_registry_manifests RENAME COLUMN tag TO reference;
    END IF;
END $$;
