ALTER INDEX IF EXISTS batch_change_agent_jobs_dequeue_idx
    RENAME TO batch_change_agent_jobs_dequeue_filter_idx;
ALTER INDEX IF EXISTS batch_change_agent_wake_jobs_dequeue_idx
    RENAME TO batch_change_agent_wake_jobs_dequeue_filter_idx;
ALTER INDEX IF EXISTS changeset_sync_jobs_dequeue_idx
    RENAME TO changeset_sync_jobs_dequeue_filter_idx;

DO $$
BEGIN
    IF TO_REGCLASS('changeset_sync_jobs_dequeue_active_order_idx') IS NOT NULL THEN
        ALTER INDEX changeset_sync_jobs_dequeue_order_idx
            RENAME TO changeset_sync_jobs_dequeue_unfiltered_order_idx;
        ALTER INDEX changeset_sync_jobs_dequeue_active_order_idx
            RENAME TO changeset_sync_jobs_dequeue_order_idx;
    END IF;
END
$$;
