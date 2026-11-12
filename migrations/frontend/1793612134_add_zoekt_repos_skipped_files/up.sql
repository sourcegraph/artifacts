ALTER TABLE zoekt_repos
    ADD COLUMN IF NOT EXISTS skipped_files jsonb,
    ADD COLUMN IF NOT EXISTS skipped_files_total bigint;

COMMENT ON COLUMN zoekt_repos.skipped_files IS 'Counts of files Zoekt skipped at index time, per skip reason, from the last index that reported them. NULL if never reported.';
COMMENT ON COLUMN zoekt_repos.skipped_files_total IS 'Number of distinct files Zoekt skipped at index time, summed over all skip reasons in skipped_files. NULL if never reported.';
