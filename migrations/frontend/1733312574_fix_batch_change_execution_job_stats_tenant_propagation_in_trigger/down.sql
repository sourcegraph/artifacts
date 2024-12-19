CREATE OR REPLACE FUNCTION batch_spec_workspace_execution_last_dequeues_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    INSERT INTO
        batch_spec_workspace_execution_last_dequeues
    SELECT
        user_id,
        MAX(started_at) as latest_dequeue
    FROM
        newtab
    GROUP BY
        user_id
    ON CONFLICT (user_id) DO UPDATE SET
        latest_dequeue = GREATEST(batch_spec_workspace_execution_last_dequeues.latest_dequeue, EXCLUDED.latest_dequeue);

    RETURN NULL;
END $$;
