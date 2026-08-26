ALTER TABLE gitserver_repos
DROP CONSTRAINT IF EXISTS gitserver_repos_default_branch_tip_metadata_consistent;

ALTER TABLE gitserver_repos
DROP COLUMN IF EXISTS default_branch_tip_commit_id;

ALTER TABLE gitserver_repos
DROP COLUMN IF EXISTS default_branch_tip_commit_date;
