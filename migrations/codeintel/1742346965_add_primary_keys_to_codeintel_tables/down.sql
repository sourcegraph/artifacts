DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_last_reconcile_pkey'
        AND conrelid = 'codeintel_last_reconcile'::regclass
    ) THEN
        ALTER TABLE codeintel_last_reconcile DROP CONSTRAINT codeintel_last_reconcile_pkey;
    END IF;
END;
$$;
