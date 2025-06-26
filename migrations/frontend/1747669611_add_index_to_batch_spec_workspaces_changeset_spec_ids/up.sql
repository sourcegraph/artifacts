-- Add a gin index on the changeset_spec_ids column
CREATE INDEX IF NOT EXISTS batch_spec_workspaces_changeset_spec_ids_gin_idx ON batch_spec_workspaces USING gin (changeset_spec_ids);
