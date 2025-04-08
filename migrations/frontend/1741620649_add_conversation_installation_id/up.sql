-- Perform migration here.
--
-- See /migrations/README.md. Highlights:
--  * Make migrations idempotent (use IF EXISTS)
--  * Make migrations backwards-compatible (old readers/writers must continue to work)
--  * If you are using CREATE INDEX CONCURRENTLY, then make sure that only one statement
--    is defined per file, and that each such statement is NOT wrapped in a transaction.
--    Each such migration must also declare "createIndexConcurrently: true" in their
--    associated metadata.yaml file.
--  * If you are modifying Postgres extensions, you must also declare "privileged: true"
--    in the associated metadata.yaml file.
--  * If you are inserting data, ensure your table is marked as a data table and that it
--    inserts for all tenants.

-- This is intentionally not a foreign key on github_app_installs.install_id
-- because it's not a unique column.
ALTER TABLE agent_conversations ADD COLUMN IF NOT EXISTS installation_id bigint GENERATED ALWAYS AS ((data->>'installation_id')::bigint) STORED;
CREATE INDEX IF NOT EXISTS agent_conversations_installation_id_idx ON agent_conversations (installation_id);
