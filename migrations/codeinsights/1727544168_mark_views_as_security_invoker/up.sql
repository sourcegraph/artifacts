ALTER VIEW insights_jobs_backfill_in_progress SET (security_invoker = TRUE); COMMIT AND CHAIN;

ALTER VIEW insights_jobs_backfill_new SET (security_invoker = TRUE);
