-- Remove duplicates keeping newest
DELETE FROM external_service_sync_jobs a
WHERE EXISTS (
  SELECT 1 FROM external_service_sync_jobs b
  WHERE a.id = b.id
  AND a.ctid < b.ctid
);

-- Add primary key if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'external_service_sync_jobs'
    AND constraint_type = 'PRIMARY KEY'
  ) THEN
    ALTER TABLE external_service_sync_jobs ADD PRIMARY KEY (id);
  END IF;
END $$;
