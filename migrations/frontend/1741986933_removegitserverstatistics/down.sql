-- Recreate the gitserver_repos_statistics table
CREATE TABLE IF NOT EXISTS public.gitserver_repos_statistics (
    shard_id text,
    total bigint DEFAULT 0 NOT NULL,
    not_cloned bigint DEFAULT 0 NOT NULL,
    cloning bigint DEFAULT 0 NOT NULL,
    cloned bigint DEFAULT 0 NOT NULL,
    failed_fetch bigint DEFAULT 0 NOT NULL,
    corrupted bigint DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);


COMMENT ON COLUMN public.gitserver_repos_statistics.shard_id IS 'ID of this gitserver shard. If an empty string then the repositories havent been assigned a shard.';
COMMENT ON COLUMN public.gitserver_repos_statistics.total IS 'Number of repositories in gitserver_repos table on this shard';
COMMENT ON COLUMN public.gitserver_repos_statistics.not_cloned IS 'Number of repositories in gitserver_repos table on this shard that are not cloned yet';
COMMENT ON COLUMN public.gitserver_repos_statistics.cloning IS 'Number of repositories in gitserver_repos table on this shard that cloning';
COMMENT ON COLUMN public.gitserver_repos_statistics.cloned IS 'Number of repositories in gitserver_repos table on this shard that are cloned';
COMMENT ON COLUMN public.gitserver_repos_statistics.failed_fetch IS 'Number of repositories in gitserver_repos table on this shard where last_error is set';
COMMENT ON COLUMN public.gitserver_repos_statistics.corrupted IS 'Number of repositories that are NOT soft-deleted and not blocked and have corrupted_at set in gitserver_repos table';

CREATE INDEX IF NOT EXISTS gitserver_repos_statistics_shard_id ON public.gitserver_repos_statistics USING btree (shard_id);
ALTER TABLE public.gitserver_repos_statistics ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
   IF NOT EXISTS (
      SELECT 1 FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'gitserver_repos_statistics'
        AND policyname = 'tenant_isolation_policy'
   ) THEN
        CREATE POLICY tenant_isolation_policy ON public.gitserver_repos_statistics USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));
   END IF;
END;
$$;


CREATE OR REPLACE FUNCTION public.recalc_gitserver_repos_statistics_on_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
      INSERT INTO gitserver_repos_statistics AS grs (shard_id, total, not_cloned, cloning, cloned, failed_fetch, corrupted)
      SELECT
        oldtab.shard_id,
        (-COUNT(*)),
        (-COUNT(*) FILTER(WHERE clone_status = 'not_cloned')),
        (-COUNT(*) FILTER(WHERE clone_status = 'cloning')),
        (-COUNT(*) FILTER(WHERE clone_status = 'cloned')),
        (-COUNT(*) FILTER(WHERE last_error IS NOT NULL)),
        (-COUNT(*) FILTER(WHERE corrupted_at IS NOT NULL))
      FROM oldtab
      GROUP BY oldtab.shard_id;

      RETURN NULL;
  END
$$;

CREATE OR REPLACE FUNCTION public.recalc_gitserver_repos_statistics_on_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
      -------------------------------------------------
      -- THIS IS CHANGED TO APPEND
      -------------------------------------------------
      INSERT INTO gitserver_repos_statistics AS grs (shard_id, total, not_cloned, cloning, cloned, failed_fetch, corrupted)
      SELECT
        shard_id,
        COUNT(*) AS total,
        COUNT(*) FILTER(WHERE clone_status = 'not_cloned') AS not_cloned,
        COUNT(*) FILTER(WHERE clone_status = 'cloning') AS cloning,
        COUNT(*) FILTER(WHERE clone_status = 'cloned') AS cloned,
        COUNT(*) FILTER(WHERE last_error IS NOT NULL) AS failed_fetch,
        COUNT(*) FILTER(WHERE corrupted_at IS NOT NULL) AS corrupted
      FROM
        newtab
      GROUP BY shard_id
      ;

      RETURN NULL;
  END
$$;

CREATE OR REPLACE FUNCTION public.recalc_gitserver_repos_statistics_on_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN

      -------------------------------------------------
      -- THIS IS CHANGED TO APPEND
      -------------------------------------------------
      WITH diff(shard_id, total, not_cloned, cloning, cloned, failed_fetch, corrupted) AS (
        SELECT
            COALESCE(newtab.shard_id, oldtab.shard_id) AS shard_id,
            COUNT(newtab.repo_id) - COUNT(oldtab.repo_id) AS total,
            COUNT(newtab.repo_id) FILTER (WHERE newtab.clone_status = 'not_cloned') - COUNT(oldtab.repo_id) FILTER (WHERE oldtab.clone_status = 'not_cloned') AS not_cloned,
            COUNT(newtab.repo_id) FILTER (WHERE newtab.clone_status = 'cloning')    - COUNT(oldtab.repo_id) FILTER (WHERE oldtab.clone_status = 'cloning') AS cloning,
            COUNT(newtab.repo_id) FILTER (WHERE newtab.clone_status = 'cloned')     - COUNT(oldtab.repo_id) FILTER (WHERE oldtab.clone_status = 'cloned') AS cloned,
            COUNT(newtab.repo_id) FILTER (WHERE newtab.last_error IS NOT NULL)      - COUNT(oldtab.repo_id) FILTER (WHERE oldtab.last_error IS NOT NULL) AS failed_fetch,
            COUNT(newtab.repo_id) FILTER (WHERE newtab.corrupted_at IS NOT NULL)    - COUNT(oldtab.repo_id) FILTER (WHERE oldtab.corrupted_at IS NOT NULL) AS corrupted
        FROM
            newtab
        FULL OUTER JOIN
            oldtab ON newtab.repo_id = oldtab.repo_id AND newtab.shard_id = oldtab.shard_id
        GROUP BY
            COALESCE(newtab.shard_id, oldtab.shard_id)
      )
      INSERT INTO gitserver_repos_statistics AS grs (shard_id, total, not_cloned, cloning, cloned, failed_fetch, corrupted)
      SELECT shard_id, total, not_cloned, cloning, cloned, failed_fetch, corrupted
      FROM diff
      WHERE
            total != 0
        OR not_cloned != 0
        OR cloning != 0
        OR cloned != 0
        OR failed_fetch != 0
        OR corrupted != 0
      ;

      -------------------------------------------------
      -- UNCHANGED
      -------------------------------------------------
      WITH diff(not_cloned, cloning, cloned, failed_fetch, corrupted) AS (
        VALUES (
          (
            (SELECT COUNT(*) FROM newtab JOIN repo r ON newtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND newtab.clone_status = 'not_cloned')
            -
            (SELECT COUNT(*) FROM oldtab JOIN repo r ON oldtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND oldtab.clone_status = 'not_cloned')
          ),
          (
            (SELECT COUNT(*) FROM newtab JOIN repo r ON newtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND newtab.clone_status = 'cloning')
            -
            (SELECT COUNT(*) FROM oldtab JOIN repo r ON oldtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND oldtab.clone_status = 'cloning')
          ),
          (
            (SELECT COUNT(*) FROM newtab JOIN repo r ON newtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND newtab.clone_status = 'cloned')
            -
            (SELECT COUNT(*) FROM oldtab JOIN repo r ON oldtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND oldtab.clone_status = 'cloned')
          ),
          (
            (SELECT COUNT(*) FROM newtab JOIN repo r ON newtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND newtab.last_error IS NOT NULL)
            -
            (SELECT COUNT(*) FROM oldtab JOIN repo r ON oldtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND oldtab.last_error IS NOT NULL)
          ),
          (
            (SELECT COUNT(*) FROM newtab JOIN repo r ON newtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND newtab.corrupted_at IS NOT NULL)
            -
            (SELECT COUNT(*) FROM oldtab JOIN repo r ON oldtab.repo_id = r.id WHERE r.deleted_at is NULL AND r.blocked IS NULL AND oldtab.corrupted_at IS NOT NULL)
          )

        )
      )
      INSERT INTO repo_statistics (not_cloned, cloning, cloned, failed_fetch, corrupted)
      SELECT not_cloned, cloning, cloned, failed_fetch, corrupted
      FROM diff
      WHERE
           not_cloned != 0
        OR cloning != 0
        OR cloned != 0
        OR failed_fetch != 0
        OR corrupted != 0
      ;

      RETURN NULL;
  END
$$;

CREATE OR REPLACE TRIGGER trig_recalc_gitserver_repos_statistics_on_delete AFTER DELETE ON gitserver_repos REFERENCING OLD TABLE AS oldtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_gitserver_repos_statistics_on_delete();
CREATE OR REPLACE TRIGGER trig_recalc_gitserver_repos_statistics_on_insert AFTER INSERT ON gitserver_repos REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_gitserver_repos_statistics_on_insert();
CREATE OR REPLACE TRIGGER trig_recalc_gitserver_repos_statistics_on_update AFTER UPDATE ON gitserver_repos REFERENCING OLD TABLE AS oldtab NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_gitserver_repos_statistics_on_update();
