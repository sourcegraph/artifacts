ALTER VIEW insights_jobs_backfill_in_progress RESET (security_invoker); COMMIT AND CHAIN;

ALTER VIEW insights_jobs_backfill_new RESET (security_invoker);
