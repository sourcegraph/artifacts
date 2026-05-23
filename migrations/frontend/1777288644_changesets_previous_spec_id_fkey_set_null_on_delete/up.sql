-- Alter changesets_previous_spec_id_fkey to SET NULL on delete.
-- Previously the constraint had no ON DELETE action, which caused a FK
-- violation when DeleteBatchSpec cascaded to changeset_specs while live
-- changesets still referenced those rows via previous_spec_id.
-- NULL is the correct state here: if the previous spec no longer exists,
-- the changeset simply has no previous spec.
ALTER TABLE changesets
    DROP CONSTRAINT IF EXISTS changesets_previous_spec_id_fkey;

ALTER TABLE changesets
    ADD CONSTRAINT changesets_previous_spec_id_fkey
        FOREIGN KEY (previous_spec_id)
            REFERENCES changeset_specs(id)
            ON DELETE SET NULL
            DEFERRABLE;
