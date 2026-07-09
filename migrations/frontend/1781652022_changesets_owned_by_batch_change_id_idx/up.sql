-- Speeds up the changeset-attachments query (ListChangesetAttachments /
-- CountChangesetAttachments), which filters changesets by
-- owned_by_batch_change_id in both the "fresh" and "stale" CTEs. Without
-- this index the changesets table is sequentially scanned once per
-- candidate workspace. Partial because the equality filter never matches
-- the NULL (imported / unowned) rows. Leads with tenant_id so the index
-- also serves the implicit RLS tenant predicate.
CREATE INDEX CONCURRENTLY IF NOT EXISTS changesets_owned_by_batch_change_id
    ON changesets (tenant_id, owned_by_batch_change_id)
    WHERE owned_by_batch_change_id IS NOT NULL;
