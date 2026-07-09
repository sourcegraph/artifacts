-- Speeds up the "stale" CTE of the changeset-attachments query
-- (ListChangesetAttachments / CountChangesetAttachments), which joins
-- batch_spec_workspaces to itself on (repo_id, path, branch) to find prior
-- specs of the same batch change. Without this index that self-join
-- requires a sequential scan of the whole batch_spec_workspaces table.
-- Leads with tenant_id so the index also serves the implicit RLS tenant
-- predicate.
CREATE INDEX CONCURRENTLY IF NOT EXISTS batch_spec_workspaces_repo_path_branch
    ON batch_spec_workspaces (tenant_id, repo_id, path, branch);
