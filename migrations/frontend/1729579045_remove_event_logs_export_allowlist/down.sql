CREATE TABLE IF NOT EXISTS event_logs_export_allowlist (
    id SERIAL PRIMARY KEY,
    event_name text NOT NULL,
    tenant_id integer DEFAULT (current_setting('app.current_tenant'::text))::integer NOT NULL
);

COMMENT ON TABLE event_logs_export_allowlist IS 'An allowlist of events that are approved for export if the scraping job is enabled';

COMMENT ON COLUMN event_logs_export_allowlist.event_name IS 'Name of the event that corresponds to event_logs.name';

CREATE UNIQUE INDEX IF NOT EXISTS event_logs_export_allowlist_event_name_idx ON event_logs_export_allowlist USING btree (event_name, tenant_id);

ALTER TABLE event_logs_export_allowlist ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS event_logs_export_allowlist_isolation_policy ON event_logs_export_allowlist;
CREATE POLICY event_logs_export_allowlist_isolation_policy ON event_logs_export_allowlist USING ((tenant_id = (current_setting('app.current_tenant'::text))::integer));
