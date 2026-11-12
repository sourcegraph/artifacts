-- Supports lookups of changesets by last_pushed_spec_id. Two paths depend on them:
--
-- * The batch changes spec expirer (DeleteExpiredChangesetSpecs) checks every
--   expired spec candidate for a changeset that still references it.
-- * The ON DELETE SET NULL action of changesets_last_pushed_spec_id_fkey runs
--   for every deleted changeset spec.
--
-- Without this index each lookup sequentially scans changesets, which makes the
-- expirer quadratic in the number of changesets.
CREATE INDEX CONCURRENTLY IF NOT EXISTS changesets_last_pushed_spec_id
    ON changesets (last_pushed_spec_id)
    WHERE last_pushed_spec_id IS NOT NULL;
