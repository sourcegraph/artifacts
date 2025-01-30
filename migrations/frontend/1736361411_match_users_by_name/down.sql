CREATE OR REPLACE VIEW user_relevant_repos WITH (security_invoker = true) AS
SELECT
    u.id as user_id,
    cd.repo_id as repo_id,
    MAX(cd.last_commit_date) as last_commit_date,
    SUM(cd.number_of_commits) as number_of_commits
FROM users u
    INNER JOIN user_emails ue
        ON u.tenant_id = ue.tenant_id
            AND u.id = ue.user_id
            AND ue.verified_at IS NOT NULL
            AND ue.deleted_at IS NULL
    INNER JOIN contributor_data cd
        ON ue.tenant_id = cd.tenant_id
            AND CAST(ue.email AS BYTEA) = cd.author_email
GROUP BY u.id, repo_id
ORDER BY u.id, last_commit_date DESC;

DROP INDEX IF EXISTS contributor_data_author_name_idx;

COMMENT ON VIEW user_relevant_repos IS $$
An aggregation of repos a user has contributed to.

This is generated from commit data on the default branch of each repo,
and uses email address to link git users to Sourcegraph users.
$$;
