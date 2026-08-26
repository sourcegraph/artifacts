ALTER TABLE gitserver_repos
    ADD COLUMN IF NOT EXISTS default_branch_tip_commit_id TEXT,
    ADD COLUMN IF NOT EXISTS default_branch_tip_commit_date TIMESTAMP WITH TIME ZONE,
    DROP CONSTRAINT IF EXISTS gitserver_repos_default_branch_tip_metadata_consistent,
    ADD CONSTRAINT gitserver_repos_default_branch_tip_metadata_consistent
        CHECK (
            (default_branch_tip_commit_id IS NULL) = (default_branch_tip_commit_date IS NULL)
            AND (
                default_branch_tip_commit_id IS NULL
                OR default_branch_tip_commit_id ~ '^[^[:space:]](.*[^[:space:]])?$'
            )
        );

COMMENT ON CONSTRAINT gitserver_repos_default_branch_tip_metadata_consistent ON gitserver_repos IS
    'Requires the default branch tip commit ID and date to both be set or both be null and rejects empty or whitespace-padded commit IDs';
