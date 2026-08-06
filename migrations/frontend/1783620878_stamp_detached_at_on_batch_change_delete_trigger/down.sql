-- Restore the original trigger function that strips the batch change ID from
-- batch_change_ids without stamping detached_at. The one-off backfill that adopted
-- already-orphaned changesets into the retention path is not reversible.
CREATE OR REPLACE FUNCTION delete_batch_change_reference_on_changesets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE
          changesets
        SET
          batch_change_ids = changesets.batch_change_ids - OLD.id::text
        WHERE
          changesets.batch_change_ids ? OLD.id::text;

        RETURN OLD;
    END;
$$;
