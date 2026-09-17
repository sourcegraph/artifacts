DROP TRIGGER IF EXISTS changeset_specs_set_diff_sha256 ON changeset_specs;
DROP FUNCTION IF EXISTS set_changeset_spec_diff_sha256();
ALTER TABLE changeset_specs DROP COLUMN IF EXISTS diff_sha256;
