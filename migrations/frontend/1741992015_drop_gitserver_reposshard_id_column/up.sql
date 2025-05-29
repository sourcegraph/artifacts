CREATE OR REPLACE FUNCTION func_insert_gitserver_repo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO gitserver_repos
(repo_id)
VALUES (NEW.id);
RETURN NULL;
END;
$$;

DROP INDEX IF EXISTS gitserver_repos_shard_id;

ALTER TABLE gitserver_repos DROP COLUMN IF EXISTS shard_id;
