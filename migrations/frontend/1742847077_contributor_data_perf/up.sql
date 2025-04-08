ALTER TABLE contributor_data DROP CONSTRAINT IF EXISTS contributor_data_pkey;
ALTER TABLE contributor_data ADD PRIMARY KEY (author_email, author_name, repo_id);

DROP INDEX IF EXISTS contributor_data_author_name_idx;
CREATE INDEX IF NOT EXISTS contributor_data_author_name_idx ON contributor_data (author_name);

CREATE OR REPLACE VIEW user_relevant_repos WITH (security_invoker = true) AS
SELECT
    u.id as user_id,
    cd.repo_id as repo_id,
    MAX(cd.last_commit_date) as last_commit_date,
    SUM(cd.number_of_commits) as number_of_commits
FROM users u
    INNER JOIN user_emails ue ON
        u.id = ue.user_id AND
        ue.verified_at IS NOT NULL AND
        ue.deleted_at IS NULL
    INNER JOIN contributor_data cd ON (
        CAST(ue.email AS BYTEA) = cd.author_email OR
        CAST(u.display_name AS BYTEA) = cd.author_name
    )
GROUP BY u.id, repo_id
ORDER BY u.id, last_commit_date DESC;
