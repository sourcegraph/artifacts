-- changeset_spec_id records which changeset spec was current on the changeset
-- when the hook job was enqueued. It scopes the per-changeset firing cap (and
-- the spawn-time workspace resolution) so that applying a new changeset spec
-- grants the hook a fresh attempt budget, and so a hook enqueued under one spec
-- never runs against a newer spec's steps.
--
-- It is intentionally a plain bigint with NO foreign key to changeset_specs: the
-- value is only ever compared numerically to changesets.current_spec_id (never
-- dereferenced), and changeset_specs.id is a bigserial that is never reused. A
-- foreign key would either block changeset_spec garbage collection, or (with ON
-- DELETE SET NULL) silently null the recorded spec when the spec is GC'd —
-- making a stale job indistinguishable from a legacy pre-migration row and
-- letting it run against the current spec. Keeping the raw id snapshot means a
-- GC'd spec still reads as "!= current spec" and is correctly treated as stale.
-- NULL therefore means only "legacy row enqueued before this column existed".
ALTER TABLE changeset_hook_jobs
    ADD COLUMN IF NOT EXISTS changeset_spec_id bigint;

-- The dedup unique indexes must be scoped by changeset_spec_id to match the
-- app-level NOT EXISTS/COUNT guard in Store.InsertChangesetHookJob: without the
-- spec in the index, ON CONFLICT DO NOTHING would silently drop a fresh-spec
-- firing whenever an in-flight job from a prior spec shared the same commit_oid
-- (or both had a NULL commit_oid). COALESCE(changeset_spec_id, 0) gives NULL-safe
-- uniqueness matching the query's IS NOT DISTINCT FROM semantics (spec ids are
-- always positive, so 0 can never collide with a real spec).
DROP INDEX IF EXISTS changeset_hook_jobs_dedup_with_oid;
CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_with_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type, commit_oid, COALESCE(changeset_spec_id, 0))
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NOT NULL;

DROP INDEX IF EXISTS changeset_hook_jobs_dedup_without_oid;
CREATE UNIQUE INDEX IF NOT EXISTS changeset_hook_jobs_dedup_without_oid
    ON changeset_hook_jobs (changeset_id, tenant_id, hook_type, COALESCE(changeset_spec_id, 0))
    WHERE state IN ('queued', 'processing', 'errored')
      AND commit_oid IS NULL;
