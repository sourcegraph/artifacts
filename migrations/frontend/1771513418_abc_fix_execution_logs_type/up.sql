-- This migration intentionally drops all task rows because execution_logs changes
-- shape from json to json[] and at this time there's no data to keep.
DELETE FROM abc_executor_tasks;

ALTER TABLE abc_executor_tasks
    ALTER COLUMN execution_logs TYPE json[] USING CASE WHEN execution_logs IS NOT NULL THEN ARRAY[execution_logs] ELSE NULL END;
