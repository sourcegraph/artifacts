DROP TABLE IF EXISTS context_detection_embedding_jobs;
DROP TABLE IF EXISTS repo_embedding_job_stats;
DROP TABLE IF EXISTS repo_embedding_jobs;

-- Drop view before removing column it depends on
DROP VIEW IF EXISTS codeintel_configuration_policies;

ALTER TABLE lsif_configuration_policies 
    DROP COLUMN IF EXISTS embeddings_enabled;

-- Recreate view without embeddings_enabled column
CREATE VIEW codeintel_configuration_policies WITH (security_invoker = TRUE) AS
SELECT id,
       repository_id,
       name,
       type,
       pattern,
       retention_enabled,
       retention_duration_hours,
       retain_intermediate_commits,
       indexing_enabled,
       index_commit_max_age_hours,
       index_intermediate_commits,
       protected,
       repository_patterns,
       last_resolved_at
FROM lsif_configuration_policies;
