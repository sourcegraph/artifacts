-- An experimental monitor is a classic cm_monitors row plus a cm_rules row.
-- Delete those monitors first; left behind, they would run as classic monitors
-- and notify on every raw match. Their queries and actions cascade.
DO $$
BEGIN
    IF to_regclass('cm_rules') IS NOT NULL THEN
        DELETE FROM cm_monitors WHERE id IN (SELECT monitor_id FROM cm_rules);
    END IF;
END
$$;

DROP TABLE IF EXISTS cm_rule_deliveries;
DROP TABLE IF EXISTS cm_rule_findings;
DROP TABLE IF EXISTS cm_rule_runs;
DROP TABLE IF EXISTS cm_rules;
