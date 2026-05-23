ALTER TABLE changesets
    DROP CONSTRAINT IF EXISTS changesets_previous_spec_id_fkey;

ALTER TABLE changesets
    ADD CONSTRAINT changesets_previous_spec_id_fkey
        FOREIGN KEY (previous_spec_id)
            REFERENCES changeset_specs(id)
            DEFERRABLE;
