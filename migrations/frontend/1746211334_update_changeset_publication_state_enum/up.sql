DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'PUSHED_ONLY' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'batch_changes_changeset_ui_publication_state')) THEN
        ALTER TYPE batch_changes_changeset_ui_publication_state ADD VALUE 'PUSHED_ONLY';
    END IF;
END
$$;