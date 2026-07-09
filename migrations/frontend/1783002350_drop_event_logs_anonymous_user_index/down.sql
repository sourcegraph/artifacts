CREATE INDEX IF NOT EXISTS event_logs_anonymous_user_id ON event_logs USING btree (anonymous_user_id);
