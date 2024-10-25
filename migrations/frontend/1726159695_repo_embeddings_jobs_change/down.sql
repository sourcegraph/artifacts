ALTER TABLE repo_embedding_jobs
    DROP COLUMN IF EXISTS commit_id;

 ALTER TABLE repo_embedding_job_stats
    DROP COLUMN IF EXISTS files_total,
    DROP COLUMN IF EXISTS files_embedded,
    DROP COLUMN IF EXISTS chunks_embedded,
    DROP COLUMN IF EXISTS files_excluded,
    DROP COLUMN IF EXISTS files_skipped,
    DROP COLUMN IF EXISTS bytes_embedded,

    ADD COLUMN IF NOT EXISTS code_files_total INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS code_files_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS code_chunks_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS code_chunks_excluded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS code_files_skipped jsonb NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS code_bytes_embedded bigint NOT NULL DEFAULT 0,

    ADD COLUMN IF NOT EXISTS text_files_total INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS text_files_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS text_chunks_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS text_chunks_excluded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS text_files_skipped jsonb NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS text_bytes_embedded bigint NOT NULL DEFAULT 0;
