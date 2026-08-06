-- Records the user who requested the tour, so async generation can later be
-- attributed to and metered against that user. Nullable: existing rows and
-- unauthenticated requests have no user. ON DELETE SET NULL preserves the
-- cached tour (rows are shared per comparison, not owned by the requester)
-- when the user is deleted.
ALTER TABLE diff_tours
    ADD COLUMN IF NOT EXISTS user_id INTEGER REFERENCES users(id) ON DELETE SET NULL;

COMMENT ON COLUMN diff_tours.user_id IS 'The user who requested generation of this tour, or NULL for unauthenticated/legacy rows. Set to NULL if the user is deleted; the cached tour is retained.';
