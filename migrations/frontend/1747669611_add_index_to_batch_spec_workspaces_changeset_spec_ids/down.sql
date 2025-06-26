-- remove the gin index on the changeset_spec_ids column
DROP INDEX IF EXISTS batch_spec_workspaces_changeset_spec_ids_gin_idx;
