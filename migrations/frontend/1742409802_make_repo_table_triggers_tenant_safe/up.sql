CREATE OR REPLACE FUNCTION recalc_repo_statistics_on_repo_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
      INSERT INTO repo_statistics (tenant_id, total, soft_deleted, not_cloned, cloning, cloned, failed_fetch)
      SELECT
        oldtab.tenant_id,
        -COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL),
        -COUNT(*) FILTER (WHERE deleted_at IS NOT NULL AND blocked IS NULL),
        -COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'not_cloned'),
        -COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloning'),
        -COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloned'),
        -COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.last_error IS NOT NULL)
      FROM oldtab
      LEFT JOIN gitserver_repos gr ON gr.repo_id = oldtab.id
      GROUP BY oldtab.tenant_id;
      RETURN NULL;
  END
$$;

CREATE OR REPLACE FUNCTION recalc_repo_statistics_on_repo_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
      INSERT INTO repo_statistics (tenant_id, total, soft_deleted, not_cloned)
      SELECT
        newtab.tenant_id,
        COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL),
        COUNT(*) FILTER (WHERE deleted_at IS NOT NULL AND blocked IS NULL),
        -- New repositories are always not_cloned by default, so we can count them as not cloned here
        COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL)
        -- New repositories never have last_error set, so we can also ignore those here
      FROM newtab
      GROUP BY newtab.tenant_id;
      RETURN NULL;
  END
$$;

CREATE OR REPLACE FUNCTION recalc_repo_statistics_on_repo_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
      -- Calculate aggregated stats by tenant_id
      WITH old_counts AS (
        SELECT
          oldtab.tenant_id,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL) AS total,
          COUNT(*) FILTER (WHERE deleted_at IS NOT NULL AND blocked IS NULL) AS soft_deleted,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'not_cloned') AS not_cloned,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloning') AS cloning,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloned') AS cloned,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.last_error IS NOT NULL) AS failed_fetch,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.corrupted_at IS NOT NULL) AS corrupted
        FROM oldtab
        LEFT JOIN gitserver_repos gr ON gr.repo_id = oldtab.id
        GROUP BY oldtab.tenant_id
      ),
      new_counts AS (
        SELECT
          newtab.tenant_id,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL) AS total,
          COUNT(*) FILTER (WHERE deleted_at IS NOT NULL AND blocked IS NULL) AS soft_deleted,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'not_cloned') AS not_cloned,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloning') AS cloning,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.clone_status = 'cloned') AS cloned,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.last_error IS NOT NULL) AS failed_fetch,
          COUNT(*) FILTER (WHERE deleted_at IS NULL AND blocked IS NULL AND gr.corrupted_at IS NOT NULL) AS corrupted
        FROM newtab
        LEFT JOIN gitserver_repos gr ON gr.repo_id = newtab.id
        GROUP BY newtab.tenant_id
      ),
      -- Combine both tenant sets to handle all affected tenants
      all_tenants AS (
        SELECT tenant_id FROM old_counts
        UNION
        SELECT tenant_id FROM new_counts
      ),
      -- Join counts and calculate diffs
      diff_counts AS (
        SELECT
          at.tenant_id,
          COALESCE(nc.total, 0) - COALESCE(oc.total, 0) AS total,
          COALESCE(nc.soft_deleted, 0) - COALESCE(oc.soft_deleted, 0) AS soft_deleted,
          COALESCE(nc.not_cloned, 0) - COALESCE(oc.not_cloned, 0) AS not_cloned,
          COALESCE(nc.cloning, 0) - COALESCE(oc.cloning, 0) AS cloning,
          COALESCE(nc.cloned, 0) - COALESCE(oc.cloned, 0) AS cloned,
          COALESCE(nc.failed_fetch, 0) - COALESCE(oc.failed_fetch, 0) AS failed_fetch,
          COALESCE(nc.corrupted, 0) - COALESCE(oc.corrupted, 0) AS corrupted
        FROM all_tenants at
        LEFT JOIN old_counts oc ON at.tenant_id = oc.tenant_id
        LEFT JOIN new_counts nc ON at.tenant_id = nc.tenant_id
      )
      -- Insert diffs where at least one value changed
      INSERT INTO repo_statistics (tenant_id, total, soft_deleted, not_cloned, cloning, cloned, failed_fetch, corrupted)
      SELECT
        tenant_id, total, soft_deleted, not_cloned, cloning, cloned, failed_fetch, corrupted
      FROM diff_counts
      WHERE
           total != 0
        OR soft_deleted != 0
        OR not_cloned != 0
        OR cloning != 0
        OR cloned != 0
        OR failed_fetch != 0
        OR corrupted != 0;
      RETURN NULL;
  END
$$;
