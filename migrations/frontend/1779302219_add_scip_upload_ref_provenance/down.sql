ALTER TABLE scip_uploads
    DROP COLUMN IF EXISTS ref,
    DROP COLUMN IF EXISTS ref_type;
