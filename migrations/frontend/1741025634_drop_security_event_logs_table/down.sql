CREATE SEQUENCE IF NOT EXISTS security_event_logs_id_seq
                START WITH 1
                INCREMENT BY 1
                NO MINVALUE
                NO MAXVALUE
                CACHE 1;

CREATE TABLE IF NOT EXISTS security_event_logs (
    id bigint NOT NULL PRIMARY KEY DEFAULT nextval('security_event_logs_id_seq'::regclass),
    name text NOT NULL,
    url text NOT NULL,
    user_id integer NOT NULL,
    anonymous_user_id text NOT NULL,
    source text NOT NULL,
    argument jsonb NOT NULL,
    version text NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL,
    CONSTRAINT security_event_logs_check_has_user CHECK ((((user_id = 0) AND (anonymous_user_id <> ''::text)) OR ((user_id <> 0) AND (anonymous_user_id = ''::text)) OR ((user_id <> 0) AND (anonymous_user_id <> ''::text)))),
    CONSTRAINT security_event_logs_check_name_not_empty CHECK ((name <> ''::text)),
    CONSTRAINT security_event_logs_check_source_not_empty CHECK ((source <> ''::text)),
    CONSTRAINT security_event_logs_check_version_not_empty CHECK ((version <> ''::text))
);

ALTER SEQUENCE security_event_logs_id_seq OWNED BY security_event_logs.id;

COMMENT ON TABLE security_event_logs IS 'Contains security-relevant events with a long time horizon for storage.';
COMMENT ON COLUMN security_event_logs.name IS 'The event name as a CAPITALIZED_SNAKE_CASE string.';
COMMENT ON COLUMN security_event_logs.url IS 'The URL within the Sourcegraph app which generated the event.';
COMMENT ON COLUMN security_event_logs.user_id IS 'The ID of the actor associated with the event.';
COMMENT ON COLUMN security_event_logs.anonymous_user_id IS 'The UUID of the actor associated with the event.';
COMMENT ON COLUMN security_event_logs.source IS 'The site section (WEB, BACKEND, etc.) that generated the event.';
COMMENT ON COLUMN security_event_logs.argument IS 'An arbitrary JSON blob containing event data.';
COMMENT ON COLUMN security_event_logs.version IS 'The version of Sourcegraph which generated the event.';

ALTER TABLE security_event_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS tenant_isolation_policy ON security_event_logs;
CREATE POLICY tenant_isolation_policy ON security_event_logs USING ((tenant_id = ( SELECT (current_setting('app.current_tenant'::text))::integer AS current_tenant)));

CREATE INDEX IF NOT EXISTS security_event_logs_timestamp ON security_event_logs USING btree ("timestamp");
