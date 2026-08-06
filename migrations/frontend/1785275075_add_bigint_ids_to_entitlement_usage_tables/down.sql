CREATE OR REPLACE FUNCTION migrate_entitlement_usage_drop_id_1785275075(target_table regclass)
RETURNS void AS $$
DECLARE
    table_name text := (SELECT relname FROM pg_class WHERE oid = target_table);
    legacy_constraint_name text := table_name || '_pkey';
    id_constraint_name text := table_name || '_id_pkey';
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = target_table
          AND conname = id_constraint_name
    ) THEN
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', target_table, id_constraint_name);
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = target_table
          AND conname = legacy_constraint_name
          AND contype = 'u'
    ) THEN
        EXECUTE format('ALTER TABLE %s DROP CONSTRAINT %I', target_table, legacy_constraint_name);
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_attribute
        WHERE attrelid = target_table
          AND attname = 'id'
          AND NOT attisdropped
    ) THEN
        EXECUTE format('ALTER TABLE %s DROP COLUMN id', target_table);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conrelid = target_table
          AND conname = legacy_constraint_name
    ) THEN
        EXECUTE format(
            'ALTER TABLE %s ADD CONSTRAINT %I PRIMARY KEY (user_id, entitlement_id)',
            target_table,
            legacy_constraint_name
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT migrate_entitlement_usage_drop_id_1785275075('batch_changes_coding_agent_entitlement_usage');
SELECT migrate_entitlement_usage_drop_id_1785275075('deepsearch_entitlement_usage');
SELECT migrate_entitlement_usage_drop_id_1785275075('diff_tour_entitlement_usage');
SELECT migrate_entitlement_usage_drop_id_1785275075('mcp_code_finder_entitlement_usage');
SELECT migrate_entitlement_usage_drop_id_1785275075('smart_hover_summary_entitlement_usage');

DROP FUNCTION migrate_entitlement_usage_drop_id_1785275075(regclass);
