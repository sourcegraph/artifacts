TRUNCATE TABLE repo_embedding_jobs CASCADE;

ALTER TABLE repo_embedding_jobs
    ADD COLUMN IF NOT EXISTS commit_id TEXT NOT NULL;

ALTER TABLE repo_embedding_job_stats
    DROP COLUMN IF EXISTS code_files_total,
    DROP COLUMN IF EXISTS code_files_embedded,
    DROP COLUMN IF EXISTS code_chunks_embedded,
    DROP COLUMN IF EXISTS code_chunks_excluded,
    DROP COLUMN IF EXISTS code_files_skipped,
    DROP COLUMN IF EXISTS code_bytes_embedded,

    DROP COLUMN IF EXISTS text_files_total,
    DROP COLUMN IF EXISTS text_files_embedded,
    DROP COLUMN IF EXISTS text_chunks_embedded,
    DROP COLUMN IF EXISTS text_chunks_excluded,
    DROP COLUMN IF EXISTS text_files_skipped,
    DROP COLUMN IF EXISTS text_bytes_embedded,

    ADD COLUMN IF NOT EXISTS files_total INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS files_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS chunks_embedded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS files_excluded INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS files_skipped jsonb NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS bytes_embedded bigint NOT NULL DEFAULT 0;
