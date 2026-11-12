ALTER TABLE zoekt_repos
    DROP COLUMN IF EXISTS skipped_files,
    DROP COLUMN IF EXISTS skipped_files_total;
