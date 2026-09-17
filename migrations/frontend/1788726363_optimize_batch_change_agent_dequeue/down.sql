-- Restore the schema from before the dequeue optimization.
DROP INDEX IF EXISTS batch_change_agent_jobs_dequeue_order_idx;
