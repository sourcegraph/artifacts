DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'codeintel_last_reconcile_pkey'
        AND conrelid = 'codeintel_last_reconcile'::regclass
    ) THEN
        ALTER TABLE codeintel_last_reconcile ADD PRIMARY KEY (dump_id);
    END IF;
END;
$$;
