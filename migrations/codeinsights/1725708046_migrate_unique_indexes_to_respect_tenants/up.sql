DO
$$
BEGIN
    IF to_regclass('insight_view_unique_id_unique_idx_new') IS NOT NULL THEN
        DROP INDEX IF EXISTS insight_view_unique_id_unique_idx;
        ALTER INDEX insight_view_unique_id_unique_idx_new RENAME TO insight_view_unique_id_unique_idx;
   END IF;
END
$$;
COMMIT AND CHAIN;

DO
$$
BEGIN
    IF to_regclass('metadata_metadata_unique_idx_new') IS NOT NULL THEN
        DROP INDEX IF EXISTS metadata_metadata_unique_idx;
        ALTER INDEX metadata_metadata_unique_idx_new RENAME TO metadata_metadata_unique_idx;
   END IF;
END
$$;
COMMIT AND CHAIN;

DO
$$
BEGIN
    IF to_regclass('repo_names_name_unique_idx_new') IS NOT NULL THEN
        DROP INDEX IF EXISTS repo_names_name_unique_idx;
        ALTER INDEX repo_names_name_unique_idx_new RENAME TO repo_names_name_unique_idx;
   END IF;
END
$$;
