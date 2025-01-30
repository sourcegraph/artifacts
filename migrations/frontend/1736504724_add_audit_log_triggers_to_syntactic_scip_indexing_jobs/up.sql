CREATE TABLE IF NOT EXISTS syntactic_scip_indexing_jobs_audit_logs
(
    sequence           bigserial PRIMARY KEY,
    log_timestamp      timestamp WITH TIME ZONE DEFAULT NOW() NOT NULL,
    record_deleted_at  timestamp WITH TIME ZONE,
    job_id             bigint NOT NULL,
    transition_columns hstore[] NOT NULL,
    reason             text DEFAULT ''::text NOT NULL,
    operation          audit_log_operation NOT NULL,
    tenant_id          integer DEFAULT (CURRENT_SETTING('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.log_timestamp
    IS 'Timestamp for this log entry.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.record_deleted_at
    IS 'Set once the indexing job this entry is associated with is deleted.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.transition_columns
    IS 'Array of changes that occurred to the indexing job for this entry, in the form of {"column"=>"<column name>", "old"=>"<previous value>", "new"=>"<new value>"}.';

COMMENT ON COLUMN syntactic_scip_indexing_jobs_audit_logs.reason IS 'The reason/source for this entry.';

CREATE INDEX IF NOT EXISTS syntactic_scip_indexing_jobs_audit_logs_timestamp
    ON syntactic_scip_indexing_jobs_audit_logs USING brin (log_timestamp);

CREATE INDEX IF NOT EXISTS syntactic_scip_indexing_jobs_audit_logs_indexing_job_id
    ON syntactic_scip_indexing_jobs_audit_logs (job_id);

ALTER TABLE syntactic_scip_indexing_jobs_audit_logs
    ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON syntactic_scip_indexing_jobs_audit_logs;
CREATE POLICY tenant_isolation_policy ON syntactic_scip_indexing_jobs_audit_logs AS PERMISSIVE FOR ALL TO PUBLIC USING (
    tenant_id = (SELECT (CURRENT_SETTING('app.current_tenant'::text))::integer AS current_tenant));

DO
$$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'syntactic_scip_indexing_jobs_transition_columns') THEN
            CREATE TYPE syntactic_scip_indexing_jobs_transition_columns AS
            (
                commit          text,
                state           text,
                num_resets      integer,
                num_failures    integer,
                worker_hostname text,
                failure_message text
            );

            COMMENT ON TYPE syntactic_scip_indexing_jobs_transition_columns IS
                'A type containing the columns that make-up the set of tracked transition columns. Primarily used to create a nulled record due to `OLD` being unset in INSERT queries, and creating a nulled record with a subquery is not allowed.';
        END IF;
    END
$$;

CREATE OR REPLACE FUNCTION func_row_to_syntactic_scip_indexing_jobs_transition_columns(rec record) RETURNS syntactic_scip_indexing_jobs_transition_columns
    LANGUAGE plpgsql
AS
$$
BEGIN
    RETURN (rec.commit, rec.state, rec.num_resets, rec.num_failures, rec.worker_hostname,
            rec.failure_message);
END;
$$;

CREATE OR REPLACE FUNCTION func_syntactic_scip_indexing_jobs_transition_columns_diff(old syntactic_scip_indexing_jobs_transition_columns,
                                                                                     new syntactic_scip_indexing_jobs_transition_columns) RETURNS hstore[]
    LANGUAGE plpgsql
AS
$$
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

CREATE OR REPLACE FUNCTION func_syntactic_scip_indexing_jobs_insert() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
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

CREATE OR REPLACE FUNCTION func_syntactic_scip_indexing_jobs_update() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
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

CREATE OR REPLACE FUNCTION func_syntactic_scip_indexing_jobs_delete() RETURNS trigger
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE syntactic_scip_indexing_jobs_audit_logs
    SET record_deleted_at = NOW()
    WHERE job_id IN (SELECT id FROM OLD);

    RETURN NULL;
END;
$$;

-- Fill the audit logs table with an entry corresponding to each job
-- in the syntactic_scip_indexing_jobs table. This is necessary to be able to enforce the
-- foreign key constraint after the migration transaction is over.
INSERT INTO syntactic_scip_indexing_jobs_audit_logs
    (job_id, tenant_id, operation, transition_columns)
SELECT job.id,
       job.tenant_id,
       'create',
       func_syntactic_scip_indexing_jobs_transition_columns_diff(
           (NULL, NULL, NULL, NULL, NULL, NULL)::syntactic_scip_indexing_jobs_transition_columns,
           (job.commit, job.state, job.num_resets, job.num_failures, job.worker_hostname, job.failure_message)
       )
FROM syntactic_scip_indexing_jobs job;


CREATE OR REPLACE TRIGGER trigger_syntactic_scip_indexing_jobs_delete
    AFTER DELETE
    ON syntactic_scip_indexing_jobs
    REFERENCING old TABLE old
EXECUTE PROCEDURE func_syntactic_scip_indexing_jobs_delete();

CREATE OR REPLACE TRIGGER trigger_syntactic_scip_indexing_jobs_insert
    AFTER INSERT
    ON syntactic_scip_indexing_jobs
    FOR EACH ROW
EXECUTE PROCEDURE func_syntactic_scip_indexing_jobs_insert();

CREATE OR REPLACE TRIGGER trigger_syntactic_scip_indexing_jobs_update
    BEFORE UPDATE
        OF commit, state, num_resets, num_failures, worker_hostname, failure_message
    ON syntactic_scip_indexing_jobs
    FOR EACH ROW
EXECUTE PROCEDURE func_syntactic_scip_indexing_jobs_update();
