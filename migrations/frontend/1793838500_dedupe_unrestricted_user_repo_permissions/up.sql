-- A repository is unrestricted when it has a user_repo_permissions row without a
-- user. The unique constraint treats NULLs as distinct, so every call that marks
-- a repository unrestricted added another such row. Keep one row per repository
-- so that a unique index on unrestricted rows can be built.
DELETE FROM user_repo_permissions
WHERE id IN (
    SELECT id
    FROM (
        SELECT
            id,
            row_number() OVER (PARTITION BY tenant_id, repo_id ORDER BY id) AS rank
        FROM user_repo_permissions
        WHERE user_id IS NULL
    ) AS ranked
    WHERE rank > 1
);
