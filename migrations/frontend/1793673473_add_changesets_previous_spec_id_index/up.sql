-- Supports lookups of changesets by previous_spec_id. Two paths depend on them:
--
-- * The batch changes spec expirer (DeleteExpiredChangesetSpecs) checks every
--   expired spec candidate for a changeset that still references it.
-- * The ON DELETE SET NULL action of changesets_previous_spec_id_fkey runs for
--   every deleted changeset spec.
--
-- previous_spec_id is only the second column of changesets_changeset_specs, so
-- without this index each lookup reads the whole index, which makes the expirer
-- quadratic in the number of changesets.
CREATE INDEX CONCURRENTLY IF NOT EXISTS changesets_previous_spec_id
    ON changesets (previous_spec_id)
    WHERE previous_spec_id IS NOT NULL;
