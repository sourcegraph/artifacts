-- The trigger that fires when a batch change row is deleted (including via ON DELETE
-- CASCADE from a user/org namespace deletion) strips the batch change ID from each
-- associated changeset's batch_change_ids. Previously it did not stamp detached_at,
-- so a changeset that became fully detached this way was invisible to the
-- reconciler_changesets view AND never reaped by CleanDetachedChangesets (which keys
-- off detached_at) -- a permanent leak. Bump updated_at and stamp detached_at when the
-- array empties, so these rows flow through the normal detached-changeset retention
-- path. This must stay in sync with the application-level Store.DeleteBatchChange,
-- which performs the identical UPDATE.
CREATE OR REPLACE FUNCTION delete_batch_change_reference_on_changesets() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE
          changesets
        SET
          batch_change_ids = changesets.batch_change_ids - OLD.id::text,
          updated_at = NOW(),
          detached_at = CASE
              WHEN changesets.batch_change_ids - OLD.id::text = '{}'::jsonb
                   AND changesets.detached_at IS NULL
              THEN NOW()
              ELSE changesets.detached_at
          END
        WHERE
          changesets.batch_change_ids ? OLD.id::text;

        RETURN OLD;
    END;
$$;

-- Backfill: adopt already-orphaned changesets (fully detached but never stamped,
-- e.g. detached by the old trigger) into the retention path so the janitor can reap
-- them. Uses updated_at as the best available approximation of when the row went
-- stale, since the original detach time was not recorded.
UPDATE changesets
SET detached_at = updated_at
WHERE batch_change_ids = '{}'::jsonb
  AND detached_at IS NULL;
