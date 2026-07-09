CREATE INDEX IF NOT EXISTS batch_spec_workspaces_repo_path_branch
    ON batch_spec_workspaces (tenant_id, repo_id, path, branch);
