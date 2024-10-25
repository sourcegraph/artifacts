CREATE INDEX IF NOT EXISTS rockskip_ancestry_repo_commit_id ON rockskip_ancestry USING btree (repo_id, commit_id);
