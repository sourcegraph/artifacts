ALTER TABLE changeset_specs ADD COLUMN IF NOT EXISTS diff_sha256 bytea;

-- Keep old frontend and worker versions compatible during a rolling deployment.
-- Remove this trigger in a follow-up migration after the previous version has
-- been fully drained.
CREATE OR REPLACE FUNCTION set_changeset_spec_diff_sha256() RETURNS trigger AS $$
BEGIN
    IF NEW.diff_sha256 IS NULL OR (
        TG_OP = 'UPDATE'
        AND NEW.diff IS DISTINCT FROM OLD.diff
        AND NEW.diff_sha256 IS NOT DISTINCT FROM OLD.diff_sha256
    ) THEN
        NEW.diff_sha256 = digest(COALESCE(NEW.diff, ''::bytea), 'sha256');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS changeset_specs_set_diff_sha256 ON changeset_specs;
CREATE TRIGGER changeset_specs_set_diff_sha256
BEFORE INSERT OR UPDATE OF diff ON changeset_specs
FOR EACH ROW EXECUTE FUNCTION set_changeset_spec_diff_sha256();

-- Commit each shard independently to bound transaction and WAL size. The main
-- changeset_specs heap is small because diff is stored out of line, so repeated
-- scans are cheap compared with reading and hashing the matching patches.
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 0;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 1;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 2;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 3;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 4;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 5;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 6;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 7;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 8;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 9;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 10;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 11;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 12;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 13;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 14;
COMMIT AND CHAIN;
UPDATE changeset_specs SET diff_sha256 = digest(COALESCE(diff, ''::bytea), 'sha256') WHERE diff_sha256 IS NULL AND id % 16 = 15;
COMMIT AND CHAIN;

ALTER TABLE changeset_specs ALTER COLUMN diff_sha256 SET NOT NULL;
