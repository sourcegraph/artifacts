DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_last_reconcile_dump_id_key'
        AND conrelid = 'codeintel_last_reconcile'::regclass
    ) THEN
        ALTER TABLE codeintel_last_reconcile ADD CONSTRAINT codeintel_last_reconcile_dump_id_key UNIQUE (dump_id);
    END IF;
END;
$$;
