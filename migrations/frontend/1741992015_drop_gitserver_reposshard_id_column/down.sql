ALTER TABLE gitserver_repos ADD COLUMN IF NOT EXISTS shard_id text NOT NULL;

CREATE INDEX IF NOT EXISTS gitserver_repos_shard_id ON gitserver_repos USING btree (shard_id, repo_id);

CREATE OR REPLACE FUNCTION func_insert_gitserver_repo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO gitserver_repos
(repo_id, shard_id)
VALUES (NEW.id, '');
RETURN NULL;
END;
$$;
