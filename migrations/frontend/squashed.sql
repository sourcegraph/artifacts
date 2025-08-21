CREATE EXTENSION IF NOT EXISTS citext;

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';

CREATE EXTENSION IF NOT EXISTS hstore;

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';

CREATE EXTENSION IF NOT EXISTS intarray;

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';

CREATE EXTENSION IF NOT EXISTS pg_trgm;

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';

CREATE EXTENSION IF NOT EXISTS pgcrypto;

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';

CREATE TYPE audit_log_operation AS ENUM (
    'create',
    'modify',
    'delete'
);

CREATE TYPE batch_changes_changeset_ui_publication_state AS ENUM (
    'UNPUBLISHED',
    'DRAFT',
    'PUBLISHED',
    'PUSHED_ONLY'
);

CREATE TYPE cm_email_priority AS ENUM (
    'NORMAL',
    'CRITICAL'
);

CREATE TYPE configuration_policies_transition_columns AS (
	name text,
	type text,
	pattern text,
	retention_enabled boolean,
	retention_duration_hours integer,
	retain_intermediate_commits boolean,
	indexing_enabled boolean,
	index_commit_max_age_hours integer,
	index_intermediate_commits boolean,
	protected boolean,
	repository_patterns text[]
);

COMMENT ON TYPE configuration_policies_transition_columns IS 'A type containing the columns that make-up the set of tracked transition columns. Primarily used to create a nulled record due to `OLD` being unset in INSERT queries, and creating a nulled record with a subquery is not allowed.';

CREATE TYPE critical_or_site AS ENUM (
    'critical',
    'site'
);

CREATE TYPE deepsearch_question_status AS ENUM (
    'processing',
    'completed',
    'cancelled'
);

CREATE TYPE entitlement_type AS ENUM (
    'completion_credits'
);

CREATE TYPE feature_flag_type AS ENUM (
    'bool',
    'rollout'
);

CREATE TYPE github_app_kind AS ENUM (
    'COMMIT_SIGNING',
    'REPO_SYNC',
    'USER_CREDENTIAL',
    'SITE_CREDENTIAL',
    'AGENTS_REVIEW'
);

CREATE TYPE lsif_uploads_transition_columns AS (
	state text,
	expired boolean,
	num_resets integer,
	num_failures integer,
	worker_hostname text,
	committed_at timestamp with time zone
);

COMMENT ON TYPE lsif_uploads_transition_columns IS 'A type containing the columns that make-up the set of tracked transition columns. Primarily used to create a nulled record due to `OLD` being unset in INSERT queries, and creating a nulled record with a subquery is not allowed.';

CREATE TYPE pattern_type AS ENUM (
    'keyword',
    'literal',
    'regexp',
    'standard',
    'structural'
);

CREATE TYPE persistmode AS ENUM (
    'record',
    'snapshot'
);

CREATE TYPE syntactic_scip_indexing_jobs_transition_columns AS (
	commit text,
	state text,
	num_resets integer,
	num_failures integer,
	worker_hostname text,
	failure_message text
);

COMMENT ON TYPE syntactic_scip_indexing_jobs_transition_columns IS 'A type containing the columns that make-up the set of tracked transition columns. Primarily used to create a nulled record due to `OLD` being unset in INSERT queries, and creating a nulled record with a subquery is not allowed.';

CREATE TYPE tenant_state AS ENUM (
    'active',
    'suspended',
    'dormant',
    'deleted'
);

CREATE FUNCTION batch_spec_workspace_execution_last_dequeues_upsert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    INSERT INTO
        batch_spec_workspace_execution_last_dequeues
    SELECT
        user_id,
        MAX(started_at) as latest_dequeue,
        tenant_id AS tenant_id
    FROM
        newtab
    GROUP BY
        user_id, tenant_id
    ON CONFLICT (user_id) DO UPDATE SET
        latest_dequeue = GREATEST(batch_spec_workspace_execution_last_dequeues.latest_dequeue, EXCLUDED.latest_dequeue);

    RETURN NULL;
END $$;

CREATE FUNCTION changesets_computed_state_ensure() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN

    NEW.computed_state = CASE
        WHEN NEW.reconciler_state = 'errored' THEN 'RETRYING'
        WHEN NEW.reconciler_state = 'failed' THEN 'FAILED'
        WHEN NEW.reconciler_state = 'scheduled' THEN 'SCHEDULED'
        WHEN NEW.reconciler_state != 'completed' THEN 'PROCESSING'
        WHEN NEW.ui_publication_state = 'PUSHED_ONLY' THEN 'PUSHED_ONLY'
        WHEN NEW.publication_state = 'UNPUBLISHED' THEN 'UNPUBLISHED'
        ELSE NEW.external_state
    END AS computed_state;

    RETURN NEW;
END $$;

CREATE FUNCTION check_user_entitlement_grant_type() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if user already has an entitlement of this type
    IF EXISTS (
        SELECT 1
        FROM entitlement_grants eg
        JOIN entitlements e1 ON eg.entitlement_id = e1.id
        JOIN entitlements e2 ON NEW.entitlement_id = e2.id
        WHERE eg.user_id = NEW.user_id
          AND e1.type = e2.type
          AND eg.entitlement_id <> NEW.entitlement_id
        FOR UPDATE
    ) THEN
        RAISE EXCEPTION 'User already has an entitlement of this type';
    END IF;

    RETURN NEW;
END;
$$;

CREATE FUNCTION delete_batch_change_reference_on_changesets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE
          changesets
        SET
          batch_change_ids = changesets.batch_change_ids - OLD.id::text
        WHERE
          changesets.batch_change_ids ? OLD.id::text;

        RETURN OLD;
    END;
$$;

CREATE FUNCTION delete_repo_ref_on_external_service_repos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- if a repo is soft-deleted, delete every row that references that repo
        IF (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL) THEN
        DELETE FROM
            external_service_repos
        WHERE
            repo_id = OLD.id;
        END IF;

        RETURN OLD;
    END;
$$;

CREATE FUNCTION delete_user_repo_permissions_on_external_account_soft_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    	DELETE FROM user_repo_permissions WHERE user_id = OLD.user_id AND user_external_account_id = OLD.id;
    END IF;
    RETURN NULL;
  END
$$;

CREATE FUNCTION delete_user_repo_permissions_on_repo_soft_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    	DELETE FROM user_repo_permissions WHERE repo_id = NEW.id;
    END IF;
    RETURN NULL;
  END
$$;

CREATE FUNCTION delete_user_repo_permissions_on_user_soft_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
    IF NEW.deleted_at IS NOT NULL AND OLD.deleted_at IS NULL THEN
    	DELETE FROM user_repo_permissions WHERE user_id = OLD.id;
    END IF;
    RETURN NULL;
  END
$$;

CREATE FUNCTION extract_topics_from_metadata(external_service_type text, metadata jsonb) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
BEGIN
    RETURN CASE external_service_type
    WHEN 'github' THEN
        ARRAY(SELECT * FROM jsonb_array_elements_text(jsonb_path_query_array(metadata, '$.RepositoryTopics.Nodes[*].Topic.Name')))
    WHEN 'gitlab' THEN
        ARRAY(SELECT * FROM jsonb_array_elements_text(metadata->'topics'))
    ELSE
        '{}'::text[]
    END;
EXCEPTION WHEN others THEN
    -- Catch exceptions in the case that metadata is not shaped like we expect
    RETURN '{}'::text[];
END;
$_$;

CREATE FUNCTION func_configuration_policies_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE configuration_policies_audit_logs
        SET record_deleted_at = NOW()
        WHERE policy_id IN (
            SELECT id FROM OLD
        );

        RETURN NULL;
    END;
$$;

CREATE FUNCTION func_configuration_policies_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO configuration_policies_audit_logs
        (policy_id, operation, transition_columns)
        VALUES (
            NEW.id, 'create',
            func_configuration_policies_transition_columns_diff(
                (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
                func_row_to_configuration_policies_transition_columns(NEW)
            )
        );
        RETURN NULL;
    END;
$$;

COMMENT ON FUNCTION func_configuration_policies_insert() IS 'Transforms a record from the configuration_policies table into an `configuration_policies_transition_columns` type variable.';

CREATE FUNCTION func_configuration_policies_transition_columns_diff(old configuration_policies_transition_columns, new configuration_policies_transition_columns) RETURNS hstore[]
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- array || NULL should be a noop, but that doesn't seem to be happening
        -- hence array_remove here
        RETURN array_remove(
            ARRAY[]::hstore[] ||
            CASE WHEN old.name IS DISTINCT FROM new.name THEN
                hstore(ARRAY['column', 'name', 'old', old.name, 'new', new.name])
                ELSE NULL
            END ||
            CASE WHEN old.type IS DISTINCT FROM new.type THEN
                hstore(ARRAY['column', 'type', 'old', old.type, 'new', new.type])
                ELSE NULL
            END ||
            CASE WHEN old.pattern IS DISTINCT FROM new.pattern THEN
                hstore(ARRAY['column', 'pattern', 'old', old.pattern, 'new', new.pattern])
                ELSE NULL
            END ||
            CASE WHEN old.retention_enabled IS DISTINCT FROM new.retention_enabled THEN
                hstore(ARRAY['column', 'retention_enabled', 'old', old.retention_enabled::text, 'new', new.retention_enabled::text])
                ELSE NULL
            END ||
            CASE WHEN old.retention_duration_hours IS DISTINCT FROM new.retention_duration_hours THEN
                hstore(ARRAY['column', 'retention_duration_hours', 'old', old.retention_duration_hours::text, 'new', new.retention_duration_hours::text])
                ELSE NULL
            END ||
            CASE WHEN old.indexing_enabled IS DISTINCT FROM new.indexing_enabled THEN
                hstore(ARRAY['column', 'indexing_enabled', 'old', old.indexing_enabled::text, 'new', new.indexing_enabled::text])
                ELSE NULL
            END ||
            CASE WHEN old.index_commit_max_age_hours IS DISTINCT FROM new.index_commit_max_age_hours THEN
                hstore(ARRAY['column', 'index_commit_max_age_hours', 'old', old.index_commit_max_age_hours::text, 'new', new.index_commit_max_age_hours::text])
                ELSE NULL
            END ||
            CASE WHEN old.index_intermediate_commits IS DISTINCT FROM new.index_intermediate_commits THEN
                hstore(ARRAY['column', 'index_intermediate_commits', 'old', old.index_intermediate_commits::text, 'new', new.index_intermediate_commits::text])
                ELSE NULL
            END ||
            CASE WHEN old.protected IS DISTINCT FROM new.protected THEN
                hstore(ARRAY['column', 'protected', 'old', old.protected::text, 'new', new.protected::text])
                ELSE NULL
            END ||
            CASE WHEN old.repository_patterns IS DISTINCT FROM new.repository_patterns THEN
                hstore(ARRAY['column', 'repository_patterns', 'old', old.repository_patterns::text, 'new', new.repository_patterns::text])
                ELSE NULL
            END,
        NULL);
    END;
$$;

COMMENT ON FUNCTION func_configuration_policies_transition_columns_diff(old configuration_policies_transition_columns, new configuration_policies_transition_columns) IS 'Diffs two `configuration_policies_transition_columns` values into an array of hstores, where each hstore is in the format {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

CREATE FUNCTION func_configuration_policies_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        diff hstore[];
    BEGIN
        diff = func_configuration_policies_transition_columns_diff(
            func_row_to_configuration_policies_transition_columns(OLD),
            func_row_to_configuration_policies_transition_columns(NEW)
        );

        IF (array_length(diff, 1) > 0) THEN
            INSERT INTO configuration_policies_audit_logs
            (policy_id, operation, transition_columns)
            VALUES (NEW.id, 'modify', diff);
        END IF;

        RETURN NEW;
    END;
$$;

CREATE FUNCTION func_insert_gitserver_repo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
INSERT INTO gitserver_repos
(repo_id)
VALUES (NEW.id);
RETURN NULL;
END;
$$;

CREATE FUNCTION func_insert_zoekt_repo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO zoekt_repos (repo_id) VALUES (NEW.id);

  RETURN NULL;
END;
$$;

CREATE FUNCTION func_lsif_uploads_transition_columns_diff(old lsif_uploads_transition_columns, new lsif_uploads_transition_columns) RETURNS hstore[]
    LANGUAGE plpgsql
    AS $$
    BEGIN
        -- array || NULL should be a noop, but that doesn't seem to be happening
        -- hence array_remove here
        RETURN array_remove(
            ARRAY[]::hstore[] ||
            CASE WHEN old.state IS DISTINCT FROM new.state THEN
                hstore(ARRAY['column', 'state', 'old', old.state, 'new', new.state])
                ELSE NULL
            END ||
            CASE WHEN old.expired IS DISTINCT FROM new.expired THEN
                hstore(ARRAY['column', 'expired', 'old', old.expired::text, 'new', new.expired::text])
                ELSE NULL
            END ||
            CASE WHEN old.num_resets IS DISTINCT FROM new.num_resets THEN
                hstore(ARRAY['column', 'num_resets', 'old', old.num_resets::text, 'new', new.num_resets::text])
                ELSE NULL
            END ||
            CASE WHEN old.num_failures IS DISTINCT FROM new.num_failures THEN
                hstore(ARRAY['column', 'num_failures', 'old', old.num_failures::text, 'new', new.num_failures::text])
                ELSE NULL
            END ||
            CASE WHEN old.worker_hostname IS DISTINCT FROM new.worker_hostname THEN
                hstore(ARRAY['column', 'worker_hostname', 'old', old.worker_hostname, 'new', new.worker_hostname])
                ELSE NULL
            END ||
            CASE WHEN old.committed_at IS DISTINCT FROM new.committed_at THEN
                hstore(ARRAY['column', 'committed_at', 'old', old.committed_at::text, 'new', new.committed_at::text])
                ELSE NULL
            END,
        NULL);
    END;
$$;

COMMENT ON FUNCTION func_lsif_uploads_transition_columns_diff(old lsif_uploads_transition_columns, new lsif_uploads_transition_columns) IS 'Diffs two `lsif_uploads_transition_columns` values into an array of hstores, where each hstore is in the format {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

CREATE FUNCTION func_package_repo_filters_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = statement_timestamp();
    RETURN NEW;
END $$;

CREATE FUNCTION func_row_to_configuration_policies_transition_columns(rec record) RETURNS configuration_policies_transition_columns
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN (
            rec.name, rec.type, rec.pattern,
            rec.retention_enabled, rec.retention_duration_hours, rec.retain_intermediate_commits,
            rec.indexing_enabled, rec.index_commit_max_age_hours, rec.index_intermediate_commits,
            rec.protected, rec.repository_patterns);
    END;
$$;

CREATE FUNCTION func_row_to_lsif_uploads_transition_columns(rec record) RETURNS lsif_uploads_transition_columns
    LANGUAGE plpgsql
    AS $$
    BEGIN
        RETURN (rec.state, rec.expired, rec.num_resets, rec.num_failures, rec.worker_hostname, rec.committed_at);
    END;
$$;

CREATE FUNCTION func_row_to_syntactic_scip_indexing_jobs_transition_columns(rec record) RETURNS syntactic_scip_indexing_jobs_transition_columns
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (rec.commit, rec.state, rec.num_resets, rec.num_failures, rec.worker_hostname,
            rec.failure_message);
END;
$$;

CREATE FUNCTION func_scip_uploads_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE lsif_uploads_audit_logs
        SET record_deleted_at = NOW()
        WHERE upload_id IN (
            SELECT id FROM OLD
        );

        RETURN NULL;
    END;
$$;

CREATE FUNCTION func_scip_uploads_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        INSERT INTO lsif_uploads_audit_logs
        (upload_id, commit, root, repository_id, uploaded_at,
        indexer, indexer_version, upload_size, associated_index_id,
        content_type, tenant_id,
        operation, transition_columns)
        VALUES (
            NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
            NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
            NEW.content_type, NEW.tenant_id,
            'create', func_lsif_uploads_transition_columns_diff(
                (NULL, NULL, NULL, NULL, NULL, NULL),
                func_row_to_lsif_uploads_transition_columns(NEW)
            )
        );
        RETURN NULL;
    END;
$$;

COMMENT ON FUNCTION func_scip_uploads_insert() IS 'Transforms a record from the lsif_uploads table into an `lsif_uploads_transition_columns` type variable.';

CREATE FUNCTION func_scip_uploads_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    DECLARE
        diff hstore[];
    BEGIN
        diff = func_lsif_uploads_transition_columns_diff(
            func_row_to_lsif_uploads_transition_columns(OLD),
            func_row_to_lsif_uploads_transition_columns(NEW)
        );

        IF (array_length(diff, 1) > 0) THEN
            INSERT INTO lsif_uploads_audit_logs
            (reason, upload_id, commit, root, repository_id, uploaded_at,
            indexer, indexer_version, upload_size, associated_index_id,
            content_type, tenant_id,
            operation, transition_columns)
            VALUES (
                COALESCE(current_setting('codeintel.lsif_uploads_audit.reason', true), ''),
                NEW.id, NEW.commit, NEW.root, NEW.repository_id, NEW.uploaded_at,
                NEW.indexer, NEW.indexer_version, NEW.upload_size, NEW.associated_index_id,
                NEW.content_type, NEW.tenant_id,
                'modify', diff
            );
        END IF;

        RETURN NEW;
    END;
$$;

CREATE FUNCTION func_syntactic_scip_indexing_jobs_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE syntactic_scip_indexing_jobs_audit_logs
    SET record_deleted_at = NOW()
    WHERE job_id IN (SELECT id FROM OLD);

    RETURN NULL;
END;
$$;

CREATE FUNCTION func_syntactic_scip_indexing_jobs_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO syntactic_scip_indexing_jobs_audit_logs
        (job_id, tenant_id, operation, transition_columns)
    VALUES (NEW.id,
            NEW.tenant_id,
            'create',
            func_syntactic_scip_indexing_jobs_transition_columns_diff(
                (NULL, NULL, NULL, NULL, NULL, NULL)::syntactic_scip_indexing_jobs_transition_columns,
                func_row_to_syntactic_scip_indexing_jobs_transition_columns(NEW)
            ));
    RETURN NULL;
END;
$$;

CREATE FUNCTION func_syntactic_scip_indexing_jobs_transition_columns_diff(old syntactic_scip_indexing_jobs_transition_columns, new syntactic_scip_indexing_jobs_transition_columns) RETURNS hstore[]
    LANGUAGE plpgsql
    AS $$
DECLARE
    changes hstore[];
BEGIN
    changes = ARRAY []::hstore[];

    IF old.commit IS DISTINCT FROM new.commit THEN
        -- Here and below, we use this constructor: https://www.postgresql.org/docs/16/hstore.html#HSTORE-OPS-FUNCS
        -- hstore ( text[] ) → hstore
        --     Constructs an hstore from an array, which may be either a key/value array, or a two-dimensional array.
        --     hstore(ARRAY['a','1','b','2']) → "a"=>"1", "b"=>"2"
        --     hstore(ARRAY[['c','3'],['d','4']]) → "c"=>"3", "d"=>"4"
        changes = changes || hstore(ARRAY ['column', 'commit', 'old', old.commit, 'new', new.commit]);
    END IF;

    IF old.failure_message IS DISTINCT FROM new.failure_message THEN
        changes = changes ||
                  hstore(ARRAY ['column', 'failure_message', 'old', old.failure_message, 'new', new.failure_message]);
    END IF;

    IF old.state IS DISTINCT FROM new.state THEN
        changes = changes || hstore(ARRAY ['column', 'state', 'old', old.state, 'new', new.state]);
    END IF;

    IF old.num_resets IS DISTINCT FROM new.num_resets THEN
        changes =
            changes || hstore(ARRAY ['column', 'num_resets', 'old', old.num_resets::text, 'new', new.num_resets::text]);
    END IF;

    IF old.num_failures IS DISTINCT FROM new.num_failures THEN
        changes = changes ||
                  hstore(ARRAY ['column', 'num_failures', 'old', old.num_failures::text, 'new', new.num_failures::text]);
    END IF;

    IF old.worker_hostname IS DISTINCT FROM new.worker_hostname THEN
        changes = changes ||
                  hstore(ARRAY ['column', 'worker_hostname', 'old', old.worker_hostname, 'new', new.worker_hostname]);
    END IF;

    RETURN changes;
END;
$$;

CREATE FUNCTION func_syntactic_scip_indexing_jobs_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    diff hstore[];
BEGIN
    diff = func_syntactic_scip_indexing_jobs_transition_columns_diff(
        func_row_to_syntactic_scip_indexing_jobs_transition_columns(OLD),
        func_row_to_syntactic_scip_indexing_jobs_transition_columns(NEW)
           );

    IF (ARRAY_LENGTH(diff, 1) > 0) THEN
        INSERT INTO syntactic_scip_indexing_jobs_audit_logs
        (job_id,
         reason,
         tenant_id,
         operation,
         transition_columns)
        VALUES (NEW.id,
                   -- By using SET LOCAL in the current transaction, we can make any information available to the trigger
                   -- https://www.postgresql.org/docs/current/sql-set.html
                COALESCE(CURRENT_SETTING('codeintel.syntactic_scip_indexing_jobs_audit.reason', TRUE), ''),
                NEW.tenant_id,
                'modify',
                diff);
    END IF;

    RETURN NEW;
END;
$$;

CREATE FUNCTION invalidate_session_for_userid_on_password_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        IF OLD.passwd != NEW.passwd THEN
            NEW.invalidated_sessions_at = now() + (1 * interval '1 second');
            RETURN NEW;
        END IF;
    RETURN NEW;
    END;
$$;

CREATE FUNCTION merge_audit_log_transitions(internal hstore, arrayhstore hstore[]) RETURNS hstore
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    DECLARE
        trans hstore;
    BEGIN
      FOREACH trans IN ARRAY arrayhstore
      LOOP
          internal := internal || hstore(trans->'column', trans->'new');
      END LOOP;

      RETURN internal;
    END;
$$;

CREATE FUNCTION recalc_gitserver_repos_statistics_on_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN
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

CREATE FUNCTION recalc_repo_statistics_on_repo_delete() RETURNS trigger
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

CREATE FUNCTION recalc_repo_statistics_on_repo_insert() RETURNS trigger
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

CREATE FUNCTION recalc_repo_statistics_on_repo_update() RETURNS trigger
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

CREATE FUNCTION repo_block(reason text, at timestamp with time zone) RETURNS jsonb
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT jsonb_build_object(
    'reason', reason,
    'at', extract(epoch from timezone('utc', at))::bigint
);
$$;

CREATE PROCEDURE set_repo_stars_null_to_zero()
    LANGUAGE plpgsql
    AS $$
DECLARE
  done boolean;
  total integer = 0;
  updated integer = 0;

BEGIN
  SELECT COUNT(*) INTO total FROM repo WHERE stars IS NULL;

  RAISE NOTICE 'repo_stars_null_to_zero: updating % rows', total;

  done := total = 0;

  WHILE NOT done LOOP
    UPDATE repo SET stars = 0
    FROM (
      SELECT id FROM repo
      WHERE stars IS NULL
      LIMIT 10000
      FOR UPDATE SKIP LOCKED
    ) s
    WHERE repo.id = s.id;

    COMMIT;

    SELECT COUNT(*) = 0 INTO done FROM repo WHERE stars IS NULL LIMIT 1;

    updated := updated + 10000;

    RAISE NOTICE 'repo_stars_null_to_zero: updated % of % rows', updated, total;
  END LOOP;
END
$$;

CREATE FUNCTION soft_delete_orphan_repo_by_external_service_repos() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- When an external service is soft or hard-deleted,
    -- performs a clean up to soft-delete orphan repositories.
    UPDATE
        repo
    SET
        name = soft_deleted_repository_name(name),
        deleted_at = transaction_timestamp()
    WHERE
      deleted_at IS NULL
      AND NOT EXISTS (
        SELECT FROM external_service_repos WHERE repo_id = repo.id
      );
END;
$$;

CREATE FUNCTION soft_deleted_repository_name(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF name LIKE 'DELETED-%' THEN
        RETURN name;
    ELSE
        RETURN 'DELETED-' || extract(epoch from transaction_timestamp()) || '-' || name;
    END IF;
END;
$$;

CREATE FUNCTION update_agent_changesets_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE FUNCTION update_agent_runs_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE FUNCTION update_deepsearch_conversation_updated_at_on_question_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE deepsearch_conversations 
    SET updated_at = now() 
    WHERE id = COALESCE(NEW.conversation_id, OLD.conversation_id);
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE FUNCTION update_deepsearch_conversations_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE FUNCTION update_deepsearch_questions_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE FUNCTION update_own_aggregate_recent_contribution() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    WITH RECURSIVE ancestors AS (
        SELECT id, parent_id, 1 AS level
        FROM repo_paths
        WHERE id = NEW.changed_file_path_id
        UNION ALL
        SELECT p.id, p.parent_id, a.level + 1
        FROM repo_paths p
        JOIN ancestors a ON p.id = a.parent_id
    )
    UPDATE own_aggregate_recent_contribution
    SET contributions_count = contributions_count + 1
    WHERE commit_author_id = NEW.commit_author_id AND changed_file_path_id IN (
        SELECT id FROM ancestors
    );

    WITH RECURSIVE ancestors AS (
        SELECT id, parent_id, 1 AS level
        FROM repo_paths
        WHERE id = NEW.changed_file_path_id
        UNION ALL
        SELECT p.id, p.parent_id, a.level + 1
        FROM repo_paths p
        JOIN ancestors a ON p.id = a.parent_id
    )
    INSERT INTO own_aggregate_recent_contribution (commit_author_id, changed_file_path_id, contributions_count)
    SELECT NEW.commit_author_id, id, 1
    FROM ancestors
    WHERE NOT EXISTS (
        SELECT 1 FROM own_aggregate_recent_contribution
        WHERE commit_author_id = NEW.commit_author_id AND changed_file_path_id = ancestors.id
    );

    RETURN NEW;
END;
$$;

CREATE FUNCTION versions_insert_row_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.first_version = NEW.version;
    RETURN NEW;
END $$;

CREATE AGGREGATE snapshot_transition_columns(hstore[]) (
    SFUNC = merge_audit_log_transitions,
    STYPE = hstore,
    INITCOND = ''
);

CREATE TABLE access_requests (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    additional_info text,
    status text NOT NULL,
    decision_by_user_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE access_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE access_requests_id_seq OWNED BY access_requests.id;

CREATE TABLE access_tokens (
    id bigint NOT NULL,
    subject_user_id integer NOT NULL,
    value_sha256 bytea NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone,
    deleted_at timestamp with time zone,
    creator_user_id integer NOT NULL,
    scopes text[] NOT NULL,
    internal boolean DEFAULT false,
    expires_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE access_tokens_id_seq OWNED BY access_tokens.id;

CREATE TABLE aggregated_user_statistics (
    user_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_last_active_at timestamp with time zone,
    user_events_count bigint,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE assigned_owners (
    id integer NOT NULL,
    owner_user_id integer NOT NULL,
    file_path_id integer NOT NULL,
    who_assigned_user_id integer,
    assigned_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE assigned_owners IS 'Table for ownership assignments, one entry contains an assigned user ID, which repo_path is assigned and the date and user who assigned the owner.';

CREATE SEQUENCE assigned_owners_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE assigned_owners_id_seq OWNED BY assigned_owners.id;

CREATE TABLE assigned_teams (
    id integer NOT NULL,
    owner_team_id integer NOT NULL,
    file_path_id integer NOT NULL,
    who_assigned_team_id integer,
    assigned_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE assigned_teams IS 'Table for team ownership assignments, one entry contains an assigned team ID, which repo_path is assigned and the date and user who assigned the owner team.';

CREATE SEQUENCE assigned_teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE assigned_teams_id_seq OWNED BY assigned_teams.id;

CREATE TABLE batch_changes (
    id bigint NOT NULL,
    name text NOT NULL,
    description text,
    creator_id integer,
    namespace_user_id integer,
    namespace_org_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    closed_at timestamp with time zone,
    batch_spec_id bigint NOT NULL,
    last_applier_id bigint,
    last_applied_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT batch_change_name_is_valid CHECK ((name ~ '^[\w.-]+$'::text)),
    CONSTRAINT batch_changes_has_1_namespace CHECK (((namespace_user_id IS NULL) <> (namespace_org_id IS NULL))),
    CONSTRAINT batch_changes_name_not_blank CHECK ((name <> ''::text))
);

CREATE SEQUENCE batch_changes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_changes_id_seq OWNED BY batch_changes.id;

CREATE TABLE batch_changes_site_credentials (
    id bigint NOT NULL,
    external_service_type text NOT NULL,
    external_service_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    credential bytea NOT NULL,
    encryption_key_id text DEFAULT ''::text NOT NULL,
    github_app_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT check_github_app_id_and_external_service_type_site_credentials CHECK (((github_app_id IS NULL) OR (external_service_type = 'github'::text)))
);

CREATE SEQUENCE batch_changes_site_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_changes_site_credentials_id_seq OWNED BY batch_changes_site_credentials.id;

CREATE TABLE batch_spec_execution_cache_entries (
    id bigint NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    version integer NOT NULL,
    last_used_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE batch_spec_execution_cache_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_execution_cache_entries_id_seq OWNED BY batch_spec_execution_cache_entries.id;

CREATE TABLE batch_spec_library_records (
    id bigint NOT NULL,
    name text NOT NULL,
    spec text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_by_user_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    labels text[] DEFAULT '{}'::text[]
);

COMMENT ON COLUMN batch_spec_library_records.labels IS 'Array of labels associated with this batch spec, such as "featured". Used for filtering and categorization.';

CREATE SEQUENCE batch_spec_library_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_library_records_id_seq OWNED BY batch_spec_library_records.id;

CREATE TABLE batch_spec_library_variables (
    id bigint NOT NULL,
    batch_spec_library_record_id bigint NOT NULL,
    name text NOT NULL,
    regex_rule text NOT NULL,
    placeholder text,
    description text,
    level text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    mandatory boolean DEFAULT false NOT NULL,
    display_name text,
    CONSTRAINT batch_spec_library_variables_level_check CHECK ((level = ANY (ARRAY['error'::text, 'warn'::text, 'info'::text])))
);

CREATE SEQUENCE batch_spec_library_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_library_variables_id_seq OWNED BY batch_spec_library_variables.id;

CREATE TABLE batch_spec_resolution_jobs (
    id bigint NOT NULL,
    batch_spec_id integer NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    initiator_id integer NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE batch_spec_resolution_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_resolution_jobs_id_seq OWNED BY batch_spec_resolution_jobs.id;

CREATE TABLE batch_spec_workspace_execution_jobs (
    id bigint NOT NULL,
    batch_spec_workspace_id integer NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    user_id integer NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE batch_spec_workspace_execution_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_workspace_execution_jobs_id_seq OWNED BY batch_spec_workspace_execution_jobs.id;

CREATE TABLE batch_spec_workspace_execution_last_dequeues (
    user_id integer NOT NULL,
    latest_dequeue timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE VIEW batch_spec_workspace_execution_queue WITH (security_invoker='true') AS
 WITH queue_candidates AS (
         SELECT exec.id,
            rank() OVER (PARTITION BY queue.user_id ORDER BY exec.created_at, exec.id) AS place_in_user_queue
           FROM (batch_spec_workspace_execution_jobs exec
             JOIN batch_spec_workspace_execution_last_dequeues queue ON ((queue.user_id = exec.user_id)))
          WHERE (exec.state = 'queued'::text)
          ORDER BY (rank() OVER (PARTITION BY queue.user_id ORDER BY exec.created_at, exec.id)), queue.latest_dequeue NULLS FIRST
        )
 SELECT id,
    row_number() OVER () AS place_in_global_queue,
    place_in_user_queue
   FROM queue_candidates;

CREATE VIEW batch_spec_workspace_execution_jobs_with_rank WITH (security_invoker='true') AS
 SELECT j.id,
    j.batch_spec_workspace_id,
    j.state,
    j.failure_message,
    j.started_at,
    j.finished_at,
    j.process_after,
    j.num_resets,
    j.num_failures,
    j.execution_logs,
    j.worker_hostname,
    j.last_heartbeat_at,
    j.created_at,
    j.updated_at,
    j.cancel,
    j.queued_at,
    j.user_id,
    j.version,
    q.place_in_global_queue,
    q.place_in_user_queue,
    j.tenant_id
   FROM (batch_spec_workspace_execution_jobs j
     LEFT JOIN batch_spec_workspace_execution_queue q ON ((j.id = q.id)));

CREATE TABLE batch_spec_workspace_files (
    id integer NOT NULL,
    rand_id text NOT NULL,
    batch_spec_id bigint NOT NULL,
    filename text NOT NULL,
    path text NOT NULL,
    size bigint NOT NULL,
    content bytea NOT NULL,
    modified_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE batch_spec_workspace_files_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_workspace_files_id_seq OWNED BY batch_spec_workspace_files.id;

CREATE TABLE batch_spec_workspaces (
    id bigint NOT NULL,
    batch_spec_id integer NOT NULL,
    changeset_spec_ids jsonb DEFAULT '{}'::jsonb NOT NULL,
    repo_id integer NOT NULL,
    branch text NOT NULL,
    commit text NOT NULL,
    path text NOT NULL,
    file_matches text[] NOT NULL,
    only_fetch_workspace boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    ignored boolean DEFAULT false NOT NULL,
    unsupported boolean DEFAULT false NOT NULL,
    skipped boolean DEFAULT false NOT NULL,
    cached_result_found boolean DEFAULT false NOT NULL,
    step_cache_results jsonb DEFAULT '{}'::jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE batch_spec_workspaces_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_spec_workspaces_id_seq OWNED BY batch_spec_workspaces.id;

CREATE TABLE batch_specs (
    id bigint NOT NULL,
    rand_id text NOT NULL,
    raw_spec text NOT NULL,
    spec jsonb DEFAULT '{}'::jsonb NOT NULL,
    namespace_user_id integer,
    namespace_org_id integer,
    user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_from_raw boolean DEFAULT false NOT NULL,
    allow_unsupported boolean DEFAULT false NOT NULL,
    allow_ignored boolean DEFAULT false NOT NULL,
    no_cache boolean DEFAULT false NOT NULL,
    batch_change_id bigint,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT batch_specs_has_1_namespace CHECK (((namespace_user_id IS NULL) <> (namespace_org_id IS NULL)))
);

CREATE SEQUENCE batch_specs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE batch_specs_id_seq OWNED BY batch_specs.id;

CREATE TABLE changeset_specs (
    id bigint NOT NULL,
    rand_id text NOT NULL,
    spec jsonb DEFAULT '{}'::jsonb,
    batch_spec_id bigint,
    repo_id integer NOT NULL,
    user_id integer,
    diff_stat_added integer,
    diff_stat_deleted integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    head_ref text,
    title text,
    external_id text,
    fork_namespace citext,
    diff bytea,
    base_rev text,
    base_ref text,
    body text,
    published text,
    commit_message text,
    commit_author_name text,
    commit_author_email text,
    type text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT changeset_specs_published_valid_values CHECK (((published = 'true'::text) OR (published = 'false'::text) OR (published = '"draft"'::text) OR (published = '"push-only"'::text) OR (published IS NULL)))
);

CREATE TABLE changesets (
    id bigint NOT NULL,
    batch_change_ids jsonb DEFAULT '{}'::jsonb NOT NULL,
    repo_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb,
    external_id text,
    external_service_type text NOT NULL,
    external_deleted_at timestamp with time zone,
    external_branch text,
    external_updated_at timestamp with time zone,
    external_state text,
    external_review_state text,
    external_check_state text,
    diff_stat_added integer,
    diff_stat_deleted integer,
    sync_state jsonb DEFAULT '{}'::jsonb NOT NULL,
    current_spec_id bigint,
    previous_spec_id bigint,
    publication_state text DEFAULT 'UNPUBLISHED'::text,
    owned_by_batch_change_id bigint,
    reconciler_state text DEFAULT 'queued'::text,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    closing boolean DEFAULT false NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    log_contents text,
    execution_logs json[],
    syncer_error text,
    external_title text,
    worker_hostname text DEFAULT ''::text NOT NULL,
    ui_publication_state batch_changes_changeset_ui_publication_state,
    last_heartbeat_at timestamp with time zone,
    external_fork_namespace citext,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    detached_at timestamp with time zone,
    computed_state text NOT NULL,
    external_fork_name citext,
    previous_failure_message text,
    commit_verification jsonb DEFAULT '{}'::jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    auto_merge_method text,
    CONSTRAINT changesets_batch_change_ids_check CHECK ((jsonb_typeof(batch_change_ids) = 'object'::text)),
    CONSTRAINT changesets_external_id_check CHECK ((external_id <> ''::text)),
    CONSTRAINT changesets_external_service_type_not_blank CHECK ((external_service_type <> ''::text)),
    CONSTRAINT changesets_metadata_check CHECK ((jsonb_typeof(metadata) = 'object'::text)),
    CONSTRAINT external_branch_ref_prefix CHECK ((external_branch ~~ 'refs/heads/%'::text))
);

COMMENT ON COLUMN changesets.external_title IS 'Normalized property generated on save using Changeset.Title()';

CREATE TABLE repo (
    id integer NOT NULL,
    name citext NOT NULL,
    description text,
    fork boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone,
    external_id text,
    external_service_type text,
    external_service_id text,
    archived boolean DEFAULT false NOT NULL,
    uri citext,
    deleted_at timestamp with time zone,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    private boolean DEFAULT false NOT NULL,
    stars integer DEFAULT 0 NOT NULL,
    blocked jsonb,
    topics text[] GENERATED ALWAYS AS (extract_topics_from_metadata(external_service_type, metadata)) STORED,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    name_lower text GENERATED ALWAYS AS ((lower((name)::text) COLLATE "C")) STORED,
    CONSTRAINT check_name_nonempty CHECK ((name OPERATOR(<>) ''::citext)),
    CONSTRAINT repo_metadata_check CHECK ((jsonb_typeof(metadata) = 'object'::text))
);

CREATE VIEW branch_changeset_specs_and_changesets WITH (security_invoker='true') AS
 SELECT changeset_specs.id AS changeset_spec_id,
    COALESCE(changesets.id, (0)::bigint) AS changeset_id,
    changeset_specs.repo_id,
    changeset_specs.batch_spec_id,
    changesets.owned_by_batch_change_id AS owner_batch_change_id,
    repo.name AS repo_name,
    changeset_specs.title AS changeset_name,
    changesets.external_state,
    changesets.publication_state,
    changesets.reconciler_state,
    changesets.computed_state
   FROM ((changeset_specs
     LEFT JOIN changesets ON (((changesets.repo_id = changeset_specs.repo_id) AND (changesets.current_spec_id IS NOT NULL) AND (EXISTS ( SELECT 1
           FROM changeset_specs changeset_specs_1
          WHERE ((changeset_specs_1.id = changesets.current_spec_id) AND (changeset_specs_1.head_ref = changeset_specs.head_ref)))))))
     JOIN repo ON ((changeset_specs.repo_id = repo.id)))
  WHERE ((changeset_specs.external_id IS NULL) AND (repo.deleted_at IS NULL));

CREATE TABLE cached_available_indexers (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    num_events integer NOT NULL,
    available_indexers jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE cached_available_indexers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cached_available_indexers_id_seq OWNED BY cached_available_indexers.id;

CREATE TABLE changeset_events (
    id bigint NOT NULL,
    changeset_id bigint NOT NULL,
    kind text NOT NULL,
    key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT changeset_events_key_check CHECK ((key <> ''::text)),
    CONSTRAINT changeset_events_kind_check CHECK ((kind <> ''::text)),
    CONSTRAINT changeset_events_metadata_check CHECK ((jsonb_typeof(metadata) = 'object'::text))
);

CREATE SEQUENCE changeset_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE changeset_events_id_seq OWNED BY changeset_events.id;

CREATE TABLE changeset_jobs (
    id bigint NOT NULL,
    bulk_group text NOT NULL,
    user_id integer NOT NULL,
    batch_change_id integer NOT NULL,
    changeset_id integer NOT NULL,
    job_type text NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT changeset_jobs_payload_check CHECK ((jsonb_typeof(payload) = 'object'::text))
);

CREATE SEQUENCE changeset_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE changeset_jobs_id_seq OWNED BY changeset_jobs.id;

CREATE SEQUENCE changeset_specs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE changeset_specs_id_seq OWNED BY changeset_specs.id;

CREATE TABLE changeset_sync_jobs (
    id bigint NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    changeset_id integer NOT NULL,
    priority integer DEFAULT 100 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE changeset_sync_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE changeset_sync_jobs_id_seq OWNED BY changeset_sync_jobs.id;

CREATE SEQUENCE changesets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE changesets_id_seq OWNED BY changesets.id;

CREATE TABLE cm_action_jobs (
    id integer NOT NULL,
    email bigint,
    state text DEFAULT 'queued'::text,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    log_contents text,
    trigger_event integer,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    webhook bigint,
    slack_webhook bigint,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT cm_action_jobs_only_one_action_type CHECK ((((
CASE
    WHEN (email IS NULL) THEN 0
    ELSE 1
END +
CASE
    WHEN (webhook IS NULL) THEN 0
    ELSE 1
END) +
CASE
    WHEN (slack_webhook IS NULL) THEN 0
    ELSE 1
END) = 1))
);

COMMENT ON COLUMN cm_action_jobs.email IS 'The ID of the cm_emails action to execute if this is an email job. Mutually exclusive with webhook and slack_webhook';

COMMENT ON COLUMN cm_action_jobs.webhook IS 'The ID of the cm_webhooks action to execute if this is a webhook job. Mutually exclusive with email and slack_webhook';

COMMENT ON COLUMN cm_action_jobs.slack_webhook IS 'The ID of the cm_slack_webhook action to execute if this is a slack webhook job. Mutually exclusive with email and webhook';

COMMENT ON CONSTRAINT cm_action_jobs_only_one_action_type ON cm_action_jobs IS 'Constrains that each queued code monitor action has exactly one action type';

CREATE SEQUENCE cm_action_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_action_jobs_id_seq OWNED BY cm_action_jobs.id;

CREATE TABLE cm_emails (
    id bigint NOT NULL,
    monitor bigint NOT NULL,
    enabled boolean NOT NULL,
    priority cm_email_priority NOT NULL,
    header text NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by integer NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    include_results boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE cm_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_emails_id_seq OWNED BY cm_emails.id;

CREATE TABLE cm_last_searched (
    monitor_id bigint NOT NULL,
    commit_oids text[] NOT NULL,
    repo_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE cm_last_searched IS 'The last searched commit hashes for the given code monitor and unique set of search arguments';

COMMENT ON COLUMN cm_last_searched.commit_oids IS 'The set of commit OIDs that was previously successfully searched and should be excluded on the next run';

CREATE TABLE cm_monitors (
    id bigint NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    description text NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by integer NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    namespace_user_id integer NOT NULL,
    namespace_org_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN cm_monitors.namespace_org_id IS 'DEPRECATED: code monitors cannot be owned by an org';

CREATE SEQUENCE cm_monitors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_monitors_id_seq OWNED BY cm_monitors.id;

CREATE TABLE cm_queries (
    id bigint NOT NULL,
    monitor bigint NOT NULL,
    query text NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by integer NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    next_run timestamp with time zone DEFAULT now(),
    latest_result timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE cm_queries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_queries_id_seq OWNED BY cm_queries.id;

CREATE TABLE cm_recipients (
    id bigint NOT NULL,
    email bigint NOT NULL,
    namespace_user_id integer,
    namespace_org_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE cm_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_recipients_id_seq OWNED BY cm_recipients.id;

CREATE TABLE cm_slack_webhooks (
    id bigint NOT NULL,
    monitor bigint NOT NULL,
    url text NOT NULL,
    enabled boolean NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by integer NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    include_results boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE cm_slack_webhooks IS 'Slack webhook actions configured on code monitors';

COMMENT ON COLUMN cm_slack_webhooks.monitor IS 'The code monitor that the action is defined on';

COMMENT ON COLUMN cm_slack_webhooks.url IS 'The Slack webhook URL we send the code monitor event to';

CREATE SEQUENCE cm_slack_webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_slack_webhooks_id_seq OWNED BY cm_slack_webhooks.id;

CREATE TABLE cm_trigger_jobs (
    id integer NOT NULL,
    query bigint NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    log_contents text,
    query_string text,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    search_results jsonb,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    logs json[],
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT search_results_is_array CHECK ((jsonb_typeof(search_results) = 'array'::text))
);

CREATE SEQUENCE cm_trigger_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_trigger_jobs_id_seq OWNED BY cm_trigger_jobs.id;

CREATE TABLE cm_webhooks (
    id bigint NOT NULL,
    monitor bigint NOT NULL,
    url text NOT NULL,
    enabled boolean NOT NULL,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    changed_by integer NOT NULL,
    changed_at timestamp with time zone DEFAULT now() NOT NULL,
    include_results boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE cm_webhooks IS 'Webhook actions configured on code monitors';

COMMENT ON COLUMN cm_webhooks.monitor IS 'The code monitor that the action is defined on';

COMMENT ON COLUMN cm_webhooks.url IS 'The webhook URL we send the code monitor event to';

COMMENT ON COLUMN cm_webhooks.enabled IS 'Whether this Slack webhook action is enabled. When not enabled, the action will not be run when its code monitor generates events';

CREATE SEQUENCE cm_webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cm_webhooks_id_seq OWNED BY cm_webhooks.id;

CREATE TABLE code_hosts (
    id integer NOT NULL,
    kind text NOT NULL,
    url text NOT NULL,
    api_rate_limit_quota integer,
    api_rate_limit_interval_seconds integer,
    git_rate_limit_quota integer,
    git_rate_limit_interval_seconds integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE code_hosts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE code_hosts_id_seq OWNED BY code_hosts.id;

CREATE TABLE codeintel_autoindex_queue (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    rev text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    processed_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE codeintel_autoindex_queue_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_autoindex_queue_id_seq OWNED BY codeintel_autoindex_queue.id;

CREATE TABLE codeintel_autoindexing_exceptions (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    disable_scheduling boolean DEFAULT false NOT NULL,
    disable_inference boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE codeintel_autoindexing_exceptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_autoindexing_exceptions_id_seq OWNED BY codeintel_autoindexing_exceptions.id;

CREATE TABLE codeintel_commit_dates (
    repository_id integer NOT NULL,
    commit_bytea bytea NOT NULL,
    committed_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeintel_commit_dates IS 'Maps commits within a repository to the commit date as reported by gitserver.';

COMMENT ON COLUMN codeintel_commit_dates.repository_id IS 'Identifies a row in the `repo` table.';

COMMENT ON COLUMN codeintel_commit_dates.commit_bytea IS 'Identifies the 40-character commit hash.';

COMMENT ON COLUMN codeintel_commit_dates.committed_at IS 'The commit date (may be -infinity if unresolvable).';

CREATE TABLE lsif_configuration_policies (
    id integer NOT NULL,
    repository_id integer,
    name text,
    type text NOT NULL,
    pattern text NOT NULL,
    retention_enabled boolean NOT NULL,
    retention_duration_hours integer,
    retain_intermediate_commits boolean NOT NULL,
    indexing_enabled boolean NOT NULL,
    index_commit_max_age_hours integer,
    index_intermediate_commits boolean NOT NULL,
    protected boolean DEFAULT false NOT NULL,
    repository_patterns text[],
    last_resolved_at timestamp with time zone,
    embeddings_enabled boolean DEFAULT false NOT NULL,
    syntactic_indexing_enabled boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT lsif_configuration_policies_syntactic_head_only_constraint CHECK (((syntactic_indexing_enabled = false) OR ((pattern = 'HEAD'::text) AND (type = 'GIT_COMMIT'::text))))
);

COMMENT ON COLUMN lsif_configuration_policies.repository_id IS 'The identifier of the repository to which this configuration policy applies. If absent, this policy is applied globally.';

COMMENT ON COLUMN lsif_configuration_policies.type IS 'The type of Git object (e.g., COMMIT, BRANCH, TAG).';

COMMENT ON COLUMN lsif_configuration_policies.pattern IS 'A pattern used to match` names of the associated Git object type.';

COMMENT ON COLUMN lsif_configuration_policies.retention_enabled IS 'Whether or not this configuration policy affects data retention rules.';

COMMENT ON COLUMN lsif_configuration_policies.retention_duration_hours IS 'The max age of data retained by this configuration policy. If null, the age is unbounded.';

COMMENT ON COLUMN lsif_configuration_policies.retain_intermediate_commits IS 'If the matching Git object is a branch, setting this value to true will also retain all data used to resolve queries for any commit on the matching branches. Setting this value to false will only consider the tip of the branch.';

COMMENT ON COLUMN lsif_configuration_policies.indexing_enabled IS 'Whether or not this configuration policy affects auto-indexing schedules.';

COMMENT ON COLUMN lsif_configuration_policies.index_commit_max_age_hours IS 'The max age of commits indexed by this configuration policy. If null, the age is unbounded.';

COMMENT ON COLUMN lsif_configuration_policies.index_intermediate_commits IS 'If the matching Git object is a branch, setting this value to true will also index all commits on the matching branches. Setting this value to false will only consider the tip of the branch.';

COMMENT ON COLUMN lsif_configuration_policies.protected IS 'Whether or not this configuration policy is protected from modification of its data retention behavior (except for duration).';

COMMENT ON COLUMN lsif_configuration_policies.repository_patterns IS 'The name pattern matching repositories to which this configuration policy applies. If absent, all repositories are matched.';

CREATE VIEW codeintel_configuration_policies WITH (security_invoker='true') AS
 SELECT id,
    repository_id,
    name,
    type,
    pattern,
    retention_enabled,
    retention_duration_hours,
    retain_intermediate_commits,
    indexing_enabled,
    index_commit_max_age_hours,
    index_intermediate_commits,
    protected,
    repository_patterns,
    last_resolved_at,
    embeddings_enabled
   FROM lsif_configuration_policies;

CREATE TABLE lsif_configuration_policies_repository_pattern_lookup (
    policy_id integer NOT NULL,
    repo_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_configuration_policies_repository_pattern_lookup IS 'A lookup table to get all the repository patterns by repository id that apply to a configuration policy.';

COMMENT ON COLUMN lsif_configuration_policies_repository_pattern_lookup.policy_id IS 'The policy identifier associated with the repository.';

COMMENT ON COLUMN lsif_configuration_policies_repository_pattern_lookup.repo_id IS 'The repository identifier associated with the policy.';

CREATE VIEW codeintel_configuration_policies_repository_pattern_lookup WITH (security_invoker='true') AS
 SELECT policy_id,
    repo_id
   FROM lsif_configuration_policies_repository_pattern_lookup;

CREATE TABLE codeintel_inference_scripts (
    insert_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    script text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON TABLE codeintel_inference_scripts IS 'Contains auto-index job inference Lua scripts as an alternative to setting via environment variables.';

CREATE SEQUENCE codeintel_inference_scripts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_inference_scripts_id_seq OWNED BY codeintel_inference_scripts.id;

CREATE TABLE codeintel_langugage_support_requests (
    id integer NOT NULL,
    user_id integer NOT NULL,
    language_id text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE codeintel_langugage_support_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeintel_langugage_support_requests_id_seq OWNED BY codeintel_langugage_support_requests.id;

CREATE TABLE codeowners (
    id integer NOT NULL,
    contents text NOT NULL,
    contents_proto bytea NOT NULL,
    repo_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE codeowners_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeowners_id_seq OWNED BY codeowners.id;

CREATE TABLE codeowners_individual_stats (
    file_path_id integer NOT NULL,
    owner_id integer NOT NULL,
    tree_owned_files_count integer NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeowners_individual_stats IS 'Data on how many files in given tree are owned by given owner.

As opposed to ownership-general `ownership_path_stats` table, the individual <path x owner> stats
are stored in CODEOWNERS-specific table `codeowners_individual_stats`. The reason for that is that
we are also indexing on owner_id which is CODEOWNERS-specific.';

COMMENT ON COLUMN codeowners_individual_stats.tree_owned_files_count IS 'Total owned file count by given owner at given file tree.';

COMMENT ON COLUMN codeowners_individual_stats.updated_at IS 'When the last background job updating counts run.';

CREATE TABLE codeowners_owners (
    id integer NOT NULL,
    reference text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE codeowners_owners IS 'Text reference in CODEOWNERS entry to use in codeowners_individual_stats. Reference is either email or handle without @ in front.';

COMMENT ON COLUMN codeowners_owners.reference IS 'We just keep the reference as opposed to splitting it to handle or email
since the distinction is not relevant for query, and this makes indexing way easier.';

CREATE SEQUENCE codeowners_owners_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE codeowners_owners_id_seq OWNED BY codeowners_owners.id;

CREATE UNLOGGED TABLE cody_audit_log (
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    protobuf_payload bytea,
    codebase_name text,
    file_name text
);

COMMENT ON COLUMN cody_audit_log.user_id IS 'Identifies the user who originally created this record. This is not a foreign key reference to users(id) to ensure records persist beyond the lifetime of a user account. Do not assume this can be used for JOINs with the users table.';

CREATE UNLOGGED SEQUENCE cody_audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE cody_audit_log_id_seq OWNED BY cody_audit_log.id;

CREATE TABLE commit_authors (
    id integer NOT NULL,
    email text NOT NULL,
    name text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE commit_authors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE commit_authors_id_seq OWNED BY commit_authors.id;

CREATE TABLE completion_credits_consumption (
    id bigint NOT NULL,
    user_id integer NOT NULL,
    credits bigint NOT NULL,
    modelref text NOT NULL,
    feature text NOT NULL,
    interaction_uri text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    tokens jsonb
);

COMMENT ON COLUMN completion_credits_consumption.modelref IS 'The completion modelref that was used';

COMMENT ON COLUMN completion_credits_consumption.feature IS 'The feature that consumed the credits';

COMMENT ON COLUMN completion_credits_consumption.interaction_uri IS 'URI identifying the specific interaction that consumed credits';

CREATE SEQUENCE completion_credits_consumption_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE completion_credits_consumption_id_seq OWNED BY completion_credits_consumption.id;

CREATE TABLE completion_credits_entitlement_window_usage (
    user_id integer NOT NULL,
    entitlement_id integer NOT NULL,
    usage bigint,
    limit_exceeded boolean,
    last_trail_id bigint,
    window_started_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE configuration_policies_audit_logs (
    log_timestamp timestamp with time zone DEFAULT clock_timestamp(),
    record_deleted_at timestamp with time zone,
    policy_id integer NOT NULL,
    transition_columns hstore[],
    sequence bigint NOT NULL,
    operation audit_log_operation NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON COLUMN configuration_policies_audit_logs.log_timestamp IS 'Timestamp for this log entry.';

COMMENT ON COLUMN configuration_policies_audit_logs.record_deleted_at IS 'Set once the upload this entry is associated with is deleted. Once NOW() - record_deleted_at is above a certain threshold, this log entry will be deleted.';

COMMENT ON COLUMN configuration_policies_audit_logs.transition_columns IS 'Array of changes that occurred to the upload for this entry, in the form of {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

CREATE SEQUENCE configuration_policies_audit_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE configuration_policies_audit_logs_id_seq OWNED BY configuration_policies_audit_logs.id;

CREATE SEQUENCE configuration_policies_audit_logs_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE configuration_policies_audit_logs_seq OWNED BY configuration_policies_audit_logs.sequence;

CREATE TABLE context_detection_embedding_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE context_detection_embedding_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE context_detection_embedding_jobs_id_seq OWNED BY context_detection_embedding_jobs.id;

CREATE TABLE contributor_data (
    author_email bytea NOT NULL,
    repo_id integer NOT NULL,
    author_name bytea NOT NULL,
    most_recent_commit_sha text NOT NULL,
    last_commit_date timestamp with time zone NOT NULL,
    number_of_commits integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE contributor_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repo_id integer NOT NULL,
    repo_name text NOT NULL,
    from_commit text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE contributor_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE contributor_jobs_id_seq OWNED BY contributor_jobs.id;

CREATE TABLE contributor_repos (
    repo_id integer NOT NULL,
    last_processed_commit_sha text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    last_processed timestamp with time zone
);

CREATE TABLE critical_and_site_config (
    id integer NOT NULL,
    type critical_or_site NOT NULL,
    contents text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    author_user_id integer,
    redacted_contents text
);

COMMENT ON COLUMN critical_and_site_config.author_user_id IS 'A null value indicates that this config was most likely added by code on the start-up path, for example from the SITE_CONFIG_FILE unless the config itself was added before this column existed in which case it could also have been a user.';

COMMENT ON COLUMN critical_and_site_config.redacted_contents IS 'This column stores the contents but redacts all secrets. The redacted form is a sha256 hash of the secret appended to the REDACTED string. This is used to generate diffs between two subsequent changes in a way that allows us to detect changes to any secrets while also ensuring that we do not leak it in the diff. A null value indicates that this config was added before this column was added or redacting the secrets during write failed so we skipped writing to this column instead of a hard failure.';

CREATE SEQUENCE critical_and_site_config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE critical_and_site_config_id_seq OWNED BY critical_and_site_config.id;

CREATE TABLE deepsearch_conversations (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    edit_token uuid DEFAULT gen_random_uuid(),
    read_token uuid DEFAULT gen_random_uuid(),
    user_id integer,
    data jsonb,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE deepsearch_conversations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE deepsearch_conversations_id_seq OWNED BY deepsearch_conversations.id;

CREATE TABLE deepsearch_questions (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    data jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    status deepsearch_question_status DEFAULT 'processing'::deepsearch_question_status
);

CREATE SEQUENCE deepsearch_questions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE deepsearch_questions_id_seq OWNED BY deepsearch_questions.id;

CREATE TABLE deepsearch_quota (
    id integer NOT NULL,
    user_id integer NOT NULL,
    quota integer DEFAULT 0 NOT NULL,
    quota_date date DEFAULT CURRENT_DATE,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE deepsearch_quota_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE deepsearch_quota_id_seq OWNED BY deepsearch_quota.id;

CREATE TABLE deepsearch_references (
    id integer NOT NULL,
    conversation_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    repo_id integer,
    file_path text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);

COMMENT ON COLUMN deepsearch_references.file_path IS 'File path can be empty because some agent tools only produce repo or commit information but not file content. We use empty string as the sentinel value so that the unique constraint works correctly';

CREATE SEQUENCE deepsearch_references_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE deepsearch_references_id_seq OWNED BY deepsearch_references.id;

CREATE TABLE entitlement_grants (
    entitlement_id integer NOT NULL,
    user_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE entitlements (
    id integer NOT NULL,
    name text NOT NULL,
    type entitlement_type NOT NULL,
    "limit" bigint NOT NULL,
    "window" interval NOT NULL,
    is_default boolean DEFAULT false NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN entitlements.type IS 'The type of entitlement. Currently supports "completion_credits" with more types to be added in the future. Must not be updated after insert.';

CREATE SEQUENCE entitlements_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE entitlements_id_seq OWNED BY entitlements.id;

CREATE TABLE event_logs (
    id bigint NOT NULL,
    name text NOT NULL,
    url text NOT NULL,
    user_id integer NOT NULL,
    anonymous_user_id text NOT NULL,
    source text NOT NULL,
    argument jsonb NOT NULL,
    version text NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    feature_flags jsonb,
    cohort_id date,
    public_argument jsonb DEFAULT '{}'::jsonb NOT NULL,
    first_source_url text,
    last_source_url text,
    referrer text,
    device_id text,
    insert_id text,
    billing_product_category text,
    billing_event_id text,
    client text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT event_logs_check_has_user CHECK ((((user_id = 0) AND (anonymous_user_id <> ''::text)) OR ((user_id <> 0) AND (anonymous_user_id = ''::text)) OR ((user_id <> 0) AND (anonymous_user_id <> ''::text)))),
    CONSTRAINT event_logs_check_name_not_empty CHECK ((name <> ''::text)),
    CONSTRAINT event_logs_check_source_not_empty CHECK ((source <> ''::text)),
    CONSTRAINT event_logs_check_version_not_empty CHECK ((version <> ''::text))
);

CREATE SEQUENCE event_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE event_logs_id_seq OWNED BY event_logs.id;

CREATE TABLE event_logs_scrape_state (
    id integer NOT NULL,
    bookmark_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE event_logs_scrape_state IS 'Contains state for the periodic telemetry job that scrapes events if enabled.';

COMMENT ON COLUMN event_logs_scrape_state.bookmark_id IS 'Bookmarks the maximum most recent successful event_logs.id that was scraped';

CREATE SEQUENCE event_logs_scrape_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE event_logs_scrape_state_id_seq OWNED BY event_logs_scrape_state.id;

CREATE TABLE event_logs_scrape_state_own (
    id integer NOT NULL,
    bookmark_id integer NOT NULL,
    job_type integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE event_logs_scrape_state_own IS 'Contains state for own jobs that scrape events if enabled.';

COMMENT ON COLUMN event_logs_scrape_state_own.bookmark_id IS 'Bookmarks the maximum most recent successful event_logs.id that was scraped';

CREATE SEQUENCE event_logs_scrape_state_own_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE event_logs_scrape_state_own_id_seq OWNED BY event_logs_scrape_state_own.id;

CREATE TABLE executor_heartbeats (
    id integer NOT NULL,
    hostname text NOT NULL,
    queue_name text,
    os text NOT NULL,
    architecture text NOT NULL,
    docker_version text NOT NULL,
    executor_version text NOT NULL,
    git_version text NOT NULL,
    ignite_version text NOT NULL,
    src_cli_version text NOT NULL,
    first_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    queue_names text[],
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT one_of_queue_name_queue_names CHECK ((((queue_name IS NOT NULL) AND (queue_names IS NULL)) OR ((queue_names IS NOT NULL) AND (queue_name IS NULL))))
);

COMMENT ON TABLE executor_heartbeats IS 'Tracks the most recent activity of executors attached to this Sourcegraph instance.';

COMMENT ON COLUMN executor_heartbeats.hostname IS 'The uniquely identifying name of the executor.';

COMMENT ON COLUMN executor_heartbeats.queue_name IS 'The queue name that the executor polls for work.';

COMMENT ON COLUMN executor_heartbeats.os IS 'The operating system running the executor.';

COMMENT ON COLUMN executor_heartbeats.architecture IS 'The machine architure running the executor.';

COMMENT ON COLUMN executor_heartbeats.docker_version IS 'The version of Docker used by the executor.';

COMMENT ON COLUMN executor_heartbeats.executor_version IS 'The version of the executor.';

COMMENT ON COLUMN executor_heartbeats.git_version IS 'The version of Git used by the executor.';

COMMENT ON COLUMN executor_heartbeats.ignite_version IS 'The version of Ignite used by the executor.';

COMMENT ON COLUMN executor_heartbeats.src_cli_version IS 'The version of src-cli used by the executor.';

COMMENT ON COLUMN executor_heartbeats.first_seen_at IS 'The first time a heartbeat from the executor was received.';

COMMENT ON COLUMN executor_heartbeats.last_seen_at IS 'The last time a heartbeat from the executor was received.';

COMMENT ON COLUMN executor_heartbeats.queue_names IS 'The list of queue names that the executor polls for work.';

CREATE SEQUENCE executor_heartbeats_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE executor_heartbeats_id_seq OWNED BY executor_heartbeats.id;

CREATE TABLE executor_job_tokens (
    id integer NOT NULL,
    value_sha256 bytea NOT NULL,
    job_id bigint NOT NULL,
    queue text NOT NULL,
    repo_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE executor_job_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE executor_job_tokens_id_seq OWNED BY executor_job_tokens.id;

CREATE TABLE executor_secret_access_logs (
    id integer NOT NULL,
    executor_secret_id integer NOT NULL,
    user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    machine_user text DEFAULT ''::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT user_id_or_machine_user CHECK ((((user_id IS NULL) AND (machine_user <> ''::text)) OR ((user_id IS NOT NULL) AND (machine_user = ''::text))))
);

CREATE SEQUENCE executor_secret_access_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE executor_secret_access_logs_id_seq OWNED BY executor_secret_access_logs.id;

CREATE TABLE executor_secrets (
    id integer NOT NULL,
    key text NOT NULL,
    value bytea NOT NULL,
    scope text NOT NULL,
    encryption_key_id text,
    namespace_user_id integer,
    namespace_org_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    creator_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN executor_secrets.creator_id IS 'NULL, if the user has been deleted.';

CREATE SEQUENCE executor_secrets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE executor_secrets_id_seq OWNED BY executor_secrets.id;

CREATE TABLE exhaustive_search_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    initiator_id integer NOT NULL,
    query text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    is_aggregated boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    description text,
    CONSTRAINT exhaustive_search_jobs_description_length_check CHECK ((length(description) <= 200))
);

CREATE SEQUENCE exhaustive_search_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE exhaustive_search_jobs_id_seq OWNED BY exhaustive_search_jobs.id;

CREATE TABLE exhaustive_search_repo_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    repo_id integer NOT NULL,
    ref_spec text NOT NULL,
    search_job_id integer NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE exhaustive_search_repo_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE exhaustive_search_repo_jobs_id_seq OWNED BY exhaustive_search_repo_jobs.id;

CREATE TABLE exhaustive_search_repo_revision_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    search_repo_job_id integer NOT NULL,
    revision text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE exhaustive_search_repo_revision_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE exhaustive_search_repo_revision_jobs_id_seq OWNED BY exhaustive_search_repo_revision_jobs.id;

CREATE TABLE explicit_permissions_bitbucket_projects_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    project_key text NOT NULL,
    external_service_id integer NOT NULL,
    permissions json[],
    unrestricted boolean DEFAULT false NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT explicit_permissions_bitbucket_projects_jobs_check CHECK ((((permissions IS NOT NULL) AND (unrestricted IS FALSE)) OR ((permissions IS NULL) AND (unrestricted IS TRUE))))
);

CREATE SEQUENCE explicit_permissions_bitbucket_projects_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE explicit_permissions_bitbucket_projects_jobs_id_seq OWNED BY explicit_permissions_bitbucket_projects_jobs.id;

CREATE TABLE external_service_repos (
    external_service_id bigint NOT NULL,
    repo_id integer NOT NULL,
    clone_url text NOT NULL,
    created_at timestamp with time zone DEFAULT transaction_timestamp() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE external_service_sync_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE external_service_sync_jobs (
    id integer DEFAULT nextval('external_service_sync_jobs_id_seq'::regclass) NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    external_service_id bigint NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    log_contents text,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    repos_synced integer DEFAULT 0 NOT NULL,
    repo_sync_errors integer DEFAULT 0 NOT NULL,
    repos_added integer DEFAULT 0 NOT NULL,
    repos_deleted integer DEFAULT 0 NOT NULL,
    repos_modified integer DEFAULT 0 NOT NULL,
    repos_unmodified integer DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    repos_wanted_to_delete integer DEFAULT 0 NOT NULL
);

COMMENT ON COLUMN external_service_sync_jobs.repos_synced IS 'The number of repos synced during this sync job.';

COMMENT ON COLUMN external_service_sync_jobs.repo_sync_errors IS 'The number of times an error occurred syncing a repo during this sync job.';

COMMENT ON COLUMN external_service_sync_jobs.repos_added IS 'The number of new repos discovered during this sync job.';

COMMENT ON COLUMN external_service_sync_jobs.repos_deleted IS 'The number of repos deleted as a result of this sync job.';

COMMENT ON COLUMN external_service_sync_jobs.repos_modified IS 'The number of existing repos whose metadata has changed during this sync job.';

COMMENT ON COLUMN external_service_sync_jobs.repos_unmodified IS 'The number of existing repos whose metadata did not change during this sync job.';

CREATE TABLE external_services (
    id bigint NOT NULL,
    kind text NOT NULL,
    display_name text NOT NULL,
    config text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    last_sync_at timestamp with time zone,
    next_sync_at timestamp with time zone,
    unrestricted boolean DEFAULT false NOT NULL,
    cloud_default boolean DEFAULT false NOT NULL,
    encryption_key_id text DEFAULT ''::text NOT NULL,
    has_webhooks boolean,
    token_expires_at timestamp with time zone,
    code_host_id integer,
    creator_id integer,
    last_updater_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT check_non_empty_config CHECK ((btrim(config) <> ''::text))
);

CREATE SEQUENCE external_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE external_services_id_seq OWNED BY external_services.id;

CREATE TABLE feature_flag_overrides (
    namespace_org_id integer,
    namespace_user_id integer,
    flag_name text NOT NULL,
    flag_value boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL,
    CONSTRAINT feature_flag_overrides_has_org_or_user_id CHECK (((namespace_org_id IS NOT NULL) OR (namespace_user_id IS NOT NULL)))
);

CREATE SEQUENCE feature_flag_overrides_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE feature_flag_overrides_id_seq OWNED BY feature_flag_overrides.id;

CREATE TABLE feature_flags (
    flag_name text NOT NULL,
    flag_type feature_flag_type NOT NULL,
    bool_value boolean,
    rollout integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT feature_flags_rollout_check CHECK (((rollout >= 0) AND (rollout <= 10000))),
    CONSTRAINT required_bool_fields CHECK ((1 =
CASE
    WHEN ((flag_type = 'bool'::feature_flag_type) AND (bool_value IS NULL)) THEN 0
    WHEN ((flag_type <> 'bool'::feature_flag_type) AND (bool_value IS NOT NULL)) THEN 0
    ELSE 1
END)),
    CONSTRAINT required_rollout_fields CHECK ((1 =
CASE
    WHEN ((flag_type = 'rollout'::feature_flag_type) AND (rollout IS NULL)) THEN 0
    WHEN ((flag_type <> 'rollout'::feature_flag_type) AND (rollout IS NOT NULL)) THEN 0
    ELSE 1
END))
);

COMMENT ON COLUMN feature_flags.bool_value IS 'Bool value only defined when flag_type is bool';

COMMENT ON COLUMN feature_flags.rollout IS 'Rollout only defined when flag_type is rollout. Increments of 0.01%';

COMMENT ON CONSTRAINT required_bool_fields ON feature_flags IS 'Checks that bool_value is set IFF flag_type = bool';

COMMENT ON CONSTRAINT required_rollout_fields ON feature_flags IS 'Checks that rollout is set IFF flag_type = rollout';

CREATE TABLE github_app_installs (
    id integer NOT NULL,
    app_id integer NOT NULL,
    installation_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    url text,
    account_login text,
    account_avatar_url text,
    account_url text,
    account_type text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE github_app_installs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE github_app_installs_id_seq OWNED BY github_app_installs.id;

CREATE TABLE github_apps (
    id integer NOT NULL,
    app_id integer NOT NULL,
    name text NOT NULL,
    slug text NOT NULL,
    base_url text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    private_key text NOT NULL,
    encryption_key_id text NOT NULL,
    logo text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    app_url text DEFAULT ''::text NOT NULL,
    webhook_id integer,
    domain text DEFAULT 'repos'::text NOT NULL,
    kind github_app_kind DEFAULT 'REPO_SYNC'::github_app_kind NOT NULL,
    creator_id bigint DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE github_apps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE github_apps_id_seq OWNED BY github_apps.id;

CREATE TABLE gitserver_relocator_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    queued_at timestamp with time zone DEFAULT now(),
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    repo_id integer NOT NULL,
    source_hostname text NOT NULL,
    dest_hostname text NOT NULL,
    delete_source boolean DEFAULT false NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE gitserver_relocator_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE gitserver_relocator_jobs_id_seq OWNED BY gitserver_relocator_jobs.id;

CREATE VIEW gitserver_relocator_jobs_with_repo_name WITH (security_invoker='true') AS
 SELECT glj.id,
    glj.state,
    glj.queued_at,
    glj.failure_message,
    glj.started_at,
    glj.finished_at,
    glj.process_after,
    glj.num_resets,
    glj.num_failures,
    glj.last_heartbeat_at,
    glj.execution_logs,
    glj.worker_hostname,
    glj.repo_id,
    glj.source_hostname,
    glj.dest_hostname,
    glj.delete_source,
    r.name AS repo_name,
    glj.tenant_id
   FROM (gitserver_relocator_jobs glj
     JOIN repo r ON ((r.id = glj.repo_id)));

CREATE TABLE gitserver_repos (
    repo_id integer NOT NULL,
    clone_status text DEFAULT 'not_cloned'::text NOT NULL,
    last_error text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_fetched timestamp with time zone,
    last_changed timestamp with time zone,
    repo_size_bytes bigint,
    corrupted_at timestamp with time zone,
    corruption_logs jsonb DEFAULT '[]'::jsonb NOT NULL,
    cloning_progress text DEFAULT ''::text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    last_fetch_attempt_at timestamp with time zone,
    failed_fetch_attempts integer DEFAULT 0 NOT NULL,
    last_cleanup_attempt_at timestamp with time zone,
    failed_cleanup_attempts integer DEFAULT 0 NOT NULL,
    last_cleaned_at timestamp with time zone
);

COMMENT ON COLUMN gitserver_repos.corrupted_at IS 'Timestamp of when repo corruption was detected';

COMMENT ON COLUMN gitserver_repos.corruption_logs IS 'Log output of repo corruptions that have been detected - encoded as json';

CREATE TABLE gitserver_repos_sync_output (
    repo_id integer NOT NULL,
    last_output text DEFAULT ''::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE gitserver_repos_sync_output IS 'Contains the most recent output from gitserver repository sync jobs.';

CREATE TABLE global_state (
    site_id uuid NOT NULL,
    initialized boolean DEFAULT false NOT NULL,
    id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE global_state_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE global_state_id_seq OWNED BY global_state.id;

CREATE TABLE idp_authorize_codes (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    client_id text NOT NULL,
    session_id bigint NOT NULL,
    active boolean NOT NULL,
    hashed_code text NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    requested_scopes text[] NOT NULL,
    granted_scopes text[] NOT NULL,
    requested_audience text[] NOT NULL,
    granted_audience text[] NOT NULL,
    request_form jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

CREATE SEQUENCE idp_authorize_codes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_authorize_codes_id_seq OWNED BY idp_authorize_codes.id;

CREATE TABLE idp_clients (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    name text NOT NULL,
    hashed_secret text NOT NULL,
    rotated_hashes jsonb NOT NULL,
    redirect_uris text[] NOT NULL,
    grant_types text[] NOT NULL,
    response_types text[] NOT NULL,
    scopes text[] NOT NULL,
    public boolean NOT NULL,
    audience text[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    description text
);

CREATE SEQUENCE idp_clients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_clients_id_seq OWNED BY idp_clients.id;

CREATE TABLE idp_consent_requests (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    request_id text NOT NULL,
    client_id text NOT NULL,
    user_id bigint NOT NULL,
    requested_scopes text[] NOT NULL,
    requested_audiences text[] NOT NULL,
    redirect_uri text NOT NULL,
    session_id bigint NOT NULL,
    response_types text[] NOT NULL,
    response_mode text NOT NULL,
    state text,
    request_form jsonb NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_consent_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_consent_requests_id_seq OWNED BY idp_consent_requests.id;

CREATE TABLE idp_device_auth_requests (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    client_id text NOT NULL,
    session_id bigint NOT NULL,
    hashed_device_code_signature text NOT NULL,
    hashed_user_code_signature text NOT NULL,
    active boolean DEFAULT true NOT NULL,
    user_code_state smallint DEFAULT 0 NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    requested_scopes text[] NOT NULL,
    granted_scopes text[] NOT NULL,
    requested_audience text[] NOT NULL,
    granted_audience text[] NOT NULL,
    request_form jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_device_auth_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_device_auth_requests_id_seq OWNED BY idp_device_auth_requests.id;

CREATE TABLE idp_id_tokens (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    client_id text NOT NULL,
    session_id bigint NOT NULL,
    hashed_authorize_code text NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    requested_scopes text[] NOT NULL,
    granted_scopes text[] NOT NULL,
    requested_audience text[] NOT NULL,
    granted_audience text[] NOT NULL,
    request_form jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_id_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_id_tokens_id_seq OWNED BY idp_id_tokens.id;

CREATE TABLE idp_oauth_apps (
    id integer NOT NULL,
    client_id text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE idp_oauth_apps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_oauth_apps_id_seq OWNED BY idp_oauth_apps.id;

CREATE TABLE idp_pkce_requests (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    client_id text NOT NULL,
    session_id bigint NOT NULL,
    hashed_signature text NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    requested_scopes text[] NOT NULL,
    granted_scopes text[] NOT NULL,
    requested_audience text[] NOT NULL,
    granted_audience text[] NOT NULL,
    request_form jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_pkce_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_pkce_requests_id_seq OWNED BY idp_pkce_requests.id;

CREATE TABLE idp_secrets (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    oidc_global_secret text NOT NULL,
    oidc_jwk_private_key text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

COMMENT ON TABLE idp_secrets IS 'Stores tenant-specific OIDC configuration secrets including global secrets and JWK private keys';

CREATE SEQUENCE idp_secrets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_secrets_id_seq OWNED BY idp_secrets.id;

CREATE TABLE idp_service_account_m2m_clients (
    id integer NOT NULL,
    client_id text NOT NULL,
    service_account_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE idp_service_account_m2m_clients_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_service_account_m2m_clients_id_seq OWNED BY idp_service_account_m2m_clients.id;

CREATE TABLE idp_sessions (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    client_id text NOT NULL,
    claims jsonb NOT NULL,
    headers jsonb NOT NULL,
    expires_at jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_sessions_id_seq OWNED BY idp_sessions.id;

CREATE TABLE idp_tokens (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    opaque_id text NOT NULL,
    type text NOT NULL,
    client_id text NOT NULL,
    session_id bigint NOT NULL,
    active boolean NOT NULL,
    hashed_signature text NOT NULL,
    requested_at timestamp with time zone NOT NULL,
    requested_scopes text[] NOT NULL,
    granted_scopes text[] NOT NULL,
    requested_audience text[] NOT NULL,
    granted_audience text[] NOT NULL,
    request_form jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);

CREATE SEQUENCE idp_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_tokens_id_seq OWNED BY idp_tokens.id;

CREATE TABLE idp_user_consents (
    id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    user_id integer NOT NULL,
    client_id text NOT NULL,
    scopes text[] NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    redirect_uris text[] DEFAULT '{}'::text[] NOT NULL
);

CREATE SEQUENCE idp_user_consents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE idp_user_consents_id_seq OWNED BY idp_user_consents.id;

CREATE TABLE insights_query_runner_jobs (
    id integer NOT NULL,
    series_id text NOT NULL,
    search_query text NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    record_time timestamp with time zone,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    priority integer DEFAULT 1 NOT NULL,
    cost integer DEFAULT 500 NOT NULL,
    persist_mode persistmode DEFAULT 'record'::persistmode NOT NULL,
    queued_at timestamp with time zone DEFAULT now(),
    cancel boolean DEFAULT false NOT NULL,
    trace_id text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE insights_query_runner_jobs IS 'See [internal/insights/background/queryrunner/worker.go:Job](https://sourcegraph.com/search?q=repo:%5Egithub%5C.com/sourcegraph/sourcegraph%24+file:internal/insights/background/queryrunner/worker.go+type+Job&patternType=literal)';

COMMENT ON COLUMN insights_query_runner_jobs.priority IS 'Integer representing a category of priority for this query. Priority in this context is ambiguously defined for consumers to decide an interpretation.';

COMMENT ON COLUMN insights_query_runner_jobs.cost IS 'Integer representing a cost approximation of executing this search query.';

COMMENT ON COLUMN insights_query_runner_jobs.persist_mode IS 'The persistence level for this query. This value will determine the lifecycle of the resulting value.';

CREATE TABLE insights_query_runner_jobs_dependencies (
    id integer NOT NULL,
    job_id integer NOT NULL,
    recording_time timestamp without time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE insights_query_runner_jobs_dependencies IS 'Stores data points for a code insight that do not need to be queried directly, but depend on the result of a query at a different point';

COMMENT ON COLUMN insights_query_runner_jobs_dependencies.job_id IS 'Foreign key to the job that owns this record.';

COMMENT ON COLUMN insights_query_runner_jobs_dependencies.recording_time IS 'The time for which this dependency should be recorded at using the parents value.';

CREATE SEQUENCE insights_query_runner_jobs_dependencies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE insights_query_runner_jobs_dependencies_id_seq OWNED BY insights_query_runner_jobs_dependencies.id;

CREATE SEQUENCE insights_query_runner_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE insights_query_runner_jobs_id_seq OWNED BY insights_query_runner_jobs.id;

CREATE TABLE insights_settings_migration_jobs (
    id integer NOT NULL,
    user_id integer,
    org_id integer,
    global boolean,
    settings_id integer NOT NULL,
    total_insights integer DEFAULT 0 NOT NULL,
    migrated_insights integer DEFAULT 0 NOT NULL,
    total_dashboards integer DEFAULT 0 NOT NULL,
    migrated_dashboards integer DEFAULT 0 NOT NULL,
    runs integer DEFAULT 0 NOT NULL,
    completed_at timestamp without time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE insights_settings_migration_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE insights_settings_migration_jobs_id_seq OWNED BY insights_settings_migration_jobs.id;

CREATE SEQUENCE lsif_configuration_policies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_configuration_policies_id_seq OWNED BY lsif_configuration_policies.id;

CREATE TABLE lsif_dependency_indexing_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    last_heartbeat_at timestamp with time zone,
    worker_hostname text DEFAULT ''::text NOT NULL,
    upload_id integer,
    external_service_kind text DEFAULT ''::text NOT NULL,
    external_service_sync timestamp with time zone,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN lsif_dependency_indexing_jobs.external_service_kind IS 'Filter the external services for this kind to wait to have synced. If empty, external_service_sync is ignored and no external services are polled for their last sync time.';

COMMENT ON COLUMN lsif_dependency_indexing_jobs.external_service_sync IS 'The sync time after which external services of the given kind will have synced/created any repositories referenced by the LSIF upload that are resolvable.';

CREATE TABLE lsif_dependency_syncing_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    upload_id integer,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_dependency_syncing_jobs IS 'Tracks jobs that scan imports of indexes to schedule auto-index jobs.';

COMMENT ON COLUMN lsif_dependency_syncing_jobs.upload_id IS 'The identifier of the triggering upload record.';

CREATE SEQUENCE lsif_dependency_indexing_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_dependency_indexing_jobs_id_seq OWNED BY lsif_dependency_syncing_jobs.id;

CREATE SEQUENCE lsif_dependency_indexing_jobs_id_seq1
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_dependency_indexing_jobs_id_seq1 OWNED BY lsif_dependency_indexing_jobs.id;

CREATE TABLE lsif_dependency_repos (
    id bigint NOT NULL,
    name text NOT NULL,
    scheme text NOT NULL,
    blocked boolean DEFAULT false NOT NULL,
    last_checked_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE lsif_dependency_repos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_dependency_repos_id_seq OWNED BY lsif_dependency_repos.id;

CREATE TABLE lsif_dirty_repositories (
    repository_id integer NOT NULL,
    dirty_token integer NOT NULL,
    update_token integer NOT NULL,
    updated_at timestamp with time zone,
    set_dirty_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_dirty_repositories IS 'Stores whether or not the nearest upload data for a repository is out of date (when update_token > dirty_token).';

COMMENT ON COLUMN lsif_dirty_repositories.dirty_token IS 'Set to the value of update_token visible to the transaction that updates the commit graph. Updates of dirty_token during this time will cause a second update.';

COMMENT ON COLUMN lsif_dirty_repositories.update_token IS 'This value is incremented on each request to update the commit graph for the repository.';

COMMENT ON COLUMN lsif_dirty_repositories.updated_at IS 'The time the update_token value was last updated.';

CREATE TABLE scip_uploads (
    id integer NOT NULL,
    commit text NOT NULL,
    root text DEFAULT ''::text NOT NULL,
    uploaded_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    repository_id integer NOT NULL,
    indexer text NOT NULL,
    num_parts integer NOT NULL,
    uploaded_parts integer[] NOT NULL,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    upload_size bigint,
    num_failures integer DEFAULT 0 NOT NULL,
    associated_index_id bigint,
    committed_at timestamp with time zone,
    commit_last_checked_at timestamp with time zone,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    num_references integer,
    expired boolean DEFAULT false NOT NULL,
    last_retention_scan_at timestamp with time zone,
    reference_count integer,
    indexer_version text,
    queued_at timestamp with time zone,
    cancel boolean DEFAULT false NOT NULL,
    uncompressed_size bigint,
    last_referenced_scan_at timestamp with time zone,
    last_traversal_scan_at timestamp with time zone,
    last_reconcile_at timestamp with time zone,
    content_type text DEFAULT 'application/x-ndjson+lsif'::text NOT NULL,
    should_reindex boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT lsif_uploads_commit_valid_chars CHECK ((commit ~ '^[a-z0-9]{40}$'::text))
);

COMMENT ON TABLE scip_uploads IS 'Stores metadata about an LSIF index uploaded by a user.';

COMMENT ON COLUMN scip_uploads.id IS 'Used as a logical foreign key with the (disjoint) codeintel database.';

COMMENT ON COLUMN scip_uploads.commit IS 'A 40-char revhash. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN scip_uploads.root IS 'The path for which the index can resolve code intelligence relative to the repository root.';

COMMENT ON COLUMN scip_uploads.indexer IS 'The name of the indexer that produced the index file. If not supplied by the user it will be pulled from the index metadata.';

COMMENT ON COLUMN scip_uploads.num_parts IS 'The number of parts src-cli split the upload file into.';

COMMENT ON COLUMN scip_uploads.uploaded_parts IS 'The index of parts that have been successfully uploaded.';

COMMENT ON COLUMN scip_uploads.upload_size IS 'The size of the index file (in bytes).';

COMMENT ON COLUMN scip_uploads.num_references IS 'Deprecated in favor of reference_count.';

COMMENT ON COLUMN scip_uploads.expired IS 'Whether or not this upload data is no longer protected by any data retention policy.';

COMMENT ON COLUMN scip_uploads.last_retention_scan_at IS 'The last time this upload was checked against data retention policies.';

COMMENT ON COLUMN scip_uploads.reference_count IS 'The number of references to this upload data from other upload records (via lsif_references).';

COMMENT ON COLUMN scip_uploads.indexer_version IS 'The version of the indexer that produced the index file. If not supplied by the user it will be pulled from the index metadata.';

COMMENT ON COLUMN scip_uploads.last_referenced_scan_at IS 'The last time this upload was known to be referenced by another (possibly expired) index.';

COMMENT ON COLUMN scip_uploads.last_traversal_scan_at IS 'The last time this upload was known to be reachable by a non-expired index.';

COMMENT ON COLUMN scip_uploads.content_type IS 'The content type of the upload record. For now, the default value is `application/x-ndjson+lsif` to backfill existing records. This will change as we remove LSIF support.';

CREATE VIEW lsif_dumps WITH (security_invoker='true') AS
 SELECT id,
    commit,
    root,
    queued_at,
    uploaded_at,
    state,
    failure_message,
    started_at,
    finished_at,
    repository_id,
    indexer,
    indexer_version,
    num_parts,
    uploaded_parts,
    process_after,
    num_resets,
    upload_size,
    num_failures,
    associated_index_id,
    expired,
    last_retention_scan_at,
    finished_at AS processed_at,
    tenant_id
   FROM scip_uploads u
  WHERE ((state = 'completed'::text) OR (state = 'deleting'::text));

CREATE VIEW lsif_dumps_with_repository_name WITH (security_invoker='true') AS
 SELECT u.id,
    u.commit,
    u.root,
    u.queued_at,
    u.uploaded_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.indexer,
    u.indexer_version,
    u.num_parts,
    u.uploaded_parts,
    u.process_after,
    u.num_resets,
    u.upload_size,
    u.num_failures,
    u.associated_index_id,
    u.expired,
    u.last_retention_scan_at,
    u.processed_at,
    r.name AS repository_name,
    u.tenant_id
   FROM (lsif_dumps u
     JOIN repo r ON ((r.id = u.repository_id)))
  WHERE (r.deleted_at IS NULL);

CREATE TABLE lsif_index_configuration (
    id bigint NOT NULL,
    repository_id integer NOT NULL,
    data bytea NOT NULL,
    autoindex_enabled boolean DEFAULT true NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_index_configuration IS 'Stores the configuration used for code intel index jobs for a repository.';

COMMENT ON COLUMN lsif_index_configuration.data IS 'The raw user-supplied [configuration](https://sourcegraph.com/github.com/sourcegraph/sourcegraph@3.23/-/blob/enterprise/internal/codeintel/autoindex/config/types.go#L3:6) (encoded in JSONC).';

COMMENT ON COLUMN lsif_index_configuration.autoindex_enabled IS 'Whether or not auto-indexing should be attempted on this repo. Index jobs may be inferred from the repository contents if data is empty.';

CREATE SEQUENCE lsif_index_configuration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_index_configuration_id_seq OWNED BY lsif_index_configuration.id;

CREATE TABLE lsif_indexes (
    id bigint NOT NULL,
    commit text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    repository_id integer NOT NULL,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    docker_steps jsonb[] NOT NULL,
    root text NOT NULL,
    indexer text NOT NULL,
    indexer_args text[] NOT NULL,
    outfile text NOT NULL,
    log_contents text,
    execution_logs json[],
    local_steps text[] NOT NULL,
    commit_last_checked_at timestamp with time zone,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    cancel boolean DEFAULT false NOT NULL,
    should_reindex boolean DEFAULT false NOT NULL,
    requested_envvars text[],
    enqueuer_user_id integer DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    matched_policy_id integer,
    matched_revision text,
    CONSTRAINT lsif_uploads_commit_valid_chars CHECK ((commit ~ '^[a-z0-9]{40}$'::text))
);

COMMENT ON TABLE lsif_indexes IS 'Stores metadata about a code intel index job.';

COMMENT ON COLUMN lsif_indexes.commit IS 'A 40-char revhash. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN lsif_indexes.docker_steps IS 'An array of pre-index [steps](https://sourcegraph.com/github.com/sourcegraph/sourcegraph@3.23/-/blob/enterprise/internal/codeintel/stores/dbstore/docker_step.go#L9:6) to run.';

COMMENT ON COLUMN lsif_indexes.root IS 'The working directory of the indexer image relative to the repository root.';

COMMENT ON COLUMN lsif_indexes.indexer IS 'The docker image used to run the index command (e.g. sourcegraph/lsif-go).';

COMMENT ON COLUMN lsif_indexes.indexer_args IS 'The command run inside the indexer image to produce the index file (e.g. [''lsif-node'', ''-p'', ''.''])';

COMMENT ON COLUMN lsif_indexes.outfile IS 'The path to the index file produced by the index command relative to the working directory.';

COMMENT ON COLUMN lsif_indexes.log_contents IS '**Column deprecated in favor of execution_logs.**';

COMMENT ON COLUMN lsif_indexes.execution_logs IS 'An array of [log entries](https://sourcegraph.com/github.com/sourcegraph/sourcegraph@3.23/-/blob/internal/workerutil/store.go#L48:6) (encoded as JSON) from the most recent execution.';

COMMENT ON COLUMN lsif_indexes.local_steps IS 'A list of commands to run inside the indexer image prior to running the indexer command.';

COMMENT ON COLUMN lsif_indexes.matched_policy_id IS 'The policy ID that triggered this indexing job to be created.';

COMMENT ON COLUMN lsif_indexes.matched_revision IS 'The revision that triggered this indexing job to be created. Depending on matched_policy_id, this may be a tag name, a branch name, or HEAD.';

CREATE SEQUENCE lsif_indexes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_indexes_id_seq OWNED BY lsif_indexes.id;

CREATE VIEW lsif_indexes_with_repository_name WITH (security_invoker='true') AS
 SELECT u.id,
    u.commit,
    u.queued_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.process_after,
    u.num_resets,
    u.num_failures,
    u.docker_steps,
    u.root,
    u.indexer,
    u.indexer_args,
    u.outfile,
    u.log_contents,
    u.execution_logs,
    u.local_steps,
    u.should_reindex,
    u.requested_envvars,
    r.name AS repository_name,
    u.enqueuer_user_id,
    u.tenant_id
   FROM (lsif_indexes u
     JOIN repo r ON ((r.id = u.repository_id)))
  WHERE (r.deleted_at IS NULL);

CREATE TABLE lsif_last_index_scan (
    repository_id integer NOT NULL,
    last_index_scan_at timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_last_index_scan IS 'Tracks the last time repository was checked for auto-indexing job scheduling.';

COMMENT ON COLUMN lsif_last_index_scan.last_index_scan_at IS 'The last time uploads of this repository were considered for auto-indexing job scheduling.';

CREATE TABLE lsif_last_retention_scan (
    repository_id integer NOT NULL,
    last_retention_scan_at timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_last_retention_scan IS 'Tracks the last time uploads a repository were checked against data retention policies.';

COMMENT ON COLUMN lsif_last_retention_scan.last_retention_scan_at IS 'The last time uploads of this repository were checked against data retention policies.';

CREATE TABLE scip_nearest_uploads (
    repository_id integer NOT NULL,
    commit_bytea bytea NOT NULL,
    uploads jsonb NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON TABLE scip_nearest_uploads IS 'Associates commits with the complete set of uploads visible from that commit. Every commit with upload data is present in this table.';

COMMENT ON COLUMN scip_nearest_uploads.commit_bytea IS 'A 40-char revhash. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN scip_nearest_uploads.uploads IS 'Encodes an {upload_id => distance} map that includes an entry for every upload visible from the commit. There is always at least one entry with a distance of zero.';

CREATE VIEW lsif_nearest_uploads WITH (security_invoker='true') AS
 SELECT repository_id,
    commit_bytea,
    uploads,
    tenant_id,
    id
   FROM scip_nearest_uploads;

CREATE TABLE scip_nearest_uploads_links (
    repository_id integer NOT NULL,
    commit_bytea bytea NOT NULL,
    ancestor_commit_bytea bytea NOT NULL,
    distance integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON TABLE scip_nearest_uploads_links IS 'Associates commits with the closest ancestor commit with usable upload data. Together, this table and lsif_nearest_uploads cover all commits with resolvable code intelligence.';

COMMENT ON COLUMN scip_nearest_uploads_links.commit_bytea IS 'A 40-char revhash. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN scip_nearest_uploads_links.ancestor_commit_bytea IS 'The 40-char revhash of the ancestor. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN scip_nearest_uploads_links.distance IS 'The distance bewteen the commits. Parent = 1, Grandparent = 2, etc.';

CREATE VIEW lsif_nearest_uploads_links WITH (security_invoker='true') AS
 SELECT repository_id,
    commit_bytea,
    ancestor_commit_bytea,
    distance,
    tenant_id,
    id
   FROM scip_nearest_uploads_links;

CREATE TABLE lsif_packages (
    id integer NOT NULL,
    scheme text NOT NULL,
    name text NOT NULL,
    version text,
    dump_id integer NOT NULL,
    manager text DEFAULT ''::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_packages IS 'Associates an upload with the set of packages they provide within a given packages management scheme.';

COMMENT ON COLUMN lsif_packages.scheme IS 'The (export) moniker scheme.';

COMMENT ON COLUMN lsif_packages.name IS 'The package name.';

COMMENT ON COLUMN lsif_packages.version IS 'The package version.';

COMMENT ON COLUMN lsif_packages.dump_id IS 'The identifier of the upload that provides the package.';

COMMENT ON COLUMN lsif_packages.manager IS 'The package manager name.';

CREATE SEQUENCE lsif_packages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_packages_id_seq OWNED BY lsif_packages.id;

CREATE TABLE lsif_references (
    id integer NOT NULL,
    scheme text NOT NULL,
    name text NOT NULL,
    version text,
    dump_id integer NOT NULL,
    manager text DEFAULT ''::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_references IS 'Associates an upload with the set of packages they require within a given packages management scheme.';

COMMENT ON COLUMN lsif_references.scheme IS 'The (import) moniker scheme.';

COMMENT ON COLUMN lsif_references.name IS 'The package name.';

COMMENT ON COLUMN lsif_references.version IS 'The package version.';

COMMENT ON COLUMN lsif_references.dump_id IS 'The identifier of the upload that references the package.';

COMMENT ON COLUMN lsif_references.manager IS 'The package manager name.';

CREATE SEQUENCE lsif_references_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_references_id_seq OWNED BY lsif_references.id;

CREATE TABLE lsif_retention_configuration (
    id integer NOT NULL,
    repository_id integer NOT NULL,
    max_age_for_non_stale_branches_seconds integer NOT NULL,
    max_age_for_non_stale_tags_seconds integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE lsif_retention_configuration IS 'Stores the retention policy of code intellience data for a repository.';

COMMENT ON COLUMN lsif_retention_configuration.max_age_for_non_stale_branches_seconds IS 'The number of seconds since the last modification of a branch until it is considered stale.';

COMMENT ON COLUMN lsif_retention_configuration.max_age_for_non_stale_tags_seconds IS 'The nujmber of seconds since the commit date of a tagged commit until it is considered stale.';

CREATE SEQUENCE lsif_retention_configuration_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE lsif_retention_configuration_id_seq OWNED BY lsif_retention_configuration.id;

CREATE VIEW lsif_uploads WITH (security_invoker='true') AS
 SELECT id,
    commit,
    root,
    uploaded_at,
    state,
    failure_message,
    started_at,
    finished_at,
    repository_id,
    indexer,
    num_parts,
    uploaded_parts,
    process_after,
    num_resets,
    upload_size,
    num_failures,
    associated_index_id,
    committed_at,
    commit_last_checked_at,
    worker_hostname,
    last_heartbeat_at,
    execution_logs,
    num_references,
    expired,
    last_retention_scan_at,
    reference_count,
    indexer_version,
    queued_at,
    cancel,
    uncompressed_size,
    last_referenced_scan_at,
    last_traversal_scan_at,
    last_reconcile_at,
    content_type,
    should_reindex,
    tenant_id
   FROM scip_uploads;

CREATE TABLE scip_uploads_audit_logs (
    log_timestamp timestamp with time zone DEFAULT now(),
    record_deleted_at timestamp with time zone,
    upload_id integer NOT NULL,
    commit text NOT NULL,
    root text NOT NULL,
    repository_id integer NOT NULL,
    uploaded_at timestamp with time zone NOT NULL,
    indexer text NOT NULL,
    indexer_version text,
    upload_size bigint,
    associated_index_id integer,
    transition_columns hstore[],
    reason text DEFAULT ''::text,
    sequence bigint NOT NULL,
    operation audit_log_operation NOT NULL,
    content_type text DEFAULT 'application/x-ndjson+lsif'::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN scip_uploads_audit_logs.log_timestamp IS 'Timestamp for this log entry.';

COMMENT ON COLUMN scip_uploads_audit_logs.record_deleted_at IS 'Set once the upload this entry is associated with is deleted. Once NOW() - record_deleted_at is above a certain threshold, this log entry will be deleted.';

COMMENT ON COLUMN scip_uploads_audit_logs.transition_columns IS 'Array of changes that occurred to the upload for this entry, in the form of {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

COMMENT ON COLUMN scip_uploads_audit_logs.reason IS 'The reason/source for this entry.';

CREATE VIEW lsif_uploads_audit_logs WITH (security_invoker='true') AS
 SELECT log_timestamp,
    record_deleted_at,
    upload_id,
    commit,
    root,
    repository_id,
    uploaded_at,
    indexer,
    indexer_version,
    upload_size,
    associated_index_id,
    transition_columns,
    reason,
    sequence,
    operation,
    content_type,
    tenant_id
   FROM scip_uploads_audit_logs;

CREATE TABLE scip_uploads_reference_counts (
    upload_id integer NOT NULL,
    reference_count integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE scip_uploads_reference_counts IS 'A less hot-path reference count for upload records.';

COMMENT ON COLUMN scip_uploads_reference_counts.upload_id IS 'The identifier of the referenced upload.';

COMMENT ON COLUMN scip_uploads_reference_counts.reference_count IS 'The number of references to the associated upload from other records (via lsif_references).';

CREATE VIEW lsif_uploads_reference_counts WITH (security_invoker='true') AS
 SELECT upload_id,
    reference_count,
    tenant_id
   FROM scip_uploads_reference_counts;

CREATE TABLE scip_uploads_visible_at_tip (
    repository_id integer NOT NULL,
    upload_id integer NOT NULL,
    branch_or_tag_name text DEFAULT ''::text NOT NULL,
    is_default_branch boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON TABLE scip_uploads_visible_at_tip IS 'Associates a repository with the set of LSIF upload identifiers that can serve intelligence for the tip of the default branch.';

COMMENT ON COLUMN scip_uploads_visible_at_tip.upload_id IS 'The identifier of the upload visible from the tip of the specified branch or tag.';

COMMENT ON COLUMN scip_uploads_visible_at_tip.branch_or_tag_name IS 'The name of the branch or tag.';

COMMENT ON COLUMN scip_uploads_visible_at_tip.is_default_branch IS 'Whether the specified branch is the default of the repository. Always false for tags.';

CREATE VIEW lsif_uploads_visible_at_tip WITH (security_invoker='true') AS
 SELECT repository_id,
    upload_id,
    branch_or_tag_name,
    is_default_branch,
    tenant_id,
    id
   FROM scip_uploads_visible_at_tip;

CREATE TABLE scip_uploads_vulnerability_scan (
    id bigint NOT NULL,
    upload_id integer NOT NULL,
    last_scanned_at timestamp without time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE VIEW lsif_uploads_vulnerability_scan WITH (security_invoker='true') AS
 SELECT id,
    upload_id,
    last_scanned_at,
    tenant_id
   FROM scip_uploads_vulnerability_scan;

CREATE VIEW lsif_uploads_with_repository_name WITH (security_invoker='true') AS
 SELECT u.id,
    u.commit,
    u.root,
    u.queued_at,
    u.uploaded_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.indexer,
    u.indexer_version,
    u.num_parts,
    u.uploaded_parts,
    u.process_after,
    u.num_resets,
    u.upload_size,
    u.num_failures,
    u.associated_index_id,
    u.content_type,
    u.should_reindex,
    u.expired,
    u.last_retention_scan_at,
    r.name AS repository_name,
    u.uncompressed_size,
    u.tenant_id
   FROM (scip_uploads u
     JOIN repo r ON ((r.id = u.repository_id)))
  WHERE (r.deleted_at IS NULL);

CREATE TABLE names (
    name citext NOT NULL,
    user_id integer,
    org_id integer,
    team_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT names_check CHECK (((user_id IS NOT NULL) OR (org_id IS NOT NULL) OR (team_id IS NOT NULL)))
);

CREATE TABLE namespace_permissions (
    id integer NOT NULL,
    namespace text NOT NULL,
    resource_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT namespace_not_blank CHECK ((namespace <> ''::text))
);

CREATE SEQUENCE namespace_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE namespace_permissions_id_seq OWNED BY namespace_permissions.id;

CREATE TABLE notebook_stars (
    notebook_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE notebooks (
    id bigint NOT NULL,
    title text NOT NULL,
    blocks jsonb DEFAULT '[]'::jsonb NOT NULL,
    public boolean NOT NULL,
    creator_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    blocks_tsvector tsvector GENERATED ALWAYS AS (jsonb_to_tsvector('english'::regconfig, blocks, '["string"]'::jsonb)) STORED,
    namespace_user_id integer,
    namespace_org_id integer,
    updater_user_id integer,
    pattern_type pattern_type DEFAULT 'keyword'::pattern_type NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT blocks_is_array CHECK ((jsonb_typeof(blocks) = 'array'::text)),
    CONSTRAINT notebooks_has_max_1_namespace CHECK ((((namespace_user_id IS NULL) AND (namespace_org_id IS NULL)) OR ((namespace_user_id IS NULL) <> (namespace_org_id IS NULL))))
);

CREATE SEQUENCE notebooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE notebooks_id_seq OWNED BY notebooks.id;

CREATE TABLE org_invitations (
    id bigint NOT NULL,
    org_id integer NOT NULL,
    sender_user_id integer NOT NULL,
    recipient_user_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    notified_at timestamp with time zone,
    responded_at timestamp with time zone,
    response_type boolean,
    revoked_at timestamp with time zone,
    deleted_at timestamp with time zone,
    recipient_email citext,
    expires_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT check_atomic_response CHECK (((responded_at IS NULL) = (response_type IS NULL))),
    CONSTRAINT check_single_use CHECK ((((responded_at IS NULL) AND (response_type IS NULL)) OR (revoked_at IS NULL))),
    CONSTRAINT either_user_id_or_email_defined CHECK (((recipient_user_id IS NULL) <> (recipient_email IS NULL)))
);

CREATE SEQUENCE org_invitations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE org_invitations_id_seq OWNED BY org_invitations.id;

CREATE TABLE org_members (
    id integer NOT NULL,
    org_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE org_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE org_members_id_seq OWNED BY org_members.id;

CREATE TABLE org_stats (
    org_id integer NOT NULL,
    code_host_repo_count integer DEFAULT 0,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE org_stats IS 'Business statistics for organizations';

COMMENT ON COLUMN org_stats.org_id IS 'Org ID that the stats relate to.';

COMMENT ON COLUMN org_stats.code_host_repo_count IS 'Count of repositories accessible on all code hosts for this organization.';

CREATE TABLE orgs (
    id integer NOT NULL,
    name citext NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    display_name text,
    slack_webhook_url text,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT orgs_display_name_max_length CHECK ((char_length(display_name) <= 255)),
    CONSTRAINT orgs_name_max_length CHECK ((char_length((name)::text) <= 255)),
    CONSTRAINT orgs_name_valid_chars CHECK ((name OPERATOR(~) '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-.](?=[a-zA-Z0-9]))*-?$'::citext))
);

CREATE SEQUENCE orgs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE orgs_id_seq OWNED BY orgs.id;

CREATE TABLE out_of_band_migrations (
    id integer NOT NULL,
    team text NOT NULL,
    component text NOT NULL,
    description text NOT NULL,
    progress double precision DEFAULT 0 NOT NULL,
    created timestamp with time zone NOT NULL,
    last_updated timestamp with time zone,
    non_destructive boolean NOT NULL,
    apply_reverse boolean DEFAULT false NOT NULL,
    is_enterprise boolean DEFAULT false NOT NULL,
    introduced_version_major integer NOT NULL,
    introduced_version_minor integer NOT NULL,
    deprecated_version_major integer,
    deprecated_version_minor integer,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT out_of_band_migrations_component_nonempty CHECK ((component <> ''::text)),
    CONSTRAINT out_of_band_migrations_description_nonempty CHECK ((description <> ''::text)),
    CONSTRAINT out_of_band_migrations_progress_range CHECK (((progress >= (0)::double precision) AND (progress <= (1)::double precision))),
    CONSTRAINT out_of_band_migrations_team_nonempty CHECK ((team <> ''::text))
);

COMMENT ON TABLE out_of_band_migrations IS 'Stores metadata and progress about an out-of-band migration routine.';

COMMENT ON COLUMN out_of_band_migrations.id IS 'A globally unique primary key for this migration. The same key is used consistently across all Sourcegraph instances for the same migration.';

COMMENT ON COLUMN out_of_band_migrations.team IS 'The name of the engineering team responsible for the migration.';

COMMENT ON COLUMN out_of_band_migrations.component IS 'The name of the component undergoing a migration.';

COMMENT ON COLUMN out_of_band_migrations.description IS 'A brief description about the migration.';

COMMENT ON COLUMN out_of_band_migrations.progress IS 'The percentage progress in the up direction (0=0%, 1=100%).';

COMMENT ON COLUMN out_of_band_migrations.created IS 'The date and time the migration was inserted into the database (via an upgrade).';

COMMENT ON COLUMN out_of_band_migrations.last_updated IS 'The date and time the migration was last updated.';

COMMENT ON COLUMN out_of_band_migrations.non_destructive IS 'Whether or not this migration alters data so it can no longer be read by the previous Sourcegraph instance.';

COMMENT ON COLUMN out_of_band_migrations.apply_reverse IS 'Whether this migration should run in the opposite direction (to support an upcoming downgrade).';

COMMENT ON COLUMN out_of_band_migrations.is_enterprise IS 'When true, these migrations are invisible to OSS mode.';

COMMENT ON COLUMN out_of_band_migrations.introduced_version_major IS 'The Sourcegraph version (major component) in which this migration was first introduced.';

COMMENT ON COLUMN out_of_band_migrations.introduced_version_minor IS 'The Sourcegraph version (minor component) in which this migration was first introduced.';

COMMENT ON COLUMN out_of_band_migrations.deprecated_version_major IS 'The lowest Sourcegraph version (major component) that assumes the migration has completed.';

COMMENT ON COLUMN out_of_band_migrations.deprecated_version_minor IS 'The lowest Sourcegraph version (minor component) that assumes the migration has completed.';

CREATE TABLE out_of_band_migrations_errors (
    id integer NOT NULL,
    migration_id integer NOT NULL,
    message text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT out_of_band_migrations_errors_message_nonempty CHECK ((message <> ''::text))
);

COMMENT ON TABLE out_of_band_migrations_errors IS 'Stores errors that occurred while performing an out-of-band migration.';

COMMENT ON COLUMN out_of_band_migrations_errors.id IS 'A unique identifer.';

COMMENT ON COLUMN out_of_band_migrations_errors.migration_id IS 'The identifier of the migration.';

COMMENT ON COLUMN out_of_band_migrations_errors.message IS 'The error message.';

COMMENT ON COLUMN out_of_band_migrations_errors.created IS 'The date and time the error occurred.';

CREATE SEQUENCE out_of_band_migrations_errors_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE out_of_band_migrations_errors_id_seq OWNED BY out_of_band_migrations_errors.id;

CREATE SEQUENCE out_of_band_migrations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE out_of_band_migrations_id_seq OWNED BY out_of_band_migrations.id;

CREATE TABLE outbound_webhook_event_types (
    id bigint NOT NULL,
    outbound_webhook_id bigint NOT NULL,
    event_type text NOT NULL,
    scope text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE outbound_webhook_event_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE outbound_webhook_event_types_id_seq OWNED BY outbound_webhook_event_types.id;

CREATE TABLE outbound_webhook_jobs (
    id bigint NOT NULL,
    event_type text NOT NULL,
    scope text,
    encryption_key_id text,
    payload bytea NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE outbound_webhook_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE outbound_webhook_jobs_id_seq OWNED BY outbound_webhook_jobs.id;

CREATE TABLE outbound_webhook_logs (
    id bigint NOT NULL,
    job_id bigint NOT NULL,
    outbound_webhook_id bigint NOT NULL,
    sent_at timestamp with time zone DEFAULT now() NOT NULL,
    status_code integer NOT NULL,
    encryption_key_id text,
    request bytea NOT NULL,
    response bytea NOT NULL,
    error bytea NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE outbound_webhook_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE outbound_webhook_logs_id_seq OWNED BY outbound_webhook_logs.id;

CREATE TABLE outbound_webhooks (
    id bigint NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    encryption_key_id text,
    url bytea NOT NULL,
    secret bytea NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE outbound_webhooks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE outbound_webhooks_id_seq OWNED BY outbound_webhooks.id;

CREATE VIEW outbound_webhooks_with_event_types WITH (security_invoker='true') AS
 SELECT id,
    created_by,
    created_at,
    updated_by,
    updated_at,
    encryption_key_id,
    url,
    secret,
    array_to_json(ARRAY( SELECT json_build_object('id', outbound_webhook_event_types.id, 'outbound_webhook_id', outbound_webhook_event_types.outbound_webhook_id, 'event_type', outbound_webhook_event_types.event_type, 'scope', outbound_webhook_event_types.scope) AS json_build_object
           FROM outbound_webhook_event_types
          WHERE (outbound_webhook_event_types.outbound_webhook_id = outbound_webhooks.id))) AS event_types
   FROM outbound_webhooks;

CREATE TABLE own_aggregate_recent_contribution (
    id integer NOT NULL,
    commit_author_id integer NOT NULL,
    changed_file_path_id integer NOT NULL,
    contributions_count integer DEFAULT 0,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE own_aggregate_recent_contribution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE own_aggregate_recent_contribution_id_seq OWNED BY own_aggregate_recent_contribution.id;

CREATE TABLE own_aggregate_recent_view (
    id integer NOT NULL,
    viewer_id integer NOT NULL,
    viewed_file_path_id integer NOT NULL,
    views_count integer DEFAULT 0,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE own_aggregate_recent_view IS 'One entry contains a number of views of a single file by a given viewer.';

CREATE SEQUENCE own_aggregate_recent_view_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE own_aggregate_recent_view_id_seq OWNED BY own_aggregate_recent_view.id;

CREATE TABLE own_background_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repo_id integer NOT NULL,
    job_type integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE own_signal_configurations (
    id integer NOT NULL,
    name text NOT NULL,
    description text DEFAULT ''::text NOT NULL,
    excluded_repo_patterns text[],
    enabled boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE VIEW own_background_jobs_config_aware WITH (security_invoker='true') AS
 SELECT obj.id,
    obj.state,
    obj.failure_message,
    obj.queued_at,
    obj.started_at,
    obj.finished_at,
    obj.process_after,
    obj.num_resets,
    obj.num_failures,
    obj.last_heartbeat_at,
    obj.execution_logs,
    obj.worker_hostname,
    obj.cancel,
    obj.repo_id,
    obj.job_type,
    osc.name AS config_name,
    obj.tenant_id
   FROM (own_background_jobs obj
     JOIN own_signal_configurations osc ON ((obj.job_type = osc.id)))
  WHERE (osc.enabled IS TRUE);

CREATE SEQUENCE own_background_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE own_background_jobs_id_seq OWNED BY own_background_jobs.id;

CREATE SEQUENCE own_signal_configurations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE own_signal_configurations_id_seq OWNED BY own_signal_configurations.id;

CREATE TABLE own_signal_recent_contribution (
    id integer NOT NULL,
    commit_author_id integer NOT NULL,
    changed_file_path_id integer NOT NULL,
    commit_timestamp timestamp without time zone NOT NULL,
    commit_id bytea NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE own_signal_recent_contribution IS 'One entry per file changed in every commit that classifies as a contribution signal.';

CREATE SEQUENCE own_signal_recent_contribution_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE own_signal_recent_contribution_id_seq OWNED BY own_signal_recent_contribution.id;

CREATE TABLE ownership_path_stats (
    file_path_id integer NOT NULL,
    tree_codeowned_files_count integer,
    last_updated_at timestamp without time zone NOT NULL,
    tree_assigned_ownership_files_count integer,
    tree_any_ownership_files_count integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE ownership_path_stats IS 'Data on how many files in given tree are owned by anyone.

We choose to have a table for `ownership_path_stats` - more general than for CODEOWNERS,
with a specific tree_codeowned_files_count CODEOWNERS column. The reason for that
is that we aim at expanding path stats by including total owned files (via CODEOWNERS
or assigned ownership), and perhaps files count by assigned ownership only.';

COMMENT ON COLUMN ownership_path_stats.last_updated_at IS 'When the last background job updating counts run.';

CREATE TABLE package_repo_filters (
    id integer NOT NULL,
    behaviour text NOT NULL,
    scheme text NOT NULL,
    matcher jsonb NOT NULL,
    deleted_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT statement_timestamp() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT package_repo_filters_behaviour_is_allow_or_block CHECK ((behaviour = ANY ('{BLOCK,ALLOW}'::text[]))),
    CONSTRAINT package_repo_filters_is_pkgrepo_scheme CHECK ((scheme = ANY ('{semanticdb,npm,go,python,rust-analyzer,scip-ruby}'::text[]))),
    CONSTRAINT package_repo_filters_valid_oneof_glob CHECK ((((matcher ? 'VersionGlob'::text) AND ((matcher ->> 'VersionGlob'::text) <> ''::text) AND ((matcher ->> 'PackageName'::text) <> ''::text) AND (NOT (matcher ? 'PackageGlob'::text))) OR ((matcher ? 'PackageGlob'::text) AND ((matcher ->> 'PackageGlob'::text) <> ''::text) AND (NOT (matcher ? 'VersionGlob'::text)))))
);

CREATE SEQUENCE package_repo_filters_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE package_repo_filters_id_seq OWNED BY package_repo_filters.id;

CREATE TABLE package_repo_versions (
    id bigint NOT NULL,
    package_id bigint NOT NULL,
    version text NOT NULL,
    blocked boolean DEFAULT false NOT NULL,
    last_checked_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE package_repo_versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE package_repo_versions_id_seq OWNED BY package_repo_versions.id;

CREATE TABLE pending_repo_permissions (
    id bigint NOT NULL,
    bind_id text NOT NULL,
    permission text NOT NULL,
    service_type text NOT NULL,
    service_id text NOT NULL,
    repo_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE pending_repo_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE pending_repo_permissions_id_seq OWNED BY pending_repo_permissions.id;

CREATE TABLE permission_sync_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    reason text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repository_id integer,
    user_id integer,
    triggered_by_user_id integer,
    priority integer DEFAULT 0 NOT NULL,
    invalidate_caches boolean DEFAULT false NOT NULL,
    cancellation_reason text,
    no_perms boolean DEFAULT false NOT NULL,
    permissions_added integer DEFAULT 0 NOT NULL,
    permissions_removed integer DEFAULT 0 NOT NULL,
    permissions_found integer DEFAULT 0 NOT NULL,
    code_host_states json[],
    is_partial_success boolean DEFAULT false,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT permission_sync_jobs_for_repo_or_user CHECK (((user_id IS NULL) <> (repository_id IS NULL)))
);

COMMENT ON COLUMN permission_sync_jobs.reason IS 'Specifies why permissions sync job was triggered.';

COMMENT ON COLUMN permission_sync_jobs.triggered_by_user_id IS 'Specifies an ID of a user who triggered a sync.';

COMMENT ON COLUMN permission_sync_jobs.priority IS 'Specifies numeric priority for the permissions sync job.';

COMMENT ON COLUMN permission_sync_jobs.cancellation_reason IS 'Specifies why permissions sync job was cancelled.';

CREATE SEQUENCE permission_sync_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE permission_sync_jobs_id_seq OWNED BY permission_sync_jobs.id;

CREATE TABLE permissions (
    id integer NOT NULL,
    namespace text NOT NULL,
    action text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT action_not_blank CHECK ((action <> ''::text)),
    CONSTRAINT namespace_not_blank CHECK ((namespace <> ''::text))
);

CREATE SEQUENCE permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE permissions_id_seq OWNED BY permissions.id;

CREATE TABLE phabricator_repos (
    id integer NOT NULL,
    callsign citext NOT NULL,
    repo_name citext NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    url text DEFAULT ''::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE phabricator_repos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE phabricator_repos_id_seq OWNED BY phabricator_repos.id;

CREATE TABLE prompt_tags (
    id integer NOT NULL,
    name text NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT prompt_tags_name_max_length CHECK ((char_length(name) <= 255)),
    CONSTRAINT prompt_tags_name_valid_chars CHECK ((name ~ ('^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-._\s](?=[a-zA-Z0-9]))*-?$'::citext)::text))
);

CREATE SEQUENCE prompt_tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE prompt_tags_id_seq OWNED BY prompt_tags.id;

CREATE TABLE prompts (
    id integer NOT NULL,
    name citext NOT NULL,
    description text NOT NULL,
    definition_text text NOT NULL,
    draft boolean DEFAULT false NOT NULL,
    visibility_secret boolean DEFAULT true NOT NULL,
    owner_user_id integer,
    owner_org_id integer,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    auto_submit boolean DEFAULT false NOT NULL,
    mode character varying DEFAULT 'CHAT'::character varying NOT NULL,
    recommended boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    builtin boolean DEFAULT false NOT NULL,
    CONSTRAINT prompts_definition_text_max_length CHECK ((char_length(definition_text) <= (1024 * 100))),
    CONSTRAINT prompts_description_max_length CHECK ((char_length(description) <= (1024 * 50))),
    CONSTRAINT prompts_has_valid_owner CHECK ((((owner_user_id IS NOT NULL) AND (owner_org_id IS NULL) AND (builtin IS FALSE)) OR ((owner_org_id IS NOT NULL) AND (owner_user_id IS NULL) AND (builtin IS FALSE)) OR ((builtin IS TRUE) AND (owner_user_id IS NULL) AND (owner_org_id IS NULL)))),
    CONSTRAINT prompts_name_max_length CHECK ((char_length((name)::text) <= 255)),
    CONSTRAINT prompts_name_valid_chars CHECK ((name OPERATOR(~) '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-.](?=[a-zA-Z0-9]))*-?$'::citext))
);

CREATE SEQUENCE prompts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE prompts_id_seq OWNED BY prompts.id;

CREATE TABLE prompts_tags_mappings (
    prompt_id integer NOT NULL,
    prompt_tag_id integer NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE users (
    id integer NOT NULL,
    username citext NOT NULL,
    display_name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    invite_quota integer DEFAULT 100 NOT NULL,
    passwd text,
    passwd_reset_code text,
    passwd_reset_time timestamp with time zone,
    site_admin boolean DEFAULT false NOT NULL,
    page_views integer DEFAULT 0 NOT NULL,
    search_queries integer DEFAULT 0 NOT NULL,
    billing_customer_id text,
    invalidated_sessions_at timestamp with time zone DEFAULT now() NOT NULL,
    tos_accepted boolean DEFAULT false NOT NULL,
    completions_quota integer,
    code_completions_quota integer,
    completed_post_signup boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    service_account boolean DEFAULT false NOT NULL,
    unrestricted_repo_access boolean DEFAULT false NOT NULL,
    CONSTRAINT users_display_name_max_length CHECK ((char_length(display_name) <= 255)),
    CONSTRAINT users_username_max_length CHECK ((char_length((username)::text) <= 255)),
    CONSTRAINT users_username_valid_chars CHECK ((username OPERATOR(~) '^\w(?:\w|[-.](?=\w))*-?$'::citext))
);

CREATE VIEW prompts_view WITH (security_invoker='true') AS
 SELECT prompts.id,
    prompts.name,
    prompts.description,
    prompts.definition_text,
    prompts.draft,
    prompts.visibility_secret,
    prompts.owner_user_id,
    prompts.owner_org_id,
    prompts.created_by,
    prompts.created_at,
    prompts.updated_by,
    prompts.updated_at,
        CASE
            WHEN (prompts.builtin IS FALSE) THEN (((COALESCE(users.username, orgs.name, ''::citext))::text || '/'::text) || (prompts.name)::text)
            ELSE (prompts.name)::text
        END AS name_with_owner,
    prompts.auto_submit,
    prompts.mode,
    prompts.recommended,
    prompts.deleted_at,
    prompts.builtin
   FROM ((prompts
     LEFT JOIN users ON ((users.id = prompts.owner_user_id)))
     LEFT JOIN orgs ON ((orgs.id = prompts.owner_org_id)));

CREATE VIEW reconciler_changesets WITH (security_invoker='true') AS
 SELECT c.id,
    c.batch_change_ids,
    c.repo_id,
    c.queued_at,
    c.created_at,
    c.updated_at,
    c.metadata,
    c.external_id,
    c.external_service_type,
    c.external_deleted_at,
    c.external_branch,
    c.external_updated_at,
    c.external_state,
    c.external_review_state,
    c.external_check_state,
    c.commit_verification,
    c.diff_stat_added,
    c.diff_stat_deleted,
    c.sync_state,
    c.current_spec_id,
    c.previous_spec_id,
    c.publication_state,
    c.owned_by_batch_change_id,
    c.reconciler_state,
    c.computed_state,
    c.failure_message,
    c.started_at,
    c.finished_at,
    c.process_after,
    c.num_resets,
    c.closing,
    c.num_failures,
    c.log_contents,
    c.execution_logs,
    c.syncer_error,
    c.external_title,
    c.worker_hostname,
    c.ui_publication_state,
    c.last_heartbeat_at,
    c.external_fork_name,
    c.external_fork_namespace,
    c.detached_at,
    c.previous_failure_message,
    c.tenant_id,
    c.auto_merge_method
   FROM (changesets c
     JOIN repo r ON ((r.id = c.repo_id)))
  WHERE ((r.deleted_at IS NULL) AND (EXISTS ( SELECT 1
           FROM ((batch_changes
             LEFT JOIN users namespace_user ON ((batch_changes.namespace_user_id = namespace_user.id)))
             LEFT JOIN orgs namespace_org ON ((batch_changes.namespace_org_id = namespace_org.id)))
          WHERE ((c.batch_change_ids ? (batch_changes.id)::text) AND (namespace_user.deleted_at IS NULL) AND (namespace_org.deleted_at IS NULL)))));

CREATE TABLE registry_extension_releases (
    id bigint NOT NULL,
    registry_extension_id integer NOT NULL,
    creator_user_id integer NOT NULL,
    release_version citext,
    release_tag citext NOT NULL,
    manifest jsonb NOT NULL,
    bundle text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    source_map text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE registry_extension_releases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE registry_extension_releases_id_seq OWNED BY registry_extension_releases.id;

CREATE TABLE registry_extensions (
    id integer NOT NULL,
    uuid uuid NOT NULL,
    publisher_user_id integer,
    publisher_org_id integer,
    name citext NOT NULL,
    manifest text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT registry_extensions_name_length CHECK (((char_length((name)::text) > 0) AND (char_length((name)::text) <= 128))),
    CONSTRAINT registry_extensions_name_valid_chars CHECK ((name OPERATOR(~) '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[_.-](?=[a-zA-Z0-9]))*$'::citext)),
    CONSTRAINT registry_extensions_single_publisher CHECK (((publisher_user_id IS NULL) <> (publisher_org_id IS NULL)))
);

CREATE SEQUENCE registry_extensions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE registry_extensions_id_seq OWNED BY registry_extensions.id;

CREATE TABLE repo_cleanup_jobs (
    id bigint NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repository_id integer NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    eager_optimize boolean DEFAULT false NOT NULL
);

CREATE SEQUENCE repo_cleanup_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_cleanup_jobs_id_seq OWNED BY repo_cleanup_jobs.id;

CREATE TABLE repo_commits_changelists (
    id integer NOT NULL,
    repo_id integer NOT NULL,
    commit_sha bytea NOT NULL,
    perforce_changelist_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE repo_commits_changelists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_commits_changelists_id_seq OWNED BY repo_commits_changelists.id;

CREATE TABLE repo_embedding_job_stats (
    job_id integer NOT NULL,
    is_incremental boolean DEFAULT false NOT NULL,
    files_total integer DEFAULT 0 NOT NULL,
    files_embedded integer DEFAULT 0 NOT NULL,
    chunks_embedded integer DEFAULT 0 NOT NULL,
    files_excluded integer DEFAULT 0 NOT NULL,
    files_skipped jsonb DEFAULT '{}'::jsonb NOT NULL,
    bytes_embedded bigint DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE repo_embedding_jobs (
    id integer NOT NULL,
    state text DEFAULT 'queued'::text,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now(),
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repo_id integer NOT NULL,
    revision text NOT NULL,
    commit_id text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE repo_embedding_jobs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_embedding_jobs_id_seq OWNED BY repo_embedding_jobs.id;

CREATE SEQUENCE repo_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_id_seq OWNED BY repo.id;

CREATE TABLE repo_kvps (
    repo_id integer NOT NULL,
    key text NOT NULL,
    value text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE repo_paths (
    id integer NOT NULL,
    repo_id integer NOT NULL,
    absolute_path text NOT NULL,
    parent_id integer,
    tree_files_count integer,
    tree_files_counts_updated_at timestamp without time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN repo_paths.absolute_path IS 'Absolute path does not start or end with forward slash. Example: "a/b/c". Root directory is empty path "".';

COMMENT ON COLUMN repo_paths.tree_files_count IS 'Total count of files in the file tree rooted at the path. 1 for files.';

COMMENT ON COLUMN repo_paths.tree_files_counts_updated_at IS 'Timestamp of the job that updated the file counts';

CREATE SEQUENCE repo_paths_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_paths_id_seq OWNED BY repo_paths.id;

CREATE TABLE repo_statistics (
    total bigint DEFAULT 0 NOT NULL,
    soft_deleted bigint DEFAULT 0 NOT NULL,
    not_cloned bigint DEFAULT 0 NOT NULL,
    cloning bigint DEFAULT 0 NOT NULL,
    cloned bigint DEFAULT 0 NOT NULL,
    failed_fetch bigint DEFAULT 0 NOT NULL,
    corrupted bigint DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    id bigint NOT NULL
);

COMMENT ON COLUMN repo_statistics.total IS 'Number of repositories that are not soft-deleted and not blocked';

COMMENT ON COLUMN repo_statistics.soft_deleted IS 'Number of repositories that are soft-deleted and not blocked';

COMMENT ON COLUMN repo_statistics.not_cloned IS 'Number of repositories that are NOT soft-deleted and not blocked and not cloned by gitserver';

COMMENT ON COLUMN repo_statistics.cloning IS 'Number of repositories that are NOT soft-deleted and not blocked and currently being cloned by gitserver';

COMMENT ON COLUMN repo_statistics.cloned IS 'Number of repositories that are NOT soft-deleted and not blocked and cloned by gitserver';

COMMENT ON COLUMN repo_statistics.failed_fetch IS 'Number of repositories that are NOT soft-deleted and not blocked and have last_error set in gitserver_repos table';

COMMENT ON COLUMN repo_statistics.corrupted IS 'Number of repositories that are NOT soft-deleted and not blocked and have corrupted_at set in gitserver_repos table';

CREATE SEQUENCE repo_statistics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_statistics_id_seq OWNED BY repo_statistics.id;

CREATE TABLE repo_update_jobs (
    id bigint NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repository_id integer NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE repo_update_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE repo_update_jobs_id_seq OWNED BY repo_update_jobs.id;

CREATE TABLE role_permissions (
    role_id integer NOT NULL,
    permission_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE roles (
    id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    system boolean DEFAULT false NOT NULL,
    name citext NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN roles.system IS 'This is used to indicate whether a role is read-only or can be modified.';

CREATE SEQUENCE roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE roles_id_seq OWNED BY roles.id;

CREATE TABLE saved_searches (
    id integer NOT NULL,
    description text NOT NULL,
    query text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    notify_owner boolean DEFAULT false NOT NULL,
    notify_slack boolean DEFAULT false NOT NULL,
    user_id integer,
    org_id integer,
    slack_webhook_url text,
    created_by integer,
    updated_by integer,
    draft boolean DEFAULT false NOT NULL,
    visibility_secret boolean DEFAULT true NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT saved_searches_notifications_disabled CHECK (((notify_owner = false) AND (notify_slack = false))),
    CONSTRAINT user_or_org_id_not_null CHECK ((((user_id IS NOT NULL) AND (org_id IS NULL)) OR ((org_id IS NOT NULL) AND (user_id IS NULL))))
);

CREATE SEQUENCE saved_searches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE saved_searches_id_seq OWNED BY saved_searches.id;

CREATE SEQUENCE scip_nearest_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_nearest_uploads_id_seq OWNED BY scip_nearest_uploads.id;

CREATE SEQUENCE scip_nearest_uploads_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_nearest_uploads_links_id_seq OWNED BY scip_nearest_uploads_links.id;

CREATE SEQUENCE scip_uploads_audit_logs_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_uploads_audit_logs_seq OWNED BY scip_uploads_audit_logs.sequence;

CREATE VIEW scip_uploads_for_available_repos WITH (security_invoker='true') AS
 SELECT u.id,
    u.commit,
    u.committed_at,
    u.root,
    u.queued_at,
    u.uploaded_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.indexer,
    u.indexer_version,
    u.num_parts,
    u.uploaded_parts,
    u.process_after,
    u.num_resets,
    u.upload_size,
    u.num_failures,
    u.associated_index_id,
    u.content_type,
    u.should_reindex,
    u.expired,
    u.last_retention_scan_at,
    r.name AS repository_name,
    u.uncompressed_size,
    u.tenant_id
   FROM (scip_uploads u
     JOIN repo r ON ((r.id = u.repository_id)))
  WHERE ((r.deleted_at IS NULL) AND (r.blocked IS NULL));

CREATE SEQUENCE scip_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_uploads_id_seq OWNED BY scip_uploads.id;

CREATE VIEW scip_uploads_nav_eligible WITH (security_invoker='true') AS
 SELECT id,
    commit,
    committed_at,
    root,
    queued_at,
    uploaded_at,
    state,
    failure_message,
    started_at,
    finished_at,
    repository_id,
    indexer,
    indexer_version,
    num_parts,
    uploaded_parts,
    process_after,
    num_resets,
    upload_size,
    num_failures,
    associated_index_id,
    content_type,
    should_reindex,
    expired,
    last_retention_scan_at,
    repository_name,
    uncompressed_size,
    tenant_id
   FROM scip_uploads_for_available_repos u
  WHERE (state = 'completed'::text);

CREATE SEQUENCE scip_uploads_visible_at_tip_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_uploads_visible_at_tip_id_seq OWNED BY scip_uploads_visible_at_tip.id;

CREATE SEQUENCE scip_uploads_vulnerability_scan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE scip_uploads_vulnerability_scan_id_seq OWNED BY scip_uploads_vulnerability_scan.id;

CREATE TABLE search_context_default (
    user_id integer NOT NULL,
    search_context_id bigint NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE search_context_default IS 'When a user sets a search context as default, a row is inserted into this table. A user can only have one default search context. If the user has not set their default search context, it will fall back to `global`.';

CREATE TABLE search_context_repos (
    search_context_id bigint NOT NULL,
    repo_id integer NOT NULL,
    revision text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE search_context_stars (
    search_context_id bigint NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE search_context_stars IS 'When a user stars a search context, a row is inserted into this table. If the user unstars the search context, the row is deleted. The global context is not in the database, and therefore cannot be starred.';

CREATE TABLE search_contexts (
    id bigint NOT NULL,
    name citext NOT NULL,
    description text NOT NULL,
    public boolean NOT NULL,
    namespace_user_id integer,
    namespace_org_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    query text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT search_contexts_has_one_or_no_namespace CHECK (((namespace_user_id IS NULL) OR (namespace_org_id IS NULL)))
);

COMMENT ON COLUMN search_contexts.deleted_at IS 'This column is unused as of Sourcegraph 3.34. Do not refer to it anymore. It will be dropped in a future version.';

CREATE SEQUENCE search_contexts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE search_contexts_id_seq OWNED BY search_contexts.id;

CREATE TABLE settings (
    id integer NOT NULL,
    org_id integer,
    contents text DEFAULT '{}'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id integer,
    author_user_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT settings_no_empty_contents CHECK ((contents <> ''::text))
);

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;

CREATE VIEW site_config WITH (security_invoker='true') AS
 SELECT site_id,
    initialized
   FROM global_state;

CREATE TABLE sub_repo_permissions (
    repo_id integer NOT NULL,
    user_id integer NOT NULL,
    version integer DEFAULT 1 NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    paths text[],
    ips text[],
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT ips_paths_length_check CHECK (((ips IS NULL) OR ((array_length(ips, 1) = array_length(paths, 1)) AND (NOT (''::text = ANY (ips))))))
);

COMMENT ON TABLE sub_repo_permissions IS 'Responsible for storing permissions at a finer granularity than repo';

COMMENT ON COLUMN sub_repo_permissions.paths IS 'Paths that begin with a minus sign (-) are exclusion paths.';

COMMENT ON COLUMN sub_repo_permissions.ips IS 'IP addresses corresponding to each path. IP in slot 0 in the array corresponds to path the in slot 0 of the path array, etc. NULL if not yet migrated, empty array for no IP restrictions.';

CREATE TABLE survey_responses (
    id bigint NOT NULL,
    user_id integer,
    email text,
    score integer NOT NULL,
    reason text,
    better text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    use_cases text[],
    other_use_case text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE survey_responses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE survey_responses_id_seq OWNED BY survey_responses.id;

CREATE TABLE syntactic_scip_indexing_jobs (
    id bigint NOT NULL,
    commit text NOT NULL,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    repository_id integer NOT NULL,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    execution_logs json[],
    commit_last_checked_at timestamp with time zone,
    worker_hostname text DEFAULT ''::text NOT NULL,
    last_heartbeat_at timestamp with time zone,
    cancel boolean DEFAULT false NOT NULL,
    should_reindex boolean DEFAULT false NOT NULL,
    enqueuer_user_id integer DEFAULT 0 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT syntactic_scip_indexing_jobs_commit_valid_chars CHECK ((commit ~ '^[a-f0-9]{40}$'::text))
);

COMMENT ON TABLE syntactic_scip_indexing_jobs IS 'Stores metadata about a code intel syntactic index job.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs.commit IS 'A 40-char revhash. Note that this commit may not be resolvable in the future.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs.execution_logs IS 'An array of [log entries](https://sourcegraph.com/github.com/sourcegraph/sourcegraph@3.23/-/blob/internal/workerutil/store.go#L48:6) (encoded as JSON) from the most recent execution.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs.enqueuer_user_id IS 'ID of the user who scheduled this index. Records with a non-NULL user ID are prioritised over the rest';

CREATE TABLE syntactic_scip_indexing_jobs_audit_logs (
    sequence bigint NOT NULL,
    log_timestamp timestamp with time zone DEFAULT now() NOT NULL,
    record_deleted_at timestamp with time zone,
    job_id bigint NOT NULL,
    transition_columns hstore[] NOT NULL,
    reason text DEFAULT ''::text NOT NULL,
    operation audit_log_operation NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.log_timestamp IS 'Timestamp for this log entry.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.record_deleted_at IS 'Set once the indexing job this entry is associated with is deleted.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.transition_columns IS 'Array of changes that occurred to the indexing job for this entry, in the form of {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.reason IS 'The reason/source for this entry.';

CREATE SEQUENCE syntactic_scip_indexing_jobs_audit_logs_sequence_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE syntactic_scip_indexing_jobs_audit_logs_sequence_seq OWNED BY syntactic_scip_indexing_jobs_audit_logs.sequence;

CREATE SEQUENCE syntactic_scip_indexing_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE syntactic_scip_indexing_jobs_id_seq OWNED BY syntactic_scip_indexing_jobs.id;

CREATE VIEW syntactic_scip_indexing_jobs_with_repository_name WITH (security_invoker='true') AS
 SELECT u.id,
    u.commit,
    u.queued_at,
    u.state,
    u.failure_message,
    u.started_at,
    u.finished_at,
    u.repository_id,
    u.process_after,
    u.num_resets,
    u.num_failures,
    u.execution_logs,
    u.should_reindex,
    u.enqueuer_user_id,
    r.name AS repository_name,
    u.tenant_id
   FROM (syntactic_scip_indexing_jobs u
     JOIN repo r ON ((r.id = u.repository_id)))
  WHERE (r.deleted_at IS NULL);

CREATE TABLE syntactic_scip_last_index_scan (
    repository_id integer NOT NULL,
    last_index_scan_at timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE syntactic_scip_last_index_scan IS 'Tracks the last time repository was checked for syntactic indexing job scheduling.';

COMMENT ON COLUMN syntactic_scip_last_index_scan.last_index_scan_at IS 'The last time uploads of this repository were considered for syntactic indexing job scheduling.';

CREATE TABLE team_members (
    team_id integer NOT NULL,
    user_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE teams (
    id integer NOT NULL,
    name citext NOT NULL,
    display_name text,
    readonly boolean DEFAULT false NOT NULL,
    parent_team_id integer,
    creator_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT teams_display_name_max_length CHECK ((char_length(display_name) <= 255)),
    CONSTRAINT teams_name_max_length CHECK ((char_length((name)::text) <= 255)),
    CONSTRAINT teams_name_valid_chars CHECK ((name OPERATOR(~) '^[a-zA-Z0-9](?:[a-zA-Z0-9]|[-.](?=[a-zA-Z0-9]))*-?$'::citext))
);

CREATE SEQUENCE teams_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE teams_id_seq OWNED BY teams.id;

CREATE TABLE telemetry_events_export_queue (
    id uuid NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    payload_pb bytea NOT NULL,
    exported_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE TABLE temporary_settings (
    id integer NOT NULL,
    user_id integer NOT NULL,
    contents jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE temporary_settings IS 'Stores per-user temporary settings used in the UI, for example, which modals have been dimissed or what theme is preferred.';

COMMENT ON COLUMN temporary_settings.user_id IS 'The ID of the user the settings will be saved for.';

COMMENT ON COLUMN temporary_settings.contents IS 'JSON-encoded temporary settings.';

CREATE SEQUENCE temporary_settings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE temporary_settings_id_seq OWNED BY temporary_settings.id;

CREATE TABLE tenants (
    id bigint NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    workspace_id uuid NOT NULL,
    display_name text,
    state tenant_state DEFAULT 'active'::tenant_state NOT NULL,
    external_url text DEFAULT ''::text NOT NULL,
    redis_pruned_at timestamp with time zone,
    deleted_at timestamp with time zone,
    gitserver_pruned_at timestamp with time zone,
    zoekt_pruned_at timestamp with time zone,
    blobstore_pruned_at timestamp with time zone,
    database_pruned_at timestamp with time zone,
    searcher_cache_pruned_at timestamp with time zone,
    CONSTRAINT tenant_name_length CHECK (((char_length(name) <= 32) AND (char_length(name) >= 3))),
    CONSTRAINT tenant_name_valid_chars CHECK ((name ~ '^[a-z](?:[a-z0-9\_-])*[a-z0-9]$'::text)),
    CONSTRAINT tenants_external_url_check CHECK ((lower(external_url) = external_url))
);

COMMENT ON TABLE tenants IS 'The table that holds all tenants known to the instance. In enterprise instances, this table will only contain the "default" tenant.';

COMMENT ON COLUMN tenants.id IS 'The ID of the tenant. To keep tenants globally addressable, and be able to move them aronud instances more easily, the ID is NOT a serial and has to be specified explicitly. The creator of the tenant is responsible for choosing a unique ID, if it cares.';

COMMENT ON COLUMN tenants.name IS 'The name of the tenant. This may be displayed to the user and must be unique.';

COMMENT ON COLUMN tenants.workspace_id IS 'The ID in workspaces service of the tenant. This is used for identifying the link between tenant and workspace.';

COMMENT ON COLUMN tenants.display_name IS 'An optional display name for the tenant. This is used for rendering the tenant name in the UI.';

COMMENT ON COLUMN tenants.state IS 'The state of the tenant. Can be active, suspended, dormant or deleted.';

CREATE SEQUENCE tenants_id_seq
    AS integer
    START WITH 2
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE tenants_id_seq OWNED BY tenants.id;

CREATE VIEW tracking_changeset_specs_and_changesets WITH (security_invoker='true') AS
 SELECT changeset_specs.id AS changeset_spec_id,
    COALESCE(changesets.id, (0)::bigint) AS changeset_id,
    changeset_specs.repo_id,
    changeset_specs.batch_spec_id,
    repo.name AS repo_name,
    COALESCE((changesets.metadata ->> 'Title'::text), (changesets.metadata ->> 'title'::text)) AS changeset_name,
    changesets.external_state,
    changesets.publication_state,
    changesets.reconciler_state,
    changesets.computed_state
   FROM ((changeset_specs
     LEFT JOIN changesets ON (((changesets.repo_id = changeset_specs.repo_id) AND (changesets.external_id = changeset_specs.external_id))))
     JOIN repo ON ((changeset_specs.repo_id = repo.id)))
  WHERE ((changeset_specs.external_id IS NOT NULL) AND (repo.deleted_at IS NULL));

CREATE TABLE user_credentials (
    id bigint NOT NULL,
    domain text NOT NULL,
    user_id integer NOT NULL,
    external_service_type text NOT NULL,
    external_service_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    credential bytea NOT NULL,
    ssh_migration_applied boolean DEFAULT false NOT NULL,
    encryption_key_id text DEFAULT ''::text NOT NULL,
    github_app_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT check_github_app_id_and_external_service_type_user_credentials CHECK (((github_app_id IS NULL) OR (external_service_type = 'github'::text)))
);

CREATE SEQUENCE user_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_credentials_id_seq OWNED BY user_credentials.id;

CREATE TABLE user_emails (
    user_id integer NOT NULL,
    email citext NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    verification_code text,
    verified_at timestamp with time zone,
    last_verification_sent_at timestamp with time zone,
    is_primary boolean DEFAULT false NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    deleted_at timestamp with time zone,
    id bigint NOT NULL
);

CREATE SEQUENCE user_emails_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_emails_id_seq OWNED BY user_emails.id;

CREATE TABLE user_external_accounts (
    id integer NOT NULL,
    user_id integer NOT NULL,
    service_type text NOT NULL,
    service_id text NOT NULL,
    account_id text NOT NULL,
    auth_data text,
    account_data text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_id text NOT NULL,
    expired_at timestamp with time zone,
    last_valid_at timestamp with time zone,
    encryption_key_id text DEFAULT ''::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE user_external_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_external_accounts_id_seq OWNED BY user_external_accounts.id;

CREATE TABLE user_onboarding_tour (
    id integer NOT NULL,
    raw_json text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_by integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE user_onboarding_tour_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_onboarding_tour_id_seq OWNED BY user_onboarding_tour.id;

CREATE VIEW user_relevant_repos WITH (security_invoker='true') AS
 SELECT u.id AS user_id,
    cd.repo_id,
    max(cd.last_commit_date) AS last_commit_date,
    sum(cd.number_of_commits) AS number_of_commits
   FROM ((users u
     JOIN user_emails ue ON (((u.id = ue.user_id) AND (ue.verified_at IS NOT NULL) AND (ue.deleted_at IS NULL))))
     JOIN contributor_data cd ON ((((ue.email)::bytea = cd.author_email) OR ((u.display_name)::bytea = cd.author_name))))
  GROUP BY u.id, cd.repo_id
  ORDER BY u.id, (max(cd.last_commit_date)) DESC;

COMMENT ON VIEW user_relevant_repos IS '
An aggregation of repos a user has contributed to.

This is generated from commit data on the default branch of each repo,
and uses email address or display name to link git users to Sourcegraph users.
';

CREATE TABLE user_repo_permissions (
    id bigint NOT NULL,
    user_id integer,
    repo_id integer NOT NULL,
    user_external_account_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    source text DEFAULT 'sync'::text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE user_repo_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_repo_permissions_id_seq OWNED BY user_repo_permissions.id;

CREATE TABLE user_roles (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE users_id_seq OWNED BY users.id;

CREATE TABLE versions (
    service text NOT NULL,
    version text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    first_version text NOT NULL,
    auto_upgrade boolean DEFAULT false NOT NULL
);

CREATE TABLE vulnerabilities (
    id integer NOT NULL,
    source_id text NOT NULL,
    summary text NOT NULL,
    details text NOT NULL,
    cpes text[] NOT NULL,
    cwes text[] NOT NULL,
    aliases text[] NOT NULL,
    related text[] NOT NULL,
    data_source text NOT NULL,
    urls text[] NOT NULL,
    severity text NOT NULL,
    cvss_vector text NOT NULL,
    cvss_score text NOT NULL,
    published_at timestamp with time zone NOT NULL,
    modified_at timestamp with time zone,
    withdrawn_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE vulnerabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE vulnerabilities_id_seq OWNED BY vulnerabilities.id;

CREATE TABLE vulnerability_affected_packages (
    id integer NOT NULL,
    vulnerability_id integer NOT NULL,
    package_name text NOT NULL,
    language text NOT NULL,
    namespace text NOT NULL,
    version_constraint text[] NOT NULL,
    fixed boolean NOT NULL,
    fixed_in text,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE vulnerability_affected_packages_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE vulnerability_affected_packages_id_seq OWNED BY vulnerability_affected_packages.id;

CREATE TABLE vulnerability_affected_symbols (
    id integer NOT NULL,
    vulnerability_affected_package_id integer NOT NULL,
    path text NOT NULL,
    symbols text[] NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE vulnerability_affected_symbols_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE vulnerability_affected_symbols_id_seq OWNED BY vulnerability_affected_symbols.id;

CREATE TABLE vulnerability_matches (
    id integer NOT NULL,
    upload_id integer NOT NULL,
    vulnerability_affected_package_id integer NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE vulnerability_matches_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE vulnerability_matches_id_seq OWNED BY vulnerability_matches.id;

CREATE TABLE webhook_logs (
    id bigint NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    external_service_id integer,
    status_code integer NOT NULL,
    request bytea NOT NULL,
    response bytea NOT NULL,
    encryption_key_id text NOT NULL,
    webhook_id integer,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE webhook_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE webhook_logs_id_seq OWNED BY webhook_logs.id;

CREATE TABLE webhooks (
    id integer NOT NULL,
    code_host_kind text NOT NULL,
    code_host_urn text NOT NULL,
    secret text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    encryption_key_id text,
    uuid uuid DEFAULT gen_random_uuid() NOT NULL,
    created_by_user_id integer,
    updated_by_user_id integer,
    name text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE webhooks IS 'Webhooks registered in Sourcegraph instance.';

COMMENT ON COLUMN webhooks.code_host_kind IS 'Kind of an external service for which webhooks are registered.';

COMMENT ON COLUMN webhooks.code_host_urn IS 'URN of a code host. This column maps to external_service_id column of repo table.';

COMMENT ON COLUMN webhooks.secret IS 'Secret used to decrypt webhook payload (if supported by the code host).';

COMMENT ON COLUMN webhooks.created_by_user_id IS 'ID of a user, who created the webhook. If NULL, then the user does not exist (never existed or was deleted).';

COMMENT ON COLUMN webhooks.updated_by_user_id IS 'ID of a user, who updated the webhook. If NULL, then the user does not exist (never existed or was deleted).';

COMMENT ON COLUMN webhooks.name IS 'Descriptive name of a webhook.';

CREATE SEQUENCE webhooks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE webhooks_id_seq OWNED BY webhooks.id;

CREATE TABLE zoekt_index_jobs (
    id bigint NOT NULL,
    state text DEFAULT 'queued'::text NOT NULL,
    failure_message text,
    queued_at timestamp with time zone DEFAULT now() NOT NULL,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    process_after timestamp with time zone,
    num_resets integer DEFAULT 0 NOT NULL,
    num_failures integer DEFAULT 0 NOT NULL,
    last_heartbeat_at timestamp with time zone,
    execution_logs json[],
    worker_hostname text DEFAULT ''::text NOT NULL,
    cancel boolean DEFAULT false NOT NULL,
    repository_id integer NOT NULL,
    priority integer DEFAULT 1 NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

CREATE SEQUENCE zoekt_index_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE zoekt_index_jobs_id_seq OWNED BY zoekt_index_jobs.id;

CREATE TABLE zoekt_repos (
    repo_id integer NOT NULL,
    branches jsonb DEFAULT '[]'::jsonb NOT NULL,
    index_status text DEFAULT 'not_indexed'::text NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_indexed_at timestamp with time zone,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    last_index_attempt_at timestamp with time zone,
    failed_index_attempts integer DEFAULT 0 NOT NULL
);

ALTER TABLE ONLY access_requests ALTER COLUMN id SET DEFAULT nextval('access_requests_id_seq'::regclass);

ALTER TABLE ONLY access_tokens ALTER COLUMN id SET DEFAULT nextval('access_tokens_id_seq'::regclass);

ALTER TABLE ONLY assigned_owners ALTER COLUMN id SET DEFAULT nextval('assigned_owners_id_seq'::regclass);

ALTER TABLE ONLY assigned_teams ALTER COLUMN id SET DEFAULT nextval('assigned_teams_id_seq'::regclass);

ALTER TABLE ONLY batch_changes ALTER COLUMN id SET DEFAULT nextval('batch_changes_id_seq'::regclass);

ALTER TABLE ONLY batch_changes_site_credentials ALTER COLUMN id SET DEFAULT nextval('batch_changes_site_credentials_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_execution_cache_entries ALTER COLUMN id SET DEFAULT nextval('batch_spec_execution_cache_entries_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_library_records ALTER COLUMN id SET DEFAULT nextval('batch_spec_library_records_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_library_variables ALTER COLUMN id SET DEFAULT nextval('batch_spec_library_variables_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_resolution_jobs ALTER COLUMN id SET DEFAULT nextval('batch_spec_resolution_jobs_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_workspace_execution_jobs ALTER COLUMN id SET DEFAULT nextval('batch_spec_workspace_execution_jobs_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_workspace_files ALTER COLUMN id SET DEFAULT nextval('batch_spec_workspace_files_id_seq'::regclass);

ALTER TABLE ONLY batch_spec_workspaces ALTER COLUMN id SET DEFAULT nextval('batch_spec_workspaces_id_seq'::regclass);

ALTER TABLE ONLY batch_specs ALTER COLUMN id SET DEFAULT nextval('batch_specs_id_seq'::regclass);

ALTER TABLE ONLY cached_available_indexers ALTER COLUMN id SET DEFAULT nextval('cached_available_indexers_id_seq'::regclass);

ALTER TABLE ONLY changeset_events ALTER COLUMN id SET DEFAULT nextval('changeset_events_id_seq'::regclass);

ALTER TABLE ONLY changeset_jobs ALTER COLUMN id SET DEFAULT nextval('changeset_jobs_id_seq'::regclass);

ALTER TABLE ONLY changeset_specs ALTER COLUMN id SET DEFAULT nextval('changeset_specs_id_seq'::regclass);

ALTER TABLE ONLY changeset_sync_jobs ALTER COLUMN id SET DEFAULT nextval('changeset_sync_jobs_id_seq'::regclass);

ALTER TABLE ONLY changesets ALTER COLUMN id SET DEFAULT nextval('changesets_id_seq'::regclass);

ALTER TABLE ONLY cm_action_jobs ALTER COLUMN id SET DEFAULT nextval('cm_action_jobs_id_seq'::regclass);

ALTER TABLE ONLY cm_emails ALTER COLUMN id SET DEFAULT nextval('cm_emails_id_seq'::regclass);

ALTER TABLE ONLY cm_monitors ALTER COLUMN id SET DEFAULT nextval('cm_monitors_id_seq'::regclass);

ALTER TABLE ONLY cm_queries ALTER COLUMN id SET DEFAULT nextval('cm_queries_id_seq'::regclass);

ALTER TABLE ONLY cm_recipients ALTER COLUMN id SET DEFAULT nextval('cm_recipients_id_seq'::regclass);

ALTER TABLE ONLY cm_slack_webhooks ALTER COLUMN id SET DEFAULT nextval('cm_slack_webhooks_id_seq'::regclass);

ALTER TABLE ONLY cm_trigger_jobs ALTER COLUMN id SET DEFAULT nextval('cm_trigger_jobs_id_seq'::regclass);

ALTER TABLE ONLY cm_webhooks ALTER COLUMN id SET DEFAULT nextval('cm_webhooks_id_seq'::regclass);

ALTER TABLE ONLY code_hosts ALTER COLUMN id SET DEFAULT nextval('code_hosts_id_seq'::regclass);

ALTER TABLE ONLY codeintel_autoindex_queue ALTER COLUMN id SET DEFAULT nextval('codeintel_autoindex_queue_id_seq'::regclass);

ALTER TABLE ONLY codeintel_autoindexing_exceptions ALTER COLUMN id SET DEFAULT nextval('codeintel_autoindexing_exceptions_id_seq'::regclass);

ALTER TABLE ONLY codeintel_inference_scripts ALTER COLUMN id SET DEFAULT nextval('codeintel_inference_scripts_id_seq'::regclass);

ALTER TABLE ONLY codeintel_langugage_support_requests ALTER COLUMN id SET DEFAULT nextval('codeintel_langugage_support_requests_id_seq'::regclass);

ALTER TABLE ONLY codeowners ALTER COLUMN id SET DEFAULT nextval('codeowners_id_seq'::regclass);

ALTER TABLE ONLY codeowners_owners ALTER COLUMN id SET DEFAULT nextval('codeowners_owners_id_seq'::regclass);

ALTER TABLE ONLY cody_audit_log ALTER COLUMN id SET DEFAULT nextval('cody_audit_log_id_seq'::regclass);

ALTER TABLE ONLY commit_authors ALTER COLUMN id SET DEFAULT nextval('commit_authors_id_seq'::regclass);

ALTER TABLE ONLY completion_credits_consumption ALTER COLUMN id SET DEFAULT nextval('completion_credits_consumption_id_seq'::regclass);

ALTER TABLE ONLY configuration_policies_audit_logs ALTER COLUMN sequence SET DEFAULT nextval('configuration_policies_audit_logs_seq'::regclass);

ALTER TABLE ONLY configuration_policies_audit_logs ALTER COLUMN id SET DEFAULT nextval('configuration_policies_audit_logs_id_seq'::regclass);

ALTER TABLE ONLY context_detection_embedding_jobs ALTER COLUMN id SET DEFAULT nextval('context_detection_embedding_jobs_id_seq'::regclass);

ALTER TABLE ONLY contributor_jobs ALTER COLUMN id SET DEFAULT nextval('contributor_jobs_id_seq'::regclass);

ALTER TABLE ONLY critical_and_site_config ALTER COLUMN id SET DEFAULT nextval('critical_and_site_config_id_seq'::regclass);

ALTER TABLE ONLY deepsearch_conversations ALTER COLUMN id SET DEFAULT nextval('deepsearch_conversations_id_seq'::regclass);

ALTER TABLE ONLY deepsearch_questions ALTER COLUMN id SET DEFAULT nextval('deepsearch_questions_id_seq'::regclass);

ALTER TABLE ONLY deepsearch_quota ALTER COLUMN id SET DEFAULT nextval('deepsearch_quota_id_seq'::regclass);

ALTER TABLE ONLY deepsearch_references ALTER COLUMN id SET DEFAULT nextval('deepsearch_references_id_seq'::regclass);

ALTER TABLE ONLY entitlements ALTER COLUMN id SET DEFAULT nextval('entitlements_id_seq'::regclass);

ALTER TABLE ONLY event_logs ALTER COLUMN id SET DEFAULT nextval('event_logs_id_seq'::regclass);

ALTER TABLE ONLY event_logs_scrape_state ALTER COLUMN id SET DEFAULT nextval('event_logs_scrape_state_id_seq'::regclass);

ALTER TABLE ONLY event_logs_scrape_state_own ALTER COLUMN id SET DEFAULT nextval('event_logs_scrape_state_own_id_seq'::regclass);

ALTER TABLE ONLY executor_heartbeats ALTER COLUMN id SET DEFAULT nextval('executor_heartbeats_id_seq'::regclass);

ALTER TABLE ONLY executor_job_tokens ALTER COLUMN id SET DEFAULT nextval('executor_job_tokens_id_seq'::regclass);

ALTER TABLE ONLY executor_secret_access_logs ALTER COLUMN id SET DEFAULT nextval('executor_secret_access_logs_id_seq'::regclass);

ALTER TABLE ONLY executor_secrets ALTER COLUMN id SET DEFAULT nextval('executor_secrets_id_seq'::regclass);

ALTER TABLE ONLY exhaustive_search_jobs ALTER COLUMN id SET DEFAULT nextval('exhaustive_search_jobs_id_seq'::regclass);

ALTER TABLE ONLY exhaustive_search_repo_jobs ALTER COLUMN id SET DEFAULT nextval('exhaustive_search_repo_jobs_id_seq'::regclass);

ALTER TABLE ONLY exhaustive_search_repo_revision_jobs ALTER COLUMN id SET DEFAULT nextval('exhaustive_search_repo_revision_jobs_id_seq'::regclass);

ALTER TABLE ONLY explicit_permissions_bitbucket_projects_jobs ALTER COLUMN id SET DEFAULT nextval('explicit_permissions_bitbucket_projects_jobs_id_seq'::regclass);

ALTER TABLE ONLY external_services ALTER COLUMN id SET DEFAULT nextval('external_services_id_seq'::regclass);

ALTER TABLE ONLY feature_flag_overrides ALTER COLUMN id SET DEFAULT nextval('feature_flag_overrides_id_seq'::regclass);

ALTER TABLE ONLY github_app_installs ALTER COLUMN id SET DEFAULT nextval('github_app_installs_id_seq'::regclass);

ALTER TABLE ONLY github_apps ALTER COLUMN id SET DEFAULT nextval('github_apps_id_seq'::regclass);

ALTER TABLE ONLY gitserver_relocator_jobs ALTER COLUMN id SET DEFAULT nextval('gitserver_relocator_jobs_id_seq'::regclass);

ALTER TABLE ONLY global_state ALTER COLUMN id SET DEFAULT nextval('global_state_id_seq'::regclass);

ALTER TABLE ONLY idp_authorize_codes ALTER COLUMN id SET DEFAULT nextval('idp_authorize_codes_id_seq'::regclass);

ALTER TABLE ONLY idp_clients ALTER COLUMN id SET DEFAULT nextval('idp_clients_id_seq'::regclass);

ALTER TABLE ONLY idp_consent_requests ALTER COLUMN id SET DEFAULT nextval('idp_consent_requests_id_seq'::regclass);

ALTER TABLE ONLY idp_device_auth_requests ALTER COLUMN id SET DEFAULT nextval('idp_device_auth_requests_id_seq'::regclass);

ALTER TABLE ONLY idp_id_tokens ALTER COLUMN id SET DEFAULT nextval('idp_id_tokens_id_seq'::regclass);

ALTER TABLE ONLY idp_oauth_apps ALTER COLUMN id SET DEFAULT nextval('idp_oauth_apps_id_seq'::regclass);

ALTER TABLE ONLY idp_pkce_requests ALTER COLUMN id SET DEFAULT nextval('idp_pkce_requests_id_seq'::regclass);

ALTER TABLE ONLY idp_secrets ALTER COLUMN id SET DEFAULT nextval('idp_secrets_id_seq'::regclass);

ALTER TABLE ONLY idp_service_account_m2m_clients ALTER COLUMN id SET DEFAULT nextval('idp_service_account_m2m_clients_id_seq'::regclass);

ALTER TABLE ONLY idp_sessions ALTER COLUMN id SET DEFAULT nextval('idp_sessions_id_seq'::regclass);

ALTER TABLE ONLY idp_tokens ALTER COLUMN id SET DEFAULT nextval('idp_tokens_id_seq'::regclass);

ALTER TABLE ONLY idp_user_consents ALTER COLUMN id SET DEFAULT nextval('idp_user_consents_id_seq'::regclass);

ALTER TABLE ONLY insights_query_runner_jobs ALTER COLUMN id SET DEFAULT nextval('insights_query_runner_jobs_id_seq'::regclass);

ALTER TABLE ONLY insights_query_runner_jobs_dependencies ALTER COLUMN id SET DEFAULT nextval('insights_query_runner_jobs_dependencies_id_seq'::regclass);

ALTER TABLE ONLY insights_settings_migration_jobs ALTER COLUMN id SET DEFAULT nextval('insights_settings_migration_jobs_id_seq'::regclass);

ALTER TABLE ONLY lsif_configuration_policies ALTER COLUMN id SET DEFAULT nextval('lsif_configuration_policies_id_seq'::regclass);

ALTER TABLE ONLY lsif_dependency_indexing_jobs ALTER COLUMN id SET DEFAULT nextval('lsif_dependency_indexing_jobs_id_seq1'::regclass);

ALTER TABLE ONLY lsif_dependency_repos ALTER COLUMN id SET DEFAULT nextval('lsif_dependency_repos_id_seq'::regclass);

ALTER TABLE ONLY lsif_dependency_syncing_jobs ALTER COLUMN id SET DEFAULT nextval('lsif_dependency_indexing_jobs_id_seq'::regclass);

ALTER TABLE ONLY lsif_index_configuration ALTER COLUMN id SET DEFAULT nextval('lsif_index_configuration_id_seq'::regclass);

ALTER TABLE ONLY lsif_indexes ALTER COLUMN id SET DEFAULT nextval('lsif_indexes_id_seq'::regclass);

ALTER TABLE ONLY lsif_packages ALTER COLUMN id SET DEFAULT nextval('lsif_packages_id_seq'::regclass);

ALTER TABLE ONLY lsif_references ALTER COLUMN id SET DEFAULT nextval('lsif_references_id_seq'::regclass);

ALTER TABLE ONLY lsif_retention_configuration ALTER COLUMN id SET DEFAULT nextval('lsif_retention_configuration_id_seq'::regclass);

ALTER TABLE ONLY namespace_permissions ALTER COLUMN id SET DEFAULT nextval('namespace_permissions_id_seq'::regclass);

ALTER TABLE ONLY notebooks ALTER COLUMN id SET DEFAULT nextval('notebooks_id_seq'::regclass);

ALTER TABLE ONLY org_invitations ALTER COLUMN id SET DEFAULT nextval('org_invitations_id_seq'::regclass);

ALTER TABLE ONLY org_members ALTER COLUMN id SET DEFAULT nextval('org_members_id_seq'::regclass);

ALTER TABLE ONLY orgs ALTER COLUMN id SET DEFAULT nextval('orgs_id_seq'::regclass);

ALTER TABLE ONLY out_of_band_migrations ALTER COLUMN id SET DEFAULT nextval('out_of_band_migrations_id_seq'::regclass);

ALTER TABLE ONLY out_of_band_migrations_errors ALTER COLUMN id SET DEFAULT nextval('out_of_band_migrations_errors_id_seq'::regclass);

ALTER TABLE ONLY outbound_webhook_event_types ALTER COLUMN id SET DEFAULT nextval('outbound_webhook_event_types_id_seq'::regclass);

ALTER TABLE ONLY outbound_webhook_jobs ALTER COLUMN id SET DEFAULT nextval('outbound_webhook_jobs_id_seq'::regclass);

ALTER TABLE ONLY outbound_webhook_logs ALTER COLUMN id SET DEFAULT nextval('outbound_webhook_logs_id_seq'::regclass);

ALTER TABLE ONLY outbound_webhooks ALTER COLUMN id SET DEFAULT nextval('outbound_webhooks_id_seq'::regclass);

ALTER TABLE ONLY own_aggregate_recent_contribution ALTER COLUMN id SET DEFAULT nextval('own_aggregate_recent_contribution_id_seq'::regclass);

ALTER TABLE ONLY own_aggregate_recent_view ALTER COLUMN id SET DEFAULT nextval('own_aggregate_recent_view_id_seq'::regclass);

ALTER TABLE ONLY own_background_jobs ALTER COLUMN id SET DEFAULT nextval('own_background_jobs_id_seq'::regclass);

ALTER TABLE ONLY own_signal_configurations ALTER COLUMN id SET DEFAULT nextval('own_signal_configurations_id_seq'::regclass);

ALTER TABLE ONLY own_signal_recent_contribution ALTER COLUMN id SET DEFAULT nextval('own_signal_recent_contribution_id_seq'::regclass);

ALTER TABLE ONLY package_repo_filters ALTER COLUMN id SET DEFAULT nextval('package_repo_filters_id_seq'::regclass);

ALTER TABLE ONLY package_repo_versions ALTER COLUMN id SET DEFAULT nextval('package_repo_versions_id_seq'::regclass);

ALTER TABLE ONLY pending_repo_permissions ALTER COLUMN id SET DEFAULT nextval('pending_repo_permissions_id_seq'::regclass);

ALTER TABLE ONLY permission_sync_jobs ALTER COLUMN id SET DEFAULT nextval('permission_sync_jobs_id_seq'::regclass);

ALTER TABLE ONLY permissions ALTER COLUMN id SET DEFAULT nextval('permissions_id_seq'::regclass);

ALTER TABLE ONLY phabricator_repos ALTER COLUMN id SET DEFAULT nextval('phabricator_repos_id_seq'::regclass);

ALTER TABLE ONLY prompt_tags ALTER COLUMN id SET DEFAULT nextval('prompt_tags_id_seq'::regclass);

ALTER TABLE ONLY prompts ALTER COLUMN id SET DEFAULT nextval('prompts_id_seq'::regclass);

ALTER TABLE ONLY registry_extension_releases ALTER COLUMN id SET DEFAULT nextval('registry_extension_releases_id_seq'::regclass);

ALTER TABLE ONLY registry_extensions ALTER COLUMN id SET DEFAULT nextval('registry_extensions_id_seq'::regclass);

ALTER TABLE ONLY repo ALTER COLUMN id SET DEFAULT nextval('repo_id_seq'::regclass);

ALTER TABLE ONLY repo_cleanup_jobs ALTER COLUMN id SET DEFAULT nextval('repo_cleanup_jobs_id_seq'::regclass);

ALTER TABLE ONLY repo_commits_changelists ALTER COLUMN id SET DEFAULT nextval('repo_commits_changelists_id_seq'::regclass);

ALTER TABLE ONLY repo_embedding_jobs ALTER COLUMN id SET DEFAULT nextval('repo_embedding_jobs_id_seq'::regclass);

ALTER TABLE ONLY repo_paths ALTER COLUMN id SET DEFAULT nextval('repo_paths_id_seq'::regclass);

ALTER TABLE ONLY repo_statistics ALTER COLUMN id SET DEFAULT nextval('repo_statistics_id_seq'::regclass);

ALTER TABLE ONLY repo_update_jobs ALTER COLUMN id SET DEFAULT nextval('repo_update_jobs_id_seq'::regclass);

ALTER TABLE ONLY roles ALTER COLUMN id SET DEFAULT nextval('roles_id_seq'::regclass);

ALTER TABLE ONLY saved_searches ALTER COLUMN id SET DEFAULT nextval('saved_searches_id_seq'::regclass);

ALTER TABLE ONLY scip_nearest_uploads ALTER COLUMN id SET DEFAULT nextval('scip_nearest_uploads_id_seq'::regclass);

ALTER TABLE ONLY scip_nearest_uploads_links ALTER COLUMN id SET DEFAULT nextval('scip_nearest_uploads_links_id_seq'::regclass);

ALTER TABLE ONLY scip_uploads ALTER COLUMN id SET DEFAULT nextval('scip_uploads_id_seq'::regclass);

ALTER TABLE ONLY scip_uploads_audit_logs ALTER COLUMN sequence SET DEFAULT nextval('scip_uploads_audit_logs_seq'::regclass);

ALTER TABLE ONLY scip_uploads_visible_at_tip ALTER COLUMN id SET DEFAULT nextval('scip_uploads_visible_at_tip_id_seq'::regclass);

ALTER TABLE ONLY scip_uploads_vulnerability_scan ALTER COLUMN id SET DEFAULT nextval('scip_uploads_vulnerability_scan_id_seq'::regclass);

ALTER TABLE ONLY search_contexts ALTER COLUMN id SET DEFAULT nextval('search_contexts_id_seq'::regclass);

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);

ALTER TABLE ONLY survey_responses ALTER COLUMN id SET DEFAULT nextval('survey_responses_id_seq'::regclass);

ALTER TABLE ONLY syntactic_scip_indexing_jobs ALTER COLUMN id SET DEFAULT nextval('syntactic_scip_indexing_jobs_id_seq'::regclass);

ALTER TABLE ONLY syntactic_scip_indexing_jobs_audit_logs ALTER COLUMN sequence SET DEFAULT nextval('syntactic_scip_indexing_jobs_audit_logs_sequence_seq'::regclass);

ALTER TABLE ONLY teams ALTER COLUMN id SET DEFAULT nextval('teams_id_seq'::regclass);

ALTER TABLE ONLY temporary_settings ALTER COLUMN id SET DEFAULT nextval('temporary_settings_id_seq'::regclass);

ALTER TABLE ONLY tenants ALTER COLUMN id SET DEFAULT nextval('tenants_id_seq'::regclass);

ALTER TABLE ONLY user_credentials ALTER COLUMN id SET DEFAULT nextval('user_credentials_id_seq'::regclass);

ALTER TABLE ONLY user_emails ALTER COLUMN id SET DEFAULT nextval('user_emails_id_seq'::regclass);

ALTER TABLE ONLY user_external_accounts ALTER COLUMN id SET DEFAULT nextval('user_external_accounts_id_seq'::regclass);

ALTER TABLE ONLY user_onboarding_tour ALTER COLUMN id SET DEFAULT nextval('user_onboarding_tour_id_seq'::regclass);

ALTER TABLE ONLY user_repo_permissions ALTER COLUMN id SET DEFAULT nextval('user_repo_permissions_id_seq'::regclass);

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);

ALTER TABLE ONLY vulnerabilities ALTER COLUMN id SET DEFAULT nextval('vulnerabilities_id_seq'::regclass);

ALTER TABLE ONLY vulnerability_affected_packages ALTER COLUMN id SET DEFAULT nextval('vulnerability_affected_packages_id_seq'::regclass);

ALTER TABLE ONLY vulnerability_affected_symbols ALTER COLUMN id SET DEFAULT nextval('vulnerability_affected_symbols_id_seq'::regclass);

ALTER TABLE ONLY vulnerability_matches ALTER COLUMN id SET DEFAULT nextval('vulnerability_matches_id_seq'::regclass);

ALTER TABLE ONLY webhook_logs ALTER COLUMN id SET DEFAULT nextval('webhook_logs_id_seq'::regclass);

ALTER TABLE ONLY webhooks ALTER COLUMN id SET DEFAULT nextval('webhooks_id_seq'::regclass);

ALTER TABLE ONLY zoekt_index_jobs ALTER COLUMN id SET DEFAULT nextval('zoekt_index_jobs_id_seq'::regclass);

ALTER TABLE ONLY access_requests
    ADD CONSTRAINT access_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_value_sha256_key UNIQUE (value_sha256, tenant_id);

ALTER TABLE ONLY aggregated_user_statistics
    ADD CONSTRAINT aggregated_user_statistics_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY assigned_owners
    ADD CONSTRAINT assigned_owners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY assigned_teams
    ADD CONSTRAINT assigned_teams_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_changes_site_credentials
    ADD CONSTRAINT batch_changes_site_credentials_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_execution_cache_entries
    ADD CONSTRAINT batch_spec_execution_cache_entries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_execution_cache_entries
    ADD CONSTRAINT batch_spec_execution_cache_entries_user_id_key_unique UNIQUE (user_id, key);

ALTER TABLE ONLY batch_spec_library_records
    ADD CONSTRAINT batch_spec_library_records_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_library_variables
    ADD CONSTRAINT batch_spec_library_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_library_variables
    ADD CONSTRAINT batch_spec_library_variables_record_name_unique UNIQUE (batch_spec_library_record_id, name);

ALTER TABLE ONLY batch_spec_resolution_jobs
    ADD CONSTRAINT batch_spec_resolution_jobs_batch_spec_id_unique UNIQUE (batch_spec_id);

ALTER TABLE ONLY batch_spec_resolution_jobs
    ADD CONSTRAINT batch_spec_resolution_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_workspace_execution_jobs
    ADD CONSTRAINT batch_spec_workspace_execution_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_workspace_execution_last_dequeues
    ADD CONSTRAINT batch_spec_workspace_execution_last_dequeues_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY batch_spec_workspace_files
    ADD CONSTRAINT batch_spec_workspace_files_batch_spec_id_filename_path UNIQUE (batch_spec_id, filename, path);

ALTER TABLE ONLY batch_spec_workspace_files
    ADD CONSTRAINT batch_spec_workspace_files_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_spec_workspaces
    ADD CONSTRAINT batch_spec_workspaces_pkey PRIMARY KEY (id);

ALTER TABLE ONLY batch_specs
    ADD CONSTRAINT batch_specs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cached_available_indexers
    ADD CONSTRAINT cached_available_indexers_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cached_available_indexers
    ADD CONSTRAINT cached_available_indexers_repository_id UNIQUE (repository_id);

ALTER TABLE ONLY changeset_events
    ADD CONSTRAINT changeset_events_changeset_id_kind_key_unique UNIQUE (changeset_id, kind, key);

ALTER TABLE ONLY changeset_events
    ADD CONSTRAINT changeset_events_pkey PRIMARY KEY (id);

ALTER TABLE ONLY changeset_jobs
    ADD CONSTRAINT changeset_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY changeset_sync_jobs
    ADD CONSTRAINT changeset_sync_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_pkey PRIMARY KEY (id);

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_repo_external_id_unique UNIQUE (repo_id, external_id);

ALTER TABLE ONLY cm_action_jobs
    ADD CONSTRAINT cm_action_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_emails
    ADD CONSTRAINT cm_emails_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_last_searched
    ADD CONSTRAINT cm_last_searched_pkey PRIMARY KEY (monitor_id, repo_id);

ALTER TABLE ONLY cm_monitors
    ADD CONSTRAINT cm_monitors_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_queries
    ADD CONSTRAINT cm_queries_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_recipients
    ADD CONSTRAINT cm_recipients_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_slack_webhooks
    ADD CONSTRAINT cm_slack_webhooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_trigger_jobs
    ADD CONSTRAINT cm_trigger_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY cm_webhooks
    ADD CONSTRAINT cm_webhooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY code_hosts
    ADD CONSTRAINT code_hosts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY code_hosts
    ADD CONSTRAINT code_hosts_url_key UNIQUE (url, tenant_id);

ALTER TABLE ONLY codeintel_autoindex_queue
    ADD CONSTRAINT codeintel_autoindex_queue_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_autoindexing_exceptions
    ADD CONSTRAINT codeintel_autoindexing_exceptions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_autoindexing_exceptions
    ADD CONSTRAINT codeintel_autoindexing_exceptions_repository_id_key UNIQUE (repository_id);

ALTER TABLE ONLY codeintel_commit_dates
    ADD CONSTRAINT codeintel_commit_dates_pkey PRIMARY KEY (repository_id, commit_bytea);

ALTER TABLE ONLY codeintel_inference_scripts
    ADD CONSTRAINT codeintel_inference_scripts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeintel_langugage_support_requests
    ADD CONSTRAINT codeintel_langugage_support_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeowners_individual_stats
    ADD CONSTRAINT codeowners_individual_stats_pkey PRIMARY KEY (file_path_id, owner_id);

ALTER TABLE ONLY codeowners_owners
    ADD CONSTRAINT codeowners_owners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeowners
    ADD CONSTRAINT codeowners_pkey PRIMARY KEY (id);

ALTER TABLE ONLY codeowners
    ADD CONSTRAINT codeowners_repo_id_key UNIQUE (repo_id);

ALTER TABLE ONLY cody_audit_log
    ADD CONSTRAINT cody_audit_log_pkey PRIMARY KEY (id);

ALTER TABLE ONLY commit_authors
    ADD CONSTRAINT commit_authors_email_name UNIQUE (email, name, tenant_id);

ALTER TABLE ONLY commit_authors
    ADD CONSTRAINT commit_authors_pkey PRIMARY KEY (id);

ALTER TABLE ONLY completion_credits_consumption
    ADD CONSTRAINT completion_credits_consumption_pkey PRIMARY KEY (id);

ALTER TABLE ONLY completion_credits_entitlement_window_usage
    ADD CONSTRAINT completion_credits_entitlement_window_usage_pkey PRIMARY KEY (user_id, entitlement_id);

ALTER TABLE ONLY configuration_policies_audit_logs
    ADD CONSTRAINT configuration_policies_audit_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY context_detection_embedding_jobs
    ADD CONSTRAINT context_detection_embedding_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY contributor_data
    ADD CONSTRAINT contributor_data_pkey PRIMARY KEY (author_email, author_name, repo_id);

ALTER TABLE ONLY contributor_jobs
    ADD CONSTRAINT contributor_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY contributor_repos
    ADD CONSTRAINT contributor_repos_pkey PRIMARY KEY (tenant_id, repo_id);

ALTER TABLE ONLY critical_and_site_config
    ADD CONSTRAINT critical_and_site_config_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deepsearch_conversations
    ADD CONSTRAINT deepsearch_conversations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deepsearch_questions
    ADD CONSTRAINT deepsearch_questions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deepsearch_quota
    ADD CONSTRAINT deepsearch_quota_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deepsearch_quota
    ADD CONSTRAINT deepsearch_quota_user_id_key UNIQUE (user_id);

ALTER TABLE ONLY deepsearch_references
    ADD CONSTRAINT deepsearch_references_pkey PRIMARY KEY (id);

ALTER TABLE ONLY deepsearch_references
    ADD CONSTRAINT deepsearch_references_repo_filepath_unique UNIQUE (conversation_id, repo_id, file_path);

ALTER TABLE ONLY entitlement_grants
    ADD CONSTRAINT entitlement_grants_pkey PRIMARY KEY (entitlement_id, user_id);

ALTER TABLE ONLY entitlements
    ADD CONSTRAINT entitlements_name_type_tenant_unique UNIQUE (name, type, tenant_id);

ALTER TABLE ONLY entitlements
    ADD CONSTRAINT entitlements_pkey PRIMARY KEY (id);

ALTER TABLE ONLY event_logs
    ADD CONSTRAINT event_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY event_logs_scrape_state_own
    ADD CONSTRAINT event_logs_scrape_state_own_pk PRIMARY KEY (id);

ALTER TABLE ONLY event_logs_scrape_state
    ADD CONSTRAINT event_logs_scrape_state_pk PRIMARY KEY (id);

ALTER TABLE ONLY executor_heartbeats
    ADD CONSTRAINT executor_heartbeats_hostname_key UNIQUE (hostname, tenant_id);

ALTER TABLE ONLY executor_heartbeats
    ADD CONSTRAINT executor_heartbeats_pkey PRIMARY KEY (id);

ALTER TABLE ONLY executor_job_tokens
    ADD CONSTRAINT executor_job_tokens_job_id_queue_repo_id_key UNIQUE (job_id, queue, repo_id);

ALTER TABLE ONLY executor_job_tokens
    ADD CONSTRAINT executor_job_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY executor_job_tokens
    ADD CONSTRAINT executor_job_tokens_value_sha256_key UNIQUE (value_sha256, tenant_id);

ALTER TABLE ONLY executor_secret_access_logs
    ADD CONSTRAINT executor_secret_access_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY executor_secrets
    ADD CONSTRAINT executor_secrets_pkey PRIMARY KEY (id);

ALTER TABLE ONLY exhaustive_search_jobs
    ADD CONSTRAINT exhaustive_search_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY exhaustive_search_repo_jobs
    ADD CONSTRAINT exhaustive_search_repo_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY exhaustive_search_repo_revision_jobs
    ADD CONSTRAINT exhaustive_search_repo_revision_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY explicit_permissions_bitbucket_projects_jobs
    ADD CONSTRAINT explicit_permissions_bitbucket_projects_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY external_service_repos
    ADD CONSTRAINT external_service_repos_pkey PRIMARY KEY (repo_id, external_service_id);

ALTER TABLE ONLY external_service_sync_jobs
    ADD CONSTRAINT external_service_sync_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY external_services
    ADD CONSTRAINT external_services_pkey PRIMARY KEY (id);

ALTER TABLE ONLY feature_flag_overrides
    ADD CONSTRAINT feature_flag_overrides_pkey PRIMARY KEY (id);

ALTER TABLE ONLY feature_flag_overrides
    ADD CONSTRAINT feature_flag_overrides_unique_org_flag UNIQUE (namespace_org_id, flag_name);

ALTER TABLE ONLY feature_flag_overrides
    ADD CONSTRAINT feature_flag_overrides_unique_user_flag UNIQUE (namespace_user_id, flag_name);

ALTER TABLE ONLY feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (flag_name, tenant_id);

ALTER TABLE ONLY github_app_installs
    ADD CONSTRAINT github_app_installs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY github_apps
    ADD CONSTRAINT github_apps_pkey PRIMARY KEY (id);

ALTER TABLE ONLY github_apps
    ADD CONSTRAINT github_apps_unique UNIQUE (app_id, client_id, base_url, tenant_id);

ALTER TABLE ONLY gitserver_relocator_jobs
    ADD CONSTRAINT gitserver_relocator_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY gitserver_repos
    ADD CONSTRAINT gitserver_repos_pkey PRIMARY KEY (repo_id);

ALTER TABLE ONLY gitserver_repos_sync_output
    ADD CONSTRAINT gitserver_repos_sync_output_pkey PRIMARY KEY (repo_id);

ALTER TABLE ONLY global_state
    ADD CONSTRAINT global_state_one_per_tenant UNIQUE (tenant_id);

ALTER TABLE ONLY global_state
    ADD CONSTRAINT global_state_pkey PRIMARY KEY (id);

ALTER TABLE ONLY global_state
    ADD CONSTRAINT global_state_site_id_unique UNIQUE (site_id, tenant_id);

ALTER TABLE ONLY idp_authorize_codes
    ADD CONSTRAINT idp_authorize_codes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_authorize_codes
    ADD CONSTRAINT idp_authorize_codes_unique UNIQUE (opaque_id, tenant_id);

ALTER TABLE ONLY idp_clients
    ADD CONSTRAINT idp_clients_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_clients
    ADD CONSTRAINT idp_clients_unique UNIQUE (opaque_id, tenant_id);

ALTER TABLE ONLY idp_consent_requests
    ADD CONSTRAINT idp_consent_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_consent_requests
    ADD CONSTRAINT idp_consent_requests_unique UNIQUE (request_id, tenant_id);

ALTER TABLE ONLY idp_device_auth_requests
    ADD CONSTRAINT idp_device_auth_requests_device_code_signature_unique UNIQUE (hashed_device_code_signature, tenant_id);

ALTER TABLE ONLY idp_device_auth_requests
    ADD CONSTRAINT idp_device_auth_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_device_auth_requests
    ADD CONSTRAINT idp_device_auth_requests_unique UNIQUE (opaque_id, tenant_id);

ALTER TABLE ONLY idp_device_auth_requests
    ADD CONSTRAINT idp_device_auth_requests_user_code_signature_unique UNIQUE (hashed_user_code_signature, tenant_id);

ALTER TABLE ONLY idp_id_tokens
    ADD CONSTRAINT idp_id_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_id_tokens
    ADD CONSTRAINT idp_id_tokens_unique UNIQUE (opaque_id, tenant_id);

ALTER TABLE ONLY idp_oauth_apps
    ADD CONSTRAINT idp_oauth_apps_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_oauth_apps
    ADD CONSTRAINT idp_oauth_apps_unique UNIQUE (client_id, tenant_id);

ALTER TABLE ONLY idp_pkce_requests
    ADD CONSTRAINT idp_pkce_requests_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_pkce_requests
    ADD CONSTRAINT idp_pkce_requests_unique UNIQUE (opaque_id, tenant_id);

ALTER TABLE ONLY idp_secrets
    ADD CONSTRAINT idp_secrets_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_secrets
    ADD CONSTRAINT idp_secrets_tenant_unique UNIQUE (tenant_id);

ALTER TABLE ONLY idp_service_account_m2m_clients
    ADD CONSTRAINT idp_service_account_m2m_clients_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_service_account_m2m_clients
    ADD CONSTRAINT idp_service_account_m2m_clients_unique UNIQUE (client_id, tenant_id);

ALTER TABLE ONLY idp_sessions
    ADD CONSTRAINT idp_sessions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_sessions
    ADD CONSTRAINT idp_sessions_unique UNIQUE (id, tenant_id);

ALTER TABLE ONLY idp_tokens
    ADD CONSTRAINT idp_tokens_pkey PRIMARY KEY (id);

ALTER TABLE ONLY idp_tokens
    ADD CONSTRAINT idp_tokens_unique UNIQUE (opaque_id, type, tenant_id);

ALTER TABLE ONLY idp_user_consents
    ADD CONSTRAINT idp_user_consents_pkey PRIMARY KEY (id);

ALTER TABLE ONLY insights_query_runner_jobs_dependencies
    ADD CONSTRAINT insights_query_runner_jobs_dependencies_pkey PRIMARY KEY (id);

ALTER TABLE ONLY insights_query_runner_jobs
    ADD CONSTRAINT insights_query_runner_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY insights_settings_migration_jobs
    ADD CONSTRAINT insights_settings_migration_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_configuration_policies
    ADD CONSTRAINT lsif_configuration_policies_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_configuration_policies_repository_pattern_lookup
    ADD CONSTRAINT lsif_configuration_policies_repository_pattern_lookup_pkey PRIMARY KEY (policy_id, repo_id);

ALTER TABLE ONLY lsif_dependency_syncing_jobs
    ADD CONSTRAINT lsif_dependency_indexing_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_dependency_indexing_jobs
    ADD CONSTRAINT lsif_dependency_indexing_jobs_pkey1 PRIMARY KEY (id);

ALTER TABLE ONLY lsif_dependency_repos
    ADD CONSTRAINT lsif_dependency_repos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_dirty_repositories
    ADD CONSTRAINT lsif_dirty_repositories_pkey PRIMARY KEY (repository_id);

ALTER TABLE ONLY lsif_index_configuration
    ADD CONSTRAINT lsif_index_configuration_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_index_configuration
    ADD CONSTRAINT lsif_index_configuration_repository_id_key UNIQUE (repository_id);

ALTER TABLE ONLY lsif_indexes
    ADD CONSTRAINT lsif_indexes_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_last_index_scan
    ADD CONSTRAINT lsif_last_index_scan_pkey PRIMARY KEY (repository_id);

ALTER TABLE ONLY lsif_last_retention_scan
    ADD CONSTRAINT lsif_last_retention_scan_pkey PRIMARY KEY (repository_id);

ALTER TABLE ONLY lsif_packages
    ADD CONSTRAINT lsif_packages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_references
    ADD CONSTRAINT lsif_references_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_retention_configuration
    ADD CONSTRAINT lsif_retention_configuration_pkey PRIMARY KEY (id);

ALTER TABLE ONLY lsif_retention_configuration
    ADD CONSTRAINT lsif_retention_configuration_repository_id_key UNIQUE (repository_id);

ALTER TABLE ONLY names
    ADD CONSTRAINT names_pkey PRIMARY KEY (name, tenant_id);

ALTER TABLE ONLY namespace_permissions
    ADD CONSTRAINT namespace_permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY notebook_stars
    ADD CONSTRAINT notebook_stars_pkey PRIMARY KEY (notebook_id, user_id);

ALTER TABLE ONLY notebooks
    ADD CONSTRAINT notebooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY org_invitations
    ADD CONSTRAINT org_invitations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY org_members
    ADD CONSTRAINT org_members_org_id_user_id_key UNIQUE (org_id, user_id);

ALTER TABLE ONLY org_members
    ADD CONSTRAINT org_members_pkey PRIMARY KEY (id);

ALTER TABLE ONLY org_stats
    ADD CONSTRAINT org_stats_pkey PRIMARY KEY (org_id);

ALTER TABLE ONLY orgs
    ADD CONSTRAINT orgs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY out_of_band_migrations_errors
    ADD CONSTRAINT out_of_band_migrations_errors_pkey PRIMARY KEY (id);

ALTER TABLE ONLY out_of_band_migrations
    ADD CONSTRAINT out_of_band_migrations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY outbound_webhook_event_types
    ADD CONSTRAINT outbound_webhook_event_types_pkey PRIMARY KEY (id);

ALTER TABLE ONLY outbound_webhook_jobs
    ADD CONSTRAINT outbound_webhook_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY outbound_webhook_logs
    ADD CONSTRAINT outbound_webhook_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY outbound_webhooks
    ADD CONSTRAINT outbound_webhooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY own_aggregate_recent_contribution
    ADD CONSTRAINT own_aggregate_recent_contribution_pkey PRIMARY KEY (id);

ALTER TABLE ONLY own_aggregate_recent_view
    ADD CONSTRAINT own_aggregate_recent_view_pkey PRIMARY KEY (id);

ALTER TABLE ONLY own_aggregate_recent_view
    ADD CONSTRAINT own_aggregate_recent_view_viewer UNIQUE (viewed_file_path_id, viewer_id);

ALTER TABLE ONLY own_background_jobs
    ADD CONSTRAINT own_background_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY own_signal_configurations
    ADD CONSTRAINT own_signal_configurations_pkey PRIMARY KEY (id);

ALTER TABLE ONLY own_signal_recent_contribution
    ADD CONSTRAINT own_signal_recent_contribution_pkey PRIMARY KEY (id);

ALTER TABLE ONLY ownership_path_stats
    ADD CONSTRAINT ownership_path_stats_pkey PRIMARY KEY (file_path_id);

ALTER TABLE ONLY package_repo_filters
    ADD CONSTRAINT package_repo_filters_pkey PRIMARY KEY (id);

ALTER TABLE ONLY package_repo_filters
    ADD CONSTRAINT package_repo_filters_unique_matcher_per_scheme UNIQUE (scheme, matcher, tenant_id);

ALTER TABLE ONLY package_repo_versions
    ADD CONSTRAINT package_repo_versions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY pending_repo_permissions
    ADD CONSTRAINT pending_repo_permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY pending_repo_permissions
    ADD CONSTRAINT pending_repo_permissions_service_perm_object_unique UNIQUE (permission, service_type, service_id, repo_id, tenant_id, bind_id);

ALTER TABLE ONLY permission_sync_jobs
    ADD CONSTRAINT permission_sync_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY phabricator_repos
    ADD CONSTRAINT phabricator_repos_pkey PRIMARY KEY (id);

ALTER TABLE ONLY phabricator_repos
    ADD CONSTRAINT phabricator_repos_repo_name_key UNIQUE (repo_name, tenant_id);

ALTER TABLE ONLY prompt_tags
    ADD CONSTRAINT prompt_tags_pkey PRIMARY KEY (id);

ALTER TABLE ONLY prompt_tags
    ADD CONSTRAINT prompt_tags_tenant_id_name_key UNIQUE (tenant_id, name);

ALTER TABLE ONLY prompts
    ADD CONSTRAINT prompts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY prompts_tags_mappings
    ADD CONSTRAINT prompts_tags_mappings_pkey PRIMARY KEY (prompt_id, prompt_tag_id, tenant_id);

ALTER TABLE ONLY registry_extension_releases
    ADD CONSTRAINT registry_extension_releases_pkey PRIMARY KEY (id);

ALTER TABLE ONLY registry_extensions
    ADD CONSTRAINT registry_extensions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo_cleanup_jobs
    ADD CONSTRAINT repo_cleanup_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo_commits_changelists
    ADD CONSTRAINT repo_commits_changelists_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo_embedding_job_stats
    ADD CONSTRAINT repo_embedding_job_stats_pkey PRIMARY KEY (job_id);

ALTER TABLE ONLY repo_embedding_jobs
    ADD CONSTRAINT repo_embedding_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo
    ADD CONSTRAINT repo_external_unique UNIQUE (external_service_type, external_service_id, external_id, tenant_id);

ALTER TABLE ONLY repo_kvps
    ADD CONSTRAINT repo_kvps_pkey PRIMARY KEY (repo_id, key) INCLUDE (value);

ALTER TABLE ONLY repo
    ADD CONSTRAINT repo_name_lower_unique UNIQUE (name_lower, tenant_id) DEFERRABLE;

ALTER TABLE ONLY repo
    ADD CONSTRAINT repo_name_unique UNIQUE (name, tenant_id) DEFERRABLE;

ALTER TABLE ONLY repo_paths
    ADD CONSTRAINT repo_paths_index_absolute_path UNIQUE (repo_id, absolute_path);

ALTER TABLE ONLY repo_paths
    ADD CONSTRAINT repo_paths_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo
    ADD CONSTRAINT repo_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo_statistics
    ADD CONSTRAINT repo_statistics_pkey PRIMARY KEY (id);

ALTER TABLE ONLY repo_update_jobs
    ADD CONSTRAINT repo_update_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (permission_id, role_id);

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);

ALTER TABLE ONLY saved_searches
    ADD CONSTRAINT saved_searches_pkey PRIMARY KEY (id);

ALTER TABLE ONLY scip_nearest_uploads_links
    ADD CONSTRAINT scip_nearest_uploads_links_pkey PRIMARY KEY (id);

ALTER TABLE ONLY scip_nearest_uploads
    ADD CONSTRAINT scip_nearest_uploads_pkey PRIMARY KEY (id);

ALTER TABLE ONLY scip_uploads_audit_logs
    ADD CONSTRAINT scip_uploads_audit_logs_pkey PRIMARY KEY (sequence);

ALTER TABLE ONLY scip_uploads
    ADD CONSTRAINT scip_uploads_pkey PRIMARY KEY (id);

ALTER TABLE ONLY scip_uploads_reference_counts
    ADD CONSTRAINT scip_uploads_reference_counts_pkey PRIMARY KEY (upload_id);

ALTER TABLE ONLY scip_uploads_visible_at_tip
    ADD CONSTRAINT scip_uploads_visible_at_tip_pkey PRIMARY KEY (id);

ALTER TABLE ONLY scip_uploads_vulnerability_scan
    ADD CONSTRAINT scip_uploads_vulnerability_scan_pkey PRIMARY KEY (id);

ALTER TABLE ONLY search_context_default
    ADD CONSTRAINT search_context_default_pkey PRIMARY KEY (user_id);

ALTER TABLE ONLY search_context_repos
    ADD CONSTRAINT search_context_repos_pkey PRIMARY KEY (repo_id, search_context_id, revision);

ALTER TABLE ONLY search_context_stars
    ADD CONSTRAINT search_context_stars_pkey PRIMARY KEY (search_context_id, user_id);

ALTER TABLE ONLY search_contexts
    ADD CONSTRAINT search_contexts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY sub_repo_permissions
    ADD CONSTRAINT sub_repo_permissions_pkey PRIMARY KEY (repo_id, user_id, version);

ALTER TABLE ONLY survey_responses
    ADD CONSTRAINT survey_responses_pkey PRIMARY KEY (id);

ALTER TABLE ONLY syntactic_scip_indexing_jobs_audit_logs
    ADD CONSTRAINT syntactic_scip_indexing_jobs_audit_logs_pkey PRIMARY KEY (sequence);

ALTER TABLE ONLY syntactic_scip_indexing_jobs
    ADD CONSTRAINT syntactic_scip_indexing_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY syntactic_scip_last_index_scan
    ADD CONSTRAINT syntactic_scip_last_index_scan_pkey PRIMARY KEY (repository_id, tenant_id);

ALTER TABLE ONLY team_members
    ADD CONSTRAINT team_members_team_id_user_id_key PRIMARY KEY (team_id, user_id);

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_pkey PRIMARY KEY (id);

ALTER TABLE ONLY telemetry_events_export_queue
    ADD CONSTRAINT telemetry_events_export_queue_pkey PRIMARY KEY (id);

ALTER TABLE ONLY temporary_settings
    ADD CONSTRAINT temporary_settings_pkey PRIMARY KEY (id);

ALTER TABLE ONLY temporary_settings
    ADD CONSTRAINT temporary_settings_user_id_key UNIQUE (user_id);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_name_key UNIQUE (name);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);

ALTER TABLE ONLY tenants
    ADD CONSTRAINT tenants_workspace_id_key UNIQUE (workspace_id);

ALTER TABLE ONLY github_app_installs
    ADD CONSTRAINT unique_app_install UNIQUE (app_id, installation_id, tenant_id);

ALTER TABLE ONLY user_credentials
    ADD CONSTRAINT user_credentials_domain_user_id_external_service_type_exter_key UNIQUE (domain, user_id, external_service_type, external_service_id);

ALTER TABLE ONLY user_credentials
    ADD CONSTRAINT user_credentials_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_no_duplicates_per_user UNIQUE (user_id, email);

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_unique_verified_email EXCLUDE USING btree (email WITH OPERATOR(=), tenant_id WITH =) WHERE (((verified_at IS NOT NULL) AND (deleted_at IS NULL)));

ALTER TABLE ONLY user_external_accounts
    ADD CONSTRAINT user_external_accounts_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_onboarding_tour
    ADD CONSTRAINT user_onboarding_tour_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_repo_permissions
    ADD CONSTRAINT user_repo_permissions_perms_unique_idx UNIQUE (user_id, user_external_account_id, repo_id);

ALTER TABLE ONLY user_repo_permissions
    ADD CONSTRAINT user_repo_permissions_pkey PRIMARY KEY (id);

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id);

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);

ALTER TABLE ONLY versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (service);

ALTER TABLE ONLY vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);

ALTER TABLE ONLY vulnerability_affected_packages
    ADD CONSTRAINT vulnerability_affected_packages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY vulnerability_affected_symbols
    ADD CONSTRAINT vulnerability_affected_symbols_pkey PRIMARY KEY (id);

ALTER TABLE ONLY vulnerability_matches
    ADD CONSTRAINT vulnerability_matches_pkey PRIMARY KEY (id);

ALTER TABLE ONLY webhook_logs
    ADD CONSTRAINT webhook_logs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_pkey PRIMARY KEY (id);

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_uuid_key UNIQUE (uuid);

ALTER TABLE ONLY zoekt_index_jobs
    ADD CONSTRAINT zoekt_index_jobs_pkey PRIMARY KEY (id);

ALTER TABLE ONLY zoekt_repos
    ADD CONSTRAINT zoekt_repos_pkey PRIMARY KEY (repo_id);

CREATE INDEX access_requests_created_at ON access_requests USING btree (created_at);

CREATE UNIQUE INDEX access_requests_email_key ON access_requests USING btree (email, tenant_id) WHERE (status = 'PENDING'::text);

CREATE INDEX access_requests_status ON access_requests USING btree (status);

CREATE INDEX access_tokens_lookup ON access_tokens USING hash (value_sha256) WHERE (deleted_at IS NULL);

CREATE INDEX access_tokens_lookup_double_hash ON access_tokens USING hash (digest(value_sha256, 'sha256'::text)) WHERE (deleted_at IS NULL);

CREATE INDEX app_id_idx ON github_app_installs USING btree (app_id);

CREATE UNIQUE INDEX assigned_owners_file_path_owner ON assigned_owners USING btree (file_path_id, owner_user_id);

CREATE UNIQUE INDEX assigned_teams_file_path_owner ON assigned_teams USING btree (file_path_id, owner_team_id);

CREATE INDEX batch_changes_namespace_org_id ON batch_changes USING btree (namespace_org_id);

CREATE INDEX batch_changes_namespace_user_id ON batch_changes USING btree (namespace_user_id);

CREATE INDEX batch_changes_site_credentials_credential_idx ON batch_changes_site_credentials USING btree (((encryption_key_id = ANY (ARRAY[''::text, 'previously-migrated'::text]))));

CREATE UNIQUE INDEX batch_changes_site_credentials_unique ON batch_changes_site_credentials USING btree (external_service_type, external_service_id, tenant_id);

CREATE UNIQUE INDEX batch_changes_unique_org_id ON batch_changes USING btree (name, namespace_org_id, tenant_id) WHERE (namespace_org_id IS NOT NULL);

CREATE UNIQUE INDEX batch_changes_unique_user_id ON batch_changes USING btree (name, namespace_user_id, tenant_id) WHERE (namespace_user_id IS NOT NULL);

CREATE UNIQUE INDEX batch_spec_library_records_name_idx ON batch_spec_library_records USING btree (tenant_id, name);

CREATE INDEX batch_spec_library_variables_library_record_id_idx ON batch_spec_library_variables USING btree (batch_spec_library_record_id);

CREATE INDEX batch_spec_resolution_jobs_state ON batch_spec_resolution_jobs USING btree (state);

CREATE INDEX batch_spec_workspace_execution_jobs_batch_spec_workspace_id ON batch_spec_workspace_execution_jobs USING btree (batch_spec_workspace_id);

CREATE INDEX batch_spec_workspace_execution_jobs_cancel ON batch_spec_workspace_execution_jobs USING btree (cancel);

CREATE INDEX batch_spec_workspace_execution_jobs_last_dequeue ON batch_spec_workspace_execution_jobs USING btree (user_id, started_at DESC);

CREATE INDEX batch_spec_workspace_execution_jobs_state ON batch_spec_workspace_execution_jobs USING btree (state);

CREATE INDEX batch_spec_workspace_files_rand_id ON batch_spec_workspace_files USING btree (rand_id);

CREATE INDEX batch_spec_workspaces_batch_spec_id ON batch_spec_workspaces USING btree (batch_spec_id);

CREATE INDEX batch_spec_workspaces_changeset_spec_ids_gin_idx ON batch_spec_workspaces USING gin (changeset_spec_ids);

CREATE INDEX batch_spec_workspaces_id_batch_spec_id ON batch_spec_workspaces USING btree (id, batch_spec_id);

CREATE UNIQUE INDEX batch_specs_unique_rand_id ON batch_specs USING btree (rand_id, tenant_id);

CREATE INDEX cached_available_indexers_num_events ON cached_available_indexers USING btree (num_events DESC) WHERE ((available_indexers)::text <> '{}'::text);

CREATE INDEX changeset_jobs_bulk_group_idx ON changeset_jobs USING btree (bulk_group);

CREATE INDEX changeset_jobs_state_idx ON changeset_jobs USING btree (state);

CREATE INDEX changeset_specs_batch_spec_id ON changeset_specs USING btree (batch_spec_id);

CREATE INDEX changeset_specs_created_at ON changeset_specs USING btree (created_at);

CREATE INDEX changeset_specs_external_id ON changeset_specs USING btree (external_id);

CREATE INDEX changeset_specs_head_ref ON changeset_specs USING btree (head_ref);

CREATE INDEX changeset_specs_title ON changeset_specs USING btree (title);

CREATE UNIQUE INDEX changeset_specs_unique_rand_id ON changeset_specs USING btree (rand_id, tenant_id);

CREATE INDEX changeset_sync_jobs_dequeue_idx ON changeset_sync_jobs USING btree (state, process_after);

CREATE INDEX changeset_sync_jobs_dequeue_order_idx ON changeset_sync_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id, tenant_id);

CREATE UNIQUE INDEX changeset_sync_jobs_one_concurrent_per_changeset ON changeset_sync_jobs USING btree (changeset_id, tenant_id) WHERE (state = ANY (ARRAY['queued'::text, 'processing'::text, 'errored'::text]));

CREATE INDEX changesets_batch_change_ids ON changesets USING gin (batch_change_ids);

CREATE INDEX changesets_bitbucket_cloud_metadata_source_commit_idx ON changesets USING btree (((((metadata -> 'source'::text) -> 'commit'::text) ->> 'hash'::text)));

CREATE INDEX changesets_changeset_specs ON changesets USING btree (current_spec_id, previous_spec_id);

CREATE INDEX changesets_computed_state ON changesets USING btree (computed_state);

CREATE INDEX changesets_detached_at ON changesets USING btree (detached_at);

CREATE INDEX changesets_external_state_idx ON changesets USING btree (external_state);

CREATE INDEX changesets_external_title_idx ON changesets USING btree (external_title);

CREATE INDEX changesets_publication_state_idx ON changesets USING btree (publication_state);

CREATE INDEX changesets_reconciler_state_idx ON changesets USING btree (reconciler_state);

CREATE INDEX cm_action_jobs_state_idx ON cm_action_jobs USING btree (state);

CREATE INDEX cm_action_jobs_trigger_event ON cm_action_jobs USING btree (trigger_event);

CREATE INDEX cm_slack_webhooks_monitor ON cm_slack_webhooks USING btree (monitor);

CREATE INDEX cm_trigger_jobs_finished_at ON cm_trigger_jobs USING btree (finished_at);

CREATE INDEX cm_trigger_jobs_state_idx ON cm_trigger_jobs USING btree (state);

CREATE INDEX cm_webhooks_monitor ON cm_webhooks USING btree (monitor);

CREATE UNIQUE INDEX codeintel_autoindex_queue_repository_id_commit ON codeintel_autoindex_queue USING btree (repository_id, rev);

CREATE UNIQUE INDEX codeintel_langugage_support_requests_user_id_language ON codeintel_langugage_support_requests USING btree (user_id, language_id, tenant_id);

CREATE INDEX codeowners_owners_reference ON codeowners_owners USING btree (reference);

CREATE INDEX completion_credits_consumption_interaction_uri_idx ON completion_credits_consumption USING btree (interaction_uri text_pattern_ops);

CREATE INDEX completion_credits_consumption_modelref_idx ON completion_credits_consumption USING btree (modelref text_pattern_ops);

CREATE INDEX configuration_policies_audit_logs_policy_id ON configuration_policies_audit_logs USING btree (policy_id);

CREATE INDEX configuration_policies_audit_logs_timestamp ON configuration_policies_audit_logs USING brin (log_timestamp);

CREATE INDEX contributor_data_author_name_idx ON contributor_data USING btree (author_name);

CREATE INDEX contributor_data_repo_id ON contributor_data USING btree (repo_id);

CREATE INDEX contributor_jobs_dequeue_idx ON contributor_jobs USING btree (state, queued_at, id) INCLUDE (process_after) WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX contributor_jobs_repo_id ON contributor_jobs USING btree (repo_id);

CREATE INDEX contributor_repos_repo_id ON contributor_repos USING btree (repo_id);

CREATE INDEX deepsearch_conversations_read_token_idx ON deepsearch_conversations USING hash (read_token);

CREATE INDEX deepsearch_questions_conversation_id_idx ON deepsearch_questions USING btree (conversation_id);

CREATE INDEX deepsearch_quota_user_id_idx ON deepsearch_quota USING btree (user_id);

CREATE INDEX entitlement_grants_user_id_idx ON entitlement_grants USING btree (user_id);

CREATE INDEX event_logs_anonymous_user_id ON event_logs USING btree (anonymous_user_id);

CREATE INDEX event_logs_name_timestamp ON event_logs USING btree (name, "timestamp" DESC);

CREATE INDEX event_logs_source ON event_logs USING btree (source);

CREATE INDEX event_logs_timestamp ON event_logs USING btree ("timestamp");

CREATE INDEX event_logs_timestamp_at_utc ON event_logs USING btree (date(timezone('UTC'::text, "timestamp")));

CREATE INDEX event_logs_user_id_name ON event_logs USING btree (user_id, name);

CREATE INDEX event_logs_user_id_timestamp ON event_logs USING btree (user_id, "timestamp");

CREATE UNIQUE INDEX executor_secrets_unique_key_global ON executor_secrets USING btree (key, scope, tenant_id) WHERE ((namespace_user_id IS NULL) AND (namespace_org_id IS NULL));

CREATE UNIQUE INDEX executor_secrets_unique_key_namespace_org ON executor_secrets USING btree (key, namespace_org_id, scope) WHERE (namespace_org_id IS NOT NULL);

CREATE UNIQUE INDEX executor_secrets_unique_key_namespace_user ON executor_secrets USING btree (key, namespace_user_id, scope) WHERE (namespace_user_id IS NOT NULL);

CREATE INDEX exhaustive_search_jobs_state ON exhaustive_search_jobs USING btree (state);

CREATE INDEX exhaustive_search_repo_jobs_search_job_id ON exhaustive_search_repo_jobs USING btree (search_job_id);

CREATE INDEX exhaustive_search_repo_jobs_state ON exhaustive_search_repo_jobs USING btree (state);

CREATE INDEX exhaustive_search_repo_revision_jobs_state ON exhaustive_search_repo_revision_jobs USING btree (state);

CREATE INDEX explicit_permissions_bitbucket_projects_jobs_project_key_extern ON explicit_permissions_bitbucket_projects_jobs USING btree (project_key, external_service_id, state);

CREATE INDEX explicit_permissions_bitbucket_projects_jobs_queued_at_idx ON explicit_permissions_bitbucket_projects_jobs USING btree (queued_at);

CREATE INDEX explicit_permissions_bitbucket_projects_jobs_state_idx ON explicit_permissions_bitbucket_projects_jobs USING btree (state);

CREATE INDEX external_service_repos_clone_url_idx ON external_service_repos USING btree (clone_url);

CREATE INDEX external_service_repos_idx ON external_service_repos USING btree (external_service_id, repo_id);

CREATE INDEX external_service_sync_jobs_state_external_service_id ON external_service_sync_jobs USING btree (state, external_service_id) INCLUDE (finished_at);

CREATE INDEX external_services_has_webhooks_idx ON external_services USING btree (has_webhooks);

CREATE INDEX feature_flag_overrides_org_id ON feature_flag_overrides USING btree (namespace_org_id) WHERE (namespace_org_id IS NOT NULL);

CREATE INDEX feature_flag_overrides_user_id ON feature_flag_overrides USING btree (namespace_user_id) WHERE (namespace_user_id IS NOT NULL);

CREATE INDEX finished_at_insights_query_runner_jobs_idx ON insights_query_runner_jobs USING btree (finished_at);

CREATE INDEX github_app_installs_account_login ON github_app_installs USING btree (account_login);

CREATE INDEX gitserver_relocator_jobs_state ON gitserver_relocator_jobs USING btree (state);

CREATE INDEX gitserver_repo_size_bytes ON gitserver_repos USING btree (repo_size_bytes);

CREATE INDEX gitserver_repos_cloned_status_idx ON gitserver_repos USING btree (repo_id) WHERE (clone_status = 'cloned'::text);

CREATE INDEX gitserver_repos_cloning_status_idx ON gitserver_repos USING btree (repo_id) WHERE (clone_status = 'cloning'::text);

CREATE INDEX gitserver_repos_last_changed_idx ON gitserver_repos USING btree (last_changed, repo_id);

CREATE INDEX gitserver_repos_last_error_idx ON gitserver_repos USING btree (repo_id) WHERE (last_error IS NOT NULL);

CREATE INDEX gitserver_repos_not_cloned_status_idx ON gitserver_repos USING btree (repo_id) WHERE (clone_status = 'not_cloned'::text);

CREATE INDEX gitserver_repos_not_explicitly_cloned_idx ON gitserver_repos USING btree (repo_id) WHERE (clone_status <> 'cloned'::text);

CREATE INDEX gitserver_repos_schedule_order_idx ON gitserver_repos USING btree (((timezone('UTC'::text, last_fetch_attempt_at) + LEAST(GREATEST((((last_fetched - last_changed) / (2)::double precision) * ((failed_fetch_attempts + 1))::double precision), '00:00:45'::interval), '08:00:00'::interval))) DESC, repo_id);

CREATE INDEX idp_secrets_tenant_id_idx ON idp_secrets USING btree (tenant_id);

CREATE UNIQUE INDEX idp_user_consents_unique_active ON idp_user_consents USING btree (tenant_id, user_id, client_id) WHERE (revoked_at IS NULL);

CREATE INDEX idx_changeset_sync_jobs_changeset_id ON changeset_sync_jobs USING btree (changeset_id, tenant_id);

CREATE INDEX idx_idp_authorize_codes_hashed_code ON idp_authorize_codes USING hash (hashed_code);

CREATE INDEX idx_idp_clients_deleted_at ON idp_clients USING btree (deleted_at);

CREATE INDEX idx_idp_consent_requests_client_id ON idp_consent_requests USING btree (client_id);

CREATE INDEX idx_idp_consent_requests_deleted_at ON idp_consent_requests USING btree (deleted_at);

CREATE INDEX idx_idp_consent_requests_expires_at ON idp_consent_requests USING btree (expires_at);

CREATE INDEX idx_idp_consent_requests_user_id ON idp_consent_requests USING btree (user_id);

CREATE INDEX idx_idp_device_auth_requests_deleted_at ON idp_device_auth_requests USING btree (deleted_at);

CREATE INDEX idx_idp_device_auth_requests_hashed_device_code_signature ON idp_device_auth_requests USING hash (hashed_device_code_signature);

CREATE INDEX idx_idp_device_auth_requests_hashed_user_code_signature ON idp_device_auth_requests USING hash (hashed_user_code_signature);

CREATE INDEX idx_idp_id_tokens_deleted_at ON idp_id_tokens USING btree (deleted_at);

CREATE INDEX idx_idp_id_tokens_hashed_authorize_code ON idp_id_tokens USING hash (hashed_authorize_code);

CREATE INDEX idx_idp_pkce_requests_deleted_at ON idp_pkce_requests USING btree (deleted_at);

CREATE INDEX idx_idp_pkce_requests_hashed_signature ON idp_pkce_requests USING hash (hashed_signature);

CREATE INDEX idx_idp_sessions_deleted_at ON idp_sessions USING btree (deleted_at);

CREATE INDEX idx_idp_tokens_deleted_at ON idp_tokens USING btree (deleted_at);

CREATE INDEX idx_idp_tokens_hashed_signature ON idp_tokens USING hash (hashed_signature);

CREATE INDEX idx_idp_user_consents_expires_at ON idp_user_consents USING btree (expires_at) WHERE (expires_at IS NOT NULL);

CREATE INDEX idx_idp_user_consents_user_client ON idp_user_consents USING btree (tenant_id, user_id, client_id);

CREATE INDEX idx_repo_cleanup_jobs_repository_id ON repo_cleanup_jobs USING btree (tenant_id, repository_id);

CREATE INDEX idx_repo_topics ON repo USING gin (topics);

CREATE INDEX idx_repo_update_jobs_repository_id ON repo_update_jobs USING btree (tenant_id, repository_id);

CREATE INDEX idx_user_id_created_at ON cody_audit_log USING btree (user_id, created_at);

CREATE INDEX idx_zoekt_index_jobs_repository_id ON zoekt_index_jobs USING btree (tenant_id, repository_id);

CREATE INDEX insights_query_runner_jobs_cost_idx ON insights_query_runner_jobs USING btree (cost);

CREATE INDEX insights_query_runner_jobs_dependencies_job_id_fk_idx ON insights_query_runner_jobs_dependencies USING btree (job_id);

CREATE INDEX insights_query_runner_jobs_priority_idx ON insights_query_runner_jobs USING btree (priority);

CREATE INDEX insights_query_runner_jobs_processable_priority_id ON insights_query_runner_jobs USING btree (priority, id) WHERE ((state = 'queued'::text) OR (state = 'errored'::text));

CREATE INDEX insights_query_runner_jobs_series_id_state ON insights_query_runner_jobs USING btree (series_id, state);

CREATE INDEX insights_query_runner_jobs_state_btree ON insights_query_runner_jobs USING btree (state);

CREATE INDEX installation_id_idx ON github_app_installs USING btree (installation_id);

CREATE UNIQUE INDEX kind_cloud_default ON external_services USING btree (kind, cloud_default, tenant_id) WHERE ((cloud_default = true) AND (deleted_at IS NULL));

CREATE INDEX lsif_configuration_policies_repository_id ON lsif_configuration_policies USING btree (repository_id);

CREATE INDEX lsif_dependency_indexing_jobs_state ON lsif_dependency_indexing_jobs USING btree (state);

CREATE INDEX lsif_dependency_indexing_jobs_upload_id ON lsif_dependency_syncing_jobs USING btree (upload_id);

CREATE INDEX lsif_dependency_repos_blocked ON lsif_dependency_repos USING btree (blocked);

CREATE INDEX lsif_dependency_repos_last_checked_at ON lsif_dependency_repos USING btree (last_checked_at NULLS FIRST);

CREATE INDEX lsif_dependency_repos_name_gin ON lsif_dependency_repos USING gin (name gin_trgm_ops);

CREATE INDEX lsif_dependency_repos_name_id ON lsif_dependency_repos USING btree (name, id);

CREATE INDEX lsif_dependency_repos_scheme_id ON lsif_dependency_repos USING btree (scheme, id);

CREATE UNIQUE INDEX lsif_dependency_repos_unique_scheme_name ON lsif_dependency_repos USING btree (scheme, name, tenant_id);

CREATE INDEX lsif_dependency_syncing_jobs_state ON lsif_dependency_syncing_jobs USING btree (state);

CREATE INDEX lsif_indexes_commit_last_checked_at ON lsif_indexes USING btree (commit_last_checked_at) WHERE (state <> 'deleted'::text);

CREATE INDEX lsif_indexes_dequeue_order_idx ON lsif_indexes USING btree (((enqueuer_user_id > 0)) DESC, queued_at DESC, id) WHERE ((state = 'queued'::text) OR (state = 'errored'::text));

CREATE INDEX lsif_indexes_matched_policy_id_partial_idx ON lsif_indexes USING btree (matched_policy_id) WHERE (matched_policy_id IS NOT NULL);

COMMENT ON INDEX lsif_indexes_matched_policy_id_partial_idx IS 'Inverted index for FK constraint to support policy deletion without a full table scan.';

CREATE INDEX lsif_indexes_queued_at_id ON lsif_indexes USING btree (queued_at DESC, id);

CREATE UNIQUE INDEX lsif_indexes_queued_partial_ukey ON lsif_indexes USING btree (repository_id, indexer, root, tenant_id, commit) WHERE ((state = 'queued'::text) AND (matched_policy_id IS NOT NULL));

COMMENT ON INDEX lsif_indexes_queued_partial_ukey IS 'Partial index for commit overwriting on detecting new commits for a repository while the old commit is still enqueued.';

CREATE INDEX lsif_indexes_repository_id_commit ON lsif_indexes USING btree (repository_id, commit);

CREATE INDEX lsif_indexes_repository_id_indexer ON lsif_indexes USING btree (repository_id, indexer);

CREATE INDEX lsif_indexes_state ON lsif_indexes USING btree (state);

CREATE INDEX lsif_packages_dump_id ON lsif_packages USING btree (dump_id);

CREATE INDEX lsif_packages_scheme_name_version_dump_id ON lsif_packages USING btree (scheme, name, version, dump_id);

CREATE INDEX lsif_references_dump_id ON lsif_references USING btree (dump_id);

CREATE INDEX lsif_references_scheme_name_version_dump_id ON lsif_references USING btree (scheme, name, version, dump_id);

CREATE INDEX notebook_stars_user_id_idx ON notebook_stars USING btree (user_id);

CREATE INDEX notebooks_blocks_tsvector_idx ON notebooks USING gin (blocks_tsvector);

CREATE INDEX notebooks_namespace_org_id_idx ON notebooks USING btree (namespace_org_id);

CREATE INDEX notebooks_namespace_user_id_idx ON notebooks USING btree (namespace_user_id);

CREATE INDEX notebooks_title_trgm_idx ON notebooks USING gin (title gin_trgm_ops);

CREATE INDEX org_invitations_org_id ON org_invitations USING btree (org_id) WHERE (deleted_at IS NULL);

CREATE INDEX org_invitations_recipient_user_id ON org_invitations USING btree (recipient_user_id) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX orgs_name ON orgs USING btree (name, tenant_id) WHERE (deleted_at IS NULL);

CREATE INDEX outbound_webhook_event_types_event_type_idx ON outbound_webhook_event_types USING btree (event_type, scope);

CREATE INDEX outbound_webhook_jobs_state_idx ON outbound_webhook_jobs USING btree (state);

CREATE INDEX outbound_webhook_logs_outbound_webhook_id_idx ON outbound_webhook_logs USING btree (outbound_webhook_id);

CREATE INDEX outbound_webhook_payload_process_after_idx ON outbound_webhook_jobs USING btree (process_after);

CREATE INDEX outbound_webhooks_logs_status_code_idx ON outbound_webhook_logs USING btree (status_code);

CREATE UNIQUE INDEX own_aggregate_recent_contribution_file_author ON own_aggregate_recent_contribution USING btree (changed_file_path_id, commit_author_id);

CREATE INDEX own_background_jobs_repo_id_idx ON own_background_jobs USING btree (repo_id);

CREATE INDEX own_background_jobs_state_idx ON own_background_jobs USING btree (state);

CREATE UNIQUE INDEX own_signal_configurations_name_uidx ON own_signal_configurations USING btree (name, tenant_id);

CREATE INDEX package_repo_versions_blocked ON package_repo_versions USING btree (blocked);

CREATE INDEX package_repo_versions_last_checked_at ON package_repo_versions USING btree (last_checked_at NULLS FIRST);

CREATE UNIQUE INDEX package_repo_versions_unique_version_per_package ON package_repo_versions USING btree (package_id, version);

CREATE INDEX permission_sync_jobs_process_after ON permission_sync_jobs USING btree (process_after);

CREATE INDEX permission_sync_jobs_repository_id ON permission_sync_jobs USING btree (repository_id);

CREATE INDEX permission_sync_jobs_state ON permission_sync_jobs USING btree (state);

CREATE UNIQUE INDEX permission_sync_jobs_unique ON permission_sync_jobs USING btree (priority, user_id, repository_id, cancel, process_after, tenant_id) WHERE (state = 'queued'::text);

CREATE INDEX permission_sync_jobs_user_id ON permission_sync_jobs USING btree (user_id);

CREATE UNIQUE INDEX permissions_unique_namespace_action ON permissions USING btree (namespace, action, tenant_id);

CREATE INDEX process_after_insights_query_runner_jobs_idx ON insights_query_runner_jobs USING btree (process_after);

CREATE UNIQUE INDEX prompts_name_is_unique_for_builtins ON prompts USING btree (name, tenant_id) WHERE (builtin IS TRUE);

CREATE UNIQUE INDEX prompts_name_is_unique_in_owner_org ON prompts USING btree (owner_org_id, name) WHERE (owner_org_id IS NOT NULL);

CREATE UNIQUE INDEX prompts_name_is_unique_in_owner_user ON prompts USING btree (owner_user_id, name) WHERE (owner_user_id IS NOT NULL);

CREATE INDEX registry_extension_releases_registry_extension_id ON registry_extension_releases USING btree (registry_extension_id, release_tag, created_at DESC) WHERE (deleted_at IS NULL);

CREATE INDEX registry_extension_releases_registry_extension_id_created_at ON registry_extension_releases USING btree (registry_extension_id, created_at) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX registry_extension_releases_version ON registry_extension_releases USING btree (registry_extension_id, release_version) WHERE (release_version IS NOT NULL);

CREATE UNIQUE INDEX registry_extensions_publisher_name ON registry_extensions USING btree (COALESCE(publisher_user_id, 0), COALESCE(publisher_org_id, 0), name, tenant_id) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX registry_extensions_uuid ON registry_extensions USING btree (uuid);

CREATE INDEX repo_archived ON repo USING btree (archived);

CREATE INDEX repo_blocked_idx ON repo USING btree (((blocked IS NOT NULL)));

CREATE INDEX repo_cleanup_jobs_dequeue_idx ON repo_cleanup_jobs USING btree (state, process_after);

CREATE INDEX repo_cleanup_jobs_dequeue_optimization_idx ON repo_cleanup_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id) INCLUDE (state, process_after) WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX repo_cleanup_jobs_dequeue_order_idx ON repo_cleanup_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id, tenant_id);

CREATE UNIQUE INDEX repo_cleanup_jobs_one_concurrent_per_repo ON repo_cleanup_jobs USING btree (repository_id, tenant_id) WHERE (state = ANY (ARRAY['queued'::text, 'processing'::text, 'errored'::text]));

CREATE INDEX repo_cleanup_jobs_repository_id ON repo_cleanup_jobs USING btree (repository_id);

CREATE INDEX repo_created_at ON repo USING btree (created_at);

CREATE INDEX repo_description_trgm_idx ON repo USING gin (lower(description) gin_trgm_ops);

CREATE INDEX repo_embedding_jobs_repo ON repo_embedding_jobs USING btree (repo_id, revision);

CREATE INDEX repo_fork ON repo USING btree (fork);

CREATE INDEX repo_hashed_name_idx ON repo USING btree (sha256((lower((name)::text))::bytea)) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX repo_id_perforce_changelist_id_unique ON repo_commits_changelists USING btree (repo_id, perforce_changelist_id);

CREATE INDEX repo_is_not_blocked_idx ON repo USING btree (((blocked IS NULL)));

CREATE INDEX repo_kvps_trgm_idx ON repo_kvps USING gin (key gin_trgm_ops, value gin_trgm_ops);

CREATE INDEX repo_metadata_gin_idx ON repo USING gin (metadata);

CREATE INDEX repo_name_case_sensitive_trgm_idx ON repo USING gin (((name)::text) gin_trgm_ops);

CREATE INDEX repo_name_lower_trgm_idx ON repo USING gin (name_lower gin_trgm_ops);

CREATE INDEX repo_non_deleted_id_name_idx ON repo USING btree (id, name) WHERE (deleted_at IS NULL);

CREATE INDEX repo_private ON repo USING btree (private);

CREATE INDEX repo_stars_desc_id_desc_idx ON repo USING btree (stars DESC NULLS LAST, id DESC) WHERE ((deleted_at IS NULL) AND (blocked IS NULL));

CREATE INDEX repo_stars_idx ON repo USING btree (stars DESC NULLS LAST);

CREATE INDEX repo_update_jobs_dequeue_idx ON repo_update_jobs USING btree (state, process_after);

CREATE INDEX repo_update_jobs_dequeue_optimization_idx ON repo_update_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id) INCLUDE (state, process_after) WHERE (state = ANY (ARRAY['queued'::text, 'errored'::text]));

CREATE INDEX repo_update_jobs_dequeue_order_idx ON repo_update_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id, tenant_id);

CREATE UNIQUE INDEX repo_update_jobs_one_concurrent_per_repo ON repo_update_jobs USING btree (repository_id, tenant_id) WHERE (state = ANY (ARRAY['queued'::text, 'processing'::text, 'errored'::text]));

CREATE INDEX repo_update_jobs_repository_id ON repo_update_jobs USING btree (repository_id);

CREATE INDEX repo_uri_idx ON repo USING btree (uri);

CREATE INDEX scip_nearest_uploads_links_repository_id_ancestor_commit_bytea ON scip_nearest_uploads_links USING btree (repository_id, ancestor_commit_bytea);

CREATE INDEX scip_nearest_uploads_links_repository_id_commit_bytea ON scip_nearest_uploads_links USING btree (repository_id, commit_bytea);

CREATE INDEX scip_nearest_uploads_repository_id_commit_bytea ON scip_nearest_uploads USING btree (repository_id, commit_bytea);

CREATE INDEX scip_nearest_uploads_uploads ON scip_nearest_uploads USING gin (uploads);

CREATE INDEX scip_uploads_associated_index_id ON scip_uploads USING btree (associated_index_id);

CREATE INDEX scip_uploads_audit_logs_timestamp ON scip_uploads_audit_logs USING brin (log_timestamp);

CREATE INDEX scip_uploads_audit_logs_upload_id ON scip_uploads_audit_logs USING btree (upload_id);

CREATE INDEX scip_uploads_commit_last_checked_at ON scip_uploads USING btree (commit_last_checked_at) WHERE (state <> 'deleted'::text);

CREATE INDEX scip_uploads_committed_at ON scip_uploads USING btree (committed_at) WHERE (state = 'completed'::text);

CREATE INDEX scip_uploads_last_reconcile_at ON scip_uploads USING btree (last_reconcile_at, id) WHERE (state = 'completed'::text);

CREATE INDEX scip_uploads_repository_id_commit ON scip_uploads USING btree (repository_id, commit);

CREATE UNIQUE INDEX scip_uploads_repository_id_commit_root_indexer ON scip_uploads USING btree (repository_id, commit, root, indexer) WHERE (state = 'completed'::text);

CREATE INDEX scip_uploads_repository_id_indexer ON scip_uploads USING btree (repository_id, indexer);

CREATE INDEX scip_uploads_state ON scip_uploads USING btree (state);

CREATE INDEX scip_uploads_uploaded_at_id ON scip_uploads USING btree (uploaded_at DESC, id) WHERE (state <> 'deleted'::text);

CREATE INDEX scip_uploads_visible_at_tip_is_default_branch ON scip_uploads_visible_at_tip USING btree (upload_id) WHERE is_default_branch;

CREATE INDEX scip_uploads_visible_at_tip_repository_id_upload_id ON scip_uploads_visible_at_tip USING btree (repository_id, upload_id);

CREATE UNIQUE INDEX scip_uploads_vulnerability_scan_upload_id ON scip_uploads_vulnerability_scan USING btree (upload_id);

CREATE UNIQUE INDEX search_contexts_name_namespace_org_id_unique ON search_contexts USING btree (name, namespace_org_id) WHERE (namespace_org_id IS NOT NULL);

CREATE UNIQUE INDEX search_contexts_name_namespace_user_id_unique ON search_contexts USING btree (name, namespace_user_id) WHERE (namespace_user_id IS NOT NULL);

CREATE UNIQUE INDEX search_contexts_name_without_namespace_unique ON search_contexts USING btree (name, tenant_id) WHERE ((namespace_user_id IS NULL) AND (namespace_org_id IS NULL));

CREATE INDEX search_contexts_query_idx ON search_contexts USING btree (query);

CREATE INDEX settings_global_id ON settings USING btree (id DESC) WHERE ((user_id IS NULL) AND (org_id IS NULL));

CREATE INDEX settings_org_id_idx ON settings USING btree (org_id);

CREATE INDEX settings_user_id_idx ON settings USING btree (user_id);

CREATE INDEX sub_repo_perms_user_id ON sub_repo_permissions USING btree (user_id);

CREATE INDEX syntactic_scip_indexing_jobs_audit_logs_indexing_job_id ON syntactic_scip_indexing_jobs_audit_logs USING btree (job_id);

CREATE INDEX syntactic_scip_indexing_jobs_audit_logs_timestamp ON syntactic_scip_indexing_jobs_audit_logs USING brin (log_timestamp);

CREATE INDEX syntactic_scip_indexing_jobs_dequeue_order_idx ON syntactic_scip_indexing_jobs USING btree (((enqueuer_user_id > 0)) DESC, queued_at DESC, id) WHERE ((state = 'queued'::text) OR (state = 'errored'::text));

CREATE INDEX syntactic_scip_indexing_jobs_queued_at_id ON syntactic_scip_indexing_jobs USING btree (queued_at DESC, id);

CREATE UNIQUE INDEX syntactic_scip_indexing_jobs_queued_partial_ukey ON syntactic_scip_indexing_jobs USING btree (tenant_id, repository_id) WHERE (state = 'queued'::text);

CREATE INDEX syntactic_scip_indexing_jobs_repository_id_commit ON syntactic_scip_indexing_jobs USING btree (repository_id, commit);

CREATE INDEX syntactic_scip_indexing_jobs_state ON syntactic_scip_indexing_jobs USING btree (state);

CREATE UNIQUE INDEX teams_name ON teams USING btree (name, tenant_id);

CREATE INDEX telemetry_events_export_queue_export_order ON telemetry_events_export_queue USING btree ("timestamp") WHERE (exported_at IS NULL);

CREATE UNIQUE INDEX unique_entitlement_type_default_idx ON entitlements USING btree (type, tenant_id) WHERE is_default;

CREATE UNIQUE INDEX unique_resource_permission ON namespace_permissions USING btree (namespace, resource_id, user_id);

CREATE UNIQUE INDEX unique_role_name ON roles USING btree (name, tenant_id);

CREATE INDEX user_credentials_credential_idx ON user_credentials USING btree (((encryption_key_id = ANY (ARRAY[''::text, 'previously-migrated'::text]))));

CREATE UNIQUE INDEX user_emails_user_id_is_primary_idx ON user_emails USING btree (user_id, is_primary) WHERE (is_primary = true);

CREATE UNIQUE INDEX user_external_accounts_account ON user_external_accounts USING btree (service_type, service_id, client_id, account_id, tenant_id) WHERE (deleted_at IS NULL);

CREATE INDEX user_external_accounts_user_id ON user_external_accounts USING btree (user_id) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX user_external_accounts_user_id_scim_service_type ON user_external_accounts USING btree (user_id, service_type) WHERE ((service_type = 'scim'::text) AND (deleted_at IS NULL));

CREATE INDEX user_repo_permissions_repo_id_idx ON user_repo_permissions USING btree (repo_id);

CREATE INDEX user_repo_permissions_source_idx ON user_repo_permissions USING btree (source);

CREATE INDEX user_repo_permissions_updated_at_idx ON user_repo_permissions USING btree (updated_at);

CREATE INDEX user_repo_permissions_user_external_account_id_idx ON user_repo_permissions USING btree (user_external_account_id);

CREATE UNIQUE INDEX users_billing_customer_id ON users USING btree (billing_customer_id, tenant_id) WHERE (deleted_at IS NULL);

CREATE INDEX users_created_at_idx ON users USING btree (created_at);

CREATE UNIQUE INDEX users_username ON users USING btree (username, tenant_id) WHERE (deleted_at IS NULL);

CREATE UNIQUE INDEX vulnerabilities_source_id ON vulnerabilities USING btree (source_id, tenant_id);

CREATE UNIQUE INDEX vulnerability_affected_packages_vulnerability_id_package_name ON vulnerability_affected_packages USING btree (vulnerability_id, package_name);

CREATE UNIQUE INDEX vulnerability_affected_symbols_vulnerability_affected_package_i ON vulnerability_affected_symbols USING btree (vulnerability_affected_package_id, path);

CREATE UNIQUE INDEX vulnerability_matches_upload_id_vulnerability_affected_package_ ON vulnerability_matches USING btree (upload_id, vulnerability_affected_package_id);

CREATE INDEX vulnerability_matches_vulnerability_affected_package_id ON vulnerability_matches USING btree (vulnerability_affected_package_id);

CREATE INDEX webhook_logs_external_service_id_idx ON webhook_logs USING btree (external_service_id);

CREATE INDEX webhook_logs_received_at_idx ON webhook_logs USING btree (received_at);

CREATE INDEX webhook_logs_status_code_idx ON webhook_logs USING btree (status_code);

CREATE INDEX zoekt_index_jobs_dequeue_idx ON zoekt_index_jobs USING btree (state, process_after);

CREATE INDEX zoekt_index_jobs_dequeue_order_idx ON zoekt_index_jobs USING btree (priority DESC, COALESCE(process_after, queued_at), id, tenant_id);

CREATE UNIQUE INDEX zoekt_index_jobs_one_concurrent_per_repo ON zoekt_index_jobs USING btree (repository_id, tenant_id) WHERE (state = ANY (ARRAY['queued'::text, 'processing'::text, 'errored'::text]));

CREATE INDEX zoekt_index_jobs_repository_id ON zoekt_index_jobs USING btree (repository_id);

CREATE INDEX zoekt_repos_index_status ON zoekt_repos USING btree (index_status);

CREATE TRIGGER batch_spec_workspace_execution_last_dequeues_insert AFTER INSERT ON batch_spec_workspace_execution_jobs REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION batch_spec_workspace_execution_last_dequeues_upsert();

CREATE TRIGGER batch_spec_workspace_execution_last_dequeues_update AFTER UPDATE ON batch_spec_workspace_execution_jobs REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION batch_spec_workspace_execution_last_dequeues_upsert();

CREATE TRIGGER changesets_update_computed_state BEFORE INSERT OR UPDATE ON changesets FOR EACH ROW EXECUTE FUNCTION changesets_computed_state_ensure();

CREATE TRIGGER enforce_single_entitlement_grant_type_per_user BEFORE INSERT OR UPDATE ON entitlement_grants FOR EACH ROW EXECUTE FUNCTION check_user_entitlement_grant_type();

CREATE TRIGGER trig_create_zoekt_repo_on_repo_insert AFTER INSERT ON repo FOR EACH ROW EXECUTE FUNCTION func_insert_zoekt_repo();

CREATE TRIGGER trig_delete_batch_change_reference_on_changesets AFTER DELETE ON batch_changes FOR EACH ROW EXECUTE FUNCTION delete_batch_change_reference_on_changesets();

CREATE TRIGGER trig_delete_repo_ref_on_external_service_repos AFTER UPDATE OF deleted_at ON repo FOR EACH ROW EXECUTE FUNCTION delete_repo_ref_on_external_service_repos();

CREATE TRIGGER trig_delete_user_repo_permissions_on_external_account_soft_dele AFTER UPDATE OF deleted_at ON user_external_accounts FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION delete_user_repo_permissions_on_external_account_soft_delete();

CREATE TRIGGER trig_delete_user_repo_permissions_on_repo_soft_delete AFTER UPDATE OF deleted_at ON repo FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION delete_user_repo_permissions_on_repo_soft_delete();

CREATE TRIGGER trig_delete_user_repo_permissions_on_user_soft_delete AFTER UPDATE OF deleted_at ON users FOR EACH ROW WHEN (((new.deleted_at IS NOT NULL) AND (old.deleted_at IS NULL))) EXECUTE FUNCTION delete_user_repo_permissions_on_user_soft_delete();

CREATE TRIGGER trig_invalidate_session_on_password_change BEFORE UPDATE OF passwd ON users FOR EACH ROW EXECUTE FUNCTION invalidate_session_for_userid_on_password_change();

CREATE TRIGGER trig_recalc_gitserver_repos_statistics_on_update AFTER UPDATE ON gitserver_repos REFERENCING OLD TABLE AS oldtab NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_gitserver_repos_statistics_on_update();

CREATE TRIGGER trig_recalc_repo_statistics_on_repo_delete AFTER DELETE ON repo REFERENCING OLD TABLE AS oldtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_repo_statistics_on_repo_delete();

CREATE TRIGGER trig_recalc_repo_statistics_on_repo_insert AFTER INSERT ON repo REFERENCING NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_repo_statistics_on_repo_insert();

CREATE TRIGGER trig_recalc_repo_statistics_on_repo_update AFTER UPDATE ON repo REFERENCING OLD TABLE AS oldtab NEW TABLE AS newtab FOR EACH STATEMENT EXECUTE FUNCTION recalc_repo_statistics_on_repo_update();

CREATE TRIGGER trigger_configuration_policies_delete AFTER DELETE ON lsif_configuration_policies REFERENCING OLD TABLE AS old FOR EACH STATEMENT EXECUTE FUNCTION func_configuration_policies_delete();

CREATE TRIGGER trigger_configuration_policies_insert AFTER INSERT ON lsif_configuration_policies FOR EACH ROW EXECUTE FUNCTION func_configuration_policies_insert();

CREATE TRIGGER trigger_configuration_policies_update BEFORE UPDATE OF name, pattern, retention_enabled, retention_duration_hours, type, retain_intermediate_commits ON lsif_configuration_policies FOR EACH ROW EXECUTE FUNCTION func_configuration_policies_update();

CREATE TRIGGER trigger_gitserver_repo_insert AFTER INSERT ON repo FOR EACH ROW EXECUTE FUNCTION func_insert_gitserver_repo();

CREATE TRIGGER trigger_package_repo_filters_updated_at BEFORE UPDATE ON package_repo_filters FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE FUNCTION func_package_repo_filters_updated_at();

CREATE TRIGGER trigger_scip_uploads_delete AFTER DELETE ON scip_uploads REFERENCING OLD TABLE AS old FOR EACH STATEMENT EXECUTE FUNCTION func_scip_uploads_delete();

CREATE TRIGGER trigger_scip_uploads_insert AFTER INSERT ON scip_uploads FOR EACH ROW EXECUTE FUNCTION func_scip_uploads_insert();

CREATE TRIGGER trigger_scip_uploads_update BEFORE UPDATE OF state, num_resets, num_failures, worker_hostname, expired, committed_at ON scip_uploads FOR EACH ROW EXECUTE FUNCTION func_scip_uploads_update();

CREATE TRIGGER trigger_syntactic_scip_indexing_jobs_delete AFTER DELETE ON syntactic_scip_indexing_jobs REFERENCING OLD TABLE AS old FOR EACH STATEMENT EXECUTE FUNCTION func_syntactic_scip_indexing_jobs_delete();

CREATE TRIGGER trigger_syntactic_scip_indexing_jobs_insert AFTER INSERT ON syntactic_scip_indexing_jobs FOR EACH ROW EXECUTE FUNCTION func_syntactic_scip_indexing_jobs_insert();

CREATE TRIGGER trigger_syntactic_scip_indexing_jobs_update BEFORE UPDATE OF commit, state, num_resets, num_failures, worker_hostname, failure_message ON syntactic_scip_indexing_jobs FOR EACH ROW EXECUTE FUNCTION func_syntactic_scip_indexing_jobs_update();

CREATE TRIGGER update_conversation_on_question_change AFTER INSERT OR UPDATE ON deepsearch_questions FOR EACH ROW EXECUTE FUNCTION update_deepsearch_conversation_updated_at_on_question_change();

CREATE TRIGGER update_deepsearch_conversations_updated_at BEFORE UPDATE ON deepsearch_conversations FOR EACH ROW EXECUTE FUNCTION update_deepsearch_conversations_updated_at();

CREATE TRIGGER update_deepsearch_questions_updated_at BEFORE UPDATE ON deepsearch_questions FOR EACH ROW EXECUTE FUNCTION update_deepsearch_questions_updated_at();

CREATE TRIGGER update_own_aggregate_recent_contribution AFTER INSERT ON own_signal_recent_contribution FOR EACH ROW EXECUTE FUNCTION update_own_aggregate_recent_contribution();

CREATE TRIGGER versions_insert BEFORE INSERT ON versions FOR EACH ROW EXECUTE FUNCTION versions_insert_row_trigger();

ALTER TABLE ONLY access_requests
    ADD CONSTRAINT access_requests_decision_by_user_id_fkey FOREIGN KEY (decision_by_user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id);

ALTER TABLE ONLY access_tokens
    ADD CONSTRAINT access_tokens_subject_user_id_fkey FOREIGN KEY (subject_user_id) REFERENCES users(id);

ALTER TABLE ONLY aggregated_user_statistics
    ADD CONSTRAINT aggregated_user_statistics_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY assigned_owners
    ADD CONSTRAINT assigned_owners_file_path_id_fkey FOREIGN KEY (file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY assigned_owners
    ADD CONSTRAINT assigned_owners_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY assigned_owners
    ADD CONSTRAINT assigned_owners_who_assigned_user_id_fkey FOREIGN KEY (who_assigned_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY assigned_teams
    ADD CONSTRAINT assigned_teams_file_path_id_fkey FOREIGN KEY (file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY assigned_teams
    ADD CONSTRAINT assigned_teams_owner_team_id_fkey FOREIGN KEY (owner_team_id) REFERENCES teams(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY assigned_teams
    ADD CONSTRAINT assigned_teams_who_assigned_team_id_fkey FOREIGN KEY (who_assigned_team_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_batch_spec_id_fkey FOREIGN KEY (batch_spec_id) REFERENCES batch_specs(id) DEFERRABLE;

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_initial_applier_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_last_applier_id_fkey FOREIGN KEY (last_applier_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_namespace_org_id_fkey FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_changes
    ADD CONSTRAINT batch_changes_namespace_user_id_fkey FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_changes_site_credentials
    ADD CONSTRAINT batch_changes_site_credentials_github_app_id_fkey FOREIGN KEY (github_app_id) REFERENCES github_apps(id) ON DELETE CASCADE;

ALTER TABLE ONLY batch_spec_execution_cache_entries
    ADD CONSTRAINT batch_spec_execution_cache_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_spec_library_variables
    ADD CONSTRAINT batch_spec_library_variables_batch_spec_library_record_id_fkey FOREIGN KEY (batch_spec_library_record_id) REFERENCES batch_spec_library_records(id) ON DELETE CASCADE;

ALTER TABLE ONLY batch_spec_resolution_jobs
    ADD CONSTRAINT batch_spec_resolution_jobs_batch_spec_id_fkey FOREIGN KEY (batch_spec_id) REFERENCES batch_specs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_spec_resolution_jobs
    ADD CONSTRAINT batch_spec_resolution_jobs_initiator_id_fkey FOREIGN KEY (initiator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_spec_workspace_execution_jobs
    ADD CONSTRAINT batch_spec_workspace_execution_job_batch_spec_workspace_id_fkey FOREIGN KEY (batch_spec_workspace_id) REFERENCES batch_spec_workspaces(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_spec_workspace_execution_last_dequeues
    ADD CONSTRAINT batch_spec_workspace_execution_last_dequeues_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY batch_spec_workspace_files
    ADD CONSTRAINT batch_spec_workspace_files_batch_spec_id_fkey FOREIGN KEY (batch_spec_id) REFERENCES batch_specs(id) ON DELETE CASCADE;

ALTER TABLE ONLY batch_spec_workspaces
    ADD CONSTRAINT batch_spec_workspaces_batch_spec_id_fkey FOREIGN KEY (batch_spec_id) REFERENCES batch_specs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY batch_spec_workspaces
    ADD CONSTRAINT batch_spec_workspaces_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) DEFERRABLE;

ALTER TABLE ONLY batch_specs
    ADD CONSTRAINT batch_specs_batch_change_id_fkey FOREIGN KEY (batch_change_id) REFERENCES batch_changes(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY batch_specs
    ADD CONSTRAINT batch_specs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY changeset_events
    ADD CONSTRAINT changeset_events_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_jobs
    ADD CONSTRAINT changeset_jobs_batch_change_id_fkey FOREIGN KEY (batch_change_id) REFERENCES batch_changes(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_jobs
    ADD CONSTRAINT changeset_jobs_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_jobs
    ADD CONSTRAINT changeset_jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_batch_spec_id_fkey FOREIGN KEY (batch_spec_id) REFERENCES batch_specs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) DEFERRABLE;

ALTER TABLE ONLY changeset_specs
    ADD CONSTRAINT changeset_specs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY changeset_sync_jobs
    ADD CONSTRAINT changeset_sync_jobs_changeset_id_fkey FOREIGN KEY (changeset_id) REFERENCES changesets(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changeset_sync_jobs
    ADD CONSTRAINT changeset_sync_jobs_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_changeset_spec_id_fkey FOREIGN KEY (current_spec_id) REFERENCES changeset_specs(id) DEFERRABLE;

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_owned_by_batch_spec_id_fkey FOREIGN KEY (owned_by_batch_change_id) REFERENCES batch_changes(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_previous_spec_id_fkey FOREIGN KEY (previous_spec_id) REFERENCES changeset_specs(id) DEFERRABLE;

ALTER TABLE ONLY changesets
    ADD CONSTRAINT changesets_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY cm_action_jobs
    ADD CONSTRAINT cm_action_jobs_email_fk FOREIGN KEY (email) REFERENCES cm_emails(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_action_jobs
    ADD CONSTRAINT cm_action_jobs_slack_webhook_fkey FOREIGN KEY (slack_webhook) REFERENCES cm_slack_webhooks(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_action_jobs
    ADD CONSTRAINT cm_action_jobs_trigger_event_fk FOREIGN KEY (trigger_event) REFERENCES cm_trigger_jobs(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_action_jobs
    ADD CONSTRAINT cm_action_jobs_webhook_fkey FOREIGN KEY (webhook) REFERENCES cm_webhooks(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_emails
    ADD CONSTRAINT cm_emails_changed_by_fk FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_emails
    ADD CONSTRAINT cm_emails_created_by_fk FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_emails
    ADD CONSTRAINT cm_emails_monitor FOREIGN KEY (monitor) REFERENCES cm_monitors(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_last_searched
    ADD CONSTRAINT cm_last_searched_monitor_id_fkey FOREIGN KEY (monitor_id) REFERENCES cm_monitors(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_last_searched
    ADD CONSTRAINT cm_last_searched_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_monitors
    ADD CONSTRAINT cm_monitors_changed_by_fk FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_monitors
    ADD CONSTRAINT cm_monitors_created_by_fk FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_monitors
    ADD CONSTRAINT cm_monitors_org_id_fk FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_monitors
    ADD CONSTRAINT cm_monitors_user_id_fk FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_recipients
    ADD CONSTRAINT cm_recipients_emails FOREIGN KEY (email) REFERENCES cm_emails(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_recipients
    ADD CONSTRAINT cm_recipients_org_id_fk FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_recipients
    ADD CONSTRAINT cm_recipients_user_id_fk FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_slack_webhooks
    ADD CONSTRAINT cm_slack_webhooks_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_slack_webhooks
    ADD CONSTRAINT cm_slack_webhooks_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_slack_webhooks
    ADD CONSTRAINT cm_slack_webhooks_monitor_fkey FOREIGN KEY (monitor) REFERENCES cm_monitors(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_trigger_jobs
    ADD CONSTRAINT cm_trigger_jobs_query_fk FOREIGN KEY (query) REFERENCES cm_queries(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_queries
    ADD CONSTRAINT cm_triggers_changed_by_fk FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_queries
    ADD CONSTRAINT cm_triggers_created_by_fk FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_queries
    ADD CONSTRAINT cm_triggers_monitor FOREIGN KEY (monitor) REFERENCES cm_monitors(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_webhooks
    ADD CONSTRAINT cm_webhooks_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_webhooks
    ADD CONSTRAINT cm_webhooks_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY cm_webhooks
    ADD CONSTRAINT cm_webhooks_monitor_fkey FOREIGN KEY (monitor) REFERENCES cm_monitors(id) ON DELETE CASCADE;

ALTER TABLE ONLY codeintel_autoindexing_exceptions
    ADD CONSTRAINT codeintel_autoindexing_exceptions_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY codeowners_individual_stats
    ADD CONSTRAINT codeowners_individual_stats_file_path_id_fkey FOREIGN KEY (file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY codeowners_individual_stats
    ADD CONSTRAINT codeowners_individual_stats_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES codeowners_owners(id);

ALTER TABLE ONLY codeowners
    ADD CONSTRAINT codeowners_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY completion_credits_consumption
    ADD CONSTRAINT completion_credits_consumption_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY completion_credits_entitlement_window_usage
    ADD CONSTRAINT completion_credits_entitlement_window_usage_entitlement_id_fkey FOREIGN KEY (entitlement_id) REFERENCES entitlements(id) ON DELETE CASCADE;

ALTER TABLE ONLY completion_credits_entitlement_window_usage
    ADD CONSTRAINT completion_credits_entitlement_window_usage_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY contributor_data
    ADD CONSTRAINT contributor_data_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY contributor_jobs
    ADD CONSTRAINT contributor_jobs_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY contributor_repos
    ADD CONSTRAINT contributor_repos_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY deepsearch_conversations
    ADD CONSTRAINT deepsearch_conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY deepsearch_questions
    ADD CONSTRAINT deepsearch_questions_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES deepsearch_conversations(id) ON DELETE CASCADE;

ALTER TABLE ONLY deepsearch_quota
    ADD CONSTRAINT deepsearch_quota_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY deepsearch_references
    ADD CONSTRAINT deepsearch_references_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES deepsearch_conversations(id) ON DELETE CASCADE;

ALTER TABLE ONLY deepsearch_references
    ADD CONSTRAINT deepsearch_references_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE SET NULL;

ALTER TABLE ONLY entitlement_grants
    ADD CONSTRAINT entitlement_grants_entitlement_id_fkey FOREIGN KEY (entitlement_id) REFERENCES entitlements(id) ON DELETE CASCADE;

ALTER TABLE ONLY entitlement_grants
    ADD CONSTRAINT entitlement_grants_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY executor_secret_access_logs
    ADD CONSTRAINT executor_secret_access_logs_executor_secret_id_fkey FOREIGN KEY (executor_secret_id) REFERENCES executor_secrets(id) ON DELETE CASCADE;

ALTER TABLE ONLY executor_secret_access_logs
    ADD CONSTRAINT executor_secret_access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY executor_secrets
    ADD CONSTRAINT executor_secrets_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY executor_secrets
    ADD CONSTRAINT executor_secrets_namespace_org_id_fkey FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY executor_secrets
    ADD CONSTRAINT executor_secrets_namespace_user_id_fkey FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY exhaustive_search_jobs
    ADD CONSTRAINT exhaustive_search_jobs_initiator_id_fkey FOREIGN KEY (initiator_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY exhaustive_search_repo_jobs
    ADD CONSTRAINT exhaustive_search_repo_jobs_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY exhaustive_search_repo_jobs
    ADD CONSTRAINT exhaustive_search_repo_jobs_search_job_id_fkey FOREIGN KEY (search_job_id) REFERENCES exhaustive_search_jobs(id) ON DELETE CASCADE;

ALTER TABLE ONLY exhaustive_search_repo_revision_jobs
    ADD CONSTRAINT exhaustive_search_repo_revision_jobs_search_repo_job_id_fkey FOREIGN KEY (search_repo_job_id) REFERENCES exhaustive_search_repo_jobs(id) ON DELETE CASCADE;

ALTER TABLE ONLY external_service_repos
    ADD CONSTRAINT external_service_repos_external_service_id_fkey FOREIGN KEY (external_service_id) REFERENCES external_services(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY external_service_repos
    ADD CONSTRAINT external_service_repos_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY external_services
    ADD CONSTRAINT external_services_code_host_id_fkey FOREIGN KEY (code_host_id) REFERENCES code_hosts(id) ON UPDATE CASCADE ON DELETE SET NULL DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE ONLY external_services
    ADD CONSTRAINT external_services_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY external_service_sync_jobs
    ADD CONSTRAINT external_services_id_fk FOREIGN KEY (external_service_id) REFERENCES external_services(id) ON DELETE CASCADE;

ALTER TABLE ONLY external_services
    ADD CONSTRAINT external_services_last_updater_id_fkey FOREIGN KEY (last_updater_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY feature_flag_overrides
    ADD CONSTRAINT feature_flag_overrides_namespace_org_id_fkey FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY feature_flag_overrides
    ADD CONSTRAINT feature_flag_overrides_namespace_user_id_fkey FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY idp_oauth_apps
    ADD CONSTRAINT fk_idp_oauth_apps_client_id FOREIGN KEY (client_id, tenant_id) REFERENCES idp_clients(opaque_id, tenant_id) ON DELETE CASCADE;

ALTER TABLE ONLY idp_service_account_m2m_clients
    ADD CONSTRAINT fk_idp_service_account_m2m_clients_client_id FOREIGN KEY (client_id, tenant_id) REFERENCES idp_clients(opaque_id, tenant_id) ON DELETE CASCADE;

ALTER TABLE ONLY idp_service_account_m2m_clients
    ADD CONSTRAINT fk_idp_service_account_m2m_clients_service_account_id FOREIGN KEY (service_account_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY vulnerability_matches
    ADD CONSTRAINT fk_upload FOREIGN KEY (upload_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY scip_uploads_vulnerability_scan
    ADD CONSTRAINT fk_upload_id FOREIGN KEY (upload_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY vulnerability_affected_packages
    ADD CONSTRAINT fk_vulnerabilities FOREIGN KEY (vulnerability_id) REFERENCES vulnerabilities(id) ON DELETE CASCADE;

ALTER TABLE ONLY vulnerability_affected_symbols
    ADD CONSTRAINT fk_vulnerability_affected_packages FOREIGN KEY (vulnerability_affected_package_id) REFERENCES vulnerability_affected_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY vulnerability_matches
    ADD CONSTRAINT fk_vulnerability_affected_packages FOREIGN KEY (vulnerability_affected_package_id) REFERENCES vulnerability_affected_packages(id) ON DELETE CASCADE;

ALTER TABLE ONLY github_app_installs
    ADD CONSTRAINT github_app_installs_app_id_fkey FOREIGN KEY (app_id) REFERENCES github_apps(id) ON DELETE CASCADE;

ALTER TABLE ONLY github_apps
    ADD CONSTRAINT github_apps_webhook_id_fkey FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE SET NULL;

ALTER TABLE ONLY gitserver_repos
    ADD CONSTRAINT gitserver_repos_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY gitserver_repos_sync_output
    ADD CONSTRAINT gitserver_repos_sync_output_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY insights_query_runner_jobs_dependencies
    ADD CONSTRAINT insights_query_runner_jobs_dependencies_fk_job_id FOREIGN KEY (job_id) REFERENCES insights_query_runner_jobs(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_dependency_syncing_jobs
    ADD CONSTRAINT lsif_dependency_indexing_jobs_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_dependency_indexing_jobs
    ADD CONSTRAINT lsif_dependency_indexing_jobs_upload_id_fkey1 FOREIGN KEY (upload_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_index_configuration
    ADD CONSTRAINT lsif_index_configuration_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_indexes
    ADD CONSTRAINT lsif_indexes_matched_policy_id_fkey FOREIGN KEY (matched_policy_id) REFERENCES lsif_configuration_policies(id) ON DELETE RESTRICT;

ALTER TABLE ONLY lsif_packages
    ADD CONSTRAINT lsif_packages_dump_id_fkey FOREIGN KEY (dump_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_references
    ADD CONSTRAINT lsif_references_dump_id_fkey FOREIGN KEY (dump_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY lsif_retention_configuration
    ADD CONSTRAINT lsif_retention_configuration_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY names
    ADD CONSTRAINT names_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY names
    ADD CONSTRAINT names_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY names
    ADD CONSTRAINT names_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY namespace_permissions
    ADD CONSTRAINT namespace_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY notebook_stars
    ADD CONSTRAINT notebook_stars_notebook_id_fkey FOREIGN KEY (notebook_id) REFERENCES notebooks(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY notebook_stars
    ADD CONSTRAINT notebook_stars_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY notebooks
    ADD CONSTRAINT notebooks_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY notebooks
    ADD CONSTRAINT notebooks_namespace_org_id_fkey FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY notebooks
    ADD CONSTRAINT notebooks_namespace_user_id_fkey FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY notebooks
    ADD CONSTRAINT notebooks_updater_user_id_fkey FOREIGN KEY (updater_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY org_invitations
    ADD CONSTRAINT org_invitations_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(id);

ALTER TABLE ONLY org_invitations
    ADD CONSTRAINT org_invitations_recipient_user_id_fkey FOREIGN KEY (recipient_user_id) REFERENCES users(id);

ALTER TABLE ONLY org_invitations
    ADD CONSTRAINT org_invitations_sender_user_id_fkey FOREIGN KEY (sender_user_id) REFERENCES users(id);

ALTER TABLE ONLY org_members
    ADD CONSTRAINT org_members_references_orgs FOREIGN KEY (org_id) REFERENCES orgs(id) ON DELETE RESTRICT;

ALTER TABLE ONLY org_members
    ADD CONSTRAINT org_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY org_stats
    ADD CONSTRAINT org_stats_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY out_of_band_migrations_errors
    ADD CONSTRAINT out_of_band_migrations_errors_migration_id_fkey FOREIGN KEY (migration_id) REFERENCES out_of_band_migrations(id) ON DELETE CASCADE;

ALTER TABLE ONLY outbound_webhook_event_types
    ADD CONSTRAINT outbound_webhook_event_types_outbound_webhook_id_fkey FOREIGN KEY (outbound_webhook_id) REFERENCES outbound_webhooks(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY outbound_webhook_logs
    ADD CONSTRAINT outbound_webhook_logs_job_id_fkey FOREIGN KEY (job_id) REFERENCES outbound_webhook_jobs(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY outbound_webhook_logs
    ADD CONSTRAINT outbound_webhook_logs_outbound_webhook_id_fkey FOREIGN KEY (outbound_webhook_id) REFERENCES outbound_webhooks(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY outbound_webhooks
    ADD CONSTRAINT outbound_webhooks_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY outbound_webhooks
    ADD CONSTRAINT outbound_webhooks_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY own_aggregate_recent_contribution
    ADD CONSTRAINT own_aggregate_recent_contribution_changed_file_path_id_fkey FOREIGN KEY (changed_file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY own_aggregate_recent_contribution
    ADD CONSTRAINT own_aggregate_recent_contribution_commit_author_id_fkey FOREIGN KEY (commit_author_id) REFERENCES commit_authors(id);

ALTER TABLE ONLY own_aggregate_recent_view
    ADD CONSTRAINT own_aggregate_recent_view_viewed_file_path_id_fkey FOREIGN KEY (viewed_file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY own_aggregate_recent_view
    ADD CONSTRAINT own_aggregate_recent_view_viewer_id_fkey FOREIGN KEY (viewer_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY own_signal_recent_contribution
    ADD CONSTRAINT own_signal_recent_contribution_changed_file_path_id_fkey FOREIGN KEY (changed_file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY own_signal_recent_contribution
    ADD CONSTRAINT own_signal_recent_contribution_commit_author_id_fkey FOREIGN KEY (commit_author_id) REFERENCES commit_authors(id);

ALTER TABLE ONLY ownership_path_stats
    ADD CONSTRAINT ownership_path_stats_file_path_id_fkey FOREIGN KEY (file_path_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY package_repo_versions
    ADD CONSTRAINT package_id_fk FOREIGN KEY (package_id) REFERENCES lsif_dependency_repos(id) ON DELETE CASCADE;

ALTER TABLE ONLY permission_sync_jobs
    ADD CONSTRAINT permission_sync_jobs_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY permission_sync_jobs
    ADD CONSTRAINT permission_sync_jobs_triggered_by_user_id_fkey FOREIGN KEY (triggered_by_user_id) REFERENCES users(id) ON DELETE SET NULL DEFERRABLE;

ALTER TABLE ONLY permission_sync_jobs
    ADD CONSTRAINT permission_sync_jobs_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY prompt_tags
    ADD CONSTRAINT prompt_tags_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY prompt_tags
    ADD CONSTRAINT prompt_tags_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY prompts
    ADD CONSTRAINT prompts_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY prompts
    ADD CONSTRAINT prompts_owner_org_id_fkey FOREIGN KEY (owner_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY prompts
    ADD CONSTRAINT prompts_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY prompts_tags_mappings
    ADD CONSTRAINT prompts_tags_mappings_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY prompts_tags_mappings
    ADD CONSTRAINT prompts_tags_mappings_prompt_id_fkey FOREIGN KEY (prompt_id) REFERENCES prompts(id) ON DELETE CASCADE;

ALTER TABLE ONLY prompts_tags_mappings
    ADD CONSTRAINT prompts_tags_mappings_prompt_tag_id_fkey FOREIGN KEY (prompt_tag_id) REFERENCES prompt_tags(id) ON DELETE CASCADE;

ALTER TABLE ONLY prompts
    ADD CONSTRAINT prompts_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY registry_extension_releases
    ADD CONSTRAINT registry_extension_releases_creator_user_id_fkey FOREIGN KEY (creator_user_id) REFERENCES users(id);

ALTER TABLE ONLY registry_extension_releases
    ADD CONSTRAINT registry_extension_releases_registry_extension_id_fkey FOREIGN KEY (registry_extension_id) REFERENCES registry_extensions(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY registry_extensions
    ADD CONSTRAINT registry_extensions_publisher_org_id_fkey FOREIGN KEY (publisher_org_id) REFERENCES orgs(id);

ALTER TABLE ONLY registry_extensions
    ADD CONSTRAINT registry_extensions_publisher_user_id_fkey FOREIGN KEY (publisher_user_id) REFERENCES users(id);

ALTER TABLE ONLY repo_cleanup_jobs
    ADD CONSTRAINT repo_cleanup_jobs_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY repo_commits_changelists
    ADD CONSTRAINT repo_commits_changelists_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY repo_embedding_job_stats
    ADD CONSTRAINT repo_embedding_job_stats_job_id_fkey FOREIGN KEY (job_id) REFERENCES repo_embedding_jobs(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY repo_kvps
    ADD CONSTRAINT repo_kvps_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY repo_paths
    ADD CONSTRAINT repo_paths_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES repo_paths(id);

ALTER TABLE ONLY repo_paths
    ADD CONSTRAINT repo_paths_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY repo_update_jobs
    ADD CONSTRAINT repo_update_jobs_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY saved_searches
    ADD CONSTRAINT saved_searches_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY saved_searches
    ADD CONSTRAINT saved_searches_org_id_fkey FOREIGN KEY (org_id) REFERENCES orgs(id);

ALTER TABLE ONLY saved_searches
    ADD CONSTRAINT saved_searches_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY saved_searches
    ADD CONSTRAINT saved_searches_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY scip_uploads_reference_counts
    ADD CONSTRAINT scip_uploads_reference_counts_upload_id_fk FOREIGN KEY (upload_id) REFERENCES scip_uploads(id) ON DELETE CASCADE;

ALTER TABLE ONLY search_context_default
    ADD CONSTRAINT search_context_default_search_context_id_fkey FOREIGN KEY (search_context_id) REFERENCES search_contexts(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY search_context_default
    ADD CONSTRAINT search_context_default_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY search_context_repos
    ADD CONSTRAINT search_context_repos_repo_id_fk FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY search_context_repos
    ADD CONSTRAINT search_context_repos_search_context_id_fk FOREIGN KEY (search_context_id) REFERENCES search_contexts(id) ON DELETE CASCADE;

ALTER TABLE ONLY search_context_stars
    ADD CONSTRAINT search_context_stars_search_context_id_fkey FOREIGN KEY (search_context_id) REFERENCES search_contexts(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY search_context_stars
    ADD CONSTRAINT search_context_stars_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY search_contexts
    ADD CONSTRAINT search_contexts_namespace_org_id_fk FOREIGN KEY (namespace_org_id) REFERENCES orgs(id) ON DELETE CASCADE;

ALTER TABLE ONLY search_contexts
    ADD CONSTRAINT search_contexts_namespace_user_id_fk FOREIGN KEY (namespace_user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_author_user_id_fkey FOREIGN KEY (author_user_id) REFERENCES users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_references_orgs FOREIGN KEY (org_id) REFERENCES orgs(id) ON DELETE RESTRICT;

ALTER TABLE ONLY settings
    ADD CONSTRAINT settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT;

ALTER TABLE ONLY sub_repo_permissions
    ADD CONSTRAINT sub_repo_permissions_repo_id_fk FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY sub_repo_permissions
    ADD CONSTRAINT sub_repo_permissions_users_id_fk FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY survey_responses
    ADD CONSTRAINT survey_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY team_members
    ADD CONSTRAINT team_members_team_id_fkey FOREIGN KEY (team_id) REFERENCES teams(id) ON DELETE CASCADE;

ALTER TABLE ONLY team_members
    ADD CONSTRAINT team_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_creator_id_fkey FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY teams
    ADD CONSTRAINT teams_parent_team_id_fkey FOREIGN KEY (parent_team_id) REFERENCES teams(id) ON DELETE CASCADE;

ALTER TABLE ONLY temporary_settings
    ADD CONSTRAINT temporary_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_credentials
    ADD CONSTRAINT user_credentials_github_app_id_fkey FOREIGN KEY (github_app_id) REFERENCES github_apps(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_credentials
    ADD CONSTRAINT user_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY user_emails
    ADD CONSTRAINT user_emails_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY user_external_accounts
    ADD CONSTRAINT user_external_accounts_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY user_onboarding_tour
    ADD CONSTRAINT user_onboarding_tour_users_fk FOREIGN KEY (updated_by) REFERENCES users(id);

ALTER TABLE ONLY user_repo_permissions
    ADD CONSTRAINT user_repo_permissions_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_repo_permissions
    ADD CONSTRAINT user_repo_permissions_user_external_account_id_fkey FOREIGN KEY (user_external_account_id) REFERENCES user_external_accounts(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_repo_permissions
    ADD CONSTRAINT user_repo_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE DEFERRABLE;

ALTER TABLE ONLY webhook_logs
    ADD CONSTRAINT webhook_logs_external_service_id_fkey FOREIGN KEY (external_service_id) REFERENCES external_services(id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY webhook_logs
    ADD CONSTRAINT webhook_logs_webhook_id_fkey FOREIGN KEY (webhook_id) REFERENCES webhooks(id) ON DELETE CASCADE;

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_created_by_user_id_fkey FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY webhooks
    ADD CONSTRAINT webhooks_updated_by_user_id_fkey FOREIGN KEY (updated_by_user_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY zoekt_index_jobs
    ADD CONSTRAINT zoekt_index_jobs_repository_id_fkey FOREIGN KEY (repository_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE ONLY zoekt_repos
    ADD CONSTRAINT zoekt_repos_repo_id_fkey FOREIGN KEY (repo_id) REFERENCES repo(id) ON DELETE CASCADE;

ALTER TABLE access_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE access_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE aggregated_user_statistics ENABLE ROW LEVEL SECURITY;

ALTER TABLE assigned_owners ENABLE ROW LEVEL SECURITY;

ALTER TABLE assigned_teams ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_changes ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_changes_site_credentials ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_execution_cache_entries ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_library_records ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_library_variables ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_resolution_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_workspace_execution_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_workspace_execution_last_dequeues ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_workspace_files ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_spec_workspaces ENABLE ROW LEVEL SECURITY;

ALTER TABLE batch_specs ENABLE ROW LEVEL SECURITY;

ALTER TABLE cached_available_indexers ENABLE ROW LEVEL SECURITY;

ALTER TABLE changeset_events ENABLE ROW LEVEL SECURITY;

ALTER TABLE changeset_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE changeset_specs ENABLE ROW LEVEL SECURITY;

ALTER TABLE changeset_sync_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE changesets ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_action_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_emails ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_last_searched ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_monitors ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_queries ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_recipients ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_slack_webhooks ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_trigger_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE cm_webhooks ENABLE ROW LEVEL SECURITY;

ALTER TABLE code_hosts ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_autoindex_queue ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_autoindexing_exceptions ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_commit_dates ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_inference_scripts ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeintel_langugage_support_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeowners ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeowners_individual_stats ENABLE ROW LEVEL SECURITY;

ALTER TABLE codeowners_owners ENABLE ROW LEVEL SECURITY;

ALTER TABLE cody_audit_log ENABLE ROW LEVEL SECURITY;

ALTER TABLE commit_authors ENABLE ROW LEVEL SECURITY;

ALTER TABLE completion_credits_consumption ENABLE ROW LEVEL SECURITY;

ALTER TABLE completion_credits_entitlement_window_usage ENABLE ROW LEVEL SECURITY;

ALTER TABLE configuration_policies_audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE context_detection_embedding_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE contributor_data ENABLE ROW LEVEL SECURITY;

ALTER TABLE contributor_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE contributor_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE deepsearch_conversations ENABLE ROW LEVEL SECURITY;

ALTER TABLE deepsearch_questions ENABLE ROW LEVEL SECURITY;

ALTER TABLE deepsearch_quota ENABLE ROW LEVEL SECURITY;

ALTER TABLE deepsearch_references ENABLE ROW LEVEL SECURITY;

ALTER TABLE entitlement_grants ENABLE ROW LEVEL SECURITY;

ALTER TABLE entitlements ENABLE ROW LEVEL SECURITY;

ALTER TABLE event_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE event_logs_scrape_state ENABLE ROW LEVEL SECURITY;

ALTER TABLE event_logs_scrape_state_own ENABLE ROW LEVEL SECURITY;

ALTER TABLE executor_heartbeats ENABLE ROW LEVEL SECURITY;

ALTER TABLE executor_job_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE executor_secret_access_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE executor_secrets ENABLE ROW LEVEL SECURITY;

ALTER TABLE exhaustive_search_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE exhaustive_search_repo_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE exhaustive_search_repo_revision_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE explicit_permissions_bitbucket_projects_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE external_service_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE external_service_sync_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE external_services ENABLE ROW LEVEL SECURITY;

ALTER TABLE feature_flag_overrides ENABLE ROW LEVEL SECURITY;

ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;

ALTER TABLE github_app_installs ENABLE ROW LEVEL SECURITY;

ALTER TABLE github_apps ENABLE ROW LEVEL SECURITY;

ALTER TABLE gitserver_relocator_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE gitserver_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE gitserver_repos_sync_output ENABLE ROW LEVEL SECURITY;

ALTER TABLE global_state ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_authorize_codes ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_clients ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_consent_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_device_auth_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_id_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_oauth_apps ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_pkce_requests ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_secrets ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_service_account_m2m_clients ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_sessions ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_tokens ENABLE ROW LEVEL SECURITY;

ALTER TABLE idp_user_consents ENABLE ROW LEVEL SECURITY;

ALTER TABLE insights_query_runner_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE insights_query_runner_jobs_dependencies ENABLE ROW LEVEL SECURITY;

ALTER TABLE insights_settings_migration_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_configuration_policies ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_configuration_policies_repository_pattern_lookup ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_dependency_indexing_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_dependency_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_dependency_syncing_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_dirty_repositories ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_index_configuration ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_indexes ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_last_index_scan ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_last_retention_scan ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_packages ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_references ENABLE ROW LEVEL SECURITY;

ALTER TABLE lsif_retention_configuration ENABLE ROW LEVEL SECURITY;

ALTER TABLE names ENABLE ROW LEVEL SECURITY;

ALTER TABLE namespace_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE notebook_stars ENABLE ROW LEVEL SECURITY;

ALTER TABLE notebooks ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_invitations ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_members ENABLE ROW LEVEL SECURITY;

ALTER TABLE org_stats ENABLE ROW LEVEL SECURITY;

ALTER TABLE orgs ENABLE ROW LEVEL SECURITY;

ALTER TABLE out_of_band_migrations_errors ENABLE ROW LEVEL SECURITY;

ALTER TABLE outbound_webhook_event_types ENABLE ROW LEVEL SECURITY;

ALTER TABLE outbound_webhook_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE outbound_webhook_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE outbound_webhooks ENABLE ROW LEVEL SECURITY;

ALTER TABLE own_aggregate_recent_contribution ENABLE ROW LEVEL SECURITY;

ALTER TABLE own_aggregate_recent_view ENABLE ROW LEVEL SECURITY;

ALTER TABLE own_background_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE own_signal_configurations ENABLE ROW LEVEL SECURITY;

ALTER TABLE own_signal_recent_contribution ENABLE ROW LEVEL SECURITY;

ALTER TABLE ownership_path_stats ENABLE ROW LEVEL SECURITY;

ALTER TABLE package_repo_filters ENABLE ROW LEVEL SECURITY;

ALTER TABLE package_repo_versions ENABLE ROW LEVEL SECURITY;

ALTER TABLE pending_repo_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE permission_sync_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE phabricator_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE prompt_tags ENABLE ROW LEVEL SECURITY;

ALTER TABLE prompts ENABLE ROW LEVEL SECURITY;

ALTER TABLE prompts_tags_mappings ENABLE ROW LEVEL SECURITY;

ALTER TABLE registry_extension_releases ENABLE ROW LEVEL SECURITY;

ALTER TABLE registry_extensions ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_cleanup_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_commits_changelists ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_embedding_job_stats ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_embedding_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_kvps ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_paths ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_statistics ENABLE ROW LEVEL SECURITY;

ALTER TABLE repo_update_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE role_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE saved_searches ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_nearest_uploads ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_nearest_uploads_links ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_uploads ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_uploads_audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_uploads_reference_counts ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_uploads_visible_at_tip ENABLE ROW LEVEL SECURITY;

ALTER TABLE scip_uploads_vulnerability_scan ENABLE ROW LEVEL SECURITY;

ALTER TABLE search_context_default ENABLE ROW LEVEL SECURITY;

ALTER TABLE search_context_repos ENABLE ROW LEVEL SECURITY;

ALTER TABLE search_context_stars ENABLE ROW LEVEL SECURITY;

ALTER TABLE search_contexts ENABLE ROW LEVEL SECURITY;

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

ALTER TABLE sub_repo_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE survey_responses ENABLE ROW LEVEL SECURITY;

ALTER TABLE syntactic_scip_indexing_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE syntactic_scip_indexing_jobs_audit_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE syntactic_scip_last_index_scan ENABLE ROW LEVEL SECURITY;

ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;

ALTER TABLE teams ENABLE ROW LEVEL SECURITY;

ALTER TABLE telemetry_events_export_queue ENABLE ROW LEVEL SECURITY;

ALTER TABLE temporary_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation_policy ON access_requests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON access_tokens USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON aggregated_user_statistics USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON assigned_owners USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON assigned_teams USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_changes USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_changes_site_credentials USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_spec_execution_cache_entries USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_spec_library_records USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_spec_library_variables USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_spec_resolution_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON batch_spec_workspace_execution_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON batch_spec_workspace_execution_last_dequeues USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON batch_spec_workspace_files USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_spec_workspaces USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON batch_specs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cached_available_indexers USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON changeset_events USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON changeset_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON changeset_specs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON changeset_sync_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON changesets USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON cm_action_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON cm_emails USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_last_searched USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_monitors USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_queries USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_recipients USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_slack_webhooks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cm_trigger_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON cm_webhooks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON code_hosts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_autoindex_queue USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_autoindexing_exceptions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_commit_dates USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_inference_scripts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeintel_langugage_support_requests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeowners USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeowners_individual_stats USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON codeowners_owners USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON cody_audit_log USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON commit_authors USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON completion_credits_consumption USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON completion_credits_entitlement_window_usage USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON configuration_policies_audit_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON context_detection_embedding_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON contributor_data USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON contributor_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON contributor_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON deepsearch_conversations USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON deepsearch_questions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON deepsearch_quota USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON deepsearch_references USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON entitlement_grants USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON entitlements USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON event_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON event_logs_scrape_state USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON event_logs_scrape_state_own USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON executor_heartbeats USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON executor_job_tokens USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON executor_secret_access_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON executor_secrets USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON exhaustive_search_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON exhaustive_search_repo_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON exhaustive_search_repo_revision_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON explicit_permissions_bitbucket_projects_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON external_service_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON external_service_sync_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON external_services USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON feature_flag_overrides USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON feature_flags USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON github_app_installs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON github_apps USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON gitserver_relocator_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON gitserver_repos USING ((( SELECT (current_setting('app.current_tenant'::text) = 'zoekttenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON gitserver_repos_sync_output USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON global_state USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_authorize_codes USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_clients USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_consent_requests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_device_auth_requests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_id_tokens USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_oauth_apps USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_pkce_requests USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_secrets USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_service_account_m2m_clients USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_sessions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_tokens USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON idp_user_consents USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON insights_query_runner_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON insights_query_runner_jobs_dependencies USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON insights_settings_migration_jobs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_configuration_policies USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_configuration_policies_repository_pattern_lookup USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_dependency_indexing_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON lsif_dependency_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_dependency_syncing_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON lsif_dirty_repositories USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_index_configuration USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_indexes USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON lsif_last_index_scan USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_last_retention_scan USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_packages USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_references USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON lsif_retention_configuration USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON names USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON namespace_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON notebook_stars USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON notebooks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON org_invitations USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON org_members USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON org_stats USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON orgs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON out_of_band_migrations_errors USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON outbound_webhook_event_types USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON outbound_webhook_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON outbound_webhook_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON outbound_webhooks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON own_aggregate_recent_contribution USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON own_aggregate_recent_view USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON own_background_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON own_signal_configurations USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON own_signal_recent_contribution USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON ownership_path_stats USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON package_repo_filters USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON package_repo_versions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON pending_repo_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON permission_sync_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON phabricator_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON prompt_tags USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON prompts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON prompts_tags_mappings USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON registry_extension_releases USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON registry_extensions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo USING ((( SELECT (current_setting('app.current_tenant'::text) = 'zoekttenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON repo_cleanup_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON repo_commits_changelists USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo_embedding_job_stats USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo_embedding_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON repo_kvps USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo_paths USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo_statistics USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON repo_update_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON role_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON roles USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON saved_searches USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON scip_nearest_uploads USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON scip_nearest_uploads_links USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON scip_uploads USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON scip_uploads_audit_logs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON scip_uploads_reference_counts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON scip_uploads_visible_at_tip USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON scip_uploads_vulnerability_scan USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON search_context_default USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON search_context_repos USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON search_context_stars USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON search_contexts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON settings USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON sub_repo_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON survey_responses USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs_audit_logs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON syntactic_scip_last_index_scan USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON team_members USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON teams USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON telemetry_events_export_queue USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON temporary_settings USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON tenants USING ((( SELECT (current_setting('app.current_tenant'::text) = ANY (ARRAY['servicetenant'::text, 'workertenant'::text, 'zoekttenant'::text]))) OR (id = ( SELECT (NULLIF(NULLIF(NULLIF(current_setting('app.current_tenant'::text), 'servicetenant'::text), 'workertenant'::text), 'zoekttenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON user_credentials USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON user_emails USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON user_external_accounts USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON user_onboarding_tour USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON user_repo_permissions USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON user_roles USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON users USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON vulnerabilities USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON vulnerability_affected_packages USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON vulnerability_affected_symbols USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON vulnerability_matches USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON webhook_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON webhooks USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE POLICY tenant_isolation_policy ON zoekt_index_jobs USING ((( SELECT (current_setting('app.current_tenant'::text) = 'workertenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'workertenant'::text))::integer AS current_tenant))));

CREATE POLICY tenant_isolation_policy ON zoekt_repos USING ((( SELECT (current_setting('app.current_tenant'::text) = 'zoekttenant'::text)) OR (tenant_id = ( SELECT (NULLIF(current_setting('app.current_tenant'::text), 'zoekttenant'::text))::integer AS current_tenant))));

ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_credentials ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_emails ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_external_accounts ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_onboarding_tour ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_repo_permissions ENABLE ROW LEVEL SECURITY;

ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

ALTER TABLE vulnerabilities ENABLE ROW LEVEL SECURITY;

ALTER TABLE vulnerability_affected_packages ENABLE ROW LEVEL SECURITY;

ALTER TABLE vulnerability_affected_symbols ENABLE ROW LEVEL SECURITY;

ALTER TABLE vulnerability_matches ENABLE ROW LEVEL SECURITY;

ALTER TABLE webhook_logs ENABLE ROW LEVEL SECURITY;

ALTER TABLE webhooks ENABLE ROW LEVEL SECURITY;

ALTER TABLE zoekt_index_jobs ENABLE ROW LEVEL SECURITY;

ALTER TABLE zoekt_repos ENABLE ROW LEVEL SECURITY;

INSERT INTO lsif_configuration_policies (id, repository_id, name, type, pattern, retention_enabled, retention_duration_hours, retain_intermediate_commits, indexing_enabled, index_commit_max_age_hours, index_intermediate_commits, protected, repository_patterns, last_resolved_at, embeddings_enabled, syntactic_indexing_enabled, tenant_id) VALUES (1, NULL, 'Default tip-of-branch retention policy', 'GIT_TREE', '*', true, 2016, false, false, 0, false, true, NULL, NULL, false, false, 1);
INSERT INTO lsif_configuration_policies (id, repository_id, name, type, pattern, retention_enabled, retention_duration_hours, retain_intermediate_commits, indexing_enabled, index_commit_max_age_hours, index_intermediate_commits, protected, repository_patterns, last_resolved_at, embeddings_enabled, syntactic_indexing_enabled, tenant_id) VALUES (2, NULL, 'Default tag retention policy', 'GIT_TAG', '*', true, 8064, false, false, 0, false, true, NULL, NULL, false, false, 1);
INSERT INTO lsif_configuration_policies (id, repository_id, name, type, pattern, retention_enabled, retention_duration_hours, retain_intermediate_commits, indexing_enabled, index_commit_max_age_hours, index_intermediate_commits, protected, repository_patterns, last_resolved_at, embeddings_enabled, syntactic_indexing_enabled, tenant_id) VALUES (3, NULL, 'Default commit retention policy', 'GIT_TREE', '*', true, 168, true, false, 0, false, true, NULL, NULL, false, false, 1);

SELECT pg_catalog.setval('lsif_configuration_policies_id_seq', 3, true);

INSERT INTO own_signal_configurations (id, name, description, excluded_repo_patterns, enabled, tenant_id) VALUES (1, 'recent-contributors', 'Indexes contributors in each file using repository history.', NULL, false, 1);
INSERT INTO own_signal_configurations (id, name, description, excluded_repo_patterns, enabled, tenant_id) VALUES (2, 'recent-views', 'Indexes users that recently viewed files in Sourcegraph.', NULL, false, 1);
INSERT INTO own_signal_configurations (id, name, description, excluded_repo_patterns, enabled, tenant_id) VALUES (3, 'analytics', 'Indexes ownership data to present in aggregated views like Admin > Analytics > Own and Repo > Ownership', NULL, false, 1);

SELECT pg_catalog.setval('own_signal_configurations_id_seq', 3, true);

INSERT INTO roles (id, created_at, system, name, tenant_id) VALUES (1, '2023-01-04 16:29:41.195966+00', true, 'USER', 1);
INSERT INTO roles (id, created_at, system, name, tenant_id) VALUES (2, '2023-01-04 16:29:41.195966+00', true, 'SITE_ADMINISTRATOR', 1);
INSERT INTO roles (id, created_at, system, name, tenant_id) VALUES (4, '2024-10-30 11:54:24.127459+00', true, 'WORKSPACE_ADMINISTRATOR', 1);
INSERT INTO roles (id, created_at, system, name, tenant_id) VALUES (5, '2025-06-17 14:47:24.127459+00', true, 'SERVICE_ACCOUNT', 1);

SELECT pg_catalog.setval('roles_id_seq', 5, true);

INSERT INTO tenants (id, name, created_at, updated_at, workspace_id, display_name, state, external_url, redis_pruned_at, deleted_at, gitserver_pruned_at, zoekt_pruned_at, blobstore_pruned_at, database_pruned_at, searcher_cache_pruned_at) VALUES (1, 'default', '2024-09-28 09:41:00+00', '2024-09-28 09:41:00+00', '6a6b043c-ffed-42ec-b1f4-abc231cd7222', NULL, 'active', '', NULL, NULL, NULL, NULL, NULL, NULL, NULL);

SELECT pg_catalog.setval('tenants_id_seq', 1, true);

INSERT INTO prompts (id, name, description, definition_text, draft, visibility_secret, owner_user_id, owner_org_id, created_by, created_at, updated_by, updated_at, tenant_id, auto_submit, mode, recommended, deleted_at, builtin) VALUES (1, 'document-code', 'Document the code in a file', 'Write a brief documentation comment for  cody://selection. If documentation comments exist in  cody://current-file, or other files with the same file extension, use them as examples. Pay attention to the scope of the selected code (e.g. exported function/API vs implementation detail in a function), and use the idiomatic style for that type of code scope. Only generate the documentation for the selected code, do not generate the code. Do not enclose any other code or comments besides the documentation. Enclose only the documentation for cody://current-selection and nothing else. ', false, false, NULL, NULL, NULL, '2024-11-20 10:51:36.752627+00', NULL, '2024-11-20 10:51:36.752627+00', 1, true, 'INSERT', false, NULL, true);
INSERT INTO prompts (id, name, description, definition_text, draft, visibility_secret, owner_user_id, owner_org_id, created_by, created_at, updated_by, updated_at, tenant_id, auto_submit, mode, recommended, deleted_at, builtin) VALUES (2, 'explain-code', 'Explain the code in a file', 'Explain what cody://selection code does in simple terms. Assume the audience is a beginner programmer who has just learned the language features and basic syntax. Focus on explaining: 1) The purpose of the code 2) What input(s) it takes 3) What output(s) it produces 4) How it achieves its purpose through the logic and algorithm. 5) Any important logic flows or data transformations happening. Use simple language a beginner could understand. Include enough detail to give a full picture of what the code aims to accomplish without getting too technical. Format the explanation in coherent paragraphs, using proper punctuation and grammar. Write the explanation assuming no prior context about the code is known. Do not make assumptions about variables or functions not shown in the shared code. Start the answer with the name of the code that is being explained.', false, false, NULL, NULL, NULL, '2024-11-20 10:51:36.752627+00', NULL, '2024-11-20 10:51:36.752627+00', 1, true, 'CHAT', false, NULL, true);
INSERT INTO prompts (id, name, description, definition_text, draft, visibility_secret, owner_user_id, owner_org_id, created_by, created_at, updated_by, updated_at, tenant_id, auto_submit, mode, recommended, deleted_at, builtin) VALUES (3, 'generate-unit-tests', 'Generate unit tests the code in a file', 'Review the shared context and configurations to identify the test framework and libraries in use. Then, generate a suite of multiple unit tests for the functions in cody://selection using the detected test framework and libraries. Be sure to import the function being tested. Follow the same patterns as any shared context. Only add packages, imports, dependencies, and assertions if they are used in cody://current-dir . Pay attention to the file path of each shared context to see if test for cody://current-file already exists. If one exists, focus on generating new unit tests for uncovered cases. If none are detected, import common unit test libraries for cody://current-file. Focus on validating key functionality with simple and complete assertions. Only include mocks if one is detected in cody://current-dir . Before writing the tests, identify which test libraries and frameworks to import, e.g. "No new imports needed - using existing libs" or "Importing test framework that matches shared context usage" or "Importing the defined framework", etc. Then briefly summarize test coverage and any limitations. At the end, enclose the full completed code for the new unit tests, including all necessary imports, in a single markdown codeblock. No fragments or TODO. The new tests should validate expected functionality and cover edge cases for cody://selection with all required imports, including importing the function being tested. Do not repeat existing tests.', false, false, NULL, NULL, NULL, '2024-11-20 10:51:36.752627+00', NULL, '2024-11-20 10:51:36.752627+00', 1, true, 'CHAT', false, NULL, true);
INSERT INTO prompts (id, name, description, definition_text, draft, visibility_secret, owner_user_id, owner_org_id, created_by, created_at, updated_by, updated_at, tenant_id, auto_submit, mode, recommended, deleted_at, builtin) VALUES (4, 'find-code-smells', 'Review and analyze code', 'Please review and analyze the cody://selection and identify potential areas for improvement related to code smells, readability, maintainability, performance, security, etc. Do not list issues already addressed in the given code. Focus on providing up to 5 constructive suggestions that could make the code more robust, efficient, or align with best practices. For each suggestion, provide a brief explanation of the potential benefits. After listing any recommendations, summarize if you found notable opportunities to enhance the code quality overall or if the code generally follows sound design principles. If no issues found, reply "There are no errors."', false, false, NULL, NULL, NULL, '2024-11-20 10:51:36.752627+00', NULL, '2024-11-20 10:51:36.752627+00', 1, true, 'CHAT', false, NULL, true);

SELECT pg_catalog.setval('prompts_id_seq', 4, true);