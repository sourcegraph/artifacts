CREATE OR REPLACE FUNCTION deepsearch_enqueue_question_for_search()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW IS NOT NULL AND NEW.status != 'processing' THEN
        INSERT INTO deepsearch_search_queue (
            question_id,
            tenant_id,
            queued_at,
            process_after,
            latest_question_updated_at
        ) VALUES (
            NEW.id,
            NEW.tenant_id,
            now(),
            NULL,
            now()
        )
        ON CONFLICT (tenant_id, question_id) DO UPDATE SET
            latest_question_updated_at = EXCLUDED.latest_question_updated_at,
            queued_at = EXCLUDED.queued_at,
            process_after = EXCLUDED.process_after,
            state = 'queued',
            started_at = NULL,
            cancel = false;
    END IF;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
