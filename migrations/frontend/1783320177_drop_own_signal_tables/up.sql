DROP VIEW IF EXISTS own_background_jobs_config_aware;

DROP TABLE IF EXISTS own_signal_recent_contribution;
DROP TABLE IF EXISTS own_aggregate_recent_contribution;
DROP TABLE IF EXISTS own_aggregate_recent_view;
DROP TABLE IF EXISTS own_background_jobs;
DROP TABLE IF EXISTS own_signal_configurations;

DROP FUNCTION IF EXISTS update_own_aggregate_recent_contribution();
